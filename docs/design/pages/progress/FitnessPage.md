# FitnessPage

Progress → Fitness answers "Is my fitness going up?" with one big chart of fitness, fatigue and form, and below it the things that drive them.

**The consumer provides** daily fitness, fatigue and form for the chosen range, daily load, the intensity split, the training load totals and the efficiency factor per ride.

**Layout**
- Title row: a `caption` "Progress" above the `page-title`, and the `⋯` menu. The range control (30 days, 90 days, 1 year) sits in the title row of the chart it changes, as `controls/Controls.md` says. On a phone the sub-pages are tabs instead.
- Full width: **Fitness, fatigue and form.** Fitness as a line with a faded area (`accent-strong`), fatigue as a dashed line (`series-power`), both labelled at their last point; form as bars round a zero line under them, `accent-strong` above zero and `signal` below. The sentence says the trend in words.
- Two thirds and one third: **Daily load** (bars, the latest in `accent-strong`) and **Easy, moderate, hard**.
- Halves: **Training load** for the range (TSS, TRIMP, rides, distance as `stat` numbers) and **Aerobic efficiency** (a line over the latest rides).

**Don't** add a fourth series to the big chart; the range control is the only setting it needs.
