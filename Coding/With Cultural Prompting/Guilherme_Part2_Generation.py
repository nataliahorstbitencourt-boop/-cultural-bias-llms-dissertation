#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Guilherme_Part2_Generation.py  —  ETAPA A (geração, braço CULTURAL)
===================================================================

Único script que chama a API no braço cultural. Varre os países de Países.csv e,
para cada país, roda 10 variantes de persona x 10 perguntas. O país é injetado no
system prompt (decisão A). Total: n_países x 10 x 10.

Dois motores de execução, escolhidos por cfg.USE_BATCH_API:
  - False  -> POOL DE THREADS: cfg.MAX_CONCURRENCY chamadas simultâneas, em tempo real.
  - True   -> BATCH API: submete um lote assíncrono (~50% mais barato, pode levar
              horas) e, quando pronto, baixa e grava os resultados. Reexecutar o
              script retoma o acompanhamento do mesmo batch (estado salvo em disco).

Em ambos os modos preserva: Structured Outputs opcional (cfg.USE_STRUCTURED_OUTPUTS),
retomada por (country, variant, scale), escrita incremental (CSV + JSONL), proveniência,
resiliência a erro por chamada (status "error_<código>") e estimativa de custo.
Nenhuma matemática de scoring aqui (Etapa B).

Saídas (mesma pasta):
  - Guilherme_Cultural_Raw_<model>.csv
  - Guilherme_Cultural_completions_<model>.jsonl
  (modo Batch, auxiliares) Guilherme_Cultural_batch_input_<model>.jsonl e
                            Guilherme_Cultural_batch_state_<model>.json

Pré-requisitos:
  - OPENAI_API_KEY definida
  - Guilherme_Prompts_Questions.csv,
    Guilherme_Prompts_Respondent_Descriptors_Cultural.csv e Países.csv na mesma pasta
"""

import csv
import json
import os
import re
import sys
import threading
import time
import uuid
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone

import pandas as pd
from openai import OpenAI

import Guilherme_Config as cfg

try:
    from openai import (
        RateLimitError,
        APITimeoutError,
        APIConnectionError,
        InternalServerError,
    )
    TRANSIENT_ERRORS = (
        RateLimitError,
        APITimeoutError,
        APIConnectionError,
        InternalServerError,
    )
except Exception:  # pragma: no cover
    from openai import OpenAIError
    TRANSIENT_ERRORS = (OpenAIError,)

# Erro de API não-transitório (ex.: 403/400): não derruba a run; a célula é
# registrada com status "error" e o loop segue. Como células não-`ok` não entram
# no "done", num re-run elas são re-tentadas automaticamente.
try:
    from openai import APIError as _APIError
except Exception:  # pragma: no cover
    _APIError = Exception


try:
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
except NameError:
    BASE_DIR = os.getcwd()

QUESTIONS_CSV = os.path.join(BASE_DIR, "Guilherme_Prompts_Questions.csv")
DESCRIPTORS_CSV = os.path.join(
    BASE_DIR, "Guilherme_Prompts_Respondent_Descriptors_Cultural.csv")
PAISES_CSV = os.path.join(BASE_DIR, cfg.PAISES_CSV)

MODEL_SLUG = re.sub(r"[^A-Za-z0-9._-]", "-", cfg.MODEL)
RAW_CSV = os.path.join(BASE_DIR, f"Guilherme_Cultural_Raw_{MODEL_SLUG}.csv")
JSONL = os.path.join(BASE_DIR, f"Guilherme_Cultural_completions_{MODEL_SLUG}.jsonl")
BATCH_INPUT = os.path.join(BASE_DIR, f"Guilherme_Cultural_batch_input_{MODEL_SLUG}.jsonl")
BATCH_STATE = os.path.join(BASE_DIR, f"Guilherme_Cultural_batch_state_{MODEL_SLUG}.json")

FIELDNAMES = [
    "run_id", "timestamp", "model", "reasoning_effort", "mode",
    "#variant", "country", "category", "scale", "survey_question",
    "raw_answer", "status", "finish_reason",
    "prompt_tokens", "completion_tokens", "reasoning_tokens", "total_tokens",
]

NULL_TOK = {"prompt_tokens": None, "completion_tokens": None,
            "reasoning_tokens": None, "total_tokens": None}

MAX_RETRIES = 6
BASE_BACKOFF = 2.0  # segundos


# ---------------------------------------------------------------------------
# Interpretação da resposta (compartilhada pelos dois motores)
# ---------------------------------------------------------------------------
def _interpret_core(content, refusal, finish, usage):
    """Decide (raw_answer, status, finish, tokens) a partir dos campos crus."""
    details = (usage or {}).get("completion_tokens_details") or {}
    tokens = {
        "prompt_tokens": (usage or {}).get("prompt_tokens"),
        "completion_tokens": (usage or {}).get("completion_tokens"),
        "reasoning_tokens": details.get("reasoning_tokens"),
        "total_tokens": (usage or {}).get("total_tokens"),
    }

    if not cfg.USE_STRUCTURED_OUTPUTS:
        # Texto livre: guarda o cru; parsing/flagging fica para a Etapa B.
        if refusal:
            return refusal, "refusal", finish, tokens
        text = (content or "").strip()
        if not text:
            return "", "empty", finish, tokens
        return text, "ok", finish, tokens

    # Structured Outputs
    if refusal:
        return json.dumps({"refusal": refusal}), "refusal", finish, tokens
    if finish == "length":
        return "", "truncated", finish, tokens
    text = (content or "").strip()
    if not text:
        return "", "empty", finish, tokens
    try:
        parsed = json.loads(text)
    except json.JSONDecodeError:
        return text, "unparseable", finish, tokens
    return json.dumps(parsed, ensure_ascii=False), "ok", finish, tokens


def interpret(completion):
    """Extrai de um objeto de completion do SDK (modo pool de threads)."""
    ch = completion.choices[0]
    msg = ch.message
    u = completion.usage
    usage = {}
    if u:
        usage = {"prompt_tokens": u.prompt_tokens,
                 "completion_tokens": u.completion_tokens,
                 "total_tokens": u.total_tokens}
        d = getattr(u, "completion_tokens_details", None)
        if d:
            usage["completion_tokens_details"] = {
                "reasoning_tokens": getattr(d, "reasoning_tokens", None)}
    return _interpret_core(msg.content, getattr(msg, "refusal", None),
                           ch.finish_reason, usage)


def serialize_completion(completion):
    usage = getattr(completion, "usage", None)
    reasoning_tokens = None
    if usage is not None:
        details = getattr(usage, "completion_tokens_details", None)
        if details is not None:
            reasoning_tokens = getattr(details, "reasoning_tokens", None)
    return {
        "id": completion.id,
        "created": completion.created,
        "model": completion.model,
        "object": completion.object,
        "choices": [
            {
                "index": ch.index,
                "finish_reason": ch.finish_reason,
                "message": {
                    "role": ch.message.role,
                    "content": ch.message.content,
                    "refusal": getattr(ch.message, "refusal", None),
                },
            }
            for ch in completion.choices
        ],
        "usage": {
            "prompt_tokens": usage.prompt_tokens,
            "completion_tokens": usage.completion_tokens,
            "reasoning_tokens": reasoning_tokens,
            "total_tokens": usage.total_tokens,
        } if usage else None,
    }


def _serialize_body(body):
    """Serializa um corpo de chat completion vindo do Batch API (dict puro)."""
    u = body.get("usage") or {}
    details = u.get("completion_tokens_details") or {}
    return {
        "id": body.get("id"),
        "created": body.get("created"),
        "model": body.get("model"),
        "object": body.get("object"),
        "choices": [
            {
                "index": c.get("index"),
                "finish_reason": c.get("finish_reason"),
                "message": {
                    "role": (c.get("message") or {}).get("role"),
                    "content": (c.get("message") or {}).get("content"),
                    "refusal": (c.get("message") or {}).get("refusal"),
                },
            }
            for c in (body.get("choices") or [])
        ],
        "usage": {
            "prompt_tokens": u.get("prompt_tokens"),
            "completion_tokens": u.get("completion_tokens"),
            "reasoning_tokens": details.get("reasoning_tokens"),
            "total_tokens": u.get("total_tokens"),
        } if u else None,
    }


# ---------------------------------------------------------------------------
# Chamada com retry/backoff (erros transitórios)
# ---------------------------------------------------------------------------
def call_with_retry(client, system, question, scale):
    attempt = 0
    while True:
        try:
            kwargs = dict(
                model=cfg.MODEL,
                messages=[
                    {"role": "system", "content": system},
                    {"role": "user", "content": question},
                ],
                reasoning_effort=cfg.REASONING_EFFORT,
                max_completion_tokens=cfg.MAX_COMPLETION_TOKENS,
            )
            if cfg.USE_STRUCTURED_OUTPUTS:
                kwargs["response_format"] = cfg.response_format_for(scale)
            return client.chat.completions.create(**kwargs)
        except TRANSIENT_ERRORS as exc:
            attempt += 1
            if attempt > MAX_RETRIES:
                raise
            delay = BASE_BACKOFF * (2 ** (attempt - 1))
            print(f"    [retry {attempt}/{MAX_RETRIES}] {type(exc).__name__}: "
                  f"aguardando {delay:.0f}s", file=sys.stderr)
            time.sleep(delay)


# ---------------------------------------------------------------------------
# Tarefas e carregamento
# ---------------------------------------------------------------------------
def _ident(task):
    return {k: task[k] for k in ("country", "category", "variant", "scale", "question")}


def build_body(task):
    body = {
        "model": cfg.MODEL,
        "messages": [
            {"role": "system", "content": task["system"]},
            {"role": "user", "content": task["question"]},
        ],
        "reasoning_effort": cfg.REASONING_EFFORT,
        "max_completion_tokens": cfg.MAX_COMPLETION_TOKENS,
    }
    if cfg.USE_STRUCTURED_OUTPUTS:
        body["response_format"] = cfg.response_format_for(task["scale"])
    return body


def load_done():
    done = set()
    if os.path.exists(RAW_CSV):
        with open(RAW_CSV, newline="", encoding="utf-8") as fh:
            for row in csv.DictReader(fh):
                if row.get("status") == "ok":
                    done.add((row["country"], row["#variant"], row["scale"]))
    return done


def load_countries():
    df = pd.read_csv(PAISES_CSV)
    countries = [
        (str(r[cfg.COUNTRY_NAME_COL]).strip(), str(r[cfg.CATEGORY_COL]).strip())
        for _, r in df.iterrows()
    ]
    if cfg.COUNTRY_LIMIT is not None:
        countries = countries[:cfg.COUNTRY_LIMIT]
    return countries


def build_tasks(countries, variants, questions, done):
    tasks = []
    for country, category in countries:
        for _, vrow in variants.iterrows():
            variant = vrow["#variant"]
            system = cfg.build_system_prompt(vrow["respondent_descriptor"], country)
            for _, qrow in questions.iterrows():
                scale = qrow["scale"]
                if (country, variant, scale) in done:
                    continue
                tasks.append({
                    "country": country, "category": category, "variant": variant,
                    "scale": scale, "question": qrow["prompt"], "system": system,
                })
    return tasks


def estimate_cost(prompt_tokens, completion_tokens):
    """Custo em USD do modelo ativo. completion_tokens já inclui raciocínio."""
    p = cfg.prices_for(cfg.MODEL)
    return (prompt_tokens * p["input"] + completion_tokens * p["output"]) / 1_000_000


# ---------------------------------------------------------------------------
# Escrita de um resultado (thread-safe)
# ---------------------------------------------------------------------------
def write_result(res, ctx):
    with ctx["lock"]:
        ctx["writer"].writerow({
            "run_id": ctx["run_id"],
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "model": res["model_name"],
            "reasoning_effort": cfg.REASONING_EFFORT,
            "mode": "structured" if cfg.USE_STRUCTURED_OUTPUTS else "free_text",
            "#variant": res["variant"],
            "country": res["country"],
            "category": res["category"],
            "scale": res["scale"],
            "survey_question": res["question"],
            "raw_answer": res["raw_answer"],
            "status": res["status"],
            "finish_reason": res["finish"],
            **res["tok"],
        })
        ctx["csv_fh"].flush()

        if res["completion"] is not None:
            ctx["jsonl_fh"].write(
                json.dumps(res["completion"], ensure_ascii=False) + "\n")
            ctx["jsonl_fh"].flush()
            ctx["spent"]["prompt"] += res["tok"]["prompt_tokens"] or 0
            ctx["spent"]["completion"] += res["tok"]["completion_tokens"] or 0
            ctx["spent"]["calls"] += 1

        ctx["prog"]["done"] += 1
        if ctx["prog"]["done"] % cfg.PROGRESS_EVERY == 0:
            print(f"[{ctx['prog']['done']}/{ctx['total']}] | última: "
                  f"{res['country']} / {res['variant']} / {res['scale']} "
                  f"(status={res['status']})")
        if res["status"] != "ok":
            print(f"    AVISO: {res['country']} / {res['variant']} / "
                  f"{res['scale']} status={res['status']}", file=sys.stderr)


# ---------------------------------------------------------------------------
# Motor 1: pool de threads
# ---------------------------------------------------------------------------
def process_cell(client, task):
    try:
        completion = call_with_retry(client, task["system"], task["question"],
                                     task["scale"])
        raw_answer, status, finish, tok = interpret(completion)
        return {**_ident(task), "model_name": completion.model,
                "raw_answer": raw_answer, "status": status, "finish": finish,
                "tok": tok, "completion": serialize_completion(completion)}
    except _APIError as exc:
        code = getattr(exc, "status_code", None)
        return {**_ident(task), "model_name": cfg.MODEL, "raw_answer": str(exc),
                "status": f"error_{code}" if code else "error", "finish": None,
                "tok": dict(NULL_TOK), "completion": None}
    except Exception as exc:  # não deixa uma thread derrubar a run
        return {**_ident(task), "model_name": cfg.MODEL, "raw_answer": repr(exc),
                "status": "error", "finish": None, "tok": dict(NULL_TOK),
                "completion": None}


def run_threadpool(client, tasks, ctx):
    print(f"Motor: pool de threads (MAX_CONCURRENCY={cfg.MAX_CONCURRENCY})")
    with ThreadPoolExecutor(max_workers=cfg.MAX_CONCURRENCY) as ex:
        futures = [ex.submit(process_cell, client, t) for t in tasks]
        for fut in as_completed(futures):
            write_result(fut.result(), ctx)


# ---------------------------------------------------------------------------
# Motor 2: Batch API
# ---------------------------------------------------------------------------
def _handle_batch_line(obj, mapping, ctx):
    cid = obj.get("custom_id")
    info = mapping.get(cid, {"country": None, "category": None, "variant": None,
                             "scale": None, "question": None})
    resp = obj.get("response")
    if resp and resp.get("status_code") == 200 and resp.get("body"):
        body = resp["body"]
        ch = (body.get("choices") or [{}])[0]
        msg = ch.get("message") or {}
        raw_answer, status, finish, tok = _interpret_core(
            msg.get("content"), msg.get("refusal"),
            ch.get("finish_reason"), body.get("usage") or {})
        res = {**info, "model_name": body.get("model", cfg.MODEL),
               "raw_answer": raw_answer, "status": status, "finish": finish,
               "tok": tok, "completion": _serialize_body(body)}
    else:
        code = (resp or {}).get("status_code")
        res = {**info, "model_name": cfg.MODEL,
               "raw_answer": json.dumps(obj.get("error") or resp or {}),
               "status": f"error_{code}" if code else "error", "finish": None,
               "tok": dict(NULL_TOK), "completion": None}
    write_result(res, ctx)


def run_batch(client, tasks, ctx):
    # Submete (se ainda não há batch em andamento) ou retoma o acompanhamento.
    if os.path.exists(BATCH_STATE):
        state = json.load(open(BATCH_STATE, encoding="utf-8"))
        batch_id = state["batch_id"]
        mapping = state["mapping"]
        print(f"Batch em andamento encontrado: {batch_id} — retomando acompanhamento.")
    else:
        if not tasks:
            print("Nada pendente para submeter ao batch.")
            return
        mapping = {}
        with open(BATCH_INPUT, "w", encoding="utf-8") as f:
            for i, t in enumerate(tasks):
                cid = str(i)
                mapping[cid] = _ident(t)
                f.write(json.dumps({
                    "custom_id": cid, "method": "POST",
                    "url": "/v1/chat/completions", "body": build_body(t),
                }, ensure_ascii=False) + "\n")
        up = client.files.create(file=open(BATCH_INPUT, "rb"), purpose="batch")
        batch = client.batches.create(input_file_id=up.id,
                                       endpoint="/v1/chat/completions",
                                       completion_window="24h")
        batch_id = batch.id
        json.dump({"batch_id": batch_id, "input_file_id": up.id, "mapping": mapping},
                  open(BATCH_STATE, "w", encoding="utf-8"))
        print(f"Batch submetido: {batch_id} ({len(tasks)} requisições). "
              f"Estado salvo em {BATCH_STATE}.")

    # Poll até um estado terminal.
    while True:
        b = client.batches.retrieve(batch_id)
        rc = getattr(b, "request_counts", None)
        done_n = getattr(rc, "completed", None) if rc else None
        total_n = getattr(rc, "total", None) if rc else None
        print(f"  status do batch: {b.status}  (concluídas: {done_n}/{total_n})")
        if b.status in ("completed", "failed", "expired", "cancelled"):
            break
        time.sleep(cfg.BATCH_POLL_SECONDS)

    if b.status != "completed":
        print(f"Batch terminou com status '{b.status}'. "
              f"Verifique no painel da OpenAI; o estado foi mantido em {BATCH_STATE}.",
              file=sys.stderr)
        return

    # Baixa saídas (e erros) e grava.
    if getattr(b, "output_file_id", None):
        for line in client.files.content(b.output_file_id).text.splitlines():
            if line.strip():
                _handle_batch_line(json.loads(line), mapping, ctx)
    if getattr(b, "error_file_id", None):
        for line in client.files.content(b.error_file_id).text.splitlines():
            if line.strip():
                _handle_batch_line(json.loads(line), mapping, ctx)

    os.remove(BATCH_STATE)  # sucesso: limpa o estado para um próximo run começar limpo


# ---------------------------------------------------------------------------
def main():
    if not os.environ.get("OPENAI_API_KEY"):
        sys.exit("Erro: defina a variável de ambiente OPENAI_API_KEY antes de rodar.")

    client = OpenAI()

    question_list = pd.read_csv(QUESTIONS_CSV)
    prompt_variant_list = pd.read_csv(DESCRIPTORS_CSV)
    countries = load_countries()

    done = load_done()
    if done:
        print(f"Retomando: {len(done)} células já coletadas serão puladas.")
    print(f"Países a processar: {len(countries)} (COUNTRY_LIMIT={cfg.COUNTRY_LIMIT})")

    tasks = build_tasks(countries, prompt_variant_list, question_list, done)
    print(f"Chamadas pendentes nesta execução: {len(tasks)}")

    new_csv = not os.path.exists(RAW_CSV) or os.path.getsize(RAW_CSV) == 0
    csv_fh = open(RAW_CSV, "a", newline="", encoding="utf-8")
    writer = csv.DictWriter(csv_fh, fieldnames=FIELDNAMES)
    if new_csv:
        writer.writeheader()
        csv_fh.flush()
    jsonl_fh = open(JSONL, "a", encoding="utf-8")

    ctx = {
        "writer": writer, "csv_fh": csv_fh, "jsonl_fh": jsonl_fh,
        "spent": {"prompt": 0, "completion": 0, "calls": 0},
        "prog": {"done": 0}, "total": len(tasks),
        "run_id": uuid.uuid4().hex[:12], "lock": threading.Lock(),
    }

    try:
        if cfg.USE_BATCH_API:
            run_batch(client, tasks, ctx)
        else:
            run_threadpool(client, tasks, ctx)
    finally:
        csv_fh.close()
        jsonl_fh.close()
        spent = ctx["spent"]
        if spent["calls"]:
            cost = estimate_cost(spent["prompt"], spent["completion"])
            p = cfg.prices_for(cfg.MODEL)
            print(f"\n--- Custo desta execução ({spent['calls']} chamadas) ---")
            print(f"  modelo: {cfg.MODEL}")
            print(f"  tokens: input={spent['prompt']} output={spent['completion']}")
            print(f"  custo estimado: US$ {cost:.4f} "
                  f"(input ${p['input']}/1M, output ${p['output']}/1M)")

    print(f"\nConcluído. Dados crus em:\n  {RAW_CSV}\n  {JSONL}")
    print("Rode Guilherme_Part2_Scoring.py para gerar os scores e a wide table.")


if __name__ == "__main__":
    main()
