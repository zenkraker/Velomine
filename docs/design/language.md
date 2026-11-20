# Velomine visual language

The rules every screen follows. The values are in `docs/design/tokens.json`; `app/lib/core/theme.dart` and `app/lib/core/tokens.dart` implement them, and `app/test/design_tokens_test.dart` keeps the theme equal to the tokens. Change a value in `tokens.json` and the theme in the same change.

Velomine is a cycling app for riders and their clubs: rides, progress, bikes and a club, on the phone and on the web. It is dark first, calm and data-rich. One colour, volt, carries the energy; everything else stays quiet so the rider's numbers lead.

## Principles

1. **One question per page.** Each page answers one question ("How am I this week?", "What is my power profile?"). A second question gets its own page, tab or detail route.
2. **One fact per card.** A card has four parts, in this order: a title, one number, one sentence that explains it, and at most one link to the details ("Power →"). A card never repeats a number shown elsewhere on the page.
3. **Summary first, details one tap away.** An overview page is a grid of fact cards; each links to its detail page. Long explanations live behind an info button, never in the card.
4. **One accent, used sparingly.** Volt (`accent`, `accent-strong`) marks what is current, selected or the main action. Everything else is `ink`, `ink-muted` and the surfaces.
5. **Surfaces, not lines.** Cards are set apart by their fill (`card` on `canvas`): no borders, no shadows. Dividers (`hairline`) only inside a card.
6. **Glass only where something floats.** The nav pill, sheets and the info card over a map use `glass` with `blur-glass` and `shadow-float`. Cards in the page flow are never glass.
7. **The route glows.** On a map the route is the brightest thing: the tiles dimmed toward `map-ground`, a blurred `route-glow` stroke under a sharp `accent-strong` line.

## Content

- Write in plain, short sentences, in English and Italian; every string exists in both.
- Sentence case everywhere: titles, buttons, nav. No uppercase eyebrows, no emoji.
- Speak to the rider as "you" ("Your best 20 minutes"). Name things as riders do: ride, climb, effort, not "activity entity".
- Numbers carry their unit with a thin gap, formatted for the language: `69.7 km`, `2 h 35`, `1,416 m` in English; `69,7 km`, `1.416 m` in Italian. Store SI; format only in the view.
- A card's sentence says what the number means, not how it was computed: "Keep it easy: endurance pace, no hard efforts."
- Errors say what happened and what to do: "Couldn't load your rides. Check the connection and try again."

## Colour

- Page: `canvas`. Cards, sidebar, sheets: `card`. A hovered row or an inset block: `card-raised`.
- Text: `ink` for titles, numbers and body; `ink-muted` for units, details, captions and axis labels.
- The main action is a filled pill in `accent` with `on-accent` text. There is one per screen.
- Links, the gauge arc, the current bar and the route line use `accent-strong`. By day this is olive (`#4e6300`), because volt on white is unreadable.
- Selected nav item, segment or chip: `accent-soft` ground, `on-accent-soft` text.
- Past bars: `bar-muted`. The current period: `accent-strong`. Only the current and the peak bar carry a value label.
- `signal` (tail light) marks the finish and states that ask for care; `warning` and `danger` always come with a word or an icon, never colour alone.
- Ride charts use the `series-*` colours so a signal looks the same everywhere: power is always `series-power`, heart rate always `series-heartrate`.
- Both themes are first class. Night is the default look; Day follows the system setting.

## Type

- Two families: Geist (`sans`) for everything you read and every number; Instrument Serif (`display`) only for the page title and the wordmark.
- The scale: `page-title` 40, `kpi` 40, `stat` 24, `card-title` 17, `body` and `nav-label` 15, `caption` 13, `axis` 12. Do not add sizes.
- Big numbers are `kpi` at regular weight with tabular figures; the unit beside them is `caption` size in `ink-muted`.
- Card titles are `card-title`, one line, sentence case.

## Space and layout

- The spacing scale is `space-xs` 4 · `space-sm` 8 · `space-md` 12 · `space-lg` 16 · `space-xl` 24 · `space-xxl` 32 · `space-xxxl` 48. Never a literal.
- Cards: padding `space-xl`, gap between cards `space-lg`, corners `radius-lg`.
- Size classes: compact under 600 dp (one column, gutter `space-lg`, floating nav pill), medium 600–1199 dp (two columns, gutter `space-xl`, collapsed rail), expanded from 1200 dp (up to four columns, gutter `space-xxl`, expanded sidebar). Content is at most 1160 px wide, centred in the space beside the sidebar.
- In a row, cards are the same height; a grid row is full: no card alone with empty space beside it.
- Touch targets are at least 48 × 48.

## Cards

- **Stat card** (`StatCard`): title, `kpi` number with unit, one `caption` or `body` sentence, one `accent-strong` link with an arrow. Optional state chip after the number.
- **Chart card**: title, one chart, an optional control (period) in the title row, at most one sentence under the chart.
- **List card**: title, rows with `body-strong` and `caption`, row actions appear on hover (web) or in the row's `⋯` menu, "All … →" link at the bottom.

## Charts

- Drawn with Flutter's canvas, never a chart library.
- Faint `hairline` grid at round values (0, 40, 80, 120), at most four lines; axis labels in `axis` and `ink-muted`.
- Bars have `radius-sm` tops and a vertical fade from full colour at the top to 55 % at the base.
- Area charts: a 2 px line, the area under it faded to transparent, the last point marked with a dot and its value.
- Fewer labels on a phone: compute the label step from the width so labels never touch.
- No data: show the empty state with a sentence, never empty axes.

## Maps

- Tiles from the server's tile address, dimmed toward `map-ground` and desaturated, in both themes.
- The route: a 14 px `route-glow` stroke blurred by 6 px, then a 4 px `accent-strong` line. Start: an `accent` dot. Finish: a `signal` dot with a `card` ring.
- Facts about the ride sit in a `glass` card at the bottom of the map, `radius-xl`.

## Navigation

- Four main destinations, in this order everywhere: Rides, Progress, Goals, Club.
- Phone: a floating `glass` pill with the four destinations; the selected one sits on `accent-soft`. Sub-pages of a destination are tabs at the top of its page.
- From 1200 dp: the sidebar on `card`, with the `brand` wordmark, destinations that expand (Rides ▾, Progress ▾, Club ▾; Goals is one page), and the account, settings and privacy note at the bottom. The current page is `accent-soft`.
- Progress has one overview and four sub-pages, each built around one main chart: Overview ("How am I today and this week?"), Fitness (fitness, fatigue and form), Power (power curve and FTP), Totals (weeks, months, years) and Wellbeing (readiness and check-ins).
- A sub-page's title row carries the parent's name as a `caption` above the `page-title`.
- An overview page fits in about one screen. When it grows past that, a card moves to its own sub-page, not further down the page.
- One main action per screen, as a filled pill in the page header. Rare and destructive actions go in the header's `⋯` menu, destructive last, in `danger`.

## Motion

- Durations 120, 220 and 320 ms; a small spring for things that arrive (sheet, pill, chip), fast-out-slow-in for things that move.
- Everything stops when the system asks to reduce motion.

## Iconography

- Material Symbols, outlined at rest and filled when selected, 24 px, in `ink` or `ink-muted`; `on-accent-soft` when selected.
- Every icon-only button has a label for screen readers.
- The previews in this system draw simplified line icons in place of Material Symbols.

## In Flutter

- Colours map to `ColorScheme` as each token's note says; the rest live in the `VelomineColors` theme extension.
- Spacing and radii are `AppSpacing` and `AppRadius` in `lib/core/tokens.dart`; never a literal `EdgeInsets` or radius.
- Text styles come from `Theme.of(context).textTheme`; `kpi` and `stat` are added there as named styles.

## Components and pages

### StatCard

One fact on a card: a title, one big number, one sentence that explains it, and one link to its details.

**The consumer provides** the title, the value and its unit (already formatted for the language), one sentence, and the route the link opens. An optional state (a word such as "Go easy") shows as a chip after the number.

**Use it** for the summary row of an overview page, up to four in a row from 1200 dp, two per row on a phone.

Do
- Number in `kpi`, unit in `ink-muted` at caption size.
- The sentence says what the number means for the rider.
- The link names the detail page: "Power →", "All weeks →".

Don't
- Put two numbers on one card, or a number another card on the same page already shows.
- Add an icon tile, an uppercase eyebrow, a border or a shadow.
- Clip the sentence: it wraps.

**Flutter:** a `StatCard` in `lib/core/widgets/` replaces today's `StatTile` and the hand-made tiles in `progress_screen.dart`.

### BarChart

A total per period (week, month, year) as rounded bars that fade toward the base, with the current period in the accent.

**The consumer provides** the periods with their values and labels, which one is current, and the unit. The chart picks round gridlines (at most four) and the label step from its width.

Do
- Current period `accent-strong`; past periods `bar-muted`.
- Write the value above the current bar (in `ink`) and above the peak (in `ink-muted`), and on no other bar.
- On a phone, label every third bar; from 600 dp every second.

Don't
- Draw values on every bar, a legend for one series, or a y-axis title.
- Show empty bars for missing data; show the empty state instead.

**Flutter:** drawn with `CustomPainter`, no chart library. Bars are `RRect`s with `radius-sm` top corners and a `LinearGradient` from full colour to 55 % opacity.

### AreaChart

One value over time as a line with a fading area under it, the latest point marked with its value.

**The consumer provides** the dated values, the unit and the series colour token (default `accent-strong`; a ride signal uses its `series-*` token).

Do
- One series per chart. A second series (fatigue next to fitness) is a thin line without area, in its `series-*` colour, with a direct label at its end instead of a legend.
- Gridlines at round values, at most three or four.
- Put the trend into the card's sentence: "Rising for 12 weeks: 4 to 18."

Don't
- Stack three series with areas; the form chart gets its own detail page.
- Start the y-axis at a data extreme; start at a round number.

**Flutter:** `CustomPainter`; the area is a `Path` filled with a vertical `LinearGradient` from 35 % to 0 %.

### GoalGauge

One goal on one card: a half-circle gauge with the percentage, the current value against the target, and one sentence that says what is left.

**The consumer provides** the goal's name, the current value, the target, the unit and the period's end date, plus the routes for editing and deleting it.

**Use it** on the Goals page, a grid of these cards: three per row from 1200 dp, two from 600 dp, one on a phone. Goals are a main destination of their own, not cards on Progress.

Do
- Gauge arc `accent-strong` on `track`, 14 px, round caps; the percentage in the middle.
- A reached goal draws the full arc, shows a "Reached" chip on `accent-soft`, and says by how much in the sentence. Over 100 % never draws past the end.
- Edit and Delete live in the card's `⋯` menu; Delete is last, in `danger`, and confirmed.

Don't
- Put two goals on one card, or a gauge on a value that is not a share of a target.

**Flutter:** `CustomPainter` with `drawArc`, `StrokeCap.round`.

### RouteMap

A ride's route on a dimmed map, drawn as a glowing line, with the ride's facts on a glass card over the bottom of the map.

**The consumer provides** the route points (already passed through the privacy function for anyone but the owner), the ride's name and date, and up to three facts (distance, moving time, climbing).

Do
- Dim and desaturate the tiles toward `map-ground` in both themes, so the route is the brightest thing.
- Draw a 14 px `route-glow` stroke blurred by 6 px, then the 4 px `accent-strong` line on top.
- Start: `accent` dot. Finish: `signal` dot. Both with a 3 px `card` ring.
- The info card is `glass`, `radius-xl`, inset by `space-lg`.

Don't
- Colour the route by speed or heart rate on overview cards; that belongs to the ride page.
- Put buttons on the map card; the whole card opens the ride.

**Flutter:** the tiles are drawn with a `ColorFilter.matrix` that lowers saturation and brightness; the glow is a `Paint` with `MaskFilter.blur(BlurStyle.normal, 6)` under the line (`features/rides/detail/route_painter.dart`).

### Sidebar

The navigation from 1200 dp: the wordmark, four main destinations, and the privacy note, profile and settings at the bottom.

**The consumer provides** the destinations and the current route: Rides ▾ (All rides, Routes, Bikes), Progress ▾ (Overview, Fitness, Power, Totals, Wellbeing), Goals (one page, no sub-pages), and the member's club ▾ (Members, Club rides, Sharing). A section holding the current page opens by itself.

Do
- The current page sits on `accent-soft` in `on-accent-soft`, semibold. Hover is `card-raised`.
- Sections with pages open and close with a chevron; their pages are indented under the section's icon. A destination with one page (Goals) is a plain link.
- The club section is named after the member's club; without a club it reads "Club" and opens the join page.
- The same four destinations, in the same order, are the phone's nav pill.

Don't
- Add a fifth destination, or put a destructive action here (Sign out lives in the Profile page's menu).
- Show counts or badges except unread notifications.

**Flutter:** one widget for the expanded rail in `home_shell.dart`; from 600 to 1199 dp the four destinations show as a collapsed rail of icons with labels, and on a phone as the nav pill.

### NavPill

The phone's main navigation: a floating glass pill with Rides, Progress, Goals and Club, above the content and the safe area.

**The consumer provides** the four destinations and the current one. A ride in progress shows as a banner above the pill.

Do
- `glass` with `blur-glass` and `shadow-float`, `radius-pill`, 64 px tall, at most 420 px wide, inset `space-md` from the edges.
- The selected item sits on `accent-soft` in `on-accent-soft`; icons filled when selected, outlined otherwise.
- The pill slides away while the page scrolls down and returns on scroll up; with reduced motion it stays.
- Pages leave room under their content so the last card clears the pill.

Don't
- Add a fifth item or a floating action button beside it.

**Flutter:** `FloatingNavPill` in `home_shell.dart`; sizes in `AppNav`.

### Controls

The four controls every page draws from: the main action, the period selector, the sport filter and the page menu.

**The consumer provides** the labels, the current choice and what each choice does.

Do
- **Main action:** one filled pill per screen, `accent` with `on-accent`, `button-label`, at least 48 px tall, in the page header.
- **Period:** a segmented control on `track`; the chosen segment is `card` with `ink`. It sits in the title row of the chart it changes.
- **Sport filter:** chips; the chosen chip is `accent-soft` with `on-accent-soft`. It sits under the page title and applies to the whole page. On a phone the row scrolls sideways.
- **Page menu:** a `⋯` icon button that opens rare actions; destructive entries come last after a divider, in `danger`, and are always confirmed.

Don't
- Put the period selector and the sport filter in one row.
- Show a destructive action as a visible button.

**Flutter:** `FilledButton`, `SegmentedButton`, `FilterChip` and `PageMenu` themed from the tokens.

### ProgressDesktop

The Progress overview from 1200 dp: it answers only "How am I today and this week?", and every card opens the sub-page that answers the next question.

**The consumer provides** the rider's numbers for the chosen sport.

Layout
- Sidebar (240 px) with Progress open and Overview current; content at most 1160 px wide.
- Title row: `page-title` and the `⋯` menu. Under it, the sport filter chips, for the whole page.
- Row 1, four stat cards, each linking to its sub-page:
  - **Readiness** (score and state) → Wellbeing
  - **Form** (today's form, "Building", fitness and fatigue in the sentence) → Fitness
  - **This week** (distance, against the 12-week average) → Totals
  - **Next event** (days to go); with no event planned, the latest record instead → Goals
- Row 2, full width: Distance per week with its period control → Totals. It grows to the bottom of the window, so the content ends level with the sidebar.

**The Progress sub-pages**, one question and one main chart each:

| Page | Question | Main chart |
|---|---|---|
| Fitness | Is my fitness going up? | Fitness, fatigue and form |
| Power | What is my power profile? | Power curve |
| Totals | What did I do each week, month, year? | Totals chart and table |
| Wellbeing | How do I feel, and why that readiness? | Readiness factors and how you feel |

FTP is the headline of Power, not of the overview: it changes every few weeks, not every day.

### ProgressPhone

The Progress overview on a phone (under 600 dp): the same cards as on the desktop in one column, the sub-pages as tabs at the top, and the glass nav pill floating over the bottom.

**The consumer provides** the rider's numbers for the chosen sport.

Layout
- Title row: `page-title`, the sport as one chip that opens a sheet ("Road ▾"), and the `⋯` menu.
- Tabs as chips that scroll sideways: Overview, Fitness, Power, Totals, Wellbeing.
- Readiness full width; Form and This week side by side (smaller `kpi`, no link: the whole card opens its page); Next event; Distance per week with its period control.
- Bar labels every third week. Page padding `space-lg`; room under the last card for the pill.

### FitnessPage

Progress → Fitness answers "Is my fitness going up?" with one big chart of fitness, fatigue and form, and below it the things that drive them.

**The consumer provides** daily fitness, fatigue and form for the chosen range, daily load, the intensity split, the training load totals and the efficiency factor per ride.

Layout
- Title row: a `caption` "Progress" above the `page-title`, the range control (30 days, 90 days, 1 year) and the `⋯` menu. On a phone the sub-pages are tabs instead.
- Full width: **Fitness, fatigue and form.** Fitness as a line with a faded area (`accent-strong`), fatigue as a dashed line (`series-power`), both labelled at their last point; form as bars round a zero line under them, `accent-strong` above zero and `signal` below. The sentence says the trend in words.
- Two thirds and one third: **Daily load** (bars, the latest in `accent-strong`) and **Easy, moderate, hard**.
- Halves: **Training load** for the range (TSS, TRIMP, rides, distance as `stat` numbers) and **Aerobic efficiency** (a line over the latest rides).

**Don't** add a fourth series to the big chart; the range control is the only setting it needs.

### PowerPage

Progress → Power answers "What is my power profile?": the numbers riders train by on top, the power curve and best efforts under them.

**The consumer provides** the FTP with where it came from and today's estimate, critical power and W′, the VO2max estimate, and the best power per duration for the chosen range.

Layout
- Title row: "Progress" caption, `page-title`, the range control and the `⋯` menu.
- Row 1, three cards: **FTP** with W/kg and where it came from; when the estimate differs from the FTP in use, the card shows it with an "Use 2xx W" button. **Critical power** with W′. **VO2max estimate** with what it was computed from.
- Row 2, two thirds and one third: **Power curve** on a log time axis (1 s to 1 h), a faded area under an `accent-strong` line, the FTP as a dashed `ink-muted` line; **Best efforts** as a table (duration, watts, W/kg) with a link to all durations.

**Don't** show the power curve without enough rides: show the empty state with what is missing ("Record rides with a power meter to see your curve").

### TotalsPage

Progress → Totals answers "What did I do each week, month and year?" with one chart and one table.

**The consumer provides** the totals per period (rides, distance, moving time, climbing) and the measure to chart.

Layout
- Title row: "Progress" caption, `page-title`, the period control (Weeks, Months, Years) and the `⋯` menu.
- Full width chart: the chosen measure per period, past periods `bar-muted`, the current one `accent-strong`, the average as a dashed `ink-muted` line with its value. A second control in the card picks the measure (Distance, Time, Climbing).
- Full width table: one row per period, newest first, the current period on `accent-soft`. Numbers right-aligned with tabular figures. Eight rows, then "Show earlier".

**Don't** repeat the table's numbers as value labels on the bars.

### WellbeingPage

Progress → Wellbeing answers "How do I feel, and why is my readiness what it is?". Wellbeing is health data: only the owner sees this page.

**The consumer provides** the readiness score with its factors and their effects, today's check-in, and how the rider felt over the last 14 days. Before the first check-in, the consent card replaces the page.

Layout
- Title row: "Progress" caption, `page-title`, the filled **Check in** button (opens a form sheet) and the `⋯` menu, where Withdraw consent sits last, in `danger`.
- Halves: **Readiness** (score, state chip, advice, and the note that it is a guide, not a medical measure) and **Why 50**: one row per factor with its value and its effect drawn from a centre line, `accent-strong` when it raises the score, `signal` when it lowers it, with the signed number.
- Full width: **How you feel** over 14 days, and the note on who can see what.

**Don't** show notes to anyone but the owner, or put readiness on a coach's view.

### GoalsPage

Goals as a main destination: it answers "Am I hitting my goals?" with one GoalGauge card per goal and Add goal as the page's one main action.

**The consumer provides** the rider's goals with their progress.

Layout
- Title row: `page-title` and the filled Add goal button. Adding opens a form sheet.
- One sentence under the title that sums up the goals ("Three goals running. One reached this month.").
- A grid of goal cards: three per row from 1200 dp, two from 600 dp, one on a phone. Running goals first, then reached ones.
- No goals yet: the empty state with a sentence and the same Add goal button.
- The rider's events (races, sportives) belong here too, as the targets the goals lead to: a "Next event" card above the goals with the days to go. The Progress overview links here from its Next event card.

The sidebar and the nav pill are the same as on every page, with Goals current. The preview shows the content area only.
