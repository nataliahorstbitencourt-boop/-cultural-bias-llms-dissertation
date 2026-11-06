# identify_outliers.R
#
# R equivalent of scripts/identify_outliers.py
#
# Two detection methods applied to each model × metric combination:
#   IQR  (Tukey fences): outlier if value < Q1 - 1.5*IQR  or  > Q3 + 1.5*IQR
#   Z-score: outlier if |z| > 2
#
# Metrics: L2_C, L2_A, diff_C_minus_A
#
# Reads:  results/Consolidated_L2_All_Models_by_Country.csv
# Writes (to results/outliers/):
#   Outliers_Detailed.csv
#   Outliers_Summary.csv
#   Prompting_Failures.csv
#   Systematic_Outliers.csv
#
# Usage (RStudio): source this file with the project root as working directory.
# Usage (terminal): Rscript scripts/identify_outliers.R

library(tidyverse)

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
BASE_DIR <- tryCatch(
  dirname(dirname(rstudioapi::getSourceEditorContext()$path)),
  error = function(e) getwd()
)

src     <- file.path(BASE_DIR, "results",
                     "Consolidated_L2_All_Models_by_Country.csv")
out_dir <- file.path(BASE_DIR, "results", "outliers")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

df <- read.csv(src)
cat(sprintf("Loaded %d countries.\n\n", nrow(df)))


# ---------------------------------------------------------------------------
# Model registry  (display name -> column prefix in the consolidated CSV)
# ---------------------------------------------------------------------------
MODELS <- c(
  "GPT-3"         = "GPT3",
  "GPT-3.5-turbo" = "GPT35Turbo",
  "GPT-4"         = "GPT4",
  "GPT-4-turbo"   = "GPT4Turbo",
  "GPT-4o"        = "GPT4o",
  "GPT-5.6-terra" = "GPT56Terra",
  "GPT-6-astra"   = "GPT6Astra"
)

METRICS <- c("L2_C", "L2_A", "diff_C_minus_A")


# ---------------------------------------------------------------------------
# Helper: flag outliers in a numeric vector using IQR and z-score
# ---------------------------------------------------------------------------
flag_outliers <- function(x, countries) {
  q1  <- quantile(x, 0.25, na.rm = TRUE)
  q3  <- quantile(x, 0.75, na.rm = TRUE)
  iqr <- IQR(x, na.rm = TRUE)
  lower_iqr <- q1 - 1.5 * iqr
  upper_iqr <- q3 + 1.5 * iqr

  z <- (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)

  tibble(
    country    = countries,
    value      = x,
    lower_iqr  = round(lower_iqr, 4),
    upper_iqr  = round(upper_iqr, 4),
    z_score    = round(z, 3),
    iqr_low    = x < lower_iqr,
    iqr_high   = x > upper_iqr,
    zscore_low = z < -2,
    zscore_high= z >  2
  ) |>
    mutate(
      any_outlier_iqr    = iqr_low    | iqr_high,
      any_outlier_zscore = zscore_low | zscore_high,
      any_outlier        = any_outlier_iqr | any_outlier_zscore
    )
}


# ---------------------------------------------------------------------------
# TABLE 1: Detailed flags
# ---------------------------------------------------------------------------
cat("=== Outliers_Detailed.csv ===\n")

detail <- map_dfr(names(MODELS), function(model_name) {
  prefix <- MODELS[[model_name]]

  map_dfr(METRICS, function(metric) {
    col     <- paste0(prefix, "_", metric)
    series  <- df[[col]]
    valid   <- !is.na(series)
    flags   <- flag_outliers(series[valid], df$country.territory[valid])

    flags |>
      filter(any_outlier) |>
      mutate(
        model  = model_name,
        metric = metric,
        direction = case_when(
          metric == "diff_C_minus_A" & value < 0          ~ "prompting_failure",
          metric == "diff_C_minus_A" & (iqr_high | zscore_high) ~ "high_gain",
          metric == "diff_C_minus_A"                       ~ "low_gain",
          iqr_high | zscore_high                           ~ "far_from_human",
          TRUE                                             ~ "close_to_human"
        ),
        iqr_outlier    = any_outlier_iqr,
        zscore_outlier = any_outlier_zscore,
        both_methods   = any_outlier_iqr & any_outlier_zscore
      ) |>
      select(country, model, metric, value,
             lower_iqr, upper_iqr, z_score,
             iqr_outlier, zscore_outlier, both_methods, direction)
  })
}) |>
  arrange(country, model, metric)

write.csv(detail, file.path(out_dir, "Outliers_Detailed.csv"), row.names = FALSE)
cat(sprintf("  %d flags across %d countries\n", nrow(detail), n_distinct(detail$country)))


# ---------------------------------------------------------------------------
# TABLE 2: Summary per country
# ---------------------------------------------------------------------------
cat("=== Outliers_Summary.csv ===\n")

summary_tbl <- df |>
  select(country.territory) |>
  rename(country = country.territory) |>
  left_join(
    detail |>
      group_by(country) |>
      summarise(
        total_outlier_flags     = n(),
        flagged_by_iqr          = sum(iqr_outlier),
        flagged_by_zscore       = sum(zscore_outlier),
        flagged_by_both_methods = sum(both_methods),
        n_models_with_any_flag  = n_distinct(model),
        models_flagged          = paste(sort(unique(model)), collapse = "; "),
        flags_in_L2_C           = sum(metric == "L2_C"),
        flags_in_L2_A           = sum(metric == "L2_A"),
        flags_in_diff           = sum(metric == "diff_C_minus_A"),
        n_prompting_failures    = sum(direction == "prompting_failure"),
        failure_models          = paste(sort(unique(model[direction == "prompting_failure"])),
                                        collapse = "; "),
        flags_far_from_human    = sum(direction == "far_from_human"),
        flags_close_to_human    = sum(direction == "close_to_human"),
        flags_high_gain         = sum(direction == "high_gain"),
        .groups = "drop"
      ),
    by = "country"
  ) |>
  mutate(across(where(is.numeric), ~ replace_na(., 0)),
         across(where(is.character) & !country, ~ replace_na(., ""))) |>
  arrange(desc(total_outlier_flags))

write.csv(summary_tbl,
          file.path(out_dir, "Outliers_Summary.csv"),
          row.names = FALSE)
cat(sprintf("  %d countries with at least one flag\n",
            sum(summary_tbl$total_outlier_flags > 0)))


# ---------------------------------------------------------------------------
# TABLE 3: Prompting failures (diff < 0 for any model)
# ---------------------------------------------------------------------------
cat("=== Prompting_Failures.csv ===\n")

failures_long <- map_dfr(names(MODELS), function(model_name) {
  prefix <- MODELS[[model_name]]
  col    <- paste0(prefix, "_diff_C_minus_A")
  df |>
    select(country = country.territory, diff = all_of(col)) |>
    filter(!is.na(diff), diff < 0) |>
    mutate(model = model_name,
           diff  = round(diff, 4))
})

fail_pivot <- failures_long |>
  pivot_wider(names_from = model, values_from = diff) |>
  mutate(n_models_failed = rowSums(!is.na(across(all_of(names(MODELS)))))) |>
  arrange(desc(n_models_failed))

write.csv(fail_pivot,
          file.path(out_dir, "Prompting_Failures.csv"),
          row.names = FALSE)
cat(sprintf("  %d countries where at least one model performed worse with prompting\n",
            nrow(fail_pivot)))


# ---------------------------------------------------------------------------
# TABLE 4: Systematic outliers (flagged in >= 3 models)
# ---------------------------------------------------------------------------
cat("=== Systematic_Outliers.csv ===\n")

systematic <- summary_tbl |>
  filter(n_models_with_any_flag >= 3)

write.csv(systematic,
          file.path(out_dir, "Systematic_Outliers.csv"),
          row.names = FALSE)
cat(sprintf("  %d countries flagged in >= 3 models\n", nrow(systematic)))


# ---------------------------------------------------------------------------
# Console preview
# ---------------------------------------------------------------------------
cat("\n", strrep("=", 60), "\n", sep = "")
cat("KEY FINDINGS\n")
cat(strrep("=", 60), "\n\n", sep = "")

cat("--- Top 10 most-flagged countries ---\n")
summary_tbl |>
  select(country, total_outlier_flags, n_models_with_any_flag, n_prompting_failures) |>
  slice_head(n = 10) |>
  print(n = 10)

cat("\n--- Countries with most prompting failures ---\n")
fail_pivot |>
  select(country, n_models_failed) |>
  slice_head(n = 10) |>
  print(n = 10)

cat("\n--- Systematic outliers (>= 3 models) ---\n")
if (nrow(systematic) > 0) {
  systematic |>
    select(country, n_models_with_any_flag, total_outlier_flags,
           n_prompting_failures, models_flagged) |>
    print(n = nrow(systematic))
} else {
  cat("  None found.\n")
}

cat(sprintf("\nAll files saved to: %s\n", out_dir))
