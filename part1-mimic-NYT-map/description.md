Map 1: Decompose and Recreate a Professional Map
The best way to learn cartographic design is to study work made by people who do it for a living. Your task: find a professionally published map that you have a big ‘crush on’, break down the design decisions that make it effective, and recreate it (or a map in its style) using your own data in R. For this map, you may certainly make use of AI tools to help you get to your final product – but I do want you to do the decomposing with your own brain to help you think through what goes into a ‘crush-worthy’ map.

The ultimate goal is not pixel-perfect replication; it’s to force yourself to notice and reverse-engineer choices you’d normally scroll past: color palettes, classification methods, annotation placement, typography, legend design, use of white space, and whether the map even needed to be a map.

What to Do
Find a professionally made map from a credible source. Good places to look: The New York Times, The Washington Post, The Guardian, FlowingData, karim.news, The Pudding, Reuters Graphics, etc. The map should be sophisticated enough that recreating it teaches you something.
Decompose the design. Before you write any code, study the map and identify the specific design choices that make it work. Write these down. You should be able to name at minimum: the map type, the projection (or your best guess of a general family of projections), the classification method and number of classes, the color palette and whether it’s sequential/diverging/categorical, how the legend is designed, what the title and annotations communicate, and what contextual layers (basemap, labels, boundaries) are included or excluded.
Recreate it in R using your own data. You do not need to use the exact same dataset as the original. Find comparable data (e.g., if the original maps county-level poverty in the UK, you could map tract-level poverty in Philadelphia). The point is to replicate the style and design logic, not the exact content. Use ggplot2, tmap, or any R mapping package.
Write a reflection (5–8 sentences) that includes:
A screenshot or link to the original map, with proper source attribution.
Your decomposition: list every design choice you identified and what you think the cartographer’s reasoning was.
What was hardest to replicate and why? What did you have to approximate or change?

A Score of 3 Looks Like

The source map is genuinely well-designed. The decomposition is thorough and names specific design choices, not vague impressions. The recreation captures the style and logic of the original, even where exact replication wasn’t possible. The reflection demonstrates that you learned something about cartographic design by doing this! Ideally, this (and all the others should be something you are proud to post on your portfolio!).