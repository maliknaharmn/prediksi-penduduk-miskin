source("scripts/00_common.R")

ipm <- read_bps_two_column("data/raw/ipm_2023.csv", "ipm")
kemiskinan <- read_bps_two_column("data/raw/kemiskinan_2023.csv", "persentase_miskin")
sanitasi <- read_bps_two_column("data/raw/sanitasi_2023.csv", "sanitasi_layak")
pdrb <- read_bps_two_column("data/raw/pdrb_per_kapita_2023.csv", "pdrb_per_kapita_ribu")
rls <- read_bps_two_column("data/raw/rls_2023.csv", "rata_lama_sekolah")
tpt <- read_bps_two_column("data/raw/tpt_2023.csv", "tpt")

penduduk_raw <- readr::read_csv(
  "data/raw/penduduk_2023.csv",
  col_types = cols(.default = col_character()),
  show_col_types = FALSE,
  progress = FALSE
)

penduduk <- penduduk_raw |>
  transmute(
    wilayah = clean_region(`Kabupaten/Kota`),
    jumlah_penduduk_ribu = parse_number(`Jumlah Penduduk (Ribu)`),
    laju_pertumbuhan_penduduk = parse_number(`Laju Pertumbuhan Penduduk per Tahun`),
    persentase_penduduk = parse_number(`Persentase Penduduk`),
    kepadatan_penduduk = parse_number(`Kepadatan Penduduk per km persegi (Km2)`),
    rasio_jenis_kelamin = parse_number(`Rasio Jenis Kelamin Penduduk`)
  ) |>
  filter(wilayah != "Jawa Timur", !is.na(kepadatan_penduduk))

dataset_final <- kemiskinan |>
  inner_join(ipm, by = "wilayah") |>
  inner_join(tpt, by = "wilayah") |>
  inner_join(pdrb, by = "wilayah") |>
  inner_join(rls, by = "wilayah") |>
  inner_join(sanitasi, by = "wilayah") |>
  inner_join(penduduk, by = "wilayah") |>
  arrange(wilayah)

expected_rows <- 38
if (nrow(dataset_final) != expected_rows) {
  warning("Dataset final berisi ", nrow(dataset_final), " baris; ekspektasi kabupaten/kota Jawa Timur = ", expected_rows, ".")
}

missing_summary <- dataset_final |>
  summarise(across(everything(), ~ sum(is.na(.x)))) |>
  tidyr::pivot_longer(everything(), names_to = "variable", values_to = "missing_count")

save_table(dataset_final, "data/processed/dataset_final.csv")
save_table(missing_summary, "output/tables/missing_summary.csv")

message("Dataset final tersimpan: data/processed/dataset_final.csv")

