#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Guilherme_Part1_Scoring.py  —  ETAPA B (scoring)
=================================================

Lê o CSV cru da Etapa A e aplica TODA a lógica dos índices WVS (nenhuma chamada
de API). Re-scorar é barato e reproduzível.

Lógica (fonte: WVS / Inglehart-Welzel, F1):
  - escalas numéricas diretas -> o próprio inteiro é o score
  - y003 (autonomia)  = (religious_faith + obedience) - (independence + determination),
                        cada termo = 1 se escolhido, 2 se não
  - y002 (pós-materialismo): (1,3)/(3,1) -> 1 ; (2,4)/(4,2) -> 3 ; senão -> 2
  - e025 (petition): A/B/C -> 1/2/3
  - a165 (trust):    A/B   -> 1/2

Validações (D3/D4): cardinalidade de y003 ("até 5") e distinção de y002 são
checadas aqui e sinalizadas, sem depender do schema.

Entradas:
  Guilherme_General_Raw_<model>.csv
Saídas:
  Guilherme_General_Scores_<model>.csv            (long, com coluna `score`)
  Guilherme_WideTable_Part1_scores_<model>.csv     (pivot para análise em R)
"""

import csv
import json
import os
import re
import sys

import pandas as pd

import Guilherme_Config as cfg

try:
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
except NameError:
    BASE_DIR = os.getcwd()

MODEL_SLUG = re.sub(r"[^A-Za-z0-9._-]", "-", cfg.MODEL)
RAW_CSV = os.path.join(BASE_DIR, f"Guilherme_General_Raw_{MODEL_SLUG}.csv")
SCORES_CSV = os.path.join(BASE_DIR, f"Guilherme_General_Scores_{MODEL_SLUG}.csv")
WIDE_CSV = os.path.join(BASE_DIR, f"Guilherme_WideTable_Part1_scores_{MODEL_SLUG}.csv")
# Respostas originais que não puderam ser pontuadas (auditoria; viram NA no analítico).
FLAGGED_CSV = os.path.join(BASE_DIR, f"Guilherme_General_Flagged_{MODEL_SLUG}.csv")


class ScoringError(Exception):
    pass


def score_cell(scale, answer):
    """Recebe o dict já parseado da resposta crua e devolve o score WVS (int)."""
    if scale in cfg.DIRECT_NUMERIC_SCALES:
        return int(answer["answer"])

    if scale == "y003":
        chosen = list(answer["answer"])
        if len(chosen) > cfg.Y003_MAX_CHOICES:
            raise ScoringError(f"y003 com {len(chosen)} escolhas (máx {cfg.Y003_MAX_CHOICES})")
        chosen_set = set(chosen)
        trad = sum(1 if q in chosen_set else 2 for q in cfg.AUTONOMY_TRADITIONAL)
        self_exp = sum(1 if q in chosen_set else 2 for q in cfg.AUTONOMY_SELF_EXPRESSION)
        return trad - self_exp

    if scale == "y002":
        a = int(answer["most_important"])
        b = int(answer["second_important"])
        if a == b:
            raise ScoringError(f"y002 com objetivos iguais ({a},{b})")
        pair = (a, b)
        if pair in {(1, 3), (3, 1)}:
            return 1
        if pair in {(2, 4), (4, 2)}:
            return 3
        return 2

    if scale == "e025":
        return cfg.PETITION_MAP[answer["answer"]]

    if scale == "a165":
        return cfg.TRUST_MAP[answer["answer"]]

    raise ScoringError(f"scale desconhecida: {scale}")


def resolve_answer(row):
    """Devolve (answer_dict, reason). reason=None em sucesso.

    - Linha já marcada na geração (status != ok) -> falha com o próprio status.
    - Modo structured -> json.loads do raw_answer.
    - Modo free_text  -> parser best-effort do Config (cfg.parse_free_text).
    """
    status = row.get("status")
    if status != "ok":
        return None, status or "no_status"

    raw = row["raw_answer"]
    mode = row.get("mode") or (
        "structured" if cfg.USE_STRUCTURED_OUTPUTS else "free_text")

    if mode == "structured":
        try:
            return json.loads(raw), None
        except (TypeError, json.JSONDecodeError):
            return None, "unparseable_json"
    return cfg.parse_free_text(row["scale"], raw)


def main():
    if not os.path.exists(RAW_CSV):
        sys.exit(f"Não encontrei {RAW_CSV}. Rode a Etapa A (geração) primeiro.")

    df = pd.read_csv(RAW_CSV)

    # Dedup: a mesma (country, #variant, scale) pode ter uma linha não-ok e,
    # após um re-run, uma linha ok. Mantém a melhor (prioriza 'ok'); evita o pivot
    # quebrar com "duplicate entries".
    before = len(df)
    df["_ok"] = (df["status"] == "ok").astype(int)
    df = (df.sort_values(["country", "#variant", "scale", "_ok"], kind="stable")
            .drop_duplicates(["country", "#variant", "scale"], keep="last")
            .drop(columns="_ok")
            .reset_index(drop=True))
    if len(df) < before:
        print(f"Deduplicado: {before - len(df)} linha(s) redundante(s) removida(s).")

    scores = []
    flagged = []
    for _, row in df.iterrows():
        answer, reason = resolve_answer(row)
        if answer is not None:
            try:
                scores.append(score_cell(row["scale"], answer))
                continue
            except (ScoringError, KeyError, ValueError, TypeError) as exc:
                reason = str(exc)
        scores.append(pd.NA)
        flagged.append({
            "country": row.get("country"),
            "#variant": row.get("#variant"),
            "scale": row.get("scale"),
            "status": row.get("status"),
            "mode": row.get("mode"),
            "reason": reason,
            "raw_answer": row.get("raw_answer"),
        })
        print(f"  FLAG: {row.get('#variant')} / {row.get('scale')} "
              f"-> NA ({reason})", file=sys.stderr)

    df["score"] = scores
    df.to_csv(SCORES_CSV, index=False, na_rep="NA")

    wide = df.pivot(index=["country", "#variant"], columns="scale", values="score")
    wide = wide.reset_index()
    wide.to_csv(WIDE_CSV, index=False, na_rep="NA")

    flag_fields = ["country", "#variant", "scale", "status", "mode",
                   "reason", "raw_answer"]
    with open(FLAGGED_CSV, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=flag_fields)
        w.writeheader()
        w.writerows(flagged)

    print(f"\nScoring concluído ({len(flagged)} célula(s) marcada(s) como NA).")
    print(f"  Long    : {SCORES_CSV}")
    print(f"  Wide    : {WIDE_CSV}")
    print(f"  Flagged : {FLAGGED_CSV}")


if __name__ == "__main__":
    main()
