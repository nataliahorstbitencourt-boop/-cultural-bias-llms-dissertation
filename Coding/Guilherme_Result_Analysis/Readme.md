Scripts

scripts/generate_statistical_tables.py

O que faz: Gera as 3 tabelas estatísticas principais a partir do arquivo de distâncias L2 já existente.
Como usar:
/usr/bin/python3 scripts/generate_statistical_tables.py

Depende de: results/cultural_prompting/RQ2_CP_Responses_L2_Results.csv
Gera: os 3 CSVs em results/ descritos abaixo.


scripts/generate_statistical_tables.R

O que faz: Equivalente R do script acima. Mesmos outputs, mesmos valores. Usa tidyverse.
Como usar no RStudio: 
Abrir o arquivo e clicar em Source (ou Ctrl+Shift+S). O script detecta o diretório raiz do projeto automaticamente via rstudioapi.

Como usar no terminal (se R estiver no PATH):
Rscript scripts/generate_statistical_tables.R

Depende de: results/cultural_prompting/RQ2_CP_Responses_L2_Results.csv


scripts/identify_outliers.py

O que faz: Detecta países outliers usando dois métodos (IQR de Tukey e z-score > 2), para cada modelo e cada métrica (L2_C, L2_A, diff). Identifica também falhas de prompting (diff < 0) e outliers sistemáticos.

Como usar:
/usr/bin/python3 scripts/identify_outliers.py

Depende de: results/Consolidated_L2_All_Models_by_Country.csv (gerado pelo script de tabelas acima)
Gera: os 4 CSVs em results/outliers/.

scripts/identify_outliers.R

O que faz: Equivalente R do script de outliers. Mesma lógica, mesmos outputs.

Como usar no RStudio: Abrir e clicar em Source.

Depende de: results/Consolidated_L2_All_Models_by_Country.csv
