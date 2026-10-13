**ARTIGO QUE GUIA O TRABALHO**: Cultural bias and cultural alignment of large language models <br> 

**LINK:** https://doi.org/10.1093/pnasnexus/pgae346 <br>

**RESULTADOS AUTORES:** https://osf.io/7sj3w/<br>

**LINK TEXTO QUALIFICAÇÃO:** https://docs.google.com/document/d/199j48Bk4fyCIyiN_NmwbA02D7XNCNMY5DnzYmmYRV20/edit?usp=sharing<br>

 
 
A minha ideia para a dissertação é replicar o estudo com versões mais recentes dos modelos OPENAI. O objetivo dos autores foi verificar se quais valores culturais os modelos de linguagem da OpenAI representam e se o “cultural prompting” (pedir ao modelo que responda como alguém de um país específico) reduz esse viés. 

O primeiro passo foi construir o parâmetro de comparação a partir do Integrated Values Surveys (IVS), base que combina a World Values Survey (WVS) e a European Values Study (EVS). Os autores usaram os três ciclos mais recentes, de 2005 a 2022, o que resultou em 393.536 observações individuais de 112 países. Cinco deles (Egito, Kuwait, Catar, Tajiquistão e Uzbequistão) foram excluídos porque não tinham respostas válidas para alguma das perguntas necessárias, e a análise final ficou com 107 países e territórios.

Com esses dados, os autores replicaram o Mapa Cultural de Inglehart-Welzel, extraindo as mesmas dez perguntas que dão origem ao mapa original: felicidade, confiança nas pessoas, respeito à autoridade, experiência de assinar petições, importância de Deus, justificabilidade da homossexualidade, justificabilidade do aborto, orgulho da nacionalidade, índice pós-materialista e índice de autonomia.

Os autores fizeram às versões do GPT (GPT-3, 3.5-turbo, 4, 4-turbo e 4o) as 10 perguntas do Mapa Cultural de Inglehart-Welzel. Foram adotados dois tipos de condição de análise: o primeiro, sem indicação de país, em que o modelo foi instruído a responder como um “ser humano médio”, com o objetivo de identificar seus valores culturais padrão; e o segundo, com indicação de país (cultural prompting), em que o modelo foi instruído a responder como uma pessoa nascida e residente em cada um dos 107 países ou territórios analisados, com o objetivo de verificar se essa instrução aproximaria suas respostas dos valores locais. As respostas são então comparadas com dados reais da World Values Survey e da European Values Study de 107 países. O viés foi medido pela distância entre a posição do modelo e a do país no mapa.

Para avançar o estudo dos autores, propõem-se, posteriormente, testar as mesmas questões com subgrupos sociodemográficos.

**IMPORTANTE:** A pasta data/original_article tem os scripts e csvs para fazer a rodagem. Está dividida pela parte sem cultural prompting e com cultural prompting. A pasta resultados contém os resultados dos dois testes preliminares que eu realizei (Piloto 1 e Piloto 2). Coloquei apenas os resultados do Piloto 2, nessa pasta (Test Pilot 2). Os parâmetros usados nesses testes podem ser encontrados no arquivo "Procedures". E a pasta scripts R tem os scripts do R para fazer a análise estatística. Fiz algumas alterações no script da rodagem geral (Part_1_New_Code). O Part1_Generation_and_Preprocessing é o script original.






































