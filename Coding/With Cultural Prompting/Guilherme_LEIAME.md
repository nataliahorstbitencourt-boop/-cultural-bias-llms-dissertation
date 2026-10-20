# LEIA-ME — Como rodar o pipeline (braço COM cultural prompting — Etapa 2)

> Guia pensado para quem **não é da área de TI**. Siga na ordem.
> Qualquer linha em caixa cinza é um comando: copie e cole no **Terminal** (Mac)
> ou no **Prompt de Comando / PowerShell** (Windows).

---

## 1. O que este pacote faz

Pergunta a um modelo de IA as 10 questões de valores do World Values Survey,
fingindo ser "um ser humano médio" (em 10 formulações) **nascido e morando em cada
um dos 107 países**, e organiza as respostas em tabelas prontas para análise. É o
**braço cultural** do estudo — mede como a visão da IA muda conforme o país simulado.

Duas etapas:
- **Etapa A — Geração:** conversa com a IA e guarda as respostas cruas. (usa internet e consome créditos da conta de IA)
- **Etapa B — Pontuação (scoring):** transforma as respostas em números/índices. (não usa internet, custo zero)

Escala: 107 países × 10 personas × 10 perguntas = **10.700 chamadas**.

---

## 2. Arquivos que compõem o pacote

**Código e configuração (enviar todos):**
- `Guilherme_Config.py` — configurações centrais (modelo, modo de extração, motor, etc.)
- `Guilherme_Part2_Generation.py` — Etapa A (geração)
- `Guilherme_Part2_Scoring.py` — Etapa B (pontuação)
- `requirements.txt` — lista das bibliotecas a instalar

**Dados de entrada (enviar todos):**
- `Guilherme_Prompts_Questions.csv` — as 10 perguntas
- `Guilherme_Prompts_Respondent_Descriptors_Cultural.csv` — as 10 personas
- `Países.csv` — os 107 países + região cultural (Inglehart-Welzel)

**Documentação (recomendado):**
- `Guilherme_LEIAME.md` — este guia
- `../without_cultural_prompting/Guilherme_Decisoes_de_Projeto.md` — registro das decisões

> **Importante:** mantenha todos esses arquivos **na mesma pasta**.
> NÃO envie a pasta `.venv` (recriada no passo 4) nem os arquivos de resultado,
> a menos que queira compartilhar os dados já coletados.

---

## 3. O que é preciso ter antes de começar

1. **Python 3.12** instalado (`python3 --version`). Se faltar, baixe em
   https://www.python.org/downloads/.
2. **Chave de API da OpenAI** (`OPENAI_API_KEY`), **com acesso ao modelo desejado**.
   Rodar a Etapa A consome créditos.

---

## 4. Preparar o ambiente (só na primeira vez)

Abra o terminal **dentro da pasta** dos arquivos e rode, uma linha por vez:

**Mac/Linux:**
```
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```
**Windows (PowerShell):**
```
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

---

## 5. Informar a chave da IA

Na **mesma** janela (com o `.venv` ativado):

**Mac/Linux:** `export OPENAI_API_KEY="cole-a-sua-chave-aqui"`
**Windows:** `$env:OPENAI_API_KEY="cole-a-sua-chave-aqui"`

> Vale só para essa janela. Fechou o terminal, informe de novo.

---

## 6. Configurar antes de rodar (abra `Guilherme_Config.py` num editor)

Os principais controles ficam no topo do arquivo:

- `MODEL` — qual IA usar. Há **duas linhas**, uma comentada (começa com `#`). Deixe
  ativa a do modelo que você vai testar (ex.: `gpt-5.6-terra`).
- `COUNTRY_LIMIT` — **quantos países** processar. Comece com um número **pequeno**
  (ex.: `2`) para testar; `None` roda os 107. Combina com a retomada: aumentar o
  número depois continua de onde parou.
- `USE_STRUCTURED_OUTPUTS` — `False` (padrão) = resposta em texto livre (reprodução
  do estudo). `True` = formato garantido (uso futuro, ex.: subgrupos).
- `USE_BATCH_API` — `False` (padrão) = **pool de threads** (tempo real, rápido).
  `True` = **Batch API** (assíncrono, ~50% mais barato, pode levar horas).
- `MAX_CONCURRENCY` — nº de chamadas simultâneas no modo threads (padrão `10`).

> Não precisa mexer em `REASONING_EFFORT` (fica `low`, aceito por todos os modelos).

---

## 7. Rodar

**Etapa A — gerar (consome créditos):**
```
python Guilherme_Part2_Generation.py
```
Mostra o progresso a cada 10 chamadas e, no fim, o **custo real** gasto.
Se a internet cair ou você interromper, rode o mesmo comando de novo: ele
**continua de onde parou** (pula o que já foi coletado).

**Etapa B — pontuar (custo zero):**
```
python Guilherme_Part2_Scoring.py
```

> No modo Batch API: a Etapa A **submete** o lote e fica acompanhando; se fechar,
> rode de novo que ela **retoma** o acompanhamento do mesmo lote e baixa os
> resultados quando prontos.

---

## 8. Onde ficam os resultados (`<modelo>` = nome do modelo)

- `Guilherme_Cultural_Raw_<modelo>.csv` — respostas cruas + dados de controle
- `Guilherme_Cultural_Scores_<modelo>.csv` — respostas com a pontuação
- `Guilherme_WideTable_Part2_all_countries_scores_<modelo>.csv` — **tabela final para análise (R)**
- `Guilherme_Cultural_Flagged_<modelo>.csv` — **respostas originais que viraram NA** (auditoria)
- `Guilherme_Cultural_completions_<modelo>.jsonl` — registro técnico
- (modo Batch) arquivos auxiliares `..._batch_input_...` e `..._batch_state_...`

Células sem resposta válida aparecem como **`NA`** na tabela final e ficam listadas,
com a resposta original, no arquivo **`Flagged`**.

---

## 9. Trocar de modelo / rodar em lotes

- **Outro modelo:** no `Config`, troque qual linha `MODEL` está ativa. Cada modelo
  gera seus próprios arquivos, sem apagar os dos outros.
- **Em lotes:** suba o `COUNTRY_LIMIT` aos poucos (ex.: 2 → 20 → 107); a retomada
  evita reprocessar.

---

## 10. DECISÃO DE PROJETO PENDENTE — idioma nas respostas abertas

Em países de outro idioma, a IA às vezes responde a pergunta de **lista** (y003 —
qualidades da criança) **no idioma local** (ex.: Argentina → espanhol: "Buenos
modales, Independencia..."). O leitor de respostas espera os termos **em inglês**,
então essas respostas viram **NA** e vão para o `Flagged`. As demais perguntas
(número ou letra) não têm esse problema.

**Precisa decidir como tratar:**
- **(A)** Deixar como NA + `Flagged` (atual). Honesto; perde esses dados.
- **(B)** Adicionar sinônimos multilíngues ao leitor (recupera dado; trabalhoso, nunca cobre tudo).
- **(C)** Usar Structured Outputs só para y003 (recupera 100%; mas "força" a resposta nessa pergunta).
- **(D)** Pedir resposta em inglês no prompt (recupera; mas altera o estímulo e foge da reprodução).

> Relacionado: hoje **não há** "re-perguntar quando a resposta não é parseável" — só
> há retry para erros de rede/API. Criar esse re-pergunta reduziria os NAs, mas
> contraria o princípio de que "a não resposta é um dado" (viés de seleção).
> **Também é uma decisão a tomar.**

---

## 11. Se algo der errado

- **Erro 403 / PermissionDenied:** sua conta não tem acesso ao `MODEL` escolhido
  (ex.: `gpt-6-astra`). Troque para um modelo que você tenha (ex.: `gpt-5.6-terra`).
- **"command not found: python":** tente `python3` no lugar de `python` (ou vice-versa).
- **Erro de chave / 401:** `OPENAI_API_KEY` não informada ou incorreta (repita o passo 5).
- **Muito lento:** confirme `USE_BATCH_API` / `MAX_CONCURRENCY`; para os 107 países,
  considere o modo Batch API.
- **Quer checar acesso ao Batch API** (read-only, sem custo):
  ```
  python -c "from openai import OpenAI; c=OpenAI(); print([b.id for b in c.batches.list(limit=5).data])"
  ```
  Imprimiu uma lista (mesmo vazia) → tem acesso; deu erro de permissão → não tem.
