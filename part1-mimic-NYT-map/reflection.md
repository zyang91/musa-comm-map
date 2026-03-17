# Part 1 Reflection — Recreating the NYT Heat Island Map

## Source Map

**Original:** Nadja Popovich & Christopher Flavelle, *The New York Times* (2019)
"How Much Hotter Is Your Hometown Than When You Were Born?"
<https://www.nytimes.com/interactive/2019/08/09/climate/city-heat-islands.html>

![Source map](source-nyt.png)

---

## Design Decomposition

| Design element | Observed choice | Cartographer's likely reasoning |
|---|---|---|
| **Map type** | Continuous raster (land surface temperature) | Pixel-level thermal data communicates the spatial gradient far better than polygons; the viewer feels the heat gradient rather than reading class breaks |
| **Projection** | Appears to be a local conformal projection (State Plane or UTM) | Minimises distortion at city scale; the tight crop makes projection choice nearly invisible, but equal-area is not critical here since the map is illustrative rather than area-comparative |
| **Classification** | Continuous diverging gradient — no discrete class breaks | Forcing breaks would hide the granular heat-pocket pattern that is the entire story; continuity lets the eye follow the gradient naturally |
| **Color palette** | Diverging: saturated teal/blue-green (cool) → off-white (neutral/median) → orange to deep red (hot) | Teal/red is the culturally intuitive temperature encoding; the white midpoint at the city-wide median temp anchors the reader's interpretation; saturation peaks at extremes to draw attention to the hottest and coolest patches |
| **Legend** | Horizontal colorbar strip at bottom center; flanked by "◄ COOLER" and "HOTTER ►"; °F labels below | The directional words pre-interpret the palette so readers never wonder which end is which; the horizontal orientation echoes the left-cool / right-hot reading convention |
| **Title & annotations** | Two italic text callouts — upper-left (cooler, with specific temp "as low as 82°F") and upper-right (hotter, "over 101°F") | Callouts replace a formal title block and embed the story directly on the map; the specific temperatures give the gradient concrete meaning without requiring readers to parse the legend |
| **Typography** | Large bold white sans-serif for "BALTIMORE"; smaller bold white for neighborhood names; italic white for callout text | White text over a coloured raster avoids contrast conflicts regardless of the underlying temperature value; weight hierarchy (large/bold → small/bold → italic) distinguishes place-name levels |
| **Contextual layers** | No basemap tiles; Patapsco River visible as a teal data break; subtle white city boundary | A satellite or street basemap would compete visually with the temperature signal; the river appears organically through the cool colour value, reinforcing the heat-island explanation |
| **White space / crop** | Map cropped tight to city outline; very narrow margin | Forces the reader's attention entirely onto the temperature pattern; the "edge of data" acts as a natural frame |

---

## Recreation Summary

My recreation maps **Philadelphia, PA** using the same style. Because downloading raw Landsat 8 land surface temperature scenes would require significant pre-processing, I instead used **ACS 2022 census tract population density** as a proxy for impervious surface fraction — the underlying driver of urban heat. Denser tracts contain more buildings and pavement, so higher density is mapped to higher temperature after normalisation to the same 82–105 °F range used in the NYT legend. Water bodies (Delaware and Schuylkill rivers, Wissahickon Creek) are burned to minimum-heat values before a multi-pass focal smoothing step that mimics the spatial continuity of real satellite LST imagery.

---

## Reflection

The NYT map earns its "crush-worthy" status through restraint: every design decision removes clutter rather than adding information. The most instructive moment in decomposing it was realising that the colorbar legend is almost secondary — the two annotation callouts with specific temperatures do the interpretive heavy lifting, letting the bar serve as a reference tool rather than the primary explanation. Replicating the palette was straightforward in principle (teal → white → red) but required careful tuning of the colour-stop positions so that the neutral off-white aligns with the city's approximate median temperature rather than the mathematical midpoint of the scale. The hardest element to reproduce faithfully was the texture of the original: real satellite LST has fine-grained variation that gives the map a "photographic" quality, whereas population-density rasters interpolate smoothly in a way that reads more like a synthetic surface. I compensated with multiple passes of focal smoothing at decreasing kernel sizes, which adds spatial continuity but still lacks the micro-variation of thermal imagery. Typography was the other challenge — matching the exact NYT typeface and weight in ggplot2 requires system fonts and `showtext` or `extrafont`, so I approximated with the default bold sans-serif. Overall, this exercise forced me to notice how much work the annotation layer does: without the two callout boxes, the map is a pretty raster; with them, it becomes a story.
