#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Guilherme_Part1_Generation.py  —  ETAPA A (geração)
====================================================

Único script que chama a API. Para o braço SEM cultural prompting:
roda 10 variantes de persona x 10 perguntas = 100 chamadas (N=1, decisão F5).

Para cada célula:
  - usa Structured Outputs estrito (schema por `scale`, de Guilherme_Config)
  - reasoning_effort="minimal", max_completion_tokens=2048
  - grava a RESPOSTA CRUA (nos termos da pergunta) + proveniência completa

Nenhuma matemática de scoring acontece aqui (desacoplamento, D6).

Robustez:
  - retry com backoff exponencial em erros transitórios (D7)
  - escrita INCREMENTAL em CSV + JSONL de auditoria (D8); nada se perde num crash
  - RETOMADA automática: células já coletadas (variant, scale) são puladas

Saídas (na mesma pasta):
  - Guilherme_General_Raw_<model>.csv          (long: 1 linha por célula)
  - Guilherme_General_completions_<model>.jsonl (objetos de completion, auditoria)

Pré-requisitos:
  - variável de ambiente OPENAI_API_KEY definida
  - arquivos Guilherme_Prompts_Questions.csv e
    Prompts_Respondent_Descriptors_General.csv na mesma pasta
"""

import csv
import json
import os
import re
import sys
import time
import uuid
from datetime import datetime, timezone

import pandas as pd
from openai import OpenAI

import Guilherme_Config as cfg

# openai expõe as exceções no topo do pacote; importamos de forma defensiva
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
except Exception:  # pragma: no cover - fallback p/ versões diferentes do SDK
    from openai import OpenAIError
    TRANSIENT_ERRORS = (OpenAIError,)


# ---------------------------------------------------------------------------
# Caminhos (resolvidos relativos a este arquivo, funciona de qualquer cwd)
# ---------------------------------------------------------------------------
try:
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
except NameError:  # execução interativa / notebook
    BASE_DIR = os.getcwd()

QUESTIONS_CSV = os.path.join(BASE_DIR, "Guilherme_Prompts_Questions.csv")
DESCRIPTORS_CSV = os.path.join(BASE_DIR, "Prompts_Respondent_Descriptors_General.csv")

MODEL_SLUG = re.sub(r"[^A-Za-z0-9._-]", "-", cfg.MODEL)
RAW_CSV = os.path.join(BASE_DIR, f"Guilherme_General_Raw_{MODEL_SLUG}.csv")
JSONL = os.path.join(BASE_DIR, f"Guilherme_General_completions_{MODEL_SLUG}.jsonl")

FIELDNAMES = [
    "run_id", "timestamp", "model", "reasoning_effort",
    "#variant", "country", "scale", "survey_question",
    "raw_answer", "status", "finish_reason",
    "prompt_tokens", "completion_tokens", "reasoning_tokens", "total_tokens",
]

MAX_RETRIES = 6
BASE_BACKOFF = 2.0  # segundos


# ---------------------------------------------------------------------------
# Serialização do objeto de completion (auditoria)
# ---------------------------------------------------------------------------
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


# ---------------------------------------------------------------------------
# Chamada com retry/backoff (D7)
# ---------------------------------------------------------------------------
def call_with_retry(client, system, question, scale):
    attempt = 0
    while True:
        try:
            return client.chat.completions.create(
                model=cfg.MODEL,
                messages=[
                    {"role": "system", "content": system},
                    {"role": "user", "content": question},
                ],
                reasoning_effort=cfg.REASONING_EFFORT,
                max_completion_tokens=cfg.MAX_COMPLETION_TOKENS,
                response_format=cfg.response_format_for(scale),
            )
        except TRANSIENT_ERRORS as exc:
            attempt += 1
            if attempt > MAX_RETRIES:
                raise
            delay = BASE_BACKOFF * (2 ** (attempt - 1))
            print(f"    [retry {attempt}/{MAX_RETRIES}] {type(exc).__name__}: "
                  f"aguardando {delay:.0f}s", file=sys.stderr)
            time.sleep(delay)


def interpret(completion):
    """Extrai (raw_answer_json, status, finish_reason, tokens) de uma completion."""
    ch = completion.choices[0]
    msg = ch.message
    finish = ch.finish_reason
    usage = completion.usage
    reasoning_tokens = None
    if usage is not None:
        details = getattr(usage, "completion_tokens_details", None)
        if details is not None:
            reasoning_tokens = getattr(details, "reasoning_tokens", None)

    tokens = {
        "prompt_tokens": usage.prompt_tokens if usage else None,
        "completion_tokens": usage.completion_tokens if usage else None,
        "reasoning_tokens": reasoning_tokens,
        "total_tokens": usage.total_tokens if usage else None,
    }

    if getattr(msg, "refusal", None):
        return json.dumps({"refusal": msg.refusal}), "refusal", finish, tokens
    if finish == "length":
        return "", "truncated", finish, tokens
    content = (msg.content or "").strip()
    if not content:
        return "", "empty", finish, tokens
    try:
        parsed = json.loads(content)
    except json.JSONDecodeError:
        # Com Structured Outputs isto não deveria ocorrer; guardamos o cru p/ auditar.
        return content, "unparseable", finish, tokens
    return json.dumps(parsed, ensure_ascii=False), "ok", finish, tokens


# ---------------------------------------------------------------------------
# Retomada: lê o CSV já existente e descobre quais células estão prontas
# ---------------------------------------------------------------------------
def load_done():
    done = set()
    if os.path.exists(RAW_CSV):
        with open(RAW_CSV, newline="", encoding="utf-8") as fh:
            for row in csv.DictReader(fh):
                if row.get("status") == "ok":
                    done.add((row["#variant"], row["scale"]))
    return done


def estimate_cost(prompt_tokens, completion_tokens):
    """Custo em USD. completion_tokens já inclui os tokens de raciocínio."""
    return (prompt_tokens * cfg.PRICE_INPUT_PER_1M
            + completion_tokens * cfg.PRICE_OUTPUT_PER_1M) / 1_000_000


def main():
    if not os.environ.get("OPENAI_API_KEY"):
        sys.exit("Erro: defina a variável de ambiente OPENAI_API_KEY antes de rodar.")

    client = OpenAI()

    question_list = pd.read_csv(QUESTIONS_CSV)
    prompt_variant_list = pd.read_csv(DESCRIPTORS_CSV)

    done = load_done()
    if done:
        print(f"Retomando: {len(done)} células já coletadas serão puladas.")

    run_id = uuid.uuid4().hex[:12]
    new_csv = not os.path.exists(RAW_CSV) or os.path.getsize(RAW_CSV) == 0

    csv_fh = open(RAW_CSV, "a", newline="", encoding="utf-8")
    writer = csv.DictWriter(csv_fh, fieldnames=FIELDNAMES)
    if new_csv:
        writer.writeheader()
        csv_fh.flush()
    jsonl_fh = open(JSONL, "a", encoding="utf-8")

    total = len(prompt_variant_list) * len(question_list)
    n = 0
    spent = {"prompt": 0, "completion": 0, "calls": 0}
    try:
        for _, vrow in prompt_variant_list.iterrows():
            system = vrow["respondent_descriptor"]
            variant = vrow["#variant"]
            country = "general"

            for _, qrow in question_list.iterrows():
                n += 1
                scale = qrow["scale"]
                question = qrow["prompt"]

                if (variant, scale) in done:
                    print(f"[{n}/{total}] {variant} / {scale} — pulado (já ok)")
                    continue

                print(f"[{n}/{total}] {variant} / {scale} ...")
                completion = call_with_retry(client, system, question, scale)
                raw_answer, status, finish, tok = interpret(completion)

                writer.writerow({
                    "run_id": run_id,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "model": completion.model,
                    "reasoning_effort": cfg.REASONING_EFFORT,
                    "#variant": variant,
                    "country": country,
                    "scale": scale,
                    "survey_question": question,
                    "raw_answer": raw_answer,
                    "status": status,
                    "finish_reason": finish,
                    **tok,
                })
                csv_fh.flush()

                jsonl_fh.write(json.dumps(serialize_completion(completion),
                                          ensure_ascii=False) + "\n")
                jsonl_fh.flush()

                spent["prompt"] += tok["prompt_tokens"] or 0
                spent["completion"] += tok["completion_tokens"] or 0
                spent["calls"] += 1

                if status != "ok":
                    print(f"    AVISO: status={status} (finish={finish})",
                          file=sys.stderr)
    finally:
        csv_fh.close()
        jsonl_fh.close()
        if spent["calls"]:
            cost = estimate_cost(spent["prompt"], spent["completion"])
            print(f"\n--- Custo desta execução ({spent['calls']} chamadas) ---")
            print(f"  tokens: input={spent['prompt']} output={spent['completion']}")
            print(f"  custo estimado: US$ {cost:.4f} "
                  f"(input ${cfg.PRICE_INPUT_PER_1M}/1M, output ${cfg.PRICE_OUTPUT_PER_1M}/1M)")

    print(f"\nConcluído. Dados crus em:\n  {RAW_CSV}\n  {JSONL}")
    print("Rode Guilherme_Part1_Scoring.py para gerar os scores e a wide table.")


if __name__ == "__main__":
    main()
