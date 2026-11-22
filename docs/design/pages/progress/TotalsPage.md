# TotalsPage

Progress → Totals answers "What did I do each week, month and year?" with one chart and one table.

**The consumer provides** the totals per period (rides, distance, moving time, climbing) and the measure to chart.

**Layout**
- Title row: "Progress" caption, `page-title` and the `⋯` menu. The period control (Weeks, Months, Years) sits in the chart card's title row, as `controls/Controls.md` says.
- Full width chart: the chosen measure per period, past periods `bar-muted`, the current one `accent-strong`, the average as a dashed `ink-muted` line with its value. A second control beside it picks the measure (Distance, Time, Climbing).
- Full width table: one row per period, newest first, the current period on `accent-soft`. Numbers right-aligned with tabular figures. Eight rows, then "Show earlier".

**Don't** repeat the table's numbers as value labels on the bars.
