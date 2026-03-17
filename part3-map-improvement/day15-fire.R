library(sf)
library(tidyverse)
library(tigris)
library(grid) 

# Load sample data
# Download data from https://hazards.fema.gov/nri/data-resources
data<- st_read("... Your Path /NRI_Shapefile_Counties/NRI_Shapefile_Counties.shp")
# or you could read in my cleaned data
#  data <- st_read("data/day15/ca_fire_risk.geojson")

data_fire <- data %>%
  select(starts_with("HWAV_"))

#get California state boundary
ca_boundary <- states(cb = TRUE) %>%
  filter(STUSPS == "CA") %>%
  st_transform(st_crs(data_fire))

ca_fire <- st_intersection(data_fire, ca_boundary)

ca_fire<- ca_fire %>%
  select(HWAV_RISKS, HWAV_RISKR)%>%
  st_transform(st_crs(3310)) # transform to California Albers

# plot fire risk map
# ggplot() +
#   geom_sf(data = ca_fire, aes(fill = HWAV_RISKS), color = NA) +
#   scale_fill_viridis_c(option = "inferno", na.value = "grey50", name = "Wildfire Risk Score") +
#   labs(title = "Wildfire Risk Scores in California",
#        subtitle = "Made by Zhanchao Yang",
#        caption = "Data Source: https://hazards.fema.gov/nri/map") +
#   theme_void() +
#   theme(legend.position = "right",
#         plot.title = element_text(size = 16, face = "bold"),
#         plot.subtitle = element_text(size = 8),
#         plot.caption = element_text(size = 8))



fire_pal <- c(
  "#264653", # very low
  "#2a9d8f",
  "#f6f4d2",
  "#f4a261",
  "#bd0026"  # very high
)

ggplot() +
  geom_sf(data = ca_fire, aes(fill = HWAV_RISKS), color = NA) +
  scale_fill_gradientn(
    colours  = fire_pal,
    na.value = "grey80",
    name     = "Wildfire Risk Score"
  ) +
  labs(
    title    = "Wildfire Risk Scores in California",
    subtitle = "Made by Zhanchao Yang",
    caption  = "Data Source: https://hazards.fema.gov/nri/map"
  ) +
  theme_void() +
  theme(
    legend.position      = "right",
    legend.title         = element_text(size = 9),
    legend.text          = element_text(size = 5),
    plot.title           = element_text(size = 16, face = "bold"),
    plot.subtitle        = element_text(size = 8),
    plot.caption         = element_text(size = 8)
  )



ggplot() +
  geom_sf(data = ca_fire, aes(fill = HWAV_RISKS), color = NA) +
  scale_fill_gradientn(
    colours  = fire_pal,
    na.value = "grey80",
    name     = "Wildfire Risk Score"
  ) +
  labs(
    title    = "Wildfire Risk Scores in California",
    subtitle = "Made by Zhanchao Yang",
    caption  = "Data Source: https://hazards.fema.gov/nri/map"
  ) +
  theme_void() +
  theme(
    legend.position = c(1, 0.97),
    legend.justification = c("right", "top"),
    legend.box.just = "right",
    legend.margin = margin(6, 6, 6, 6),
    legend.title    = element_text(
      size   = 9,
      margin = margin(b = 10)   # <- more space between title and legend
    ),
    legend.text     = element_text(size = 7),
    plot.title      = element_text(size = 16, face = "bold"),
    plot.subtitle   = element_text(size = 8),
    plot.caption    = element_text(size = 8)
  )
