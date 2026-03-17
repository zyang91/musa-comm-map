# ==============================================================================
# good_projection.R
# Map 2: Projection as a Design Choice
#
# THE GOOD MAP: Antarctica in Antarctic Polar Stereographic (EPSG:3031)
# "Three Expeditions. Three Fates. One Continent — Shown Correctly."
#
# In 1911, three teams raced to the South Pole. One won. One died trying.
# One never made it — and became the greatest survival story ever told.
# When you look at Antarctica the right way (from above, as scientists do),
# these routes become readable as geography, not just biography.
#
# Projection: EPSG:3031 — Antarctic Polar Stereographic
# Preserves: Shape and relative distances near the pole (conformal)
# Sacrifices: Area at the continent's edges
# Perfect for: Any map centered on or covering Antarctica
# ==============================================================================

library(sf)
library(ggplot2)
library(rnaturalearth)
library(rnaturalearthdata)
library(dplyr)
library(scales)

# ------------------------------------------------------------------------------
# Color Palette — NYT-inspired dark polar aesthetic
# ------------------------------------------------------------------------------
pal <- list(
  ocean      = "#0b1f3a",      # deep navy — cold, vast, dangerous
  ice        = "#ddeef5",      # pale ice blue — Antarctica
  shelf      = "#c8e2ef",      # slightly darker for ice shelves
  land_other = "#1e3a14",      # dark forest green — other continents
  grid       = "#162d4a",      # subtle grid lines
  shackleton = "#f4a11d",      # amber gold — survival against the odds
  amundsen   = "#56cfe1",      # polar blue — cool triumph
  scott      = "#c44536",      # red — tragedy
  station    = "#ffffff",      # white dots — research stations
  text_main  = "#f0f4f8",      # near-white text
  text_dim   = "#8aa5bf",      # muted text for captions
  annotation = "#e8d5a3"       # warm annotation color
)

# ------------------------------------------------------------------------------
# Data: World Countries
# ------------------------------------------------------------------------------
world <- ne_countries(scale = "medium", returnclass = "sf") |>
  st_make_valid()

# Separate Antarctica from other land (different styling)
antarctica  <- world |> filter(name == "Antarctica")
other_land  <- world |> filter(name != "Antarctica")

# ------------------------------------------------------------------------------
# Data: Antarctic Research Stations (10 major year-round stations)
# ------------------------------------------------------------------------------
stations <- data.frame(
  name    = c("McMurdo\n(USA)", "South Pole\n(USA)", "Vostok\n(Russia)",
              "Concordia\n(Fr/It)", "Rothera\n(UK)", "Casey\n(Aus)",
              "Davis\n(Aus)", "Syowa\n(Japan)", "Neumayer III\n(Ger)",
              "Esperanza\n(Arg)"),
  lon     = c(166.67,   0.00, 106.87, 123.38, -68.13, 110.52,
               77.97,  39.59,  -8.27, -57.00),
  lat     = c(-77.85, -89.99, -78.46, -75.10, -67.57, -66.28,
              -68.58, -69.01, -70.67, -63.40),
  stringsAsFactors = FALSE
)
stations_sf   <- st_as_sf(stations, coords = c("lon", "lat"), crs = 4326)
stations_3031 <- st_transform(stations_sf, crs = 3031)

# Extract projected coordinates for labeling
stations_coords <- as.data.frame(st_coordinates(stations_3031))
stations_labelled <- bind_cols(stations, stations_coords)

# ------------------------------------------------------------------------------
# Data: Historic Expedition Routes
# ------------------------------------------------------------------------------

# Shackleton's Endurance Expedition (1914–1916)
# THE SURVIVAL STORY: Never reached the pole. Became legend by saving everyone.
shackleton_pts <- matrix(c(
  -36.5, -54.3,   # South Georgia — Nov 1914
  -38.0, -65.0,   # Into Weddell Sea pack ice
  -31.0, -76.5,   # Endurance beset — Jan 1915
  -52.4, -68.6,   # Endurance sinks — Nov 21, 1915
  -55.1, -61.1,   # Elephant Island — Apr 1916
  -36.5, -54.3    # South Georgia — rescued Aug 1916
), ncol = 2, byrow = TRUE)

# Amundsen's South Pole Expedition (1910–1912)
# THE VICTORY: First humans to reach the South Pole, Dec 14, 1911.
amundsen_pts <- matrix(c(
  -163.4, -78.6,
  -163.0, -82.0,
  -163.0, -85.5,
    0.0,  -89.99
), ncol = 2, byrow = TRUE)

# Scott's Terra Nova Expedition (1910–1913)
# THE TRAGEDY: Reached the Pole 33 days after Amundsen. Died 11 miles from safety.
scott_pts <- matrix(c(
  166.4, -77.6,
  166.0, -80.0,
  163.0, -83.5,
    0.0, -89.99
), ncol = 2, byrow = TRUE)

routes_sf <- st_sf(
  name = c("Shackleton (1914–16)", "Amundsen (1910–12)", "Scott (1910–12)"),
  story = c(
    "Survival — Every crew member lived",
    "Victory — First to the South Pole",
    "Tragedy — All five perished returning"
  ),
  geometry = st_sfc(
    st_linestring(shackleton_pts),
    st_linestring(amundsen_pts),
    st_linestring(scott_pts),
    crs = 4326
  )
)

# ------------------------------------------------------------------------------
# Transform to EPSG:3031 (Antarctic Polar Stereographic)
# ------------------------------------------------------------------------------
routes_3031      <- st_transform(routes_sf, crs = 3031)
antarctica_3031  <- st_transform(antarctica, crs = 3031)

# Clip other land to southern hemisphere before transforming to avoid
# distortion artifacts from very northern features
other_land_3031 <- other_land |>
  st_crop(xmin = -180, ymin = -90, xmax = 180, ymax = -30) |>
  st_transform(crs = 3031)

# ------------------------------------------------------------------------------
# Graticules: Circular latitude rings at 60°S, 70°S, 80°S
# These give the map its distinctive "looking down from space" feel
# ------------------------------------------------------------------------------
graticules <- st_graticule(
  lat = c(-80, -70, -60),
  lon = seq(-180, 180, by = 30),
  crs = 4326
) |>
  st_transform(crs = 3031)

# ------------------------------------------------------------------------------
# Key annotation points (in projected coords for annotate())
# South Pole is the origin (0, 0) in EPSG:3031
# ------------------------------------------------------------------------------

# Pre-compute label coordinates for Shackleton's key events
route_coords <- st_coordinates(routes_3031)

# ------------------------------------------------------------------------------
# BUILD THE MAP
# ------------------------------------------------------------------------------
p <- ggplot() +

  # --- Base layers ---

  # Subtle polar grid — orients viewer without cluttering
  geom_sf(data      = graticules,
          color     = pal$grid,
          linewidth = 0.25,
          alpha     = 0.8) +

  # Other southern land (South America tip, New Zealand, etc.)
  geom_sf(data      = other_land_3031,
          fill      = pal$land_other,
          color     = NA) +

  # Antarctica ice sheet — the star of the show
  geom_sf(data      = antarctica_3031,
          fill      = pal$ice,
          color     = alpha("white", 0.5),
          linewidth = 0.3) +

  # --- Expedition Routes (the human story) ---
  # Draw twice: thick glow underneath, thinner bright line on top
  geom_sf(data      = routes_3031,
          aes(color = name),
          linewidth = 3.5,
          alpha     = 0.15,
          lineend   = "round") +
  geom_sf(data      = routes_3031,
          aes(color = name),
          linewidth = 1.3,
          lineend   = "round") +

  # Route color legend
  scale_color_manual(
    name   = NULL,
    values = c(
      "Shackleton (1914–16)" = pal$shackleton,
      "Amundsen (1910–12)"   = pal$amundsen,
      "Scott (1910–12)"      = pal$scott
    ),
    labels = c(
      "Shackleton (1914–16)" = "Shackleton  —  Survived. Never reached the pole.",
      "Amundsen (1910–12)"   = "Amundsen  —  First to the South Pole, Dec 14 1911.",
      "Scott (1910–12)"      = "Scott  —  Arrived 33 days late. Died returning."
    )
  ) +

  # --- Research Stations ---
  geom_sf(data   = stations_3031,
          shape  = 21,
          size   = 3.5,
          fill   = pal$station,
          color  = "#333333",
          stroke = 0.7) +

  # Station labels (key ones only for readability)
  geom_text(
    data  = stations_labelled |> filter(grepl("McMurdo|South Pole|Vostok|Esperanza", name)),
    aes(x = X, y = Y, label = name),
    color    = pal$text_dim,
    size     = 2.2,
    nudge_x  = 150000,
    nudge_y  = 150000,
    hjust    = 0,
    lineheight = 0.9,
    fontface = "italic"
  ) +

  # Weddell Sea label
  annotate("text",
    x        = -600000, y = 1100000,
    label    = "Weddell\nSea",
    color    = alpha(pal$text_dim, 0.7),
    size     = 2.1,
    fontface = "italic",
    lineheight = 0.85
  ) +

  # Ross Sea label
  annotate("text",
    x        = 600000, y = -1700000,
    label    = "Ross\nSea",
    color    = alpha(pal$text_dim, 0.7),
    size     = 2.1,
    fontface = "italic",
    lineheight = 0.85
  ) +

  # Number of nations annotation
  annotate("text",
    x        = -2800000, y = -2800000,
    label    = "10 nations.\n1 continent.\nNo owner.",
    color    = pal$annotation,
    size     = 2.6,
    fontface = "bold",
    lineheight = 1.1,
    hjust    = 0
  ) +

  # --- Coordinate System ---
  coord_sf(
    crs    = 3031,
    xlim   = c(-3.4e6, 3.4e6),
    ylim   = c(-3.4e6, 3.4e6),
    expand = FALSE
  ) +

  # --- Labels ---
  labs(
    title   = "Three Expeditions. Three Fates. One Continent",
    subtitle = "The path human explore the South polar",
    caption  = paste0(
      "Projection: Antarctic Polar Stereographic (EPSG:3031)  |  Data: Natural Earth, Historic expedition records\n",
      "Today, 10 nations maintain permanent research stations on a continent no country owns.\n",
      "The Antarctic Treaty (1959) suspended all territorial claims and dedicated the continent to peaceful science."
    )
  ) +

  # --- Theme ---
  theme_void(base_size = 12) +
  theme(
    # Background
    plot.background  = element_rect(fill = pal$ocean, color = NA),
    panel.background = element_rect(fill = pal$ocean, color = NA),

    # Title hierarchy
    plot.title    = element_text(
      color     = pal$text_main,
      size      = 17,
      face      = "bold",
      margin    = margin(t = 16, b = 5)
    ),
    plot.subtitle = element_text(
      color     = alpha(pal$text_main, 0.70),
      size      = 10.5,
      margin    = margin(b = 10)
    ),
    plot.caption  = element_text(
      color      = pal$text_dim,
      size       = 7.5,
      hjust      = 0,
      lineheight = 1.5,
      margin     = margin(t = 12)
    ),

    # Legend
    legend.position   = c(0.83, 0.88),
    legend.background = element_rect(fill = alpha(pal$ocean, 0.88), color = NA),
    legend.text       = element_text(color = pal$text_main, size = 8),
    legend.title      = element_blank(),
    legend.key        = element_rect(fill = NA, color = NA),
    legend.key.width  = unit(1.6, "cm"),
    legend.key.height = unit(0.5, "cm"),
    legend.spacing.y  = unit(0.15, "cm"),

    # Margins
    plot.margin = margin(12, 12, 12, 12)
  )

p
# ------------------------------------------------------------------------------
# Export
# ------------------------------------------------------------------------------
ggsave(
  filename = "output_good_projection.png",
  plot     = p,
  width    = 10,
  height   = 10,
  dpi      = 300,
  bg       = pal$ocean
)


