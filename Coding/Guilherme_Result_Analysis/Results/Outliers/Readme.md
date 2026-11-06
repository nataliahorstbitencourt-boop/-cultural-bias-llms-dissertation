Tabelas de outliers — results/outliers/

results/outliers/Outliers_Detailed.csv

91 registros. Cada linha é uma flag individual: país + modelo + métrica + valor + limites IQR + z-score + qual(is) método(s) detectou + rótulo de direção (far_from_human, prompting_failure, high_gain, etc.).

results/outliers/Outliers_Summary.csv

Um resumo por país (39 países com ao menos uma flag). Consolida: total de flags, flags por método, por métrica, por condição, quantos modelos flagaram, quais modelos falharam no prompting.

results/outliers/Prompting_Failures.csv

45 países onde pelo menos um modelo produziu distância maior com prompting do que sem. Formato wide: uma coluna por modelo com o valor negativo da diff. Coluna n_models_failed indica em quantos dos 7 modelos o prompting falhou.

results/outliers/Systematic_Outliers.csv

10 países flagados em 3 ou mais modelos simultaneamente — os casos mais robustos e potencialmente mais relevantes para a dissertação.
