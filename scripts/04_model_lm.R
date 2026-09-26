source("scripts/00_common.R")

model_dataset <- readr::read_csv("data/processed/model_dataset.csv", show_col_types = FALSE)
formula_model <- persentase_miskin ~ ipm + tpt + pdrb_per_kapita_juta + rata_lama_sekolah + sanitasi_layak + kepadatan_penduduk

lm_model <- lm(formula_model, data = model_dataset)
lm_predictions <- predict(lm_model, newdata = model_dataset)

lm_in_sample <- metrics_regression(model_dataset$persentase_miskin, lm_predictions) |>
  mutate(model = "Regresi Linear", evaluation = "In-sample")

lm_coefficients <- as.data.frame(summary(lm_model)$coefficients) |>
  tibble::rownames_to_column("variable") |>
  rename(
    estimate = Estimate,
    std_error = `Std. Error`,
    statistic = `t value`,
    p_value = `Pr(>|t|)`
  )

saveRDS(lm_model, "output/models/lm_model.rds")
save_table(lm_in_sample, "output/tables/lm_in_sample_metrics.csv")
save_table(lm_coefficients, "output/tables/lm_coefficients.csv")

lm_diagnostics <- tibble(
  wilayah = model_dataset$wilayah,
  actual = model_dataset$persentase_miskin,
  predicted = as.numeric(lm_predictions),
  residual = actual - predicted,
  standardized_residual = rstandard(lm_model),
  fitted = fitted(lm_model),
  sqrt_abs_standardized_residual = sqrt(abs(standardized_residual))
)

vif_table <- tibble(
  variable = names(car::vif(lm_model)),
  vif = as.numeric(car::vif(lm_model))
)

save_table(lm_diagnostics, "output/tables/lm_diagnostics.csv")
save_table(vif_table, "output/tables/lm_vif.csv")

p_lm_qq <- ggplot(lm_diagnostics, aes(sample = standardized_residual)) +
  stat_qq(color = "#2f6f73", alpha = 0.8) +
  stat_qq_line(color = "gray35", linetype = "dashed") +
  labs(
    title = "Q-Q Plot Residual Regresi Linear",
    x = "Theoretical quantiles",
    y = "Standardized residuals"
  ) +
  theme_minimal(base_size = 12)

ggsave("output/figures/lm_qq_residual.png", p_lm_qq, width = 7, height = 5, dpi = 300)

p_lm_scale_location <- ggplot(lm_diagnostics, aes(x = fitted, y = sqrt_abs_standardized_residual)) +
  geom_point(color = "#2f6f73", alpha = 0.8, size = 2) +
  geom_smooth(method = "loess", se = FALSE, color = "#8f4e45") +
  labs(
    title = "Scale-Location Plot Regresi Linear",
    x = "Fitted values",
    y = "Sqrt(|standardized residuals|)"
  ) +
  theme_minimal(base_size = 12)

ggsave("output/figures/lm_scale_location.png", p_lm_scale_location, width = 7, height = 5, dpi = 300)

message("Model regresi linear selesai.")
