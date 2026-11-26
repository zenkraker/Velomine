# BarChart

A total per period (week, month, year) as rounded bars that fade toward the base, with the current period in the accent.

**The consumer provides** the periods with their values and labels, which one is current, and the unit. The chart picks round gridlines (at most four) and the label step from its width.

**Do**
- Current period `accent-strong`; past periods `bar-muted`.
- Write the value above the current bar (in `ink`) and above the peak (in `ink-muted`), and on no other bar.
- On a phone, label every third bar; from 600 dp every second.

**Don't**
- Draw values on every bar, a legend for one series, or a y-axis title.
- Show empty bars for missing data; show the empty state instead.

**Flutter:** drawn with `CustomPainter`, no chart library. Bars are `RRect`s with `radius-sm` top corners and a `LinearGradient` from full colour to 55 % opacity.
