source("scripts/00_common.R")

dataset <- readr::read_csv("data/processed/dataset_final.csv", show_col_types = FALSE)
numeric_data <- dataset |> select(-wilayah)

descriptive_stats <- numeric_data |>
  summarise(across(
    everything(),
    list(
      mean = ~ mean(.x, na.rm = TRUE),
      median = ~ median(.x, na.rm = TRUE),
      min = ~ min(.x, na.rm = TRUE),
      max = ~ max(.x, na.rm = TRUE),
      sd = ~ sd(.x, na.rm = TRUE)
    ),
    .names = "{.col}_{.fn}"
  )) |>
  tidyr::pivot_longer(everything(), names_to = "metric", values_to = "value")

correlation_matrix <- cor(numeric_data, use = "complete.obs")
correlation_table <- as.data.frame(as.table(correlation_matrix)) |>
  rename(variable_1 = Var1, variable_2 = Var2, correlation = Freq)

save_table(descriptive_stats, "output/tables/descriptive_stats.csv")
save_table(correlation_table, "output/tables/correlation_matrix.csv")

p_distribution <- ggplot(dataset, aes(x = persentase_miskin)) +
  geom_histogram(bins = 10, fill = "#2f6f73", color = "white") +
  labs(
    title = "Distribusi Persentase Penduduk Miskin",
    x = "Persentase penduduk miskin",
    y = "Jumlah kabupaten/kota"
  ) +
  theme_minimal(base_size = 12)

ggsave("output/figures/distribusi_kemiskinan.png", p_distribution, width = 8, height = 5, dpi = 300)

png("output/figures/korelasi_variabel.png", width = 1800, height = 1600, res = 220)
corrplot::corrplot(correlation_matrix, method = "color", type = "upper", addCoef.col = "black", tl.cex = 0.75, number.cex = 0.6)
dev.off()

p_top_poverty <- dataset |>
  arrange(desc(persentase_miskin)) |>
  slice_head(n = 10) |>
  ggplot(aes(x = reorder(wilayah, persentase_miskin), y = persentase_miskin)) +
  geom_col(fill = "#8f4e45") +
  coord_flip() +
  labs(
    title = "10 Wilayah dengan Persentase Kemiskinan Tertinggi",
    x = NULL,
    y = "Persentase penduduk miskin"
  ) +
  theme_minimal(base_size = 12)

ggsave("output/figures/top_10_kemiskinan.png", p_top_poverty, width = 8, height = 5, dpi = 300)

message("EDA selesai.")

