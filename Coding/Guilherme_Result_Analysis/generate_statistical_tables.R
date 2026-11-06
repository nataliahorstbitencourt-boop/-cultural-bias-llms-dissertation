# generate_statistical_tables.R
#
# R equivalent of scripts/generate_statistical_tables.py
#
# Reads:  results/cultural_prompting/RQ2_CP_Responses_L2_Results.csv
# Writes:
#   results/Statistical_Analysis_PerModel_CvsA.csv
#   results/Statistical_Analysis_Pairwise_Wilcoxon.csv
#   results/Consolidated_L2_All_Models_by_Country.csv
#
# Usage (RStudio): source this file with the project root as working directory.
# Usage (terminal): Rscript scripts/generate_statistical_tables.R

library(tidyverse)

# ---------------------------------------------------------------------------
# Paths — set BASE_DIR to the project root if running outside RStudio
# ---------------------------------------------------------------------------
BASE_DIR <- tryCatch(
  dirname(dirname(rstudioapi::getSourceEditorContext()$path)),
  error = function(e) getwd()
)

src     <- file.path(BASE_DIR, "results", "cultural_prompting",
                     "RQ2_CP_Responses_L2_Results.csv")
out_dir <- file.path(BASE_DIR, "results")

df <- read.csv(src)
cat(sprintf("Loaded %d countries/territories.\n\n", nrow(df)))


# ---------------------------------------------------------------------------
# Model registry  (name -> c(col_c, col_a))
# ---------------------------------------------------------------------------
MODELS <- list(
  "GPT-3"         = c("l2_c_gpt_3",         "l2_a_gpt3"),
  "GPT-3.5-turbo" = c("l2_c_gpt_3.5_turbo", "l2_a_gpt3.5turbo"),
  "GPT-4"         = c("l2_c_gpt_4",         "l2_a_gpt4"),
  "GPT-4-turbo"   = c("l2_c_gpt_4_turbo",   "l2_a_gpt4turbo"),
  "GPT-4o"        = c("l2_c_gpt_4o",        "l2_a_gpt4o"),
  "GPT-5.6-terra" = c("l2_c_gpt_5.6",       "l2_a_gpt5.6terra"),
  "GPT-6-astra"   = c("l2_c_gpt_6_astra",   "l2_a_gpt6astra")
)


# ---------------------------------------------------------------------------
# TABLE 1: Per-model descriptives + Shapiro-Wilk + paired Wilcoxon (C vs A)
# ---------------------------------------------------------------------------
cat("=== TABLE 1: Per-model C vs A ===\n")

table1 <- map_dfr(names(MODELS), function(model_name) {
  col_c <- MODELS[[model_name]][1]
  col_a <- MODELS[[model_name]][2]

  paired <- df[, c("country.territory", col_c, col_a)] |>
    na.omit()
  n   <- nrow(paired)
  x_c <- paired[[col_c]]
  x_a <- paired[[col_a]]

  shap_c  <- shapiro.test(x_c)
  shap_a  <- shapiro.test(x_a)
  wilcox  <- wilcox.test(x_c, x_a, paired = TRUE)

  cat(sprintf("  %-14s: n=%d  mean_C=%.3f  mean_A=%.3f  wilcox_p=%.2e\n",
              model_name, n, mean(x_c), mean(x_a), wilcox$p.value))

  tibble(
    model               = model_name,
    n_paired            = n,
    # --- Without CP ---
    mean_L2_C           = round(mean(x_c),   4),
    median_L2_C         = round(median(x_c), 4),
    sd_L2_C             = round(sd(x_c),     4),
    min_L2_C            = round(min(x_c),    4),
    max_L2_C            = round(max(x_c),    4),
    shapiro_W_C         = round(shap_c$statistic, 4),
    shapiro_p_C         = shap_c$p.value,
    normal_C            = if_else(shap_c$p.value > 0.05, "yes", "no"),
    # --- With CP ---
    mean_L2_A           = round(mean(x_a),   4),
    median_L2_A         = round(median(x_a), 4),
    sd_L2_A             = round(sd(x_a),     4),
    min_L2_A            = round(min(x_a),    4),
    max_L2_A            = round(max(x_a),    4),
    shapiro_W_A         = round(shap_a$statistic, 4),
    shapiro_p_A         = shap_a$p.value,
    normal_A            = if_else(shap_a$p.value > 0.05, "yes", "no"),
    # --- Wilcoxon C vs A ---
    mean_diff_C_minus_A = round(mean(x_c - x_a), 4),
    wilcoxon_V          = wilcox$statistic,
    wilcoxon_p          = wilcox$p.value,
    significant_p05     = if_else(wilcox$p.value < 0.05, "yes", "no")
  )
})

write.csv(table1,
          file.path(out_dir, "Statistical_Analysis_PerModel_CvsA.csv"),
          row.names = FALSE)
cat(sprintf("\nSaved → Statistical_Analysis_PerModel_CvsA.csv\n\n"))


# ---------------------------------------------------------------------------
# TABLE 2: Pairwise Wilcoxon between models (both conditions)
# ---------------------------------------------------------------------------
cat("=== TABLE 2: Pairwise Wilcoxon between models ===\n")

pairwise_wilcoxon <- function(data, col_map, condition) {
  model_names <- names(col_map)
  pairs <- combn(model_names, 2, simplify = FALSE)

  rows <- map_dfr(pairs, function(pair) {
    m1 <- pair[1]; m2 <- pair[2]
    c1 <- col_map[[m1]]; c2 <- col_map[[m2]]

    paired <- data[, c(c1, c2)] |> na.omit()
    n      <- nrow(paired)
    test   <- wilcox.test(paired[[c1]], paired[[c2]], paired = TRUE)

    tibble(
      condition   = condition,
      model_1     = m1,
      model_2     = m2,
      n_paired    = n,
      wilcoxon_V  = test$statistic,
      p_value     = test$p.value
    )
  })

  k <- nrow(rows)
  rows |>
    mutate(
      p_adjusted          = pmin(p_value * k, 1),
      significant_p05     = if_else(p_value    < 0.05, "yes", "no"),
      significant_adj_p05 = if_else(p_adjusted < 0.05, "yes", "no")
    )
}

c_cols <- map(MODELS, 1) |> setNames(names(MODELS))
a_cols <- map(MODELS, 2) |> setNames(names(MODELS))

table2 <- bind_rows(
  pairwise_wilcoxon(df, c_cols, "Without_Cultural_Prompting"),
  pairwise_wilcoxon(df, a_cols, "With_Cultural_Prompting")
)

write.csv(table2,
          file.path(out_dir, "Statistical_Analysis_Pairwise_Wilcoxon.csv"),
          row.names = FALSE)
cat(sprintf("  %d pairwise tests (%d per condition)\n",
            nrow(table2), nrow(table2) / 2))
cat(sprintf("Saved → Statistical_Analysis_Pairwise_Wilcoxon.csv\n\n"))


# ---------------------------------------------------------------------------
# TABLE 3: Consolidated L2 by Country (all models, wide + diff columns)
# ---------------------------------------------------------------------------
cat("=== TABLE 3: Consolidated L2 by Country ===\n")

rename_map <- c(
  l2_c_gpt_3         = "GPT3_L2_C",
  l2_c_gpt_3.5_turbo = "GPT35Turbo_L2_C",
  l2_c_gpt_4         = "GPT4_L2_C",
  l2_c_gpt_4_turbo   = "GPT4Turbo_L2_C",
  l2_c_gpt_4o        = "GPT4o_L2_C",
  l2_c_gpt_5.6       = "GPT56Terra_L2_C",
  l2_c_gpt_6_astra   = "GPT6Astra_L2_C",
  l2_a_gpt3          = "GPT3_L2_A",
  l2_a_gpt3.5turbo   = "GPT35Turbo_L2_A",
  l2_a_gpt4          = "GPT4_L2_A",
  l2_a_gpt4turbo     = "GPT4Turbo_L2_A",
  l2_a_gpt4o         = "GPT4o_L2_A",
  l2_a_gpt5.6terra   = "GPT56Terra_L2_A",
  l2_a_gpt6astra     = "GPT6Astra_L2_A"
)

short_names <- c("GPT3", "GPT35Turbo", "GPT4", "GPT4Turbo",
                 "GPT4o", "GPT56Terra", "GPT6Astra")

cons <- df |>
  select(country.territory, all_of(names(rename_map))) |>
  rename(all_of(rename_map))

for (sn in short_names) {
  cons[[paste0(sn, "_diff_C_minus_A")]] <-
    round(cons[[paste0(sn, "_L2_C")]] - cons[[paste0(sn, "_L2_A")]], 4)
}

# Column order: country | [C, A, diff] × 7 models
ordered_cols <- c("country.territory",
                  as.vector(outer(short_names,
                                  c("_L2_C", "_L2_A", "_diff_C_minus_A"),
                                  paste0)))
cons <- cons |>
  select(all_of(ordered_cols)) |>
  arrange(country.territory)

write.csv(cons,
          file.path(out_dir, "Consolidated_L2_All_Models_by_Country.csv"),
          row.names = FALSE)
cat(sprintf("  %d countries × %d columns\n", nrow(cons), ncol(cons)))
cat(sprintf("Saved → Consolidated_L2_All_Models_by_Country.csv\n\n"))


# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
cat(strrep("=", 60), "\n")
cat("All tables generated successfully.\n")
