scripts <- c(
  "scripts/01_load_data.R",
  "scripts/02_eda.R",
  "scripts/03_preprocessing.R",
  "scripts/04_model_lm.R",
  "scripts/05_model_rf.R",
  "scripts/06_evaluation.R",
  "scripts/07_nested_validation.R"
)

for (script in scripts) {
  message("\n== Menjalankan ", script, " ==")
  source(script, local = new.env(parent = globalenv()))
}

message("\nSemua tahap analisis selesai.")

