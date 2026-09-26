# Model Prediksi Persentase Penduduk Miskin Jawa Timur 2023

Project ini menganalisis dan memodelkan persentase penduduk miskin kabupaten/kota di Provinsi Jawa Timur tahun 2023 menggunakan Regresi Linear dan Random Forest Regression.

Nama project sengaja memakai istilah **persentase penduduk miskin**, bukan **poverty line/garis kemiskinan**, karena target data yang digunakan adalah persentase penduduk miskin.

## Struktur Project

```text
.
├── data/
│   ├── raw/                  # CSV BPS mentah dengan nama file stabil
│   └── processed/            # Dataset gabungan dan dataset modeling
├── scripts/
│   ├── 00_common.R           # Helper, dependency check, metrik
│   ├── 01_load_data.R        # Import dan penggabungan data
│   ├── 02_eda.R              # Statistik deskriptif dan visualisasi EDA
│   ├── 03_preprocessing.R    # Seleksi variabel, missing value, outlier
│   ├── 04_model_lm.R         # Regresi Linear dan diagnostik VIF/residual
│   ├── 05_model_rf.R         # Random Forest dan feature importance
│   ├── 06_evaluation.R       # Repeated k-fold CV, residual, dan perbandingan model
│   └── run_all.R             # Menjalankan seluruh pipeline
├── output/
│   ├── figures/              # Grafik hasil analisis
│   ├── models/               # Model RDS
│   └── tables/               # Tabel metrik dan ringkasan
└── report/
    └── laporan_kemiskinan_jatim.Rmd
```

## Cara Menjalankan

Package utama yang digunakan: `readr`, `dplyr`, `ggplot2`, `tidyr`, `tibble`, `randomForest`, `caret`, `corrplot`, `MLmetrics`, `car`, `rmarkdown`.

Library lokal `renv/library` tidak disertakan dalam repository. Install package R yang diperlukan, lalu jalankan dari direktori project:

```r
install.packages(c("readr", "dplyr", "ggplot2", "tidyr", "tibble", "randomForest", "caret", "corrplot", "MLmetrics", "car", "rmarkdown"))
source("scripts/run_all.R")
rmarkdown::render("report/laporan_kemiskinan_jatim.Rmd", output_format = "html_document")
```

Output HTML akan tersimpan di `report/laporan_kemiskinan_jatim.html`.

Output utama:

- `data/processed/dataset_final.csv`
- `output/tables/model_comparison.csv`
- `output/tables/cv_metric_summary.csv`
- `output/tables/lm_vif.csv`
- `output/tables/model_outliers.csv`
- `output/figures/prediksi_vs_aktual.png`
- `output/figures/residual_vs_prediksi.png`
- `output/figures/lm_qq_residual.png`
- `output/figures/lm_scale_location.png`

## Catatan Metodologis

Dataset berisi 38 observasi kabupaten/kota untuk satu tahun. Karena ukuran sampel kecil, evaluasi utama menggunakan repeated 5-fold cross-validation, bukan hanya split 80/20. Hasil model harus dibaca sebagai kemampuan prediktif pada data yang tersedia, bukan bukti sebab-akibat.

Feature importance Random Forest menunjukkan variabel yang paling membantu prediksi, bukan variabel yang pasti menyebabkan kemiskinan.
