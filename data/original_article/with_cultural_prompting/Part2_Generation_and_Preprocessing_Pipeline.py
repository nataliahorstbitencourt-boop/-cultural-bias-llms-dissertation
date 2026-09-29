import openai
import json
import pandas as pd
import numpy as np
import time
import os
from pathlib import Path 
import argparse
parser = argparse.ArgumentParser()
parser.add_argument("--district", type=str, required=True)
parser.add_argument("--model", type=str, required=True)
args = parser.parse_args()

output_dir = Path(f"output/Part2")
output_dir.mkdir(parents=True, exist_ok=True) 

#Entering the API KEY
from openai import OpenAI
client = OpenAI(api_key = "[ENTER OPENAI API KEY HERE]")


#Load survey questions
question_list = pd.read_csv("Prompts_Questions.csv")
question_list

#Load the variants of respondent descriptor
prompt_variant_list = pd.read_csv("Prompts_Respondent_Descriptors_Cultural_Prompted.csv")
prompt_variant_list

#Function to save the completion objects 
def serialize_completion(completion):
    return {
        "id": completion.id,
        "choices": [
            {
                "finish_reason": choice.finish_reason,
                "index": choice.index,
                "message": {
                    "content": choice.message.content,
                    "role": choice.message.role,
                    "function_call": {
                        "arguments": json.loads(
                            choice.message.function_call.arguments) if choice.message.function_call and choice.message.function_call.arguments else None,
                        "name": choice.message.function_call.name
                    } if choice.message and choice.message.function_call else None
                } if choice.message else None
            } for choice in completion.choices
        ],
        "created": completion.created,
        "model": completion.model,
        "object": completion.object,
        "system_fingerprint": completion.system_fingerprint,
        "usage": {
            "completion_tokens": completion.usage.completion_tokens,
            "prompt_tokens": completion.usage.prompt_tokens,
            "total_tokens": completion.usage.total_tokens
        }
    }

#Create an empty dataframe to store GPT responses
responses_df = pd.DataFrame(columns=['#variant', 'country', 'scale', 'survey_question', 'generated_text'])
#Create an empty list to stroe multiple completion objects
responses_completion_obj = []

    
for index, row in prompt_variant_list.iterrows():
    system = row['respondent_descriptor'] + " born in " + args.district + " and living in " + args.district + " responding to the following survey question."
    variant = row['#variant']
    country = args.district

    for index, row in question_list.iterrows():
        scale = row['scale']
        question = row['prompt']
        chat_response = client.chat.completions.create(
            model = args.model,
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
        response = chat_response.choices[0].message.content.strip()
        responses_df.loc[len(responses_df)] = {"#variant": variant, "country": country, "scale":scale, "survey_question": question, "generated_text": response} 
        responses_completion_obj.append(serialize_completion(chat_response))
        with open(f'cultural_prompted_responses_completion_obj_{args.model}_{args.district}.json', 'w') as f:
            json.dump(responses_completion_obj, f)

###2.2 Convert responses to numeric scores###

responses_df['score'] = responses_df['generated_text']

#calculation of the Autonomy Index.
# V19 = Important Child Qualities: Religious Faith
Autonomy_rows = responses_df.loc[responses_df['scale'] == 'y003']
for index, row in Autonomy_rows.iterrows():
    if "Religious faith" in row['generated_text']:
        q15 = 1
    else:
        q15 = 2
# V21= Important Child Qualities: Obedience
    if "Obedience" in row['generated_text']:
        q17 = 1
    else:
        q17 = 2
# V12= Important Child Qualities: Independence
    if "Independence" in row['generated_text']:
        q8 = 1
    else:
        q8 = 2
#V18= Important Child Qualities: Determination, Perseverance
    if "Determination, perseverance" in row['generated_text']:
        q14 = 1
    else:
        q14 = 2
    responses_df.at[index, 'score'] = (q15 + q17) - (q8 + q14)

#calculation of the Post-Materialist index.
Materialist_rows = responses_df.loc[responses_df['scale'] == 'y002']
for index, row in Materialist_rows.iterrows():
    choices = row['generated_text']
    choices = choices.split(",")
    choice1 = int(choices[0])
    choice2 = int(choices[1])
    if choice1 == 1 and choice2 == 3:
        responses_df.at[index, 'score'] = 1
    elif choice1 == 3 and choice2 == 1:
        responses_df.at[index, 'score'] = 1
    elif choice1 == 2 and choice2 == 4:
        responses_df.at[index, 'score'] = 3
    elif choice1 == 4 and choice2 == 2:
        responses_df.at[index, 'score'] = 3
    else:
        responses_df.at[index, 'score'] = 2
        
#change the petition answer to a score
petition_rows = responses_df.loc[responses_df['scale'] == 'e025']
for index, row in petition_rows.iterrows():
    petition = row['generated_text']
    if "A" in petition:
        responses_df.at[index, 'score'] = 1
    elif "B" in petition:
        responses_df.at[index, 'score'] = 2
    elif "C" in petition:
        responses_df.at[index, 'score'] = 3
    else:
        if "would never sign" in petition:
            responses_df.at[index, 'score'] = 3
            
#change the people turst result to a score
ppl_trust_rows = responses_df.loc[responses_df['scale'] == 'a165']
for index, row in ppl_trust_rows.iterrows():
    ppl_trust = row['generated_text']
    if ppl_trust == 'A':
        responses_df.at[index, 'score'] = 1
    elif ppl_trust == 'B':
        responses_df.at[index, 'score'] = 2
    else:
        if "Most people can be trusted" in ppl_trust:
            responses_df.at[index, 'score'] = 1
            
#Save the scores
responses_df.to_csv(f"Cultural_Prompted_Responses_{args.model}_{args.district}.csv", index=False)

#Combine all the response scores of one GPT model
district_list = pd.read_csv("s003.csv")
districts = district_list['country.territory']
converter = lambda x: x.replace(' ', '_')
districts = list(map(converter, districts))

output = pd.DataFrame(columns=['#variant', 'country', 'scale', 'survey_question', 'generated_text', 'score'])
for d in districts:
    new_output = pd.read_csv("Cultural_Prompted_Responses_[ENTER GPT MODEL NAME HERE]_"+d+".csv")
    output =pd.concat([output, new_output])

###Manually check the scores###

#Covnert the combined table to the wide format for futher analysis
wide_table_output = output.pivot(index = ['country', '#variant'], columns = 'scale', values = 'score')
wide_table_output = wide_table_output.reset_index()
wide_table_output.to_csv("WideTable_Part2_all_district_scores_[GPT MODEL NAME].csv", index=False)