`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

required_packages <- c("readr", "dplyr", "ggplot2", "randomForest", "caret", "corrplot", "MLmetrics", "tidyr", "tibble", "car")
local_lib <- file.path(getwd(), "renv", "library")
if (dir.exists(local_lib)) {
  .libPaths(c(normalizePath(local_lib), .libPaths()))
}

missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop(
    "Package belum tersedia: ",
    paste(missing_packages, collapse = ", "),
    ". Jalankan install.packages(..., lib = 'renv/library') atau gunakan README.",
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(ggplot2)
  library(randomForest)
  library(caret)
  library(corrplot)
  library(MLmetrics)
  library(tidyr)
  library(tibble)
  library(car)
})

set.seed(2026)

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("output/models", recursive = TRUE, showWarnings = FALSE)

clean_region <- function(x) {
  x |>
    gsub("\ufeff", "", x = _) |>
    trimws() |>
    gsub("^Kabupaten\\s+", "", x = _) |>
    trimws()
}

read_bps_two_column <- function(path, value_name) {
  raw <- readr::read_csv(
    path,
    col_names = FALSE,
    col_types = cols(.default = col_character()),
    show_col_types = FALSE,
    progress = FALSE
  )

  names(raw)[1:2] <- c("wilayah", value_name)
  raw |>
    transmute(
      wilayah = clean_region(.data$wilayah),
      value = suppressWarnings(readr::parse_number(.data[[value_name]], locale = locale(decimal_mark = ".", grouping_mark = ",")))
    ) |>
    filter(
      !is.na(wilayah),
      wilayah != "",
      wilayah != "Jawa Timur",
      wilayah != "Keterangan",
      !is.na(value)
    ) |>
    distinct(wilayah, .keep_all = TRUE) |>
    rename(!!value_name := value)
}

metrics_regression <- function(actual, predicted) {
  tibble(
    rmse = sqrt(mean((actual - predicted)^2)),
    mae = mean(abs(actual - predicted)),
    r2 = 1 - sum((actual - predicted)^2) / sum((actual - mean(actual))^2)
  )
}

save_table <- function(data, path) {
  readr::write_csv(data, path)
  invisible(data)
}
