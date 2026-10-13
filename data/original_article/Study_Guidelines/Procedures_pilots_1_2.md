**PILOTOS 1 e 2**




**VERSÕES GPT UTILIZADAS PELOS AUTORES:** GPT-3.5-turbo, GPT-4, GPT-4-turbo, GPT-4o
**VERSÕES GPT A SEREM UTILIZADAS:**  GPT 5.6 Terra e GPT 6 Astra

**PARÂMETROS UTILIZADOS PELOS AUTORES**:

 chat_response = client.chat.completions.create
            temperature=0,
            max_tokens=256,
            top_p=1,
            frequency_penalty=0,
            presence_penalty=0



**Modelo: GPT 5**
**Versão:** gpt-5-2025-08-07
**Custo Estimado:** US$ 2,74
**Informações:** 
reasoning.effort: controla o esforço de raciocínio dedicado à tarefa. 
reasoning.effort supports minimal, low, medium, and high.
text.verbosity: orienta o nível de detalhe da resposta que será apresentada.
• low → terse UX, minimal prose.
• medium (default) → balanced detail.
• high → verbose, great for audits, teaching, or hand-offs
max_completion_tokens= 
**Fonte:** https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5&; https://crazyrouter.com/en/blog/gpt-5-api-parameters-guide-2026-unsupported-parameter-fixes; https://developers.openai.com/api/docs/models/gpt-5.


**Modelo:** GPT 5.6
**Versão:** Terra
A versão Terra é o ponto intermediário na família GPT-5.6. É significativamente mais capaz que Luna, ao mesmo tempo que é consideravelmente mais barato e mais rápido que Sol. Foi escolhido por custo X eficiência em comparação aos demais modelos GPT 5.6.
**Custo Estimado:** US$ 5,17
**Informações:**

**Fonte:** https://developers.openai.com/api/docs/models/gpt-5.6-terra; 


**Modelo:** GPT 6 Astra
**Versão**: gpt-6-astra
**Custo Estimado:** US$ 24,61
**Informações:**
reasoning.effort supports low, medium, high, xhigh, and max. O parâmetro controla o nível de esforço que o modelo dedica ao raciocínio antes de produzir a resposta.
**Fonte:** https://developers.openai.com/api/docs/models/gpt-6-astra; https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5&;



**PILOTO_TESTES_1:**

 
**Teste 1:** 
Modelo: gpt-5-2025-08-07
reasoning_effort="minimal",
max_completion_tokens=256
Resultado: Segundo melhor resultado entre os GPTs 5.


**Teste 2:** 
Modelo: gpt-5-2025-08-07
reasoning_effort="medium",
max_completion_tokens=512
Resultado: Pior resultado entre os modelos GPT 5. Modelo não respondeu algumas perguntas. Aumentar tokens.


**Teste 3:** 
Modelo: gpt-5-2025-08-07
reasoning_effort="low",
max_completion_tokens= 1024
verbosity="low"
Resultado: Melhor resultado entre os modelos GPT 5 quando avaliada a média. Aumentar os tokens.


**Teste 1:**
Modelo: gpt-6-astra
Parâmetros do estudo:
reasoning.effort: low
max_completion_tokens: 512
Resultado: Tokens suficientes.


**Teste 2:**
Modelo: gpt-6-astra
Parâmetros do estudo:
reasoning.effort: high
max_completion_tokens: 1024
Resultado: Tokens suficientes. Resultado melhor, mas pouca diferença.







**PILOTO_TESTES_2:**


**TESTE 01**
Modelo: gpt-5-2025-08-07
reasoning.effort: Low
max_completion_tokens: 2000


**TESTE 02**
Modelo: gpt-5-2025-08-07
reasoning.effort: Medium
max_completion_tokens: 2000


**TESTE 03**
Modelo:gpt-6-astra
reasoning.effort:Low
max_completion_tokens: 1600


**TESTE 04**
Modelo: gpt-6-astra
reasoning.effort: Medium
max_completion_tokens: 1600


**TESTE 05**
Modelo: GPT 5.6 Terra
reasoning.effort: Low
max_completion_tokens: 1600


**TESTE 06**
Modelo: GPT 5.6 Terra
reasoning.effort: Medium
max_completion_tokens: 1600



**Resultados Piloto 2:** Tive que aumentar o número de tokens do gpt-5-2025-08-07, o que acabou deixando caro os testes com esse modelo. Ambos os testes com o GPT 5 tiveram, cada um, uma resposta textual, sem score, que coloquei como NA. Para fazer a parte estatística, retirei a linha que continha os NAs da análise. Todos os modelos testados exibiram um viés forte de auto-expressão e de valores seculares-racionais.











**CONDIDERAÇÕES FINAIS E JUSTIFICATIVA DAS ESCOLHAS**
Observação: em todos estou utilizando a chat completions API. Priorizei os parâmetros de reasoning effort como low ou medium em virtude na não necessidade de alto esforço para a tarefa solicitada.

Considerando que estou solicitando ao modelo apenas as respostas, de forma direta, considera-se que deve-se utilizar o parâmetro de reasoning effort low. Modelo GPT 5 foi menos eficiente nas respostas considerando o uso de tokens. O parâmetro max_completion_tokens estabelece o número máximo de tokens que podem ser gerados na conclusão. Nos modelos que utilizam tokens internos de raciocínio, esses tokens também entram nesse limite.

Imagine que você configure max_completion_tokens=1024:
- Parte dos tokens pode ser utilizada no raciocínio interno do modelo.
- Outra parte pode ser utilizada na resposta final visível.
- Se o limite for atingido antes de a resposta ser concluída, a resposta pode ficar incompleta.
Aumentar o limite não obriga o modelo a raciocinar mais. Ele apenas permite que gere mais tokens caso precise deles. O esforço de raciocínio é controlado por outros mecanismos, como reasoning_effort, quando disponíveis.

