source("scripts/00_common.R")

model_dataset <- readr::read_csv("data/processed/model_dataset.csv", show_col_types = FALSE)
formula_model <- persentase_miskin ~ ipm + tpt + pdrb_per_kapita_juta + rata_lama_sekolah + sanitasi_layak + kepadatan_penduduk

rf_grid <- expand.grid(mtry = c(2, 3, 4, 5, 6), ntree = c(300, 500))

train_control <- caret::trainControl(
  method = "repeatedcv",
  number = 5,
  repeats = 10,
  savePredictions = "final"
)

rf_tuned <- caret::train(
  formula_model,
  data = model_dataset |> select(-wilayah),
  method = "rf",
  metric = "RMSE",
  trControl = train_control,
  tuneGrid = rf_grid |> select(mtry),
  ntree = 500,
  importance = TRUE
)

rf_model <- rf_tuned$finalModel
rf_predictions <- predict(rf_tuned, newdata = model_dataset)
rf_in_sample <- metrics_regression(model_dataset$persentase_miskin, rf_predictions) |>
  mutate(model = "Random Forest", evaluation = "In-sample")

rf_importance <- randomForest::importance(rf_model, type = 1) |>
  as.data.frame() |>
  tibble::rownames_to_column("variable") |>
  rename(importance = `%IncMSE`) |>
  arrange(desc(importance))

saveRDS(rf_tuned, "output/models/rf_model.rds")
save_table(rf_in_sample, "output/tables/rf_in_sample_metrics.csv")
save_table(rf_tuned$results, "output/tables/rf_tuning_results.csv")
save_table(rf_importance, "output/tables/rf_feature_importance.csv")

rf_diagnostics <- tibble(
  wilayah = model_dataset$wilayah,
  actual = model_dataset$persentase_miskin,
  predicted = as.numeric(rf_predictions),
  residual = actual - predicted,
  abs_residual = abs(residual)
)

save_table(rf_diagnostics, "output/tables/rf_diagnostics.csv")

p_importance <- rf_importance |>
  ggplot(aes(x = reorder(variable, importance), y = importance)) +
  geom_col(fill = "#4c6f9f") +
  coord_flip() +
  labs(
    title = "Feature Importance Random Forest",
    subtitle = "Permutation importance (%IncMSE)",
    x = NULL,
    y = "Importance"
  ) +
  theme_minimal(base_size = 12)

ggsave("output/figures/feature_importance_rf.png", p_importance, width = 8, height = 5, dpi = 300)

message("Model Random Forest selesai.")
