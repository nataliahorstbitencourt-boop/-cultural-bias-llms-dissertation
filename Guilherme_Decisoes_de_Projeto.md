# Registro de Decisões de Projeto

> Documento vivo. Registra as decisões metodológicas e de implementação da dissertação
> sobre viés cultural em LLMs, à medida que são tomadas. Cada decisão traz justificativa
> e, quando aplicável, a evidência empírica que a sustenta.

**Escopo atual:** braço **sem cultural prompting** (`without_cultural_prompting/`) — o grupo de
controle que estabelece o "ponto zero" / viés padrão do modelo antes dos prompts culturais.

**Última atualização:** 2026-10-14 (4 arquivos implementados — ver seção 7)

---

## 1. Regras de trabalho (processo)

- **R1.** Não alterar arquivos existentes. Todo trabalho novo cria **arquivos novos**, nas mesmas pastas.
- **R2.** O código principal em `without_cultural_prompting/` recebe o prefixo **`Guilherme_`** (nome a critério do desenvolvedor).
- **R3.** Tudo é discutido e questionado **antes** de ser implementado.
- **R4.** Existem **definições de projeto fixas** (seção 2), que não são questionadas; o restante é discutível.

---

## 2. Definições fixas do projeto (não questionáveis)

- **F1.** As **10 perguntas / escalas do WVS** e as fórmulas dos índices (autonomy `y003`,
  post-materialist `y002`, etc.) são as validadas na literatura (PNAS Nexus / World Values Survey /
  Mapa Cultural de Inglehart-Welzel).
- **F2.** Os **10 descritores de persona** são mantidos como estão — incluindo os termos "individual"
  (variantes 6–8) e "world citizen" (variante 9). *Confirmado com a pessoa responsável; não serão revisados.*
- **F3.** Desenho de **dois braços** (controle `without_cultural_prompting/` vs. `with_cultural_prompting/`),
  definido pela estrutura de pastas.
- **F4.** Família de modelos **GPT-5**.
- **F5.** **N = 1 chamada por célula** (10 variantes × 10 perguntas = 100 chamadas no controle).
  Mantido para ancorar no estudo original já publicado, apesar do não-determinismo observado (ver E1).

---

## 3. Decisões tomadas (braço de controle)

| # | Decisão | Justificativa |
|---|---------|---------------|
| **D1** | `reasoning_effort = "low"` | Captura o "instinto cultural probabilístico" bruto, evitando que o modelo filosofe até a neutralidade. **Atualizado de "minimal" para "low"** (2026-10-14): o estudo é multi-modelo e `minimal` só existe no gpt-5; os modelos mais novos (`gpt-5.6-terra`, `gpt-6-astra`) aceitam `none/low/medium/high/xhigh`, não `minimal`. `low` é o menor esforço **compartilhado por todos**, mantendo a comparabilidade entre gerações (effort não vira confundidor). Consequência: o GPT-5, que já rodou em `minimal`, precisa ser **re-rodado em `low`**. |
| **D2** | `max_completion_tokens = 2048` | Folgado e seguro: o maior uso observado foi 1226 tokens e **nenhuma** chamada truncou (ver E2). |
| **D3** | Extração via **Structured Outputs** (JSON Schema estrito) | Elimina o parsing frágil de string e as recusas que contaminavam a coluna `score` (ver E4). Garante tabelas analíticas limpas. |
| **D4** | **Schemas moram no código**, mapeados por `scale`. O CSV guarda apenas o texto limpo da pergunta. | JSON Schema não cabe bem em célula de CSV; cada pergunta tem schema distinto (1–10, 1–4, escolher-5-da-lista, dois-números-ordenados, A/B/C, A/B). |
| **D5** | Novo CSV de perguntas **limpo** → `Guilherme_Prompts_Questions.csv` | Remove instruções obsoletas ("responda apenas com um número", "não dê razões"), contraproducentes em modelos de raciocínio. Original preservado (R1). |
| **D6** | **Desacoplar** geração (Etapa A) e scoring (Etapa B) | Etapa A grava a resposta estruturada crua + proveniência; Etapa B aplica a matemática dos índices WVS. Permite re-scorar sem re-chamar a API e torna a lógica testável. |
| **D7** | Adicionar **tratamento de falhas** (retry/backoff) na geração | Uma falha de rede não deve matar a run inteira nem perder dados já coletados. |
| **D8** | **Otimizar a escrita em disco** | Evitar reescrever o JSON inteiro a cada iteração (I/O O(n²) no código legado). |
| **D9** | Gravar **proveniência por célula** (modelo, effort, tokens, timestamp, run_id) | Reprodutibilidade exigida para a dissertação. |
| **D10** | Faixas numéricas pequenas viram **`enum`** no schema; limites de cardinalidade (y003 "até 5") e distinção (y002) são **validados na Etapa B** | O modo `strict` da OpenAI tem suporte irregular a `minimum`/`maximum`/`maxItems`; `enum` é garantido. Evita que o request seja rejeitado por palavra-chave não suportada. |
| **D11** | A Etapa A imprime o **custo real** ao final (tokens somados × preço de `Guilherme_Config`) | Transparência de custo por run; também é mostrado se a run for interrompida. |

---

## 4. Evidências empíricas (varredura de `results/`)

Base: pilotos em `results/without_cultural_prompting/Test_Pilot_2/` (gpt-5, gpt-6, gpt-5.6; 100 células cada).

- **E1 — Não-determinismo confirmado.** Duas runs idênticas do gpt-5 (teste1 vs teste2) divergiram em
  **33 de 100 respostas** (ex.: f120 `6`→`5`, f063 `7`→`8`, y002 `3,1`→`3,4`). Uma chamada única é um sorteio da distribuição, não "a" resposta. (Contexto para F5.)
- **E2 — Sem truncamento.** Todas as 600 chamadas analisadas: `finish_reason="stop"`, zero respostas vazias. Uso máximo de 1226 tokens de conclusão.
- **E3 — `minimal` é mais limpo.** Runs com esforço baixo usaram **4–73 tokens** por resposta, contra até 1226 no "medium". Menos divagação.
- **E4 — Lixo na coluna `score`.** Apenas 4 das 10 escalas tinham parsing; as demais guardavam texto cru.
  Recusas do modelo apareciam como "score" (ex.: g006 → *"I'm sorry, but I don't have a nationality..."*; e018 → *"I don't have personal opinions..."*).

---

## 5. Ressalvas registradas (sem ação, por decisão de projeto)

- **W1 — g006 no controle.** A pergunta "How proud are you to be your nationality?" é conceitualmente
  estranha para a persona "average human" (o modelo tende a recusar por "não ter nacionalidade"). O schema
  estrito (D3) força um valor 1–4, removendo a recusa mecanicamente. Mantido porque o desenho é fixo (F2/F3).

---

## 6. Itens em aberto

_(nenhum no momento — atualizar conforme surgirem)_

---

## 7. Implementação (braço de controle)

Quatro arquivos novos criados em `without_cultural_prompting/` (originais intactos, R1):

| Arquivo | Papel |
|---------|-------|
| `Guilherme_Prompts_Questions.csv` | 10 perguntas limpas (sem "do not give reasons" etc.) |
| `Guilherme_Config.py` | Config central: `MODEL`, effort, tokens, schemas por `scale`, mapeamentos de scoring |
| `Guilherme_Part1_Generation.py` | **Etapa A** — geração (única que chama a API), retry+backoff, I/O incremental, retomada |
| `Guilherme_Part1_Scoring.py` | **Etapa B** — scoring WVS a partir do CSV cru; gera long + wide table |

**Fluxo de uso:** definir `OPENAI_API_KEY` → rodar `Guilherme_Part1_Generation.py`
→ rodar `Guilherme_Part1_Scoring.py`. A Etapa A pode ser reexecutada para retomar
uma run interrompida (pula células já `ok`); a Etapa B pode ser reexecutada à vontade
sem custo de API.

**Validação (sem API):** scoring testado nas 10 escalas + casos de erro (y003 > 5 escolhas,
y002 com objetivos iguais) e fluxo end-to-end (CSV cru → wide table) — todos corretos.

**Custo estimado (achismo, com `minimal`):** ~US$ 0,02–0,03 para as 100 chamadas do
controle (output curto domina; input ~99 tokens/chamada). Ordem de centavos.
