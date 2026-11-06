"""
Outlier identification for L2 cultural distance results.

Two complementary methods are applied for each model and metric:
  - IQR (Tukey fences): outlier if value < Q1 - 1.5*IQR  or  > Q3 + 1.5*IQR
    Robust to non-normal distributions (appropriate here: L2_C is non-normal).
  - Z-score: outlier if |z| > 2  (approx. top/bottom 5% under normality)

Metrics analysed per model:
  - L2_C  : distance without cultural prompting
  - L2_A  : distance with cultural prompting
  - diff  : L2_C - L2_A  (positive = prompting helped; negative = prompting hurt)

Outputs saved to results/outliers/:
  1. Outliers_Detailed.csv      — every flag for every country/model/metric
  2. Outliers_Summary.csv       — per country: total flags + breakdown
  3. Prompting_Failures.csv     — countries where diff < 0 for any model
  4. Systematic_Outliers.csv    — countries flagged in ≥ 3 models (any metric)

Run:
    /usr/bin/python3 scripts/identify_outliers.py
"""

import os
import pandas as pd
import numpy as np

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
BASE   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC    = os.path.join(BASE, "results", "Consolidated_L2_All_Models_by_Country.csv")
OUTDIR = os.path.join(BASE, "results", "outliers")
os.makedirs(OUTDIR, exist_ok=True)

df = pd.read_csv(SRC)
print(f"Loaded {len(df)} countries.\n")

# ---------------------------------------------------------------------------
# Model registry  (short_name → column prefixes in the consolidated CSV)
# ---------------------------------------------------------------------------
MODELS = {
    "GPT-3":         "GPT3",
    "GPT-3.5-turbo": "GPT35Turbo",
    "GPT-4":         "GPT4",
    "GPT-4-turbo":   "GPT4Turbo",
    "GPT-4o":        "GPT4o",
    "GPT-5.6-terra": "GPT56Terra",
    "GPT-6-astra":   "GPT6Astra",
}

METRICS = ["L2_C", "L2_A", "diff_C_minus_A"]

# ---------------------------------------------------------------------------
# Helper: detect outliers in a series using IQR and z-score
# ---------------------------------------------------------------------------
def flag_outliers(series, label):
    """
    Returns a DataFrame with one row per observation containing:
      - value
      - IQR bounds (lower_iqr, upper_iqr)
      - z-score
      - flags: iqr_low, iqr_high, zscore_low, zscore_high
      - combined: any_outlier_iqr, any_outlier_zscore, any_outlier
    """
    s = series.copy()

    q1, q3 = s.quantile(0.25), s.quantile(0.75)
    iqr = q3 - q1
    lower_iqr = q1 - 1.5 * iqr
    upper_iqr = q3 + 1.5 * iqr

    mean, sd = s.mean(), s.std(ddof=1)
    z = (s - mean) / sd

    out = pd.DataFrame({
        "value":       s.values,
        "lower_iqr":   round(lower_iqr, 4),
        "upper_iqr":   round(upper_iqr, 4),
        "z_score":     z.round(3).values,
        "iqr_low":     (s < lower_iqr).values,
        "iqr_high":    (s > upper_iqr).values,
        "zscore_low":  (z < -2).values,
        "zscore_high": (z >  2).values,
    }, index=s.index)

    out["any_outlier_iqr"]    = out["iqr_low"]    | out["iqr_high"]
    out["any_outlier_zscore"] = out["zscore_low"]  | out["zscore_high"]
    out["any_outlier"]        = out["any_outlier_iqr"] | out["any_outlier_zscore"]
    return out


# ---------------------------------------------------------------------------
# Build detailed flags table
# ---------------------------------------------------------------------------
detail_rows = []

for model_name, prefix in MODELS.items():
    for metric in METRICS:
        col = f"{prefix}_{metric}"
        series = df.set_index("country.territory")[col].dropna()
        flags  = flag_outliers(series, col)

        for country, row in flags.iterrows():
            if not row["any_outlier"]:
                continue

            # Direction label for interpretability
            if metric == "diff_C_minus_A":
                direction = (
                    "prompting_failure"   if row["value"] < 0 else
                    "high_gain"           if row["iqr_high"] or row["zscore_high"] else
                    "low_gain"
                )
            else:
                direction = (
                    "far_from_human"  if row["iqr_high"] or row["zscore_high"] else
                    "close_to_human"
                )

            detail_rows.append({
                "country":          country,
                "model":            model_name,
                "metric":           metric,
                "value":            round(row["value"], 4),
                "lower_iqr":        row["lower_iqr"],
                "upper_iqr":        row["upper_iqr"],
                "z_score":          row["z_score"],
                "iqr_outlier":      row["any_outlier_iqr"],
                "zscore_outlier":   row["any_outlier_zscore"],
                "both_methods":     row["any_outlier_iqr"] and row["any_outlier_zscore"],
                "direction":        direction,
            })

detail = pd.DataFrame(detail_rows).sort_values(
    ["country", "model", "metric"]
).reset_index(drop=True)

out1 = os.path.join(OUTDIR, "Outliers_Detailed.csv")
detail.to_csv(out1, index=False)
print(f"Outliers_Detailed.csv  →  {len(detail)} flags across "
      f"{detail['country'].nunique()} countries")


# ---------------------------------------------------------------------------
# Summary per country
# ---------------------------------------------------------------------------
summary_rows = []

for country in df["country.territory"]:
    cdf = detail[detail["country"] == country]

    total_flags     = len(cdf)
    iqr_flags       = cdf["iqr_outlier"].sum()
    zscore_flags    = cdf["zscore_outlier"].sum()
    both_flags      = cdf["both_methods"].sum()
    models_flagged  = sorted(cdf["model"].unique().tolist())
    n_models        = len(models_flagged)

    l2c_flags  = len(cdf[cdf["metric"] == "L2_C"])
    l2a_flags  = len(cdf[cdf["metric"] == "L2_A"])
    diff_flags = len(cdf[cdf["metric"] == "diff_C_minus_A"])

    failures = cdf[cdf["direction"] == "prompting_failure"]
    n_failures       = len(failures)
    failure_models   = sorted(failures["model"].unique().tolist())

    far_flags  = len(cdf[cdf["direction"] == "far_from_human"])
    close_flags= len(cdf[cdf["direction"] == "close_to_human"])
    gain_flags = len(cdf[cdf["direction"] == "high_gain"])

    summary_rows.append({
        "country":                  country,
        "total_outlier_flags":      total_flags,
        "flagged_by_iqr":           iqr_flags,
        "flagged_by_zscore":        zscore_flags,
        "flagged_by_both_methods":  both_flags,
        "n_models_with_any_flag":   n_models,
        "models_flagged":           "; ".join(models_flagged) if models_flagged else "",
        "flags_in_L2_C":            l2c_flags,
        "flags_in_L2_A":            l2a_flags,
        "flags_in_diff":            diff_flags,
        "n_prompting_failures":     n_failures,
        "failure_models":           "; ".join(failure_models) if failure_models else "",
        "flags_far_from_human":     far_flags,
        "flags_close_to_human":     close_flags,
        "flags_high_gain":          gain_flags,
    })

summary = (
    pd.DataFrame(summary_rows)
    .sort_values("total_outlier_flags", ascending=False)
    .reset_index(drop=True)
)

out2 = os.path.join(OUTDIR, "Outliers_Summary.csv")
summary.to_csv(out2, index=False)
print(f"Outliers_Summary.csv   →  {len(summary[summary['total_outlier_flags'] > 0])} "
      f"countries with at least one flag")


# ---------------------------------------------------------------------------
# Prompting failures  (diff < 0 for any model)
# ---------------------------------------------------------------------------
fail_rows = []
for model_name, prefix in MODELS.items():
    col = f"{prefix}_diff_C_minus_A"
    sub = df[["country.territory", col]].copy()
    sub.columns = ["country", "diff"]
    sub["model"] = model_name
    fail_rows.append(sub[sub["diff"] < 0])

failures_df = (
    pd.concat(fail_rows, ignore_index=True)
    .rename(columns={"diff": "diff_C_minus_A"})
    [["country", "model", "diff_C_minus_A"]]
    .sort_values(["country", "model"])
    .reset_index(drop=True)
)
failures_df["diff_C_minus_A"] = failures_df["diff_C_minus_A"].round(4)

# Pivot for readability: one row per country, one column per model
fail_pivot = failures_df.pivot_table(
    index="country", columns="model", values="diff_C_minus_A", aggfunc="first"
)
fail_pivot.columns.name = None
fail_pivot = fail_pivot.reset_index()
fail_pivot["n_models_failed"] = fail_pivot.iloc[:, 1:].notna().sum(axis=1)
fail_pivot = fail_pivot.sort_values("n_models_failed", ascending=False)

out3 = os.path.join(OUTDIR, "Prompting_Failures.csv")
fail_pivot.to_csv(out3, index=False)
print(f"Prompting_Failures.csv →  {len(fail_pivot)} countries where at least one "
      f"model got further from human culture with prompting")


# ---------------------------------------------------------------------------
# Systematic outliers  (flagged in ≥ 3 models, any metric)
# ---------------------------------------------------------------------------
systematic = summary[summary["n_models_with_any_flag"] >= 3].copy()

out4 = os.path.join(OUTDIR, "Systematic_Outliers.csv")
systematic.to_csv(out4, index=False)
print(f"Systematic_Outliers.csv→  {len(systematic)} countries flagged in ≥ 3 models")


# ---------------------------------------------------------------------------
# Console preview of key findings
# ---------------------------------------------------------------------------
print("\n" + "=" * 60)
print("KEY FINDINGS")
print("=" * 60)

print("\n--- Top 10 most-flagged countries ---")
print(summary[["country", "total_outlier_flags", "n_models_with_any_flag",
               "n_prompting_failures"]]
      .head(10).to_string(index=False))

print("\n--- Countries with most prompting failures ---")
top_fail = fail_pivot.nlargest(10, "n_models_failed")[
    ["country", "n_models_failed"]
]
print(top_fail.to_string(index=False))

print("\n--- Systematic outliers (≥ 3 models) ---")
if len(systematic):
    print(systematic[["country", "n_models_with_any_flag", "total_outlier_flags",
                       "n_prompting_failures", "models_flagged"]]
          .to_string(index=False))
else:
    print("  None found.")

print(f"\nAll files saved to: {OUTDIR}/")
