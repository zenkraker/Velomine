# AreaChart

One value over time as a line with a fading area under it, the latest point marked with its value.

**The consumer provides** the dated values, the unit and the series colour token (default `accent-strong`; a ride signal uses its `series-*` token).

**Do**
- One series per chart. A second series (fatigue next to fitness) is a thin line without area, in its `series-*` colour, with a direct label at its end instead of a legend.
- Gridlines at round values, at most three or four.
- Put the trend into the card's sentence: "Rising for 12 weeks: 4 to 18."

**Don't**
- Stack three series with areas; the form chart gets its own detail page.
- Start the y-axis at a data extreme; start at a round number.

**Flutter:** `CustomPainter`; the area is a `Path` filled with a vertical `LinearGradient` from 35 % to 0 %.
