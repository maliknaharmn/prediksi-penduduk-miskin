# Reusable data guards and honest out-of-fold model evaluation.
validate_model_data <- function(data, expected_rows = 38L) {
  required <- c("wilayah", "persentase_miskin", "ipm", "tpt", "pdrb_per_kapita_juta",
                "rata_lama_sekolah", "sanitasi_layak", "kepadatan_penduduk")
  absent <- setdiff(required, names(data))
  if (length(absent)) stop("Kolom tidak tersedia: ", paste(absent, collapse = ", "))
  if (nrow(data) != expected_rows) stop("Jumlah wilayah harus ", expected_rows, "; ditemukan ", nrow(data))
  if (anyNA(data[required])) stop("Data modeling mengandung NA")
  if (any(!nzchar(trimws(data$wilayah))) || anyDuplicated(data$wilayah))
    stop("Nama wilayah kosong atau duplikat")
  if (!is.numeric(data$persentase_miskin)) stop("Target harus numerik")
  if (any(!vapply(data[setdiff(required, "wilayah")], is.numeric, logical(1))))
    stop("Prediktor harus numerik")
  if (any(!is.finite(as.matrix(data[setdiff(required, "wilayah")]))) )
    stop("Nilai numerik harus finite")
  if (any(data$persentase_miskin < 0 | data$persentase_miskin > 100))
    stop("Persentase miskin harus dalam rentang 0-100")
  invisible(TRUE)
}

evaluate_nested_cv <- function(data, k = 5L, inner_k = 3L, seed = 2026L,
                               ntree = 500L, mtry_grid = 2:6) {
  validate_model_data(data, expected_rows = nrow(data))
  if (k < 2L || k > nrow(data) || inner_k < 2L || inner_k > nrow(data) - ceiling(nrow(data) / k))
    stop("Jumlah fold tidak valid")
  if (ntree < 1L || !length(mtry_grid) || any(!mtry_grid %in% 1:6))
    stop("Parameter Random Forest tidak valid")
  local_lib <- file.path(getwd(), "renv", "library")
  if (dir.exists(local_lib)) .libPaths(c(normalizePath(local_lib), .libPaths()))
  if (!requireNamespace("caret", quietly = TRUE) || !requireNamespace("randomForest", quietly = TRUE))
    stop("Instal paket caret dan randomForest terlebih dahulu")
  predictors <- c("ipm", "tpt", "pdrb_per_kapita_juta", "rata_lama_sekolah",
                  "sanitasi_layak", "kepadatan_penduduk")
  form <- stats::reformulate(predictors, response = "persentase_miskin")
  set.seed(seed)
  outer_folds <- caret::createFolds(data$persentase_miskin, k = k, returnTrain = FALSE)
  predictions <- lapply(seq_along(outer_folds), function(i) {
    held_out <- outer_folds[[i]]
    train <- data[-held_out, , drop = FALSE]
    test <- data[held_out, , drop = FALSE]
    lm_fit <- stats::lm(form, data = train)
    set.seed(seed + i)
    rf_fit <- caret::train(
      form, data = train, method = "rf", metric = "RMSE",
      trControl = caret::trainControl(method = "cv", number = inner_k),
      tuneGrid = data.frame(mtry = mtry_grid), ntree = ntree
    )
    values <- list("Rerata pelatihan" = rep(mean(train$persentase_miskin), nrow(test)),
                   "Regresi Linear" = as.numeric(stats::predict(lm_fit, test)),
                   "Random Forest" = as.numeric(stats::predict(rf_fit, test)))
    do.call(rbind, lapply(names(values), function(model) {
      data.frame(model = model, fold = i, row_index = held_out, wilayah = test$wilayah,
                 actual = test$persentase_miskin, predicted = values[[model]])
    }))
  })
  predictions <- do.call(rbind, predictions)
  rownames(predictions) <- NULL
  summary <- do.call(rbind, lapply(unique(predictions$model), function(model) {
    x <- predictions[predictions$model == model, ]
    residual <- x$actual - x$predicted
    data.frame(model = model, rmse = sqrt(mean(residual^2)), mae = mean(abs(residual)),
               r2 = 1 - sum(residual^2) / sum((x$actual - mean(x$actual))^2))
  }))
  rownames(summary) <- NULL
  list(predictions = predictions, summary = summary)
}
