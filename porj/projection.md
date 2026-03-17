# Map 2: Projection as a Design Choice

Map Projections can be editorial decision that shapes how your audience perceives the data and, as we discussed in class, can be part of the story that you are telling. For this map, you will work with a geography outside of North America where the default projection (WGS84 / Mercator) would visibly distort the story.

## What to Do
Choose a geography and a dataset from the options below (or propose your own) The geography must be one where the wrong projection creates a meaningful visual distortion or where the projection is part of the story you are telling – like the geographic evolution one we saw (and some of us liked and others not so much!)
Make two versions of the same map: one in an appropriate projection for your geography, and one in WGS84 (EPSG:4326) or Web Mercator (EPSG:3857).
Apply map design rules to the correctly projected version: normalized data, appropriate classification, clean legend, insightful title, decluttered design. This should be a polished map, not just a projection demo – you may do any type of map you'd like here - flows showing Edmund Shackleton's Antarctic Exploration for example, are welcome. Use annotation! Tell a story! Make my greatest hits slides.
Write a short reflection (3–5 sentences) answering: What projection did you choose and why? What specific distortion does the default create? How does that distortion change what the audience perceives about the data?

## Suggested Geographies
You may choose one of these or propose your own. The key requirement is that the projection choice must matter visually.

## A Score of 3 Looks Like
The side-by-side comparison makes the distortion immediately visible. The correctly projected map is a polished choropleth with real data, appropriate classification, and a clear story. The reflection demonstrates understanding of what the chosen projection preserves and sacrifices, and how the default distortion would mislead a viewer.

---

## My Submission

### Geography & Dataset
**Antarctica** — Historic expedition routes (Shackleton 1914–16, Amundsen 1910–12, Scott 1910–12) overlaid with the locations of 10 current year-round international research stations.

**Story**: In 1911, three teams raced to the South Pole. One won. One died trying. One never made it and became the greatest survival story ever told. In the default projection, these routes are cartographic nonsense — you cannot read the geography that shaped their fates. In the correct polar projection, the continent snaps into focus, and the human drama becomes spatially legible.

### Files
| File | Purpose |
|---|---|
| `bad_projection.R` | Antarctic stations & expedition routes in **EPSG:4326** (WGS84 equirectangular) — the wrong choice |
| `good_projection.R` | Same data in **EPSG:3031** (Antarctic Polar Stereographic) — dark NYT-style polar map |
| `description.md` | Full narrative essay explaining the projections, the history, and why it matters |
| `output_bad_projection.png` | Output from bad_projection.R |
| `output_good_projection.png` | Output from good_projection.R |

### Required Packages
```r
install.packages(c("sf", "ggplot2", "rnaturalearth", "rnaturalearthdata", "dplyr", "scales"))
```

---

## Projection Reflection

**What projection did you choose and why?**
I chose the Antarctic Polar Stereographic projection (EPSG:3031), centered on the South Pole — the standard projection used by every Antarctic research program on Earth. It is the only reasonable choice for a map that must show Antarctica as a coherent geographic whole, because it renders the continent in its true circular form and preserves local shapes (conformal) while keeping distances from the pole accurate.

**What specific distortion does the default projection create?**
In the equirectangular/WGS84 projection (EPSG:4326), latitude and longitude are treated as simple Cartesian coordinates, causing catastrophic east-west stretching near the poles. At 80°S, one degree of longitude represents only ~17 km of actual ground but is drawn as if it were ~111 km — a sixfold exaggeration. Most egregiously, the South Pole itself — a single geographic point — is rendered as an entire line stretching across the full width of the map.

**How does that distortion change what the audience perceives?**
The distortion makes Antarctica completely unreadable as a place. In the default projection, Amundsen and Scott's routes appear to end at *different* locations on the map — even though both men stood at the exact same point on Earth. Shackleton's elliptical loop around the Weddell Sea appears as a flat squiggle. The circular structure of the continent, which governs wind patterns, ocean currents, territorial claims, and the spatial logic of every expedition ever mounted there, is entirely invisible. The polar view restores all of it: the continent snaps into a recognizable shape, the expedition routes become geographically coherent, and the story of who went where — and what it cost them — can finally be read in the map.
