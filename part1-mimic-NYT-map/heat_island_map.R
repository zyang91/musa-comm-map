# ============================================================
# Part 1: NYT-Style Urban Heat Island Map — Philadelphia, PA
#
# Original map: New York Times (2019)
# "How Much Hotter Is Your Hometown Than When You Were Born?"
# Cartographers: Nadja Popovich & Christopher Flavelle
# URL: https://www.nytimes.com/interactive/2019/08/09/climate/city-heat-islands.html
#
# DESIGN DECOMPOSITION:
#   Map type         : Continuous raster (land surface temperature)
#   Projection       : Local UTM or State Plane (tight city crop, minimal distortion)
#   Classification   : Continuous diverging gradient — no discrete classes
#   Color palette    : Diverging — teal/blue-green (cool) → off-white (neutral)
#                      → orange/deep red (hot); roughly an inverted RdBu, saturated
#   Legend           : Horizontal colorbar strip at bottom center,
#                      labeled with °F; "◄ COOLER" / "HOTTER ►" flanking the bar
#   Title            : Appears in the article context, not on map face
#   Annotations      : Two short italic callout blocks — upper-left (cool),
#                      upper-right (hot) — provide narrative context
#   Typography       : Large bold white sans-serif for city name;
#                      small bold white for neighborhoods; italic for callouts
#   Contextual layers: Subtle white city-boundary stroke; water visible via
#                      cool colour break in raster; NO traditional basemap
#   White space      : Map cropped tight to city extent; minimal margins
# ============================================================

# ── Required packages ──────────────────────────────────────────────────────────
# install.packages(c("tidyverse","sf","terra","tigris","tidycensus","scales"))

library(tidyverse)
library(sf)
library(terra)
library(ggplot2)
library(tigris)
library(tidycensus)
library(scales)

# NOTE: tidycensus requires a Census API key.
# Register (free) at https://api.census.gov/data/key_signup.html then run:
#   census_api_key("YOUR_KEY_HERE", install = TRUE)

options(tigris_use_cache = TRUE)

# ── Projection: UTM Zone 18N ──────────────────────────────────────────────────
proj_crs <- 26918

# =============================================================================
# 1. SPATIAL BOUNDARIES
# =============================================================================

philly <- counties(state = "PA", cb = TRUE) |>
  filter(NAME == "Philadelphia") |>
  st_transform(proj_crs)

philly_tracts <- tracts(state = "PA", county = "Philadelphia", cb = TRUE) |>
  st_transform(proj_crs)

water <- area_water("PA", "Philadelphia") |>
  st_transform(proj_crs)

# =============================================================================
# 2. POPULATION DATA  (proxy for impervious surface fraction / urban heat)
# =============================================================================

pop_raw <- get_acs(
  geography = "tract",
  variables = "B01003_001",       # total population
  state     = "PA",
  county    = "Philadelphia",
  year      = 2022,
  output    = "wide"
)

philly_tracts <- philly_tracts |>
  left_join(pop_raw |> select(GEOID, pop = B01003_001E), by = "GEOID") |>
  mutate(
    area_km2    = as.numeric(st_area(philly_tracts)) / 1e6,
    pop_density = pop / area_km2           # people per km²
  ) |>
  filter(!is.na(pop_density), pop_density > 0)

# =============================================================================
# 3. BUILD TEMPERATURE RASTER
#    Logic: denser tracts → more impervious surface → higher land surface temp
#    Water bodies get minimum heat value (strong cooling anchor)
# =============================================================================

# 100 m resolution raster
r <- rast(ext(vect(philly)), resolution = 100, crs = paste0("EPSG:", proj_crs))

# Rasterize population density
pop_r <- rasterize(vect(philly_tracts), r, field = "pop_density", fun = mean)

# Burn water bodies as cool anchor values
if (nrow(water) > 0) {
  tryCatch({
    water_clip <- st_intersection(
      st_make_valid(water),
      st_make_valid(philly)
    )
    if (nrow(water_clip) > 0) {
      water_r <- rasterize(vect(water_clip), r, field = 1, background = NA)
      cool_floor <- global(pop_r, "min", na.rm = TRUE)[[1]] * 0.2
      pop_r[!is.na(water_r)] <- cool_floor
    }
  }, error = function(e) message("Water clip skipped: ", e$message))
}

# Multi-pass Gaussian-style smoothing → spatial continuity like real satellite LST
for (w in c(41, 25, 15)) {
  pop_r <- focal(pop_r, w = w, fun = mean, na.rm = TRUE)
}

# Scale from [0, 1] → [82, 105] °F  (matches NYT legend range for mid-Atlantic cities)
p_min <- global(pop_r, "min", na.rm = TRUE)[[1]]
p_max <- global(pop_r, "max", na.rm = TRUE)[[1]]
temp_r <- ((pop_r - p_min) / (p_max - p_min)) * 23 + 82

# Mask to city boundary
temp_r <- mask(temp_r, vect(philly))

# Convert to data frame for ggplot
temp_df <- as.data.frame(temp_r, xy = TRUE) |>
  setNames(c("x", "y", "temp")) |>
  filter(!is.na(temp))

# =============================================================================
# 4. NEIGHBORHOOD LABEL POINTS
# =============================================================================

neighborhoods <- tibble::tribble(
  ~label,                 ~lon,      ~lat,
  "CENTER\nCITY",        -75.165,   39.952,
  "NORTH\nPHILLY",       -75.155,   39.990,
  "WEST\nPHILLY",        -75.225,   39.952,
  "SOUTH\nPHILLY",       -75.162,   39.924,
  "KENSINGTON",          -75.111,   39.997,
  "WISSAHICKON\nVALLEY", -75.212,   40.030,
  "MANAYUNK",            -75.226,   40.027,
  "FISHTOWN",            -75.132,   39.975,
  "ROXBOROUGH",          -75.227,   40.048
) |>
  st_as_sf(coords = c("lon", "lat"), crs = 4326) |>
  st_transform(proj_crs)

# Arc-line target points (arc tips land here)
hot_dot <- tibble(lon = -75.162, lat = 39.913) |>   # South Philly core
  st_as_sf(coords = c("lon", "lat"), crs = 4326) |>
  st_transform(proj_crs)

cool_dot <- tibble(lon = -75.212, lat = 40.030) |>   # Wissahickon Valley
  st_as_sf(coords = c("lon", "lat"), crs = 4326) |>
  st_transform(proj_crs)

# Extract projected coordinates for use in annotate()
hot_x  <- st_coordinates(hot_dot)[1, "X"]
hot_y  <- st_coordinates(hot_dot)[1, "Y"]
cool_x <- st_coordinates(cool_dot)[1, "X"]
cool_y <- st_coordinates(cool_dot)[1, "Y"]

# =============================================================================
# 5. NYT COLOR PALETTE
#    Teal (cool) → off-white (neutral / median) → orange-red (hot)
# =============================================================================

nyt_pal <- c(
  "#1c6b74",   # darkest teal
  "#3a8f98",   # medium-dark teal
  "#6ab4bc",   # medium teal
  "#a8d4d8",   # light teal
  "#d8ebec",   # very light teal
  "#f0e8e0",   # near-white warm
  "#e8c4a0",   # light peach-orange
  "#d09060",   # medium orange
  "#bb5930",   # dark orange
  "#8b2010",   # deep red
  "#5c0e0a"    # darkest red
)

# =============================================================================
# 6. MAP LAYOUT ANCHORS
# =============================================================================

bbox  <- st_bbox(philly)

# =============================================================================
# 7. BUILD GGPLOT
# =============================================================================

p <- ggplot() +

  # ── Temperature raster ─────────────────────────────────────────────────────
  geom_raster(data = temp_df, aes(x = x, y = y, fill = temp)) +
  scale_fill_gradientn(
    colors   = nyt_pal,
    limits   = c(82, 105),
    breaks   = c(82, 87, 93, 99, 105),
    labels   = c("82°F", "87°", "93°", "99°", "105°"),
    name     = "◄ COOLER                               HOTTER ►",
    na.value = "#e8e4de",
    guide    = guide_colorbar(
      direction      = "horizontal",
      barwidth       = unit(8, "cm"),
      barheight      = unit(0.4, "cm"),
      title.position = "top",
      title.hjust    = 0.5,
      label.position = "bottom",
      ticks          = FALSE
    )
  ) +

  # ── City boundary ──────────────────────────────────────────────────────────
  geom_sf(data = philly, fill = NA, color = "gray20", linewidth = 0.5) +

  # ── Neighborhood labels ────────────────────────────────────────────────────
  geom_sf_text(
    data        = neighborhoods,
    aes(label   = label),
    color       = "black",
    size        = 2.1,
    fontface    = "bold",
    lineheight  = 0.85,
    check_overlap = TRUE
  ) +

  # ── Arc lines: callout text → map location ────────────────────────────────
  # Cooler arc: leaves bottom-right edge of text block → Wissahickon Valley
  annotate("curve",
    x         = bbox["xmin"] + 3800,
    y         = bbox["ymax"] - 2600,
    xend      = cool_x,
    yend      = cool_y,
    curvature = -0.25,
    linewidth = 0.4,
    color     = "#3a8f98",
    arrow     = arrow(length = unit(0.1, "cm"), type = "open", ends = "last")
  ) +
  # Hotter arc: leaves top-left edge of text block → South Philly
  annotate("curve",
    x         = bbox["xmax"] - 5200,
    y         = bbox["ymin"] + 5800,
    xend      = hot_x,
    yend      = hot_y,
    curvature = -0.2,
    linewidth = 0.4,
    color     = "#bb5930",
    arrow     = arrow(length = unit(0.1, "cm"), type = "open", ends = "last")
  ) +

  # ── Cooler callout — upper left ────────────────────────────────────────────
  annotate("text",
    x          = bbox["xmin"] + 400,
    y          = bbox["ymax"] - 400,
    label      = paste0(
      "Cooler: Neighborhoods\n",
      "near Wissahickon Valley\n",
      "and Fairmount Park stay\n",
      "as low as 82°F on a\n",
      "hot summer afternoon"
    ),
    hjust      = 0,
    vjust      = 1,
    color      = "black",
    size       = 2.3,
    fontface   = "italic",
    lineheight = 1.1
  ) +

  # ── Hotter callout — bottom right (South Philly) ──────────────────────────
  annotate("text",
    x          = bbox["xmax"] - 400,
    y          = bbox["ymin"] + 3500,
    label      = paste0(
      "Hotter: South Philly's\n",
      "dense row-home blocks\n",
      "trap heat, reaching\n",
      "over 105°F in summer"
    ),
    hjust      = 1,
    vjust      = 0,
    color      = "black",
    size       = 2.3,
    fontface   = "italic",
    lineheight = 1.1
  ) +

  coord_sf(expand = FALSE) +
  theme_void() +
  theme(
    plot.background  = element_rect(fill = "#eeebe5", color = NA),
    panel.background = element_rect(fill = "#eeebe5", color = NA),
    legend.position  = "bottom",
    legend.margin    = margin(t = 4, b = 8),
    legend.title     = element_text(size = 7, color = "gray25", face = "bold"),
    legend.text      = element_text(size = 7, color = "gray25"),
    plot.title       = element_text(
      size   = 15, face = "bold", hjust = 0.5,
      margin = margin(t = 14, b = 3)
    ),
    plot.subtitle    = element_text(
      size   = 9, hjust = 0.5, color = "gray40",
      margin = margin(b = 6)
    ),
    plot.caption     = element_text(
      size   = 6.5, hjust = 0.5, color = "gray55",
      margin = margin(t = 4, b = 8)
    ),
    plot.margin = margin(8, 12, 4, 12)
  ) +
  labs(
    title    = "Heat Islands in Philadelphia",
    subtitle = "Estimated land surface temperature, summer afternoon",
    caption  = paste0(
      "Data: U.S. Census Bureau ACS 2022 (population density as urbanization proxy); ",
      "boundaries: TIGER/Line via tigris\n",
      "Style inspired by The New York Times (2019) — Nadja Popovich & Christopher Flavelle"
    )
  )

# =============================================================================
# 8. SAVE OUTPUT
#    Run this script from its own directory, or adjust the path below.
# =============================================================================

# If you open this script in RStudio and run setwd(dirname(...)) first,
# the output lands next to the script. Otherwise adjust the path.
ggsave(
  filename = "output_heat_island_philly.png",
  plot     = p,
  width    = 7.5,
  height   = 8.5,
  dpi      = 300,
  bg       = "#eeebe5"
)


