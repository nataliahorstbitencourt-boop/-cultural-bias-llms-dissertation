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










