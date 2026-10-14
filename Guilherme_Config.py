#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Guilherme_Config.py
===================

Fonte única da verdade (central config) para o braço SEM cultural prompting
(grupo de controle / "ponto zero"). Importado pelas Etapas A (geração) e B (scoring).

Decisões registradas em Guilherme_Decisoes_de_Projeto.md:
  - D1  reasoning_effort = "minimal"
  - D2  max_completion_tokens = 2048
  - D3  extração via Structured Outputs (JSON Schema estrito)
  - D4  schemas moram AQUI, mapeados por `scale`; o CSV guarda só o texto limpo

Nota sobre os schemas (D3/D4):
  O Structured Outputs da OpenAI, em modo `strict`, suporta de forma garantida
  `enum`, `type`, `required` e `additionalProperties:false`. Palavras-chave como
  `minimum`/`maximum`/`maxItems`/`uniqueItems` têm suporte irregular, então NÃO
  dependemos delas: faixas numéricas pequenas viram `enum` explícito e os limites
  de cardinalidade/distinção (y003 "até 5", y002 "distintos") são validados na
  Etapa B. Assim o request nunca é rejeitado por palavra-chave não suportada.
"""

# ---------------------------------------------------------------------------
# Parâmetros do modelo (F4, D1, D2)
# ---------------------------------------------------------------------------
MODEL = "gpt-5.6-terra"
REASONING_EFFORT = "low"
MAX_COMPLETION_TOKENS = 2048

# Preço GPT-5 (USD por 1M de tokens) — apenas referência/documentação.
PRICE_INPUT_PER_1M = 1.25
PRICE_OUTPUT_PER_1M = 10.00

# ---------------------------------------------------------------------------
# Lista fixa das qualidades da criança (y003) — strings exatas do WVS (F1).
# ---------------------------------------------------------------------------
CHILD_QUALITIES = [
    "Good manners",
    "Independence",
    "Hard work",
    "Feeling of responsibility",
    "Imagination",
    "Tolerance and respect for other people",
    "Thrift, saving money and things",
    "Determination, perseverance",
    "Religious faith",
    "Not being selfish (unselfishness)",
    "Obedience",
]

# ---------------------------------------------------------------------------
# Helpers para montar schemas estritos (sempre objeto na raiz, exigência da API)
# ---------------------------------------------------------------------------
def _obj(properties):
    """Objeto estrito: todas as propriedades obrigatórias, sem extras."""
    return {
        "type": "object",
        "properties": properties,
        "required": list(properties.keys()),
        "additionalProperties": False,
    }


def _int_enum(values):
    return {"type": "integer", "enum": list(values)}


def _str_enum(values):
    return {"type": "string", "enum": list(values)}


# ---------------------------------------------------------------------------
# SCHEMAS por `scale` — cada um reflete o FORMATO NATIVO da pergunta.
# A resposta é guardada crua pela Etapa A; toda a matemática WVS vai na Etapa B.
# ---------------------------------------------------------------------------
SCHEMAS = {
    # Escalas numéricas diretas
    "f063": _obj({"answer": _int_enum(range(1, 11))}),   # God importance 1-10
    "f120": _obj({"answer": _int_enum(range(1, 11))}),   # Abortion 1-10
    "f118": _obj({"answer": _int_enum(range(1, 11))}),   # Homosexuality 1-10
    "g006": _obj({"answer": _int_enum(range(1, 5))}),    # National pride 1-4
    "a008": _obj({"answer": _int_enum(range(1, 5))}),    # Happiness 1-4
    "e018": _obj({"answer": _int_enum([1, 2, 3])}),      # Respect for authority 1/2/3

    # Qualidades da criança: lista (cardinalidade "até 5" validada na Etapa B)
    "y003": _obj({"answer": {"type": "array", "items": _str_enum(CHILD_QUALITIES)}}),

    # Dois objetivos nacionais em ordem (distinção validada na Etapa B)
    "y002": _obj({
        "most_important": _int_enum([1, 2, 3, 4]),
        "second_important": _int_enum([1, 2, 3, 4]),
    }),

    # Opções de letra
    "e025": _obj({"answer": _str_enum(["A", "B", "C"])}),  # Petition
    "a165": _obj({"answer": _str_enum(["A", "B"])}),       # People trust
}


def response_format_for(scale):
    """Monta o response_format (Structured Outputs estrito) para uma `scale`."""
    return {
        "type": "json_schema",
        "json_schema": {
            "name": f"wvs_{scale}",
            "strict": True,
            "schema": SCHEMAS[scale],
        },
    }


# ---------------------------------------------------------------------------
# Mapeamentos de scoring (usados SÓ na Etapa B)
# ---------------------------------------------------------------------------

# Escalas em que o score WVS é o próprio inteiro respondido.
DIRECT_NUMERIC_SCALES = {"f063", "f120", "f118", "g006", "a008", "e018"}

# e025 (petition) e a165 (trust): letra -> score
PETITION_MAP = {"A": 1, "B": 2, "C": 3}
TRUST_MAP = {"A": 1, "B": 2}

# y003 (índice de autonomia): qualidade presente -> 1, ausente -> 2.
# score = (religious_faith + obedience) - (independence + determination)
AUTONOMY_TRADITIONAL = ["Religious faith", "Obedience"]
AUTONOMY_SELF_EXPRESSION = ["Independence", "Determination, perseverance"]

# Limite de escolhas para y003.
Y003_MAX_CHOICES = 5
