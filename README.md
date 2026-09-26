# Model Prediksi Persentase Penduduk Miskin Jawa Timur 2023

Analisis 38 kabupaten/kota di Jawa Timur tahun 2023 menggunakan Regresi Linear dan Random Forest. Targetnya **persentase penduduk miskin**, bukan *poverty line/garis kemiskinan*. Hasil bersifat prediktif, bukan kausal.

## Hasil Singkat

Evaluasi awal, repeated 5-fold CV × 10 (`output/tables/model_comparison.csv`; tuning RF memakai resampling yang sama):

| Model | RMSE | MAE | R² |
| --- | ---: | ---: | ---: |
| Regresi Linear | 3,068 | 2,452 | 0,539 |
| Random Forest | 2,713 | 2,145 | 0,640 |

Evaluasi tambahan dengan 5 fold luar, 3 fold dalam untuk tuning RF, dan baseline rerata data latih tiap fold (`output/tables/nested_cv_summary.csv`; seed 2026):

| Model | RMSE | MAE | R² |
| --- | ---: | ---: | ---: |
| Rerata pelatihan | 4,286 | 3,326 | -0,010 |
| Regresi Linear | 3,306 | 2,525 | 0,399 |
| Random Forest | 2,674 | 2,137 | 0,607 |

RMSE/MAE dalam poin persentase. Sampel kecil membuat angka sensitif terhadap pembagian fold; belum ada pengujian eksternal lintas tahun. [Laporan HTML](report/laporan_kemiskinan_jatim.html) memuat analisis awal, sedangkan evaluasi nested tambahan tersedia di CSV.

## Data dan Sumber

Berkas `data/raw/` memuat salinan data BPS tahun 2023. Berikut tautan tabel resmi dan satuan variabel modeling; tabel daring dapat diperbarui setelah CSV diunduh sehingga audit nilai per wilayah tetap diperlukan.

| Variabel | Satuan / definisi | Referensi BPS |
| --- | --- | --- |
| `persentase_miskin` | Penduduk miskin, Maret (%) | [Kemiskinan kabupaten/kota](https://jatim.bps.go.id/id/statistics-table/2/NDk3IzI=/persentase-penduduk-miskin-menurutkabupaten-kota-di-jawa-timur.html) |
| `ipm` | Indeks Pembangunan Manusia (indeks) | [IPM kabupaten/kota](https://jatim.bps.go.id/id/statistics-table/2/MzYjMg==/indeks-pembangunan-manusia-menurut-kebupaten-kota.html) |
| `tpt` | Pengangguran terbuka, Agustus (%) | [TPT kabupaten/kota](https://jatim.bps.go.id/id/statistics-table/2/NTQjMg==/tingkat-pengangguran-terbuka--tpt--menurut-kabupaten-kota.html) |
| `pdrb_per_kapita_juta` | PDRB ADHB per kapita (juta rupiah); CSV sumber ribu rupiah dibagi 1.000 | [PDRB per kapita](https://jatim.bps.go.id/id/statistics-table/2/MzI3IzI=/-seri-2010--pdrb-perkapita-atas-dasar-harga-berlaku-menurut-kabupaten-kota.html) |
| `rata_lama_sekolah` | Rata-rata lama sekolah penduduk 15+ (tahun) | URL tabel spesifik belum terverifikasi; lihat `data/raw/rls_2023.csv` |
| `sanitasi_layak` | Rumah tangga dengan sanitasi layak (%) | [Sanitasi layak kabupaten/kota](https://jatim.bps.go.id/id/statistics-table/3/VGtGTU5qbDFlQzl1VWxCTVNWZElXbWRhWkUwMFVUMDkjMyMzNTAw/persentase-rumah-tangga-yang-memiliki-akses-terhadap-sanitasi-layak-menurut-kabupaten-kota-di-provinsi-jawa-timur.html) |
| `kepadatan_penduduk` | Jiwa/km² | URL tabel spesifik belum terverifikasi; lihat `data/raw/penduduk_2023.csv` |

Baris agregat Jawa Timur dikeluarkan dari observasi kabupaten/kota. Tautan seri BPS ditemukan melalui indeks pencarian; pilih tahun 2023 pada tabel multi-tahun. Untuk RLS dan kepadatan, jangan menebak URL sebelum diverifikasi.

## Struktur Project

- `data/raw/`: CSV BPS; `data/processed/`: dataset gabungan dan modeling.
- `scripts/run_all.R`: pipeline impor → EDA → preprocessing → model → evaluasi awal → nested CV dan baseline.
- `scripts/validation.R`: pemeriksaan kualitas data dan evaluasi nested; `tests/test_validation.R`: pengujian fungsi tersebut.
- `output/figures/`, `output/models/`, `output/tables/`: artefak hasil; `report/`: laporan Rmd dan HTML.
- `renv.lock`: versi R dan dependensi R; `renv/library/` lokal tidak di-commit.

## Cara Menjalankan

Prasyarat R 4.1+ (base pipe `|>`); lockfile dibuat dengan R 4.6.0. Jalankan dari root repo:

```sh
Rscript -e 'install.packages("renv")' # jika renv belum terpasang
Rscript -e 'renv::restore(prompt = FALSE)'
Rscript tests/test_validation.R
Rscript scripts/run_all.R
Rscript -e 'rmarkdown::render("report/laporan_kemiskinan_jatim.Rmd", output_format = "html_document")'
```

Paket inti: `readr`, `dplyr`, `ggplot2`, `tidyr`, `tibble`, `randomForest`, `caret`, `corrplot`, `MLmetrics`, `car`, `rmarkdown`. Laporan menjalankan ulang pipeline saat dirender.

## Keterbatasan dan Saran Berikutnya

- Tuning `mtry` dan pelaporan CV awal memakai fold yang sama; gunakan hasil nested untuk estimasi internal yang lebih hati-hati. Fold repeated CV saling berkorelasi sehingga interval kepercayaan naif di `cv_metric_summary.csv` tidak boleh dianggap bukti generalisasi.
- Evaluasi temporal eksternal memerlukan data tahun lain dan belum dilakukan; jangan menyamakan prediksi dengan hubungan sebab-akibat. IPM dan rata-rata lama sekolah juga mungkin berkorelasi.
- Validasi data menolak wilayah duplikat, kolom/angka hilang, target di luar 0–100, dan jumlah wilayah yang bukan 38. Periksa ulang kesesuaian snapshot CSV dengan seri BPS saat memperbarui data.
