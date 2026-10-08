VERSÕES GPT UTILIZADAS PELOS AUTORES: GPT-3.5-turbo, GPT-4, GPT-4-turbo, GPT-4o


PARÂMETROS UTILIZADOS:


 chat_response = client.chat.completions.create(
            model = "[ENTER GPT MODEL NAME HERE]",
            messages = [
                {"role": "system", "content": system},
                {"role": "user", "content": question}
            ],
            temperature=0,
            max_tokens=256,
            top_p=1,
            frequency_penalty=0,
            presence_penalty=0
        )




GPT 5

Modelo: 
Custo Estimado:
Parâmetros do estudo:













GPT 6 Sol:

Modelo: 
Custo Estimado:
Parâmetros do estudo:































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










