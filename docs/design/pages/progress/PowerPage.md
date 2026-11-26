# PowerPage

Progress → Power answers "What is my power profile?": the numbers riders train by on top, the power curve and best efforts under them.

**The consumer provides** the rider card, the FTP with where it came from and today's estimate, critical power and W′, the VO2max estimate, and the best power per duration for the chosen range.

**Layout**
- Title row: "Progress" caption, `page-title` and the `⋯` menu. The range control sits in the title row of the power curve card, as `controls/Controls.md` says.
- First, full width: **Your numbers** (the rider card of Pack 2): only what no other card on this page shows, each with where it came from: maximum heart rate, threshold heart rate, FTP as W/kg, and peak power. Its link "Whole rider card →" opens the full card in a sheet (every number with its source: FTP and W/kg, critical power, W′ and peak, the 90-day bests with their rides, both heart-rate numbers, eight weeks of efficiency, the 90-day totals, today's fitness and form, the next event); a best effort in the sheet opens its ride.
- Row 1, three cards: **FTP** with W/kg and where it came from; when the estimate differs from the FTP in use, the card shows it with an "Use 2xx W" button. **Critical power** with W′. **VO2max estimate** with what it was computed from.
- Row 2, two thirds and one third: **Power curve** on a log time axis (1 s to 1 h), a faded area under an `accent-strong` line, the FTP as a dashed `ink-muted` line; **Best efforts** as a table (duration, watts, W/kg) with a link to all durations.

**Don't** show the power curve without enough rides: show the empty state with what is missing ("Record rides with a power meter to see your curve").
