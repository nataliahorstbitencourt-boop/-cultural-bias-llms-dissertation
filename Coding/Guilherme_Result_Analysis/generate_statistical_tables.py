"""
Generate statistical summary tables from L2 distance results.

Outputs (saved to results/):
  1. Statistical_Analysis_PerModel_CvsA.csv
       Descriptives + Shapiro-Wilk + paired Wilcoxon (C vs A) for each model.

  2. Statistical_Analysis_Pairwise_Wilcoxon.csv
       All pairwise Wilcoxon tests between models, for both conditions
       (without CP and with CP), with Bonferroni correction.

  3. Consolidated_L2_All_Models_by_Country.csv
       Single wide table: country, L2_C and L2_A for every model, plus diff.

Run from the project root:
    python -I scripts/generate_statistical_tables.py
"""

import sys, os
import pandas as pd
import numpy as np
from scipy import stats
from itertools import combinations

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC  = os.path.join(BASE, "results", "cultural_prompting",
                    "RQ2_CP_Responses_L2_Results.csv")
OUT  = os.path.join(BASE, "results")

df = pd.read_csv(SRC, index_col=0)
print(f"Loaded {len(df)} countries/territories.")
print(f"Columns: {list(df.columns)}\n")

# ---------------------------------------------------------------------------
# Model registry  (name → (col_c, col_a))
# ---------------------------------------------------------------------------
MODELS = {
    "GPT-3":         ("l2_c_gpt_3",         "l2_a_gpt3"),
    "GPT-3.5-turbo": ("l2_c_gpt_3.5_turbo", "l2_a_gpt3.5turbo"),
    "GPT-4":         ("l2_c_gpt_4",         "l2_a_gpt4"),
    "GPT-4-turbo":   ("l2_c_gpt_4_turbo",   "l2_a_gpt4turbo"),
    "GPT-4o":        ("l2_c_gpt_4o",        "l2_a_gpt4o"),
    "GPT-5.6-terra": ("l2_c_gpt_5.6",       "l2_a_gpt5.6terra"),
    "GPT-6-astra":   ("l2_c_gpt_6_astra",   "l2_a_gpt6astra"),
}

# ---------------------------------------------------------------------------
# TABLE 1: Per-model descriptives + Shapiro + paired Wilcoxon (C vs A)
# ---------------------------------------------------------------------------
print("=== TABLE 1: Per-model C vs A ===")
rows = []
for model, (col_c, col_a) in MODELS.items():
    paired = df[["country.territory", col_c, col_a]].dropna()
    n = len(paired)

    x_c = paired[col_c].values
    x_a = paired[col_a].values

    shap_c  = stats.shapiro(x_c)
    shap_a  = stats.shapiro(x_a)
    wilcox  = stats.wilcoxon(x_c, x_a)

    rows.append({
        "model":           model,
        "n_paired":        n,
        # --- Without CP ---
        "mean_L2_C":       round(x_c.mean(),  4),
        "median_L2_C":     round(np.median(x_c), 4),
        "sd_L2_C":         round(x_c.std(ddof=1), 4),
        "min_L2_C":        round(x_c.min(),   4),
        "max_L2_C":        round(x_c.max(),   4),
        "shapiro_W_C":     round(shap_c.statistic, 4),
        "shapiro_p_C":     shap_c.pvalue,
        "normal_C":        "yes" if shap_c.pvalue > 0.05 else "no",
        # --- With CP ---
        "mean_L2_A":       round(x_a.mean(),  4),
        "median_L2_A":     round(np.median(x_a), 4),
        "sd_L2_A":         round(x_a.std(ddof=1), 4),
        "min_L2_A":        round(x_a.min(),   4),
        "max_L2_A":        round(x_a.max(),   4),
        "shapiro_W_A":     round(shap_a.statistic, 4),
        "shapiro_p_A":     shap_a.pvalue,
        "normal_A":        "yes" if shap_a.pvalue > 0.05 else "no",
        # --- Wilcoxon C vs A ---
        "mean_diff_C_minus_A": round(float((x_c - x_a).mean()), 4),
        "wilcoxon_V":      wilcox.statistic,
        "wilcoxon_p":      wilcox.pvalue,
        "significant_p05": "yes" if wilcox.pvalue < 0.05 else "no",
    })
    print(f"  {model}: n={n}, mean_C={rows[-1]['mean_L2_C']:.3f}, "
          f"mean_A={rows[-1]['mean_L2_A']:.3f}, "
          f"wilcox_p={wilcox.pvalue:.2e}")

table1 = pd.DataFrame(rows)
out1 = os.path.join(OUT, "Statistical_Analysis_PerModel_CvsA.csv")
table1.to_csv(out1, index=False)
print(f"\nSaved → {out1}\n")

# ---------------------------------------------------------------------------
# TABLE 2: Pairwise Wilcoxon between models (both conditions)
# ---------------------------------------------------------------------------
print("=== TABLE 2: Pairwise Wilcoxon between models ===")

C_COLS = {name: cols[0] for name, cols in MODELS.items()}
A_COLS = {name: cols[1] for name, cols in MODELS.items()}

def pairwise_wilcoxon(data, col_map, condition):
    pairs = list(combinations(col_map.items(), 2))
    rows  = []
    for (m1, c1), (m2, c2) in pairs:
        paired = data[[c1, c2]].dropna()
        n      = len(paired)
        stat, p = stats.wilcoxon(paired[c1].values, paired[c2].values)
        rows.append({
            "condition": condition,
            "model_1":   m1,
            "model_2":   m2,
            "n_paired":  n,
            "wilcoxon_V": stat,
            "p_value":   p,
        })
    result = pd.DataFrame(rows)
    # Bonferroni correction
    k = len(result)
    result["p_adjusted"] = (result["p_value"] * k).clip(upper=1.0)
    result["significant_p05"]     = result["p_value"].lt(0.05).map({True:"yes", False:"no"})
    result["significant_adj_p05"] = result["p_adjusted"].lt(0.05).map({True:"yes", False:"no"})
    return result

table2 = pd.concat([
    pairwise_wilcoxon(df, C_COLS, "Without_Cultural_Prompting"),
    pairwise_wilcoxon(df, A_COLS, "With_Cultural_Prompting"),
], ignore_index=True)

out2 = os.path.join(OUT, "Statistical_Analysis_Pairwise_Wilcoxon.csv")
table2.to_csv(out2, index=False)
print(f"  {len(table2)} pairwise tests ({len(table2)//2} per condition)")
print(f"Saved → {out2}\n")

# ---------------------------------------------------------------------------
# TABLE 3: Consolidated L2 by Country (all models, wide + diff columns)
# ---------------------------------------------------------------------------
print("=== TABLE 3: Consolidated L2 by Country ===")

RENAME = {
    "l2_c_gpt_3":         "GPT3_L2_C",
    "l2_c_gpt_3.5_turbo": "GPT35Turbo_L2_C",
    "l2_c_gpt_4":         "GPT4_L2_C",
    "l2_c_gpt_4_turbo":   "GPT4Turbo_L2_C",
    "l2_c_gpt_4o":        "GPT4o_L2_C",
    "l2_c_gpt_5.6":       "GPT56Terra_L2_C",
    "l2_c_gpt_6_astra":   "GPT6Astra_L2_C",
    "l2_a_gpt3":          "GPT3_L2_A",
    "l2_a_gpt3.5turbo":   "GPT35Turbo_L2_A",
    "l2_a_gpt4":          "GPT4_L2_A",
    "l2_a_gpt4turbo":     "GPT4Turbo_L2_A",
    "l2_a_gpt4o":         "GPT4o_L2_A",
    "l2_a_gpt5.6terra":   "GPT56Terra_L2_A",
    "l2_a_gpt6astra":     "GPT6Astra_L2_A",
}

# Desired column order: country | [model: C, A, diff] × 7
SHORT_NAMES = ["GPT3", "GPT35Turbo", "GPT4", "GPT4Turbo", "GPT4o", "GPT56Terra", "GPT6Astra"]

cons = df[["country.territory"] + list(RENAME.keys())].rename(columns=RENAME).copy()

for sn in SHORT_NAMES:
    cons[f"{sn}_diff_C_minus_A"] = round(cons[f"{sn}_L2_C"] - cons[f"{sn}_L2_A"], 4)

# Reorder: C, A, diff per model
ordered_cols = ["country.territory"]
for sn in SHORT_NAMES:
    ordered_cols += [f"{sn}_L2_C", f"{sn}_L2_A", f"{sn}_diff_C_minus_A"]

cons = cons[ordered_cols].sort_values("country.territory")

out3 = os.path.join(OUT, "Consolidated_L2_All_Models_by_Country.csv")
cons.to_csv(out3, index=False)
print(f"  {len(cons)} countries × {len(cons.columns)} columns")
print(f"Saved → {out3}\n")

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
print("=" * 60)
print("All tables generated successfully.")
print(f"  1. {out1}")
print(f"  2. {out2}")
print(f"  3. {out3}")
