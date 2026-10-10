VERSÕES GPT UTILIZADAS PELOS AUTORES: GPT-3.5-turbo, GPT-4, GPT-4-turbo, GPT-4o


PARÂMETROS UTILIZADOS PELOS AUTORES:


 chat_response = client.chat.completions.create
            temperature=0,
            max_tokens=256,
            top_p=1,
            frequency_penalty=0,
            presence_penalty=0



Observação: em todos estou utilizando a chat completions API.



Modelo: GPT 5
Versão: gpt-5-2025-08-07
Custo Estimado: US$ 2,74
Informações: 
reasoning.effort: controla o esforço de raciocínio dedicado à tarefa. 
reasoning.effort supports minimal, low, medium, and high.
text.verbosity: orienta o nível de detalhe da resposta que será apresentada.
• low → terse UX, minimal prose.
• medium (default) → balanced detail.
• high → verbose, great for audits, teaching, or hand-offs
max_completion_tokens= 

Parâmetros do estudo: 

Teste 1: 
reasoning_effort="minimal",
max_completion_tokens=256
Resultado:


Teste 2: 
reasoning_effort="medium",
max_completion_tokens=512
Resultado: Pior, valores mais seculares.


Teste 3: 
reasoning_effort="low",
max_completion_tokens= 256
verbosity="low"
Resultado:




Resultado:


Fonte: https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5&; https://crazyrouter.com/en/blog/gpt-5-api-parameters-guide-2026-unsupported-parameter-fixes; https://developers.openai.com/api/docs/models/gpt-5.














Modelo: GPT 6 Astra
Versão: 
Custo Estimado: US$ 17,67
Informações:
reasoning.effort supports low, medium, high, xhigh, and max. O parâmetro controla o nível de esforço que o modelo dedica ao raciocínio antes de produzir a resposta.





Parâmetros do estudo:
reasoning.effort: low
max_completion_tokens: 512


Fonte: https://developers.openai.com/api/docs/models/gpt-6-astra; https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5&;




























Chat GPT 5
https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5&utm_source=chatgpt.com











Primeiro teste:
for index, row in question_list.iterrows():
        scale = row['scale']
        question = row['prompt']
        chat_response = client.chat.completions.create(
    model="gpt-5-2025-08-07",
    messages=[
        {"role": "system", "content": system},
        {"role": "user", "content": question}
    ],
    reasoning_effort="minimal",
    max_completion_tokens=512
)










