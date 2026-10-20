# LEIA-ME — Como rodar o pipeline (braço SEM cultural prompting)

> Guia pensado para quem **não é da área de TI**. Siga na ordem.
> Qualquer linha que apareça em caixa cinza é um comando: copie e cole no
> **Terminal** (Mac) ou no **Prompt de Comando / PowerShell** (Windows).

---

## 1. O que este pacote faz

Ele pergunta a um modelo de IA (ex.: GPT-5) as 10 questões de valores do World
Values Survey, fingindo ser "um ser humano médio" em 10 formulações diferentes,
e organiza as respostas em tabelas prontas para análise estatística. É o **grupo
de controle** do estudo (o "ponto zero" / viés padrão da IA).

O trabalho acontece em duas etapas:
- **Etapa A — Geração:** conversa com a IA e guarda as respostas cruas. (usa internet e consome créditos da conta de IA)
- **Etapa B — Pontuação (scoring):** transforma as respostas em números/índices. (não usa internet, custo zero)

---

## 2. Arquivos que compõem o pacote

**Código e configuração (precisa enviar todos):**
- `Guilherme_Config.py` — configurações centrais (qual modelo usar, etc.)
- `Guilherme_Part1_Generation.py` — Etapa A (geração)
- `Guilherme_Part1_Scoring.py` — Etapa B (pontuação)
- `requirements.txt` — lista das bibliotecas a instalar

**Dados de entrada (precisa enviar todos):**
- `Guilherme_Prompts_Questions.csv` — as 10 perguntas
- `Prompts_Respondent_Descriptors_General.csv` — as 10 personas ("ser humano médio" etc.)

**Documentação (recomendado enviar):**
- `Guilherme_Decisoes_de_Projeto.md` — registro das decisões metodológicas
- `Guilherme_LEIAME.md` — este guia

> **Importante:** mantenha todos esses arquivos **na mesma pasta**.

**NÃO é preciso enviar:**
- A pasta `.venv` (ambiente virtual) — ela é específica do computador e será
  recriada no passo 4.
- Os arquivos de resultado já gerados (`Guilherme_General_Raw_...`,
  `..._Scores_...`, `..._WideTable_...`, `....jsonl`) — a não ser que você também
  queira compartilhar os resultados já coletados.

---

## 3. O que é preciso ter antes de começar

1. **Python 3.12** instalado. Para checar se já tem, rode no terminal:
   ```
   python3 --version
   ```
   Se não aparecer "Python 3.12.x" (ou superior), baixe em
   https://www.python.org/downloads/ e instale.

2. **Uma chave de API da OpenAI** (`OPENAI_API_KEY`), com acesso ao modelo
   desejado. Essa chave é obtida na conta da OpenAI (https://platform.openai.com).
   Rodar a Etapa A **consome créditos** dessa conta (poucos centavos para o controle).

---

## 4. Preparar o ambiente (só na primeira vez)

Abra o terminal **dentro da pasta** onde estão os arquivos e rode, uma linha por vez:

**No Mac/Linux:**
```
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

**No Windows (PowerShell):**
```
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Depois disso, as bibliotecas estarão instaladas num ambiente isolado chamado `.venv`.

---

## 5. Informar a chave da IA

Na **mesma** janela do terminal (com o `.venv` ativado), informe a chave:

**No Mac/Linux:**
```
export OPENAI_API_KEY="cole-a-sua-chave-aqui"
```

**No Windows (PowerShell):**
```
$env:OPENAI_API_KEY="cole-a-sua-chave-aqui"
```

> A chave vale só para essa janela. Se fechar o terminal, informe de novo.

---

## 6. Rodar

**Etapa A — gerar as respostas (consome créditos):**
```
python Guilherme_Part1_Generation.py
```
Vai aparecer o progresso (`[1/100] ...`) e, ao final, o custo real gasto.
Se cair a internet no meio, é só rodar o mesmo comando de novo: ele **continua
de onde parou**.

**Etapa B — pontuar (custo zero):**
```
python Guilherme_Part1_Scoring.py
```

---

## 7. Onde ficam os resultados

Na mesma pasta, com o nome do modelo embutido:
- `Guilherme_General_Raw_<modelo>.csv` — respostas cruas + dados de controle
- `Guilherme_General_Scores_<modelo>.csv` — respostas com a pontuação
- `Guilherme_WideTable_Part1_scores_<modelo>.csv` — **tabela final para análise (R/Pandas)**
- `Guilherme_General_completions_<modelo>.jsonl` — registro técnico (auditoria)

---

## 8. Trocar de modelo de IA

Para testar outro modelo, abra o `Guilherme_Config.py` num editor de texto e
mude **apenas** a linha:
```
MODEL = "gpt-5-2025-08-07"
```
para o nome do outro modelo (ex.: `"gpt-5.6-terra"`). Salve e repita o passo 6.
Cada modelo gera seus próprios arquivos, sem apagar os dos outros.

> Observação: modelos diferentes aceitam níveis diferentes de "esforço de
> raciocínio". Este projeto usa `low` (linha `REASONING_EFFORT` no `Config`),
> que é aceito por todos os modelos testados. Não altere sem necessidade.

---

## 9. Se algo der errado

- **"command not found: python" / "python não é reconhecido":** tente `python3`
  no lugar de `python` (ou vice-versa).
- **Erro 400 "does not support ... reasoning_effort":** o modelo escolhido não
  aceita o valor em `REASONING_EFFORT`. Use `low` (ver passo 8).
- **Erro de chave / 401:** a `OPENAI_API_KEY` não foi informada ou está incorreta
  (repita o passo 5).
- **"duplicate entries" na Etapa B:** apague os arquivos de resultado daquele
  modelo e rode a Etapa A de novo do zero.
