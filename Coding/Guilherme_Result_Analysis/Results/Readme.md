Tabelas geradas — results/

results/Statistical_Analysis_PerModel_CvsA.csv

7 linhas (uma por modelo). Para cada modelo: média, mediana, DP, min, max, Shapiro-Wilk (W e p) e flag de normalidade para L2_C e L2_A; diferença de médias; Wilcoxon pareado (V e p) comparando C vs A; flag de significância. 
Responde: o cultural prompting reduziu significativamente a distância cultural?


results/Statistical_Analysis_Pairwise_Wilcoxon.csv

42 linhas (21 pares de modelos × 2 condições). Para cada par: p-valor bruto e corrigido por Bonferroni, flags de significância. 
Responde: os modelos diferem significativamente entre si, dentro da mesma condição?


results/Consolidated_L2_All_Models_by_Country.csv

107 linhas (uma por país). 22 colunas: L2_C, L2_A e diff (C−A) para cada um dos 7 modelos. Tabela de referência granular para comparação entre países e modelos. Valores negativos em diff indicam falha do prompting.
