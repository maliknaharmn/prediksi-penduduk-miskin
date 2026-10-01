source("scripts/validation.R")

sample_data <- data.frame(
  wilayah = paste0("W", seq_len(38)),
  persentase_miskin = seq(5, 19, length.out = 38),
  ipm = seq(65, 79, length.out = 38),
  tpt = seq(3, 7, length.out = 38),
  pdrb_per_kapita_juta = seq(20, 90, length.out = 38),
  rata_lama_sekolah = seq(6, 10, length.out = 38),
  sanitasi_layak = seq(60, 95, length.out = 38),
  kepadatan_penduduk = seq(200, 1600, length.out = 38)
)

validate_model_data(sample_data, expected_rows = 38)
expected_columns <- c(
  "wilayah", "persentase_miskin", "ipm", "tpt", "pdrb_per_kapita_juta",
  "rata_lama_sekolah", "sanitasi_layak", "kepadatan_penduduk"
)
actual_data <- read.csv("data/processed/model_dataset.csv", check.names = FALSE)
stopifnot(identical(names(actual_data), expected_columns))
validate_model_data(actual_data, expected_rows = 38)

expect_error <- function(data, message) {
  err <- tryCatch({ validate_model_data(data, expected_rows = 38); NULL }, error = identity)
  stopifnot(inherits(err, "error"), grepl(message, conditionMessage(err)))
}

duplicate <- sample_data; duplicate$wilayah[2] <- duplicate$wilayah[1]
expect_error(duplicate, "duplikat")
missing <- sample_data; missing$ipm[1] <- NA_real_
expect_error(missing, "NA")
out_of_range <- sample_data; out_of_range$persentase_miskin[1] <- 101
expect_error(out_of_range, "0-100")
wrong_type <- sample_data; wrong_type$persentase_miskin <- as.character(wrong_type$persentase_miskin)
expect_error(wrong_type, "numerik")
expect_error(sample_data[-1, ], "38")

result <- evaluate_nested_cv(sample_data, k = 3, inner_k = 4, seed = 42, ntree = 10, mtry_grid = 1:2)
stopifnot(nrow(result$predictions) == 3 * nrow(sample_data))
for (model in unique(result$predictions$model)) {
  row_indices <- result$predictions$row_index[result$predictions$model == model]
  stopifnot(length(unique(row_indices)) == nrow(sample_data))
  stopifnot(setequal(row_indices, seq_len(nrow(sample_data))))
}
stopifnot(setequal(result$summary$model, c("Rerata pelatihan", "Regresi Linear", "Random Forest")))
stopifnot(all(is.finite(result$predictions$predicted)))
stopifnot(all(is.finite(result$summary$rmse)))
for (fold in unique(result$predictions$fold)) {
  held_out <- unique(result$predictions$row_index[result$predictions$fold == fold])
  baseline <- result$predictions[result$predictions$fold == fold & result$predictions$model == "Rerata pelatihan", ]
  stopifnot(isTRUE(all.equal(unique(baseline$predicted), mean(sample_data$persentase_miskin[-held_out]))))
}
cat("Validation and nested CV tests passed\n")
