# Part 3 Reflection — Redesigning the California Heat Wave Risk Map

## Before (Original Map)

The original map was produced during MUSA 5080 Day 15 and mapped FEMA National Risk Index heat-wave scores (`HWAV_RISKS`) at the county level across California. The R script is preserved unchanged in `day15-fire.R`.

---

## Design Problems in the Original

1. **Incorrect subject label.** The title reads "Wildfire Risk Scores" but the variable plotted — `HWAV_RISKS` — is FEMA's *heat wave* risk score, not fire risk. This is the single most damaging flaw: the map is factually mislabeled.

2. **Uninformative subtitle.** "Made by Zhanchao Yang" is a byline, not a narrative. It adds no interpretive value and wastes the subtitle slot, which is the best place to give readers a one-line headline for what they should take away.

3. **Semantically wrong color palette.** The original palette runs blue → teal → light yellow → orange → red. Blue and teal culturally connote water, coolness, and safety — exactly the wrong signal for a *heat* variable. A reader's eye is drawn to the teal areas as though they are "interesting," when they represent low risk. The yellow midpoint is also nearly invisible against a white background.

4. **Continuous gradient with raw numeric legend.** Readers see a score of "91.7" and have no frame of reference: is that high? The legend axis labels raw floats, forcing the reader to mentally map an arbitrary scale to risk categories. There are no named tiers.

5. **No geographic context.** No city labels, no annotation — the reader cannot locate familiar places to anchor risk. Someone unfamiliar with California's geography cannot tell which high-risk areas are urban or rural.

6. **No narrative annotation.** The map is a choropleth of numbers. It does not tell any story about *why* some areas are riskier, or *where* the most exposed populations live.

7. **Legend overlap.** In the second version of the original, `legend.position = c(1, 0.97)` places the legend in the upper-right corner, directly covering map data in the Central Valley.

---

## Changes Made and Why

| Design element | Original | Redesign | Reasoning |
|---|---|---|---|
| **Subject / title** | "Wildfire Risk Scores" | "Inland California Faces the Greatest Extreme-Heat Risk" | Corrects the factual error; the new title is a Big Idea statement, not just a variable name |
| **Subtitle** | "Made by Zhanchao Yang" | "County-level heat wave risk score, classified into five equal-frequency tiers" | Tells the reader exactly what they are looking at and how data are classified |
| **Color palette** | Blue-teal-yellow-orange-red (diverging) | Pale cream → amber → deep crimson (sequential) | Heat risk is one-directional; a sequential palette is semantically correct. Cream-to-crimson is culturally intuitive for temperature and danger |
| **Classification** | Continuous gradient | 5 quantile classes labeled Low → High | Discrete tiers let readers immediately categorize a county without parsing a numeric axis; quantile breaks ensure each class contains the same number of counties so no tier dominates visually |
| **Legend design** | Right-side vertical bar with raw score axis | Bottom horizontal legend with "◄ LOWER RISK … HIGHER RISK ►" flanking | Directional labels pre-interpret the palette; bottom placement keeps the map face clear; mirrors the Part 1 NYT approach |
| **Geographic context** | None | 8 major city dots with labels | Anchors risk to real places (e.g., Fresno, Riverside) so readers immediately understand that inland urban areas are most exposed |
| **Annotation** | None | Callout arc to Central Valley corridor | Points to the highest-risk region and explains the mechanism (sparse tree cover, low elevation), turning the map from a data display into a story |
| **Projection** | California Albers (retained) | California Albers (retained) | Correct choice: equal-area is appropriate for comparing county-level magnitudes across a large state |

---

## Reflection

The original map's most damaging problem was not aesthetic — it was the factual mislabeling of a heat-wave variable as "wildfire risk." A reader who trusted the title would leave with a completely wrong understanding of the data. Fixing the label was therefore the first and non-negotiable change. Beyond that, the redesign addresses the original's two biggest visual failures: the counterintuitive cool-colored palette and the formless continuous gradient. Switching to a cream-to-crimson sequential scheme made the map immediately legible — the darkest areas are the most dangerous, full stop — and classifying into five quantile tiers gave readers a vocabulary ("High," "Moderate") rather than a raw number. Adding city labels transformed the map from an abstract county grid into a recognizable landscape: seeing Fresno, Bakersfield, and Riverside sitting inside the darkest tier tells the story far more powerfully than any annotation could alone. The callout arc was added last, specifically to answer the "so what?" question that the original left entirely unaddressed. Finally, repositioning the legend to the bottom and adding directional cue text eliminated both the data-overlap problem and the ambiguity about which end of the scale is "bad."

**Big Idea statement:** For a general California audience, the map argues that *inland communities — not coastal cities — bear a disproportionately high heat-wave risk, and that land-use and topography are the underlying drivers*, so that policymakers and emergency managers should prioritize heat-resilience investment in the Central Valley and Inland Empire first.
