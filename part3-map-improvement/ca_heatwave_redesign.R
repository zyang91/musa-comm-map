# ============================================================
# Part 3: Redesign — California Heat Wave Risk Map
#
# Original map: MUSA 5080, Day 15 assignment (day15-fire.R)
# Data: FEMA National Risk Index — Heat Wave Risk Scores
#       https://hazards.fema.gov/nri/data-resources
#
# ORIGINAL MAP PROBLEMS IDENTIFIED:
#   1. Title mislabeling: Original said "Wildfire Risk" but
#      HWAV_ = Heat Wave risk (not fire)
#   2. Subtitle "Made by Zhanchao Yang" — not a narrative,
#      adds no interpretive value to the reader
#   3. Color palette (blue-teal-yellow-orange-red) sends mixed
#      signals: teal and blue connote water/coolness rather than
#      heat risk; low-saturation yellow midpoint is hard to read
#   4. Continuous gradient with raw numeric legend — reader
#      cannot determine if a score of 70 is "bad" or "moderate"
#   5. No geographic context: no city labels, no county lines,
#      reader cannot anchor risk to familiar places
#   6. No annotation or narrative — the map is a pretty raster
#      but tells no story
#   7. Legend in second version overlaps the map data
#
# REDESIGN DECISIONS:
#   Subject fix    : Renamed to Heat Wave Risk (correct label)
#   Big Idea title : "Inland California Faces the Greatest
#                     Extreme-Heat Risk"
#   Projection     : Retain California Albers (EPSG:3310) —
#                    equal-area, appropriate for state-wide
#                    comparison
#   Classification : 5 quantile classes with plain-language
#                    labels (Low → Very High); discrete classes
#                    make tier comparisons unambiguous
#   Color palette  : Sequential single-hue shift from pale
#                    cream → deep crimson; heat risk is a
#                    one-directional variable, so a sequential
#                    (not diverging) palette is semantically
#                    correct; saturated dark red draws attention
#                    to the highest-risk inland areas
#   Legend         : Horizontal colorbar at bottom with
#                    "LOWER RISK" / "HIGHER RISK" flanking
#                    labels, mirroring the Part 1 NYT approach
#   Context layers : Major city dots + labels to anchor risk to
#                    real places; subtle county outlines in white
#   Annotation     : Single callout highlighting the high-risk
#                    Central Valley / Inland Empire corridor
#   Clutter        : theme_void() base; no axes, no graticule;
#                    narrow margins
# ============================================================

# ── Packages ──────────────────────────────────────────────────────────────────
# install.packages(c("tidyverse","sf","tigris","ggrepel","scales"))

library(tidyverse)
library(sf)
library(tigris)
library(scales)

options(tigris_use_cache = TRUE)

# ── Projection: California Albers (EPSG:3310) ─────────────────────────────────
proj_crs <- 3310

# =============================================================================
# 1. LOAD DATA
# =============================================================================

ca_fire <- st_read("data/ca_fire_risk.geojson", quiet = TRUE) |>
  select(HWAV_RISKS, HWAV_RISKR) |>
  st_transform(proj_crs)

# =============================================================================
# 2. CLASSIFY INTO 5 QUANTILE TIERS
# =============================================================================

ca_fire <- ca_fire |>
  mutate(
    risk_class = cut(
      HWAV_RISKS,
      breaks = quantile(HWAV_RISKS, probs = seq(0, 1, 0.2), na.rm = TRUE),
      labels = c("Low", "Relatively Low", "Moderate", "Relatively High", "High"),
      include.lowest = TRUE
    )
  )

# =============================================================================
# 3. GEOGRAPHIC CONTEXT: STATE BOUNDARY + MAJOR CITIES
# =============================================================================

ca_boundary <- states(cb = TRUE) |>
  filter(STUSPS == "CA") |>
  st_transform(proj_crs)

cities <- tibble::tribble(
  ~city,           ~lon,      ~lat,
  "Los Angeles",   -118.243,  34.052,
  "San Francisco", -122.419,  37.775,
  "Sacramento",    -121.494,  38.576,
  "San Diego",     -117.162,  32.716,
  "Fresno",        -119.787,  36.737,
  "Bakersfield",   -119.019,  35.373,
  "Riverside",     -117.397,  33.953,
  "Redding",       -122.391,  40.587
) |>
  st_as_sf(coords = c("lon", "lat"), crs = 4326) |>
  st_transform(proj_crs)

# =============================================================================
# 4. COLOR PALETTE
#    Magma (viridis family), 5-class, light → dark
#    Multi-hue sequential: hue AND lightness shift at every step, so each
#    tier is unambiguous even in grayscale or with color vision deficiency.
#    Cream → amber → coral → deep magenta → dark purple
# =============================================================================

heat_pal <- c(
  "#fde9bc",   # Low            — pale cream-yellow
  "#fbb068",   # Relatively Low — warm amber
  "#ef6145",   # Moderate       — coral-red
  "#a62b6e",   # Relatively High— deep magenta
  "#4b1148"    # High           — dark purple
)

# =============================================================================
# 5. ANNOTATION ANCHOR: high-risk Central Valley / Inland Empire corridor
# =============================================================================

# Point in the Central Valley (Fresno/Bakersfield corridor)
callout_pt <- tibble(lon = -119.3, lat = 35.8) |>
  st_as_sf(coords = c("lon", "lat"), crs = 4326) |>
  st_transform(proj_crs)

cx <- st_coordinates(callout_pt)[1, "X"]
cy <- st_coordinates(callout_pt)[1, "Y"]

bbox <- st_bbox(ca_fire)

# =============================================================================
# 6. BUILD GGPLOT  —  NYT editorial style
#
# NYT design principles applied:
#   • Left-aligned title (declarative, large, bold) + deck subtitle
#   • Uppercase city labels — standard NYT cartographic convention
#   • Annotation pushed into the right margin (outside state boundary)
#     via xlim expansion; connected by a thin gray segment + filled dot
#     rather than a chunky curved arrow
#   • Minimal horizontal legend: end-labels only, no centred title block
#   • Source line flush-left, small, gray — NYT house style
#   • Thin state boundary (gray45, 0.4 lwd) — data, not decoration
#   • Generous left margin so flush-left text aligns with map edge
# =============================================================================

# Annotation text anchor — right margin, outside state boundary
text_x <- bbox["xmax"] + 55000

p <- ggplot() +

  # ── Classified choropleth ────────────────────────────────────────────────
  geom_sf(data = ca_fire, aes(fill = risk_class), color = NA) +
  scale_fill_manual(
    values   = heat_pal,
    na.value = "grey85",
    name     = NULL,                          # no legend title — end labels carry the weight
    guide    = guide_legend(
      direction      = "horizontal",
      nrow           = 1,
      label.position = "bottom",
      keywidth       = unit(1.3, "cm"),
      keyheight      = unit(0.35, "cm"),
      label.theme    = element_text(size = 6.5, color = "gray30")
    )
  ) +

  # ── State boundary — thin, unobtrusive ──────────────────────────────────
  geom_sf(data = ca_boundary, fill = NA, color = "gray45", linewidth = 0.4) +

  # ── City dots ────────────────────────────────────────────────────────────
  geom_sf(data = cities, color = "white", size = 1.0, shape = 19) +

  # ── City labels — uppercase, NYT convention ──────────────────────────────
  # SF + Redding: light-colored counties → black text for contrast
  geom_sf_text(
    data      = cities |> filter(city %in% c("San Francisco", "Redding")),
    aes(label = toupper(city)),
    size      = 1.8,
    color     = "gray5",
    fontface  = "bold",
    nudge_x   = -28000,
    hjust     = 1,
    lineheight = 0.85
  ) +
  # Sacramento: nudge left, white
  geom_sf_text(
    data      = cities |> filter(city == "Sacramento"),
    aes(label = toupper(city)),
    size      = 1.8,
    color     = "white",
    fontface  = "bold",
    nudge_x   = -28000,
    hjust     = 1,
    lineheight = 0.85
  ) +
  # Inland / southern cities: darker counties → white text
  geom_sf_text(
    data      = cities |> filter(city %in% c("Los Angeles", "San Diego",
                                              "Fresno", "Bakersfield",
                                              "Riverside")),
    aes(label = toupper(city)),
    size      = 1.8,
    color     = "white",
    fontface  = "bold",
    nudge_x   = 28000,
    hjust     = 0,
    lineheight = 0.85
  ) +

  # ── Callout: small filled dot at the target location ─────────────────────
  annotate("point",
    x     = cx,
    y     = cy,
    size  = 1.8,
    color = "#4b1148",
    shape = 19
  ) +

  # ── Short segment: dot → nearby label box ────────────────────────────────
  annotate("segment",
    x         = cx + 12000,
    y         = cy,
    xend      = text_x - 6000,
    yend      = cy + 35000,
    linewidth = 0.3,
    color     = "gray40"
  ) +

  # ── Annotation text — close to the dot ──────────────────────────────────
  annotate("text",
    x          = text_x,
    y          = cy + 40000,
    label      = paste0(
      "The Central Valley\n",
      "and Inland Empire\n",
      "bear the highest\n",
      "heat-wave risk —\n",
      "sparse vegetation\n",
      "and low elevation\n",
      "trap summer heat."
    ),
    hjust      = 0,
    vjust      = 0,
    color      = "gray15",
    size       = 2.1,
    fontface   = "italic",
    lineheight = 1.25
  ) +

  # ── Expand xlim right for the right-margin annotation text ──────────────
  coord_sf(
    xlim   = c(bbox["xmin"], bbox["xmax"] + 240000),
    ylim   = c(bbox["ymin"], bbox["ymax"]),
    expand = FALSE
  ) +

  theme_void() +
  theme(
    # ── Background ──────────────────────────────────────────────────────────
    plot.background  = element_rect(fill = "#eef2f0", color = NA),
    panel.background = element_rect(fill = "#eef2f0", color = NA),

    # ── Legend — flush left, minimal ────────────────────────────────────────
    legend.position   = "bottom",
    legend.justification = "left",
    legend.margin     = margin(t = 2, b = 6, l = 0),

    # ── Title: large, bold, flush left — NYT declarative headline ───────────
    plot.title = element_text(
      size     = 15,
      face     = "bold",
      hjust    = 0,
      color    = "gray5",
      margin   = margin(t = 14, b = 3)
    ),

    # ── Subtitle: deck / standfirst — flush left, gray ──────────────────────
    plot.subtitle = element_text(
      size     = 8.5,
      hjust    = 0,
      color    = "gray38",
      margin   = margin(b = 8)
    ),

    # ── Caption: "Source:" style, flush left, smallest size ─────────────────
    plot.caption = element_text(
      size     = 6,
      hjust    = 0,
      color    = "gray55",
      margin   = margin(t = 5, b = 8)
    ),

    # ── Generous left margin so flush-left text aligns with map edge ─────────
    plot.margin = margin(8, 8, 4, 16)
  ) +
  labs(
    title    = "Inland California Faces the Greatest Extreme-Heat Risk",
    subtitle = "County-level heat wave risk score | five equal-frequency tiers",
    caption  = paste0(
      "Source: FEMA National Risk Index (HWAV_RISKS)  |  ",
      "Projection: California Albers Equal Area (EPSG:3310)  |  ",
      "Classification: Quantile, 5 classes"
    )
  )

# =============================================================================
# 7. SAVE OUTPUT
#    Width widened slightly to accommodate the right-margin annotation
# =============================================================================

ggsave(
  filename = "output_ca_heatwave_redesign.png",
  plot     = p,
  width    = 8,
  height   = 9,
  dpi      = 300,
  bg       = "#eef2f0"
)

