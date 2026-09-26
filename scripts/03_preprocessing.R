source("scripts/00_common.R")
source("scripts/validation.R")

dataset <- readr::read_csv("data/processed/dataset_final.csv", show_col_types = FALSE)

numeric_columns <- names(dataset)[vapply(dataset, is.numeric, logical(1))]
outlier_summary <- lapply(numeric_columns, function(variable) {
  x <- dataset[[variable]]
  q1 <- quantile(x, 0.25, na.rm = TRUE)
  q3 <- quantile(x, 0.75, na.rm = TRUE)
  iqr <- q3 - q1
  lower <- q1 - 1.5 * iqr
  upper <- q3 + 1.5 * iqr
  tibble(
    variable = variable,
    lower_bound = lower,
    upper_bound = upper,
    outlier_count = sum(x < lower | x > upper, na.rm = TRUE)
  )
}) |>
  bind_rows()

model_dataset <- dataset |>
  mutate(pdrb_per_kapita_juta = pdrb_per_kapita_ribu / 1000) |>
  select(
    wilayah,
    persentase_miskin,
    ipm,
    tpt,
    pdrb_per_kapita_juta,
    rata_lama_sekolah,
    sanitasi_layak,
    kepadatan_penduduk
  )

validate_model_data(model_dataset)

save_table(model_dataset, "data/processed/model_dataset.csv")
save_table(outlier_summary, "output/tables/outlier_summary.csv")

message("Preprocessing selesai.")
