source("scripts/00_common.R")

model_dataset <- readr::read_csv("data/processed/model_dataset.csv", show_col_types = FALSE)
formula_model <- persentase_miskin ~ ipm + tpt + pdrb_per_kapita_juta + rata_lama_sekolah + sanitasi_layak + kepadatan_penduduk

train_control <- caret::trainControl(
  method = "repeatedcv",
  number = 5,
  repeats = 10,
  savePredictions = "final"
)

lm_cv <- caret::train(
  formula_model,
  data = model_dataset |> select(-wilayah),
  method = "lm",
  metric = "RMSE",
  trControl = train_control
)

rf_cv <- caret::train(
  formula_model,
  data = model_dataset |> select(-wilayah),
  method = "rf",
  metric = "RMSE",
  trControl = train_control,
  tuneGrid = expand.grid(mtry = c(2, 3, 4, 5, 6)),
  ntree = 500,
  importance = TRUE
)

cv_metrics <- bind_rows(
  lm_cv$results |> transmute(model = "Regresi Linear", mtry = NA_real_, rmse = RMSE, r2 = Rsquared, mae = MAE),
  rf_cv$results |> transmute(model = "Random Forest", mtry = mtry, rmse = RMSE, r2 = Rsquared, mae = MAE)
) |>
  arrange(rmse)

best_metrics <- bind_rows(
  lm_cv$results |> transmute(model = "Regresi Linear", rmse = RMSE, r2 = Rsquared, mae = MAE),
  rf_cv$results |> filter(mtry == rf_cv$bestTune$mtry) |> transmute(model = "Random Forest", rmse = RMSE, r2 = Rsquared, mae = MAE)
)

prediction_metrics <- bind_rows(
  lm_cv$pred |>
    transmute(model = "Regresi Linear", actual = obs, predicted = pred, row_index = rowIndex, resample = Resample),
  rf_cv$pred |>
    filter(mtry == rf_cv$bestTune$mtry) |>
    transmute(model = "Random Forest", actual = obs, predicted = pred, row_index = rowIndex, resample = Resample)
) |>
  mutate(residual = actual - predicted, abs_residual = abs(residual))

cv_resample_metrics <- prediction_metrics |>
  group_by(model, resample) |>
  summarise(
    rmse = sqrt(mean((actual - predicted)^2)),
    mae = mean(abs(actual - predicted)),
    r2 = ifelse(sum((actual - mean(actual))^2) == 0, NA_real_, 1 - sum((actual - predicted)^2) / sum((actual - mean(actual))^2)),
    .groups = "drop"
  )

cv_metric_summary <- cv_resample_metrics |>
  group_by(model) |>
  summarise(
    rmse_mean = mean(rmse, na.rm = TRUE),
    rmse_sd = sd(rmse, na.rm = TRUE),
    rmse_ci_low = rmse_mean - qt(0.975, n() - 1) * rmse_sd / sqrt(n()),
    rmse_ci_high = rmse_mean + qt(0.975, n() - 1) * rmse_sd / sqrt(n()),
    mae_mean = mean(mae, na.rm = TRUE),
    mae_sd = sd(mae, na.rm = TRUE),
    mae_ci_low = mae_mean - qt(0.975, n() - 1) * mae_sd / sqrt(n()),
    mae_ci_high = mae_mean + qt(0.975, n() - 1) * mae_sd / sqrt(n()),
    r2_mean = mean(r2, na.rm = TRUE),
    r2_sd = sd(r2, na.rm = TRUE),
    .groups = "drop"
  )

model_outliers <- prediction_metrics |>
  group_by(model, row_index) |>
  summarise(
    actual = mean(actual),
    predicted = mean(predicted),
    residual = mean(residual),
    abs_residual = mean(abs_residual),
    .groups = "drop"
  ) |>
  mutate(wilayah = model_dataset$wilayah[row_index]) |>
  arrange(model, desc(abs_residual)) |>
  group_by(model) |>
  slice_head(n = 5) |>
  ungroup() |>
  select(model, wilayah, actual, predicted, residual, abs_residual)

saveRDS(lm_cv, "output/models/lm_cv_model.rds")
saveRDS(rf_cv, "output/models/rf_cv_model.rds")
save_table(cv_metrics, "output/tables/cv_all_metrics.csv")
save_table(best_metrics, "output/tables/model_comparison.csv")
save_table(prediction_metrics, "output/tables/cv_predictions.csv")
save_table(cv_resample_metrics, "output/tables/cv_resample_metrics.csv")
save_table(cv_metric_summary, "output/tables/cv_metric_summary.csv")
save_table(model_outliers, "output/tables/model_outliers.csv")

p_comparison <- best_metrics |>
  tidyr::pivot_longer(c(rmse, mae, r2), names_to = "metric", values_to = "value") |>
  ggplot(aes(x = model, y = value, fill = model)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ metric, scales = "free_y") +
  labs(
    title = "Perbandingan Performa Model",
    subtitle = "Repeated 5-fold cross-validation, 10 repeats",
    x = NULL,
    y = "Nilai metrik"
  ) +
  scale_fill_manual(values = c("Regresi Linear" = "#2f6f73", "Random Forest" = "#8f4e45")) +
  theme_minimal(base_size = 12)

ggsave("output/figures/perbandingan_model.png", p_comparison, width = 9, height = 5, dpi = 300)

p_pred_actual <- prediction_metrics |>
  ggplot(aes(x = actual, y = predicted, color = model)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray35") +
  geom_point(alpha = 0.6, size = 2) +
  facet_wrap(~ model) +
  labs(
    title = "Prediksi vs Aktual",
    subtitle = "Prediksi out-of-fold dari repeated 5-fold cross-validation",
    x = "Aktual persentase penduduk miskin",
    y = "Prediksi persentase penduduk miskin"
  ) +
  scale_color_manual(values = c("Regresi Linear" = "#2f6f73", "Random Forest" = "#8f4e45")) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")

ggsave("output/figures/prediksi_vs_aktual.png", p_pred_actual, width = 9, height = 5, dpi = 300)

p_residual <- prediction_metrics |>
  ggplot(aes(x = predicted, y = residual, color = model)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray35") +
  geom_point(alpha = 0.6, size = 2) +
  facet_wrap(~ model) +
  labs(
    title = "Residual vs Prediksi",
    subtitle = "Residual out-of-fold dari repeated 5-fold cross-validation",
    x = "Prediksi",
    y = "Residual"
  ) +
  scale_color_manual(values = c("Regresi Linear" = "#2f6f73", "Random Forest" = "#8f4e45")) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")

ggsave("output/figures/residual_vs_prediksi.png", p_residual, width = 9, height = 5, dpi = 300)

message("Evaluasi model selesai.")
