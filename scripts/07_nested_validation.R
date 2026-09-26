source("scripts/validation.R")

model_dataset <- readr::read_csv("data/processed/model_dataset.csv", show_col_types = FALSE)
validate_model_data(model_dataset)
result <- evaluate_nested_cv(model_dataset)
readr::write_csv(result$predictions, "output/tables/nested_cv_predictions.csv")
readr::write_csv(result$summary, "output/tables/nested_cv_summary.csv")
message("Nested cross-validation dan baseline selesai.")
