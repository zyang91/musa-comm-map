# ==============================================================================
# bad_projection.R
# Map 2: Projection as a Design Choice
#
# THE WRONG MAP: Antarctica in WGS84 Equirectangular (EPSG:4326)
# "What Every Atlas Gets Wrong About the Bottom of the World"
#
# This is the BAD version — intentionally showing how a default projection
# mangles Antarctica into a meaningless horizontal strip. The South Pole,
# a single geographic point, becomes an entire LINE across the bottom.
# Shackleton's circular Weddell Sea route looks like a flat squiggle.
# All polar distances are fiction.
# ==============================================================================

library(sf)
library(ggplot2)
library(rnaturalearth)
library(rnaturalearthdata)
library(dplyr)

# ------------------------------------------------------------------------------
# Data: World Countries
# ------------------------------------------------------------------------------
world <- ne_countries(scale = "medium", returnclass = "sf") |>
  st_make_valid()

# ------------------------------------------------------------------------------
# Data: Antarctic Research Stations (10 major year-round stations)
# Coordinates in WGS84 (lon, lat)
# ------------------------------------------------------------------------------
stations <- data.frame(
  name    = c("McMurdo (USA)", "South Pole (USA)", "Vostok (Russia)",
              "Concordia (Fr/It)", "Rothera (UK)", "Casey (Australia)",
              "Davis (Australia)", "Syowa (Japan)", "Neumayer III (Germany)",
              "Esperanza (Argentina)"),
  lon     = c(166.67,   0.00, 106.87, 123.38, -68.13, 110.52,
               77.97,  39.59,  -8.27, -57.00),
  lat     = c(-77.85, -89.99, -78.46, -75.10, -67.57, -66.28,
              -68.58, -69.01, -70.67, -63.40),
  stringsAsFactors = FALSE
)
stations_sf <- st_as_sf(stations, coords = c("lon", "lat"), crs = 4326)

# ------------------------------------------------------------------------------
# Data: Historic Expedition Routes (simplified key waypoints)
# ------------------------------------------------------------------------------

# Shackleton's Endurance Expedition (1914–1916)
# South Georgia → Weddell Sea (ship trapped) → ship sank → Elephant Island → South Georgia
shackleton_pts <- matrix(c(
  -36.5, -54.3,   # South Georgia — departure Nov 1914
  -38.0, -65.0,   # Entering Weddell Sea pack ice
  -31.0, -76.5,   # Endurance beset in ice — Jan 1915
  -52.4, -68.6,   # Endurance sinks — Nov 21, 1915
  -55.1, -61.1,   # Elephant Island — survival camp Apr 1916
  -36.5, -54.3    # South Georgia — rescue Aug 1916
), ncol = 2, byrow = TRUE)

# Amundsen's South Pole Expedition (1910–1912)
# Bay of Whales → Ross Ice Shelf → Polar Plateau → South Pole
amundsen_pts <- matrix(c(
  -163.4, -78.6,   # Bay of Whales / Framheim base
  -163.0, -82.0,   # Southern Ross Ice Shelf
  -163.0, -85.5,   # Axel Heiberg Glacier ascent
    0.0,  -89.99   # South Pole — Dec 14, 1911
), ncol = 2, byrow = TRUE)

# Scott's Terra Nova Expedition (1910–1913)
# Cape Evans → Ross Ice Shelf → Beardmore Glacier → South Pole
scott_pts <- matrix(c(
  166.4, -77.6,   # Cape Evans, Ross Island
  166.0, -80.0,   # Ross Ice Shelf
  163.0, -83.5,   # Beardmore Glacier
    0.0, -89.99   # South Pole — Jan 17, 1912
), ncol = 2, byrow = TRUE)

routes_sf <- st_sf(
  name = c("Shackleton (1914–16)", "Amundsen (1910–12)", "Scott (1910–12)"),
  geometry = st_sfc(
    st_linestring(shackleton_pts),
    st_linestring(amundsen_pts),
    st_linestring(scott_pts),
    crs = 4326
  )
)

# ------------------------------------------------------------------------------
# BAD MAP: WGS84 Equirectangular (EPSG:4326)
# Design sins: default gray theme, rainbow-adjacent colors, no story hierarchy,
# no annotation, confusing layout, latitude axis makes Antarctica look like
# a flat strip rather than a continent.
# ------------------------------------------------------------------------------

ggplot() +
  # Ocean: default light blue background (bad — blends with ice)
  geom_sf(data = world,
          fill    = "gray75",
          color   = "white",
          linewidth = 0.15) +

  # Expedition routes — inconsistent, hard to distinguish colors
  geom_sf(data = routes_sf,
          aes(color = name),
          linewidth = 0.9,
          linetype = "solid") +
  scale_color_manual(
    name   = "Expedition Route",
    values = c(
      "Shackleton (1914–16)" = "orange",
      "Amundsen (1910–12)"   = "steelblue",
      "Scott (1910–12)"      = "firebrick"
    )
  ) +

  # Stations — all same symbol, no country context
  geom_sf(data   = stations_sf,
          color  = "black",
          fill   = "yellow",
          shape  = 21,
          size   = 2.5,
          stroke = 0.6) +

  # BAD PROJECTION: treating latitude as linear — catastrophic at poles
  coord_sf(
    crs    = 4326,
    xlim   = c(-180, 180),
    ylim   = c(-90, -45),
    expand = FALSE
  ) +

  labs(
    title    = "Antarctic Research Stations and Historic Expedition Routes",
    subtitle = "Projection: WGS84 Equirectangular (EPSG:4326)  ← THIS IS THE PROBLEM",
    x        = "Longitude",
    y        = "Latitude",
    color    = "Expedition",
    caption  = paste0(
      "⚠  DISTORTION ALERT: In equirectangular/Mercator projections, Antarctica is catastrophically wrong.\n",
      "The South Pole — a single geographic POINT — renders as an entire line stretching across the bottom.\n",
      "Shackleton's circular Weddell Sea loop appears flat. East-west distances near the pole are ~10× reality.\n",
      "Amundsen and Scott's routes to the same South Pole appear to end at completely different locations."
    )
  ) +

  # Bad design: default gray theme, cluttered, no visual hierarchy
  theme_gray(base_size = 11) +
  theme(
    panel.background  = element_rect(fill = "lightblue"),
    plot.title        = element_text(size = 13, face = "bold"),
    plot.subtitle     = element_text(size = 9.5, color = "red3", face = "bold"),
    plot.caption      = element_text(size = 8, color = "gray30", hjust = 0, lineheight = 1.4),
    legend.position   = "right",
    axis.title        = element_text(size = 9),
    axis.text         = element_text(size = 8)
  )

ggsave(
  filename = "output_bad_projection.png",
  width    = 12,
  height   = 7,
  dpi      = 200,
  bg       = "white"
)

message("Bad projection map saved to: output_bad_projection.png")
message("Notice how Antarctica stretches infinitely wide — that's the projection lying to you.")
