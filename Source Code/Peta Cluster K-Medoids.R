##   PETA CLUSTER K-MEDOIDS JAWA BARAT (DATA BPS)
# 0. LOAD LIBRARY
library(readxl)
library(dplyr)
library(sf)
library(ggplot2)
library(stringr)

# 1. BACA EXCEL HASIL CLUSTER
cluster_kmed <- read_excel(
  "D:/Pascasarjana IPB/Semester 1/Pemograman Statistika/Pempro Project/Clustering K-Medoid.xlsx")

# Kolom join: pakai nama lengkap, cuma dibersihkan spasi & huruf besar
cluster_kmed <- cluster_kmed %>%
  mutate(
    KabKota_join = `Kabupaten/Kota` |>
      str_trim() |>
      toupper())

# 2. BACA SHAPEFILE BPS ADM2 SELURUH INDONESIA
indo_kab <- st_read(
  "D:/Pascasarjana IPB/Semester 1/Pemograman Statistika/Pempro Project/Admin2Kabupaten/idn_admbnda_adm2_bps_20200401.shp")

# Siapkan nama join dari shapefile
indo_jabar <- indo_kab %>%
  filter(ADM1_EN == "Jawa Barat") %>%
  filter(!ADM2_EN %in% c("Waduk Cirata", "Cirata Reservoir", "Waduk Jatiluhur")) %>% 
  mutate(
    KabKota_join = ADM2_EN |>
      str_trim() |>
      toupper())

# 4. GABUNGKAN DATA SHAPEFILE DENGAN CLUSTER
peta_jabar <- indo_jabar %>%
  left_join(cluster_kmed, by = "KabKota_join")

# 5. BUAT LABEL UNTUK DITAMPILKAN DI PETA
peta_jabar <- peta_jabar %>%
  mutate(
    Label_peta = ADM2_EN |>
      str_replace("^Kabupaten\\s+", "Kab. ")   |>  # jadi "Kab. Bandung"
      str_replace("^Kota\\s+", "Kota ")       # tetap "Kota Bandung"
  )

# 6. PLOT PETA CLUSTERING
library(sf)
library(ggplot2)
library(ggrepel)
library(dplyr)

# --- 1. Gabungkan polygon per kab/kota (supaya 1 geometry per daerah) ---
peta_jabar_single <- peta_jabar %>%
  group_by(ADM2_EN, Label_peta, Cluster) %>%   # ADM2_EN beda antara Kab Bandung & Kota Bandung
  summarise(geometry = st_union(geometry), .groups = "drop")

# --- 2. Hitung centroid untuk posisi label ---
peta_jabar_centroid <- st_centroid(peta_jabar_single)

# --- 3. Plot peta dengan label tidak tumpang tindih 
ggplot(peta_jabar_single) +
  geom_sf(aes(fill = as.factor(Cluster)), color = "gray50", size = 0.3) +
  
  geom_text_repel(
    data = peta_jabar_centroid,
    aes(label = Label_peta, geometry = geometry),
    stat = "sf_coordinates",
    size = 5,  # Ukuran label kab/kota diperbesar
    color = "black",
    fontface = "bold",
    max.overlaps = Inf,
    box.padding = 0.8,
    point.padding = 0.3
  ) +
  
  scale_fill_manual(
    values = c(
      "1" = "#F6416C",
      "2" = "#F8C630",
      "3" = "#00E676",
      "4" = "#08D9D6"
    ),
    name = "Cluster"
  ) +
  labs(
    title = "Peta Cluster Kemiskinan Jawa Barat (K-Medoids)"
  ) +
  theme_minimal(base_size = 16) +  # memperbesar font dasar seluruh plot
  theme(
    plot.title      = element_text(size = 24, face = "bold"), # Judul lebih besar
    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.title    = element_text(size = 18, face = "bold"), # Title legend lebih besar
    legend.text     = element_text(size = 16),                # Angka cluster diperbesar
    legend.box.margin = margin(t = -5),
    
    # Hilangkan axis & grid
    axis.title      = element_blank(),
    axis.text       = element_blank(),
    panel.grid      = element_blank()
  )

