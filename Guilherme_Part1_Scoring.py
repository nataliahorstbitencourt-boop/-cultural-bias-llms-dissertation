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


def main():
    if not os.path.exists(RAW_CSV):
        sys.exit(f"Não encontrei {RAW_CSV}. Rode a Etapa A (geração) primeiro.")

    df = pd.read_csv(RAW_CSV)

    scores = []
    problems = 0
    for _, row in df.iterrows():
        if row.get("status") != "ok":
            scores.append(pd.NA)
            problems += 1
            print(f"  AVISO: {row['#variant']} / {row['scale']} "
                  f"status={row.get('status')} -> score vazio", file=sys.stderr)
            continue
        try:
            answer = json.loads(row["raw_answer"])
            scores.append(score_cell(row["scale"], answer))
        except (ScoringError, KeyError, ValueError, json.JSONDecodeError) as exc:
            scores.append(pd.NA)
            problems += 1
            print(f"  AVISO: {row['#variant']} / {row['scale']} "
                  f"não pôde ser scorada: {exc}", file=sys.stderr)

    df["score"] = scores
    df.to_csv(SCORES_CSV, index=False)

    wide = df.pivot(index=["country", "#variant"], columns="scale", values="score")
    wide = wide.reset_index()
    wide.to_csv(WIDE_CSV, index=False)

    print(f"\nScoring concluído ({problems} célula(s) sem score).")
    print(f"  Long : {SCORES_CSV}")
    print(f"  Wide : {WIDE_CSV}")


if __name__ == "__main__":
    main()
