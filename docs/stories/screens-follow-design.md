# Screens follow the design

## Overview
`docs/design/pages/` is the design of every screen and shared component (`AGENTS.md`, *Screens and layout*): its `README.md` holds the visual language, and each page has a guideline (`.md`) and a mock-up (`.html`, open it in a browser). **Where the code and the design differ, the code is wrong.** A full audit on 22 Nov compared every guideline and mock-up with its screen and found the differences below. This story makes the screens match. It changes no server behaviour except Task 7 (route lines in the routes list).

Each item quotes the design, says what the code does (file:line on `64cc9e5`, may drift) and the fix. The fix is a strong suggestion: **the guideline and mock-up win** if the fix text and the design disagree.

## How to work
- **Branch:** the worktree `.dev/worktrees/screens` on `feat/screens-follow-design` (from `feat/before-pack-3` with `docs/cleanup` merged). Commit this file first. Do not push.
- **Order: Task 1 → 11.** One commit per task. Task 1 changes shared widgets the others use.
- **Before each page:** read its guideline and open its mock-up (`docs/design/pages/<area>/<Name>.md` and `.html`) and `docs/design/pages/README.md` (*The visual language*). Build from the shared widgets in `app/lib/core/widgets/` (`PageScaffold`, `SectionCard`, `AppCard`, `StatCard`, `CardGrid`, `SegmentedControl`, `PageMenu`, `EmptyState`, `ErrorState`, ...). A widget a second screen needs moves to `lib/core/widgets/`.
- **Rules from `AGENTS.md` that apply everywhere:** one main action per screen as `primaryAction` (a filled pill, never `IconButton.filled` and never a `FloatingActionButton`); rare and destructive actions in the `PageMenu`, destructive last after a divider and confirmed with `confirmDestructive`; every segmented choice is a `SegmentedControl`; a list is one card with rows (not one card per item); no literal colours, text sizes, `EdgeInsets` or radii; every new string in **both** `app_en.arb` and `app_it.arb` (Italian says "giro/giri" for a ride), then `flutter gen-l10n`; Riverpod and MVVM stay as they are: views render state, ViewModels hold logic.
- **Tests:** the existing widget tests find widgets by `Key`: keep the keys, and change a test only when the design changes what it checks (say why in the commit). Every changed screen keeps or gains a `<Screen>_ShouldNotOverflow_WhenWidthIs<N>` test at 390 and 1300 dp. Add a test for each behaviour change (an action moved into a menu, a card split, a choice that became a `SegmentedControl`). Names follow `Subject_ShouldDoSomething_WhenCondition`.
- After each task run that area's tests: `nix develop --command bash -c 'cd app && flutter test test/<file>'`. Run the full `nix develop --command just check` **once, after Task 11**, and fix what it finds in a last commit.
- Do not add a dependency. Do not edit `app/packages/velomine_api/` by hand (Task 7 regenerates it). Do not change a screen the design does not cover.
- If an item is wrong, impossible without a server change, or contradicts its guideline, **skip it and list it in your report** with the reason. Do not guess.

## Decisions already taken (do not reopen)
- The period control sits in the title row of the chart it changes (`controls/Controls.md`); it does not move to the page header.
- The Rides page's main action is Upload ride at every width; Start ride goes in the ⋯ menu.
- Profile keeps the Zones card (after Athlete); the Supporter card shows the licence, the hide-badge switch, a replay link and the solo-trial badge.
- The route page: Download GPX is the main action; Edit, Share and the destructive entries are in the ⋯ menu.

## Task 1: Shared widgets
Changes every later task builds on. Do these first:
1. **Main action is always a pill.** Replace every `IconButton.filled` / `IconButton.filledTonal` used as a screen's main action with the `FilledButton` pill `primaryAction` (`rg -n "IconButton.filled" app/lib`; filter buttons that are not the main action stay). If `PageScaffold` needs a compact pill style on the phone, add it there, not per screen.
2. **Sub-pages carry their parent.** Every pushed screen whose mock-up shows a caption above the title passes `parent:` to `PageScaffold` (the slot exists). The items below name each one.
3. **`AuthPage` gets a caption and the page-title style:** add an optional `caption` drawn as a muted caption above the title, and draw the title with the same style `PageScaffold` uses. Items in Task 10 pass the captions.
4. **One badge widget** for the small chips on the ride page (`ride_type_chips.dart`, `power_record_chips.dart`) and wherever a later task needs a badge, in `lib/core/widgets/`, from `AppSpacing`/`AppRadius` and theme colours (item list in Task 2).

## Task 2: Rides

- **[rides/RidesPage.md] (medium)** Design: rides/RidesPage.md:5 "Upload ride is the page's one action; Import from Strava and Zwift are in the `...` menu."
  Code: app/lib/features/rides/rides_screen.dart:169 `final startRidePrimary = hasRecorder && !wide;` and :183-195: with a recorder on a phone the header's one action is Start ride and Upload ride is demoted into the `...` menu (:200-206).
  Fix: Upload ride is the `primaryAction` at every width; Start ride (where the recorder exists) moves to the ⋯ menu as the first entry (owner decision, 22 Nov: follow the design).

- **[rides/RecordPhone.md] (medium)** Design: rides/RecordPhone.md:5 "One big Start button, the ride type, auto-pause and the heart-rate strap. Recording settings are in the `...` menu." The mock-up draws the ride-type chips, the Pause when stopped switch and the strap row on the page (RecordPhone.html:9-12).
  Code: app/lib/features/recording/recording_screen.dart:194-210 draws only a one-line summary plus a `tune` IconButton (no `...` menu), and the ride type, e-bike, auto-pause and strap live inside a settings sheet (:255-311). The ride type is a `DropdownButtonFormField` (:263-283), not chips.
  Fix: Put a `PageMenu` on `PageScaffold` (:69) for recorder settings, and draw the ride type as a chip row, the Pause when stopped switch and the strap row (`_SensorTile`) directly on the start card instead of inside `_SettingsSheet`.

- **[rides/RecordPhone.md] (small)** Design: rides/RecordPhone.md:6 "each row's menu holds Retry, Upload and Delete from the phone."
  Code: app/lib/features/recording/recording_screen.dart:630-678: Upload/Retry are visible `TextButton`s in the row's trailing side; the row's `PageMenu` holds only `delete-<id>`.
  Fix: Move the `upload-<id>` / `retry-upload-<id>` actions into the row's `PageMenu` as `PageMenuEntry`s before the destructive delete entry, and drop the trailing TextButtons.

- **[rides/RecordingLivePhone.md] (small)** Design: rides/RecordingLivePhone.md:5 "The moving time is the largest thing on the screen; distance, speed, heart rate and GPS accuracy under it."
  Code: app/lib/features/recording/recording_screen.dart:434-441 makes the total elapsed time (`state.elapsedS`, `displayLarge`) the largest number, and moving time is one ordinary `StatFigure` among the tiles (:447-449).
  Fix: Render `stopwatch(state.movingS)` in the large clock slot and keep elapsed time (when it differs) among the small figures.

- **[rides/RecordingLivePhone.md] (small)** Design: rides/RecordingLivePhone.md:6 "Pause and Stop and save are full-width; stopping is the main action."
  Code: app/lib/features/recording/recording_screen.dart:509-527: Pause/Resume is the `FilledButton` and Stop and save is the quiet `OutlinedButton`, so the filled action is Pause.
  Fix: Swap the button styles: `FilledButton` for `record-stop` (Stop and save) and `OutlinedButton` for `record-pause` / `record-resume`.

- **[rides/RideDetailPage.md] (medium)** Design: rides/RideDetailPage.md:6 "the numbers: four headline numbers, then every other number the ride has as tiles on one card, never loose on the page." The mock-up is a card titled Numbers holding four big numbers and a tile grid (RideDetailPage.html:9).
  Code: app/lib/features/rides/detail/ride_detail_screen.dart:398-404 puts `_Stats` in the page flow, and `_Stats` (:718-727) is a bare `Wrap` of `StatFigure`s with no card, no title and no four headline numbers.
  Fix: Wrap `_Stats` in a `SectionCard`/`AppCard` titled with the numbers heading, and give it a first row of the four headline figures (distance, moving time, climbing, average power) in the `kpi`/`stat` size, with the remaining tiles below.

- **[rides/RideDetailPage.md] (medium)** Design: rides/RideDetailPage.md:7 "The charts share one cursor; the zones card switches between heart rate and power." The mock-up has one zones card with a Heart rate | Power segmented control (RideDetailPage.html:11).
  Code: app/lib/features/rides/detail/ride_detail_screen.dart:433-460 draws two separate `_ZonesCard`s (heart rate and power) with no switch.
  Fix: Draw one zones card holding a `SegmentedControl` of heart rate/power in its title row and the selected zone list under it.

- **[rides/RideDetailPage.md] (medium)** Design: rides/RideDetailPage.md:6-7: the route map leads, then the numbers, then the charts sharing one cursor, then laps, feel, bike and who looked.
  Code: app/lib/features/rides/detail/ride_detail_screen.dart:476-510 appends the moment line and every `SeriesChart` at the end of the list, after the laps (:420), the zones (:433), the bike (:461), how the ride felt (:466) and who looked (:475).
  Fix: Move the moment line and the `SeriesChart` loop to just after the numbers card, so the order is map, numbers, charts, zones, laps, feel, bike, views.

- **[rides/RideDetailPage.md] (small)** Design: rides/RideDetailPage.md:7 and the README visual language (README.md:32) that ride charts use the `series-*` colours; app AGENTS.md: "widgets never use a literal colour or text size".
  Code: app/lib/features/rides/detail/ride_detail_screen.dart:876-892 defines the zone bars as literal `Color(0xFF...)` lists (`_heartRateZoneColors`, `_powerZoneColors`).
  Fix: Drop both literal lists and take the zone bar colours from `VelomineColors.of(context)` (the `series` map / `barMuted` + `accentStrong`), as the mock-up draws them.

- **[rides/RideDetailPage.md] (small)** Design: app AGENTS.md Screens and layout: "a card in the page flow is an `AppCard` or `SectionCard`"; cards take `space-xl` padding and `radius-lg` (README.md:22 and the space rules).
  Code: app/lib/features/rides/detail/ride_detail_screen.dart:799 `_ZonesCard` builds a raw `Card` with `AppSpacing.lg` padding, and app/lib/features/rides/detail/lap_table.dart:30 does the same for the laps.
  Fix: Build both as `SectionCard`/`AppCard` (title + children) so their fill, padding and title row match every other card.

- **[rides/RideDetailPage.md] (small)** Design: README.md:89 "A sub-page's title row carries the parent's name as a `caption` above the `page-title`." The mock-up shows the crumb Rides (RideDetailPage.html:7).
  Code: app/lib/features/rides/detail/ride_detail_screen.dart:133-139 passes only `title` and `menu` to `PageScaffold`; no `parent`.
  Fix: Pass `parent: l10n.navRides` to `PageScaffold` (the `parent` slot already exists, page_scaffold.dart:78).

- **[rides/RideDetailPage.md] (small)** Design: README.md:22 (surfaces, spacing and radii come from tokens) and the badge chips the mock-up draws as `vm-badge` (RideDetailPage.html:8).
  Code: app/lib/features/rides/ride_type_chips.dart:60-77 and app/lib/features/rides/detail/power_record_chips.dart:26-50 hand-build chips with literal spacing (`6`, `4`, `8`, `3`) and a literal radius (`12`) instead of tokens or a shared chip.
  Fix: Move the badge to one shared widget in app/lib/core/widgets/ built from `AppSpacing`/`AppRadius` and the theme's chip colours, and use it for both chip rows.

- **[rides/ImportPage.md] (small)** Design: rides/ImportPage.md:5 "When it ends: 'Import finished' and Back to rides." The mock-up draws Back to rides as a quiet button under the card (ImportPage.html:8).
  Code: app/lib/features/rides/import/import_screen.dart:94-101 puts a filled `FilledButton` inside the `SectionCard`, and `PageScaffold` gets no `primaryAction`.
  Fix: Move Back to rides out of the card to a quiet button under it (the mock-up's placement), not a filled button inside the card.

- **[rides/ImportPage.md] (small)** Design: rides/ImportPage.md:5 "activities read of the total" — the mock-up shows the count as the card's number with a unit under it (ImportPage.html:7).
  Code: app/lib/features/rides/import/import_screen.dart:71-77 shows a `LinearProgressIndicator` and a plain text line for "n of m", with no `kpi` number.
  Fix: Render the count done and the total as the card's `kpi` number with a caption unit ("412" + "of 618 activities read") above the progress bar.

- **[rides/ImportPage.md] (small)** Design: README.md:89 "A sub-page's title row carries the parent's name as a `caption` above the `page-title`." The mock-up shows the crumb Rides (ImportPage.html:7).
  Code: app/lib/features/rides/import/import_screen.dart:35-37 passes only `title` and `maxWidth` to `PageScaffold`.
  Fix: Pass `parent: l10n.navRides` to `PageScaffold`.

## Task 3: Progress

- **[progress/ProgressDesktop.md] (large)** Design: progress/ProgressDesktop.md:3 "it answers only 'How am I today and this week', and every card opens the sub-page that answers the next question"; the layout ends at row 1 (four stat cards) and row 2 (Distance per week) (:10-15).
  Code: app/lib/features/progress/progress_screen.dart:227-325 builds an `analysis` list (RiderCard, FTP suggestion, heart-rate notes, FTP reminder, TrainingSummary, IntensityCard, EfficiencyCard, PowerSummary) and :450-469 draws them on the overview for a training rider, plus a `MoreDetails` fold for a simple one. TrainingSummary/CardGrid carry the Fitness and Power sub-pages' charts.
  Fix: Remove the analysis list and the fold from the overview so the page is title row, sport chips, the four stat cards and the distance-per-week card; keep those cards on `/progress/fitness` and `/progress/power` where the design puts them.

- **[progress/ProgressDesktop.md] (small)** Design: progress/ProgressDesktop.md:15 "Row 2, full width: Distance per week with its period control -> Totals. It grows to the bottom of the window"; the mock-up adds the 'Totals ->' link (ProgressDesktop.html:108).
  Code: app/lib/features/progress/progress_screen.dart:425-447 draws an `AppCard` with a title, the `SegmentedControl` and `TotalsChart` and no link to `/progress/totals`, and it does not grow to fill the window.
  Fix: Add a `StatCard`-style link ("All weeks ->") to the chart card that opens `/progress/totals`.

- **[progress/ProgressPhone.md] (small)** Design: progress/ProgressPhone.md:8 "Title row: `page-title`, the sport as one chip that opens a sheet ('Road v'), and the `...` menu." The mock-up puts the chip in the header (ProgressPhone.html:33-40).
  Code: app/lib/features/progress/progress_screen.dart:330-390 draws `ProgressTabs` first (:332) and the sport `ActionChip` as page content after them (:376-390); the header (`primaryAction`/`menu`, :326-329) has no chip.
  Fix: Move the single sport chip into the header row beside the `...` menu (as part of the title row), and keep only the tabs as content under it.

- **[progress/ProgressPhone.md] (small)** Design: progress/ProgressPhone.md:10 "Form and This week side by side (smaller `kpi`, no link: the whole card opens its page)".
  Code: app/lib/features/progress/progress_screen.dart:157-195 builds both cards with a `link:` and `onLink:`, and :396-411 lays them out side by side with the standard `StatCard` (link visible, card itself not tappable).
  Fix: On a phone pass no `link`/`onLink` for Form and This week, use a smaller number size, and wrap each card in an `InkWell`/`GestureDetector` that opens `/progress/fitness` and `/progress/totals`.

- **[progress/PowerPage.md] (small)** Design: progress/PowerPage.md:10 "Best efforts as a table (duration, watts, W/kg) with a link to all durations." The mock-up shows 'All durations ->' under the table (PowerPage.html:39).
  Code: app/lib/features/progress/power_summary.dart:250-266 draws the Best efforts card with `_BestEffortsTable` only; no link.
  Fix: Add a link under the table naming every duration (the StatCard link style, `accent-strong` with an arrow) and wire it to the full-durations view or `/progress/power`.

- **[progress/TotalsPage.md] (medium)** Design: progress/TotalsPage.md:10 "Full width table: one row per period ... Numbers right-aligned with tabular figures." The mock-up is a table with Week, Rides, Distance, Moving time, Climbing columns (TotalsPage.html:19-30).
  Code: app/lib/features/progress/totals_screen.dart:417-471 renders a `ListTile` per period: the rides/time/climbing numbers are folded into one subtitle string and only the distance is a trailing number.
  Fix: Render the rows as a table with one column per number (rides, distance, moving time, climbing), right-aligned and tabular, with the current period's row on `accent-soft`.

- **[progress/WellbeingPage.md] (medium)** Design: progress/WellbeingPage.md:9 "Halves: **Readiness** (score, state chip, advice, and the note that it is a guide, not a medical measure) and **Why 50**: one row per factor ..." The mock-up draws two cards side by side (WellbeingPage.html:11-22).
  Code: app/lib/features/progress/readiness_card.dart:55-115 puts the score, the band and the factor rows in one card titled Readiness (no "Why N" card), and app/lib/features/progress/wellbeing_screen.dart:596-607 stacks that card above the how-you-feel card in one column.
  Fix: Split `ReadinessCard` into a Readiness card (score, state chip, advice, the not-medical note) and a "Why <score>" card holding the factor rows, and lay the two out as halves with a `CardGrid(columns: 2, tabletColumns: 2)`.

- **[progress/WellbeingPage.md] (small)** Design: progress/WellbeingPage.md:9 "the score" is the card's big number and a state chip follows it; the mock-up shows `kpi` 50 with a 'Go easy' chip (WellbeingPage.html:13).
  Code: app/lib/features/progress/readiness_card.dart:62-96 draws the score inside a `CircleAvatar` at `headlineMedium`, and the state as coloured `titleSmall` text rather than a chip.
  Fix: Draw the score in `VelomineText.of(context).kpi` with the band as the `StatCard` state chip (`state`/`stateCare`).

- **[progress/WellbeingPage.md] (medium)** Design: progress/WellbeingPage.md:9 "one row per factor with its value and its effect drawn from a centre line, `accent-strong` when it raises the score, `signal` when it lowers it, with the signed number."
  Code: app/lib/features/progress/readiness_card.dart:151-171 draws each factor as a text row: label, value and the signed number, with no centre-line effect bar.
  Fix: Add the effect bar per factor (a centre line with a bar drawn right in `accentStrong` and left in `signal`, width from the effect) beside the signed number, as the mock-up draws it.

- **[progress/WellbeingPage.md] (medium)** Design: progress/WellbeingPage.md:10 "Full width: **How you feel** over 14 days" — the mock-up draws it as a chart (WellbeingPage.html:27).
  Code: app/lib/features/progress/wellbeing_card.dart:353-361 lists the 14 days as text rows (`_HistoryRow`), not a chart.
  Fix: Draw the 14-day series with a shared chart (`AreaChart` or a small line painter) and keep the rows (or the latest scores) beneath it.

## Task 4: Goals and notifications

- **[goals/GoalsPage.md] (small)** Design: goals/GoalsPage.md:11 "No goals yet: the empty state with a sentence and the same Add goal button."
  Code: app/lib/features/goals/goals_screen.dart:118-125 draws `EmptyState` with a message and an icon only; the Add goal action exists just in the header (:90-95).
  Fix: Pass the same Add goal `FilledButton` as `EmptyState`'s `action` on the no-goals branch.

- **[goals/EventsPage.md] (small)** Design: goals/EventsPage.md:5 "Add an event is the page's one action"; controls/Controls.md:8 "Main action: one filled pill per screen, `accent` with `on-accent` ... in the page header."
  Code: app/lib/features/progress/events_screen.dart:99-104 uses `FilledButton.tonalIcon` for `add-event`, i.e. the tonal (secondary) surface rather than the filled accent pill.
  Fix: Use `FilledButton.icon` (the same main-action button as the other pages) for Add an event.

- **[goals/EventsPage.md] (small)** Design: goals/EventsPage.md:7 "A past event links the ride that was it when it is the rider's only ride that day."
  Code: app/lib/features/progress/events_screen.dart:73-88: `_linkRide` always opens `showRidePicker` with every ride of that day; there is no single-ride shortcut, so the rider picks among one.
  Fix: When `ridesOn(event.date)` returns exactly one ride, link it directly (`linkRide`) instead of opening the picker; keep the picker for two or more.

- **[inbox/NotificationsPage.md] (medium)** Design: inbox/NotificationsPage.md:5 "Unread first, then grouped by area." The mock-up draws an Unread card above the Rides, Bikes and Club cards (NotificationsPage.html:8-12).
  Code: app/lib/features/notifications/notifications_screen.dart:46-54 sorts unread first but then buckets by area, so an unread bike warning can sit under read ride notifications.
  Fix: Render an unread group first (all unread, newest first) and then the area groups of the read ones, so every unread row is above every read row.

- **[inbox/NotificationsPage.md] (medium)** Design: inbox/NotificationsPage.md:5 and the mock-up's one card per area with rows inside (NotificationsPage.html:8-18).
  Code: app/lib/features/notifications/notifications_screen.dart:94-101 draws a `SectionHeading` per group and then one `AppCard` per notification (:150-168), so every row is its own card.
  Fix: Draw each group as one `SectionCard`/`AppCard` whose children are the rows (divided by `hairline`), instead of a card per notification.

## Task 5: Shared map and navigation

- **[maps/RouteMap.md] (small)** Design: maps/RouteMap.md:11 "The info card is `glass`, `radius-xl`, inset by `space-lg`."
  Code: app/lib/features/rides/detail/route_map.dart:165-169 insets the card by `AppSpacing.sm`, and app/lib/core/widgets/glass_card.dart:33/44 uses `AppRadius.medium` instead of `AppRadius.xlarge` (radius-xl).
  Fix: Inset the card by `AppSpacing.lg` on all sides and draw `GlassCard` with `AppRadius.xlarge`.

- **[navigation/NavPill.md] (small)** Design: navigation/NavPill.md:8 "`glass` with `blur-glass` and `shadow-float`"; README.md:23 "The nav pill ... use `glass` with `blur-glass`".
  Code: app/lib/core/widgets/floating_nav_pill.dart:60-63 paints `scheme.surfaceContainer` at 82 % (or 96 % with no blur) instead of the `glass` token, and :14-24 gives Android and the web no blur at all (`pillBlurOf` returns 0).
  Fix: Fill the pill with `VelomineColors.of(context).glass` and keep the blur everywhere it can run, falling back to the opaque glass colour rather than to `surfaceContainer`.

- **[navigation/Sidebar.md] (small)** Design: README.md:87 "From 1200 dp: the sidebar on `card`"; navigation/Sidebar.md:3 gives the same three parts.
  Code: app/lib/home_shell.dart:676-678 fills the expanded sidebar with `scheme.surfaceContainerLow`, and :449-450 gives the 600-1199 dp rail the same fill, neither of which is the `card` surface (`surfaceContainer` in app/lib/core/theme.dart:244).
  Fix: Paint both the rail and the sidebar with `scheme.surfaceContainer` (the `card` token), as `AppCard` does.

## Task 6: Club

- **[club/AddRoutePage.md] (small)** Design: AddRoutePage.html:7 draws the source choice as a segmented control: `<div class="vm-seg" role="group">From one of my rides / From a GPX file</div>`; AGENTS.md:127 "every segmented choice is a `SegmentedControl`".
  Code: route_forms.dart:107 and :113 build the two-way choice from `ChoiceChip`s.
  Fix: Replace the two ChoiceChips with one `SegmentedControl<String>(segments: [ButtonSegment(value: 'ride', label: Text(l10n.addRouteFromRide)), ButtonSegment(value: 'file', label: Text(l10n.addRouteFromFile))], selected: _source, onChanged: (v) => setState(() => _source = v))`.

- **[club/AddRoutePage.md] (small)** Design: AddRoutePage.html:7 shows Surface as a segmented control of Road / Gravel / Mountain / Mixed under the label "Surface".
  Code: route_forms.dart:208 uses a `DropdownButtonFormField<String>` for the surface.
  Fix: Replace the dropdown with `SegmentedControl<String>(segments: [for (final s in routeSurfaceIds) ButtonSegment(value: s, label: Text(routeSurfaceName(l10n, s)))], selected: _surface, onChanged: ...)`.

- **[club/AthletePage.md] (small)** Design: AthletePage.html:7 lays the athlete's shared parts out in a two-card grid (`<div class="vm-grid2">` holding the Rides card and the Wellbeing card).
  Code: coach_athlete_screen.dart:41 passes every card to `PageScaffold(children: ...)` as a plain list, so each shared part is stacked in one column at every width.
  Fix: Collect the shared-part cards (`TrainingSummary`, `DailyLoadCard`, `TrainingLoadCard`, `PowerSummary`, `_CoachWellbeingCard`, the rides card) and render them through `CardGrid(columns: 2, tabletColumns: 2, children: [...])` instead of as flat `children`.

- **[club/AthletePage.md] (small)** Design: AthletePage.md:5 "each shared part has its card"; a titled card in the page flow is a `SectionCard` (AGENTS.md:127, README.md:64), so the Wellbeing card reads title, sentence, rows.
  Code: coach_athlete_screen.dart:142-148 builds the wellbeing card as an `AppCard` with a `SectionHeading` nested inside it, so the card has an in-body heading instead of a card title row.
  Fix: Make `_CoachWellbeingCard` a `SectionCard(title: l10n.coachWellbeing, description: l10n.coachWellbeingNoNotes, children: [...the check-in and RPE rows...])` and drop the inner `SectionHeading` and `SizedBox`.

- **[club/AthletesPage.md] (medium)** Design: AthletesPage.html:7 gives every athlete row a set of badges of what that athlete shares (`<span class="vm-badges"><span class="vm-badge">Rides</span>…`), always visible beside the name.
  Code: coach_athletes_screen.dart:68-73 only mentions the sharing in the subtitle, and only when `athlete.lastRideAt == null && athlete.tss7 == null`; an athlete with a recent ride shows no sharing at all.
  Fix: Always build a trailing `Wrap` of `Chip`s from `athlete.sharesRides / sharesAnalytics / sharesWellbeing` on the `ListTile` (line 57) and keep the last-ride/TSS line as the subtitle alone.

- **[club/AthletesPage.md] (small)** Design: AthletesPage.html:7 puts every athlete as a row inside one list card (README.md:66, "List card: title, rows …").
  Code: coach_athletes_screen.dart:51-80 wraps each athlete in its own `AppCard` inside a `CardGrid`.
  Fix: Render one `AppCard(padding: EdgeInsets.zero, child: Column(children: [...one ListTile per athlete...]))` instead of a card per athlete.

- **[club/CalendarFeedPage.md] (medium)** Design: CalendarFeedPage.md:5 "Replace and Stop the address (danger) are in the `⋯` menu, both confirmed."
  Code: calendar_feed_screen.dart:42-68 puts only Stop (destructive, confirmed) in the `PageMenu`; Replace is a visible `OutlinedButton` on the page at :135-152.
  Fix: Add a non-destructive `PageMenuEntry(key: Key('replace-calendar-address'), icon: Icons.refresh, label: l10n.calendarReplace, onSelected: …confirmDestructive→notifier.create())` as the first entry, ahead of the destructive Stop, and delete the page button.

- **[club/CalendarFeedPage.md] (small)** Design: CalendarFeedPage.html:7 puts the address, its note and Copy inside a card titled "Your address" ("<h3 class=\"vm-card-title card-title\">Your address</h3>").
  Code: calendar_feed_screen.dart:70-83 wraps them in a titleless `AppCard` (padding zero plus an inner padding of `AppSpacing.lg`), so the card has no title row and a padding that is not the card's `space-xl`.
  Fix: Use `SectionCard(title: l10n.calendarAddressTitle, description: l10n.calendarHelp, children: [SelectableText(address), Text(l10n.calendarShownOnce), the copy button])` and add the one new string.

- **[club/ClubPage.md] (medium)** Design: ClubPage.md:5 "The header names the club"; ClubPage.html:7 shows the crumb "Club" with `<h1 class="page-title">Velo Club Demo</h1>`.
  Code: club_screen.dart:303-304 sets the header to `title: l10n.navClub` ("Club") and `subtitle: l10n.clubSubtitle`; the club's name appears only inside `ClubHeroCard` (widgets/club_hero_card.dart:26).
  Fix: Pass `title: club.name, parent: l10n.navClub, subtitle: l10n.clubSubtitle` to `PageScaffold` and drop the name row from `ClubHeroCard`.

- **[club/ClubPage.md] (small)** Design: ClubPage.html:7 titles the two list cards "Rides" and "Routes" once each (a card title, no heading above it).
  Code: club_screen.dart:342 and :344 add a `SectionHeading` with exactly the title the `SectionCard` right below it renders again (`_ridesSection` at :467, `_routesSection` at :521 both use `l10n.clubRidesTitle` / `l10n.clubRoutesTitle`), so "Rides" and "Routes" each appear twice in a row.
  Fix: Delete the `SectionHeading`s at :342 and :344 and let the `SectionCard` titles head those sections (as `SectionHeading(title: l10n.clubMembers)` at :346 does for the titleless members card).

- **[club/ClubPage.md] (medium)** Design: ClubPage.md:6 "Owner and coaches see the plan, the join code, join requests, members …, the location and the athletes; riders see the rides, the routes and what they share."
  Code: club_screen.dart:282-287 adds `ClubMembersCard` for every role, so a plain rider also gets the members list.
  Fix: Wrap the members card in `if (coach)` so only the owner and coaches see it.

- **[club/ClubPage.md] (small)** Design: ClubPage.html:7 orders the owner's cards join requests → members → what you share → club location (after the top row of club, plan and join code).
  Code: club_screen.dart:249-289 orders them plan → join requests → join code → location (:270) → members (:282) → athletes → what you share (:289).
  Fix: Reorder the `manage` list to join requests, members, sharing, location (with plan and join code kept together), matching the mock-up.

- **[club/ClubRideDetailPage.md] (medium)** Design: ClubRideDetailPage.md:5 "I'm in / Take me out is the page's one action. Edit ride and Cancel ride (last, in danger red, confirmed) are in the `⋯` menu for the planner"; ClubRideDetailPage.html:7 puts `<button>I'm in</button>` in `.vm-acts` and the `⋯` beside it.
  Code: club_ride_detail_screen.dart:110-124 gives the header slot to Edit (`primaryAction: detail.canPlan ? OutlinedButton… 'edit-ride'`), leaves the menu only Cancel (:125-142), and renders the join/leave button at the bottom of the content instead (:215-222, `_joinButton` :227).
  Fix: Set `primaryAction: detail.canPlan ? null : _joinButton(...)` and add `PageMenuEntry(key: Key('edit-ride'), icon: Icons.edit_outlined, label: l10n.rideEdit, onSelected: onEdit)` as the first entry of the planner's menu, ahead of the destructive Cancel; drop the trailing `Wrap` of the join button.

- **[club/ClubRideDetailPage.md] (small)** Design: ClubRideDetailPage.md:6 "Pace, no-drop and places, then the meeting point, the route, notes and who is in."
  Code: club_ride_detail_screen.dart:171 renders the route `SectionCard` before the meeting point `SectionCard` at :185.
  Fix: Move the route card (lines 170-184) after the meeting point card.

- **[club/ClubRideDetailPage.md] (small)** Design: ClubRideDetailPage.html:7 states the day, time and planner once, in the header subtitle (`<p class="sub body">Sat 22 Nov 2026 · 08:30 · Planned by Marco</p>`); README.md:19 "A card never repeats a number shown elsewhere on the page".
  Code: club_ride_detail_screen.dart:108 already prints the start date and time as the header subtitle, then :150 prints the same string again as the first child, while "Planned by" sits in the pace line at :156.
  Fix: Delete the `Text(rideStartText(...))` at :150 and move `l10n.ridePlannedBy(...)` into the header `subtitle` next to the start text.

- **[club/ClubRidesPage.md] (medium)** Design: ClubRidesPage.md:5 "Each ride shows its date block, meeting time and place, pace and the rider's own state"; ClubRidesPage.html:7 renders `<span class="vm-date"><b>22</b><span>Nov</span></span>` as the leading block of every row.
  Code: club_rides_screen.dart:145 gives every row the same `leading: const Icon(Icons.event)`; the day and month are buried inside the subtitle string built at :160-166.
  Fix: Replace the leading icon with a date block built from the ride's local start (`ride.startsAt` + `utcOffsetMinutes`): a `Column` with the day number in `titleMedium` and the short month in `bodySmall`/muted, and drop the date from the subtitle.

- **[club/ClubRidesPage.md] (medium)** Design: ClubRidesPage.html:7 keeps the rows of each list inside one card titled "Coming up" and one titled "Just happened" (README.md:66 list card).
  Code: club_rides_screen.dart:103-110 uses `SectionHeading`s and then one `AppCard` per ride (`_RideCard` at :118-140), so each ride is its own card.
  Fix: Group the upcoming rides into one `SectionCard(title: l10n.ridesUpcoming, children: [...tiles...])` and the past ones into another with `l10n.ridesPast`, building a `ListTile` per ride instead of an `AppCard`.

- **[club/CoachRidePage.md] (medium)** Design: CoachRidePage.html:7 puts the numbers in a card: `<article class="vm-card"><h3 class="vm-card-title card-title">Numbers</h3>` with the big figures and the tiles inside it.
  Code: coach_ride_screen.dart:65-107 renders the `StatFigure`s in a bare `Wrap` directly on the page, with no `AppCard`/`SectionCard` and no card title.
  Fix: Wrap the figure `Wrap` in `AppCard(child: Column(...))` (or a `SectionCard(title: l10n.rideNumbers)`) so the numbers read as one card, and split the four headline figures from the rest as the mock-up does.

- **[club/CoachRidePage.md] (small)** Design: CoachRidePage.html:7 places the map directly under the header, before the numbers card.
  Code: coach_ride_screen.dart:116 draws `RouteMap` after the figures and after the lap table (:113).
  Fix: Move the route map / `l10n.routeNotShared` branch above the numbers block.

- **[club/CoachRidePage.md] (small)** Design: CoachRidePage.html:7 sets the ride's name as the page title with the athlete as the caption above it (`<p class="crumb caption">Giulia Ferri</p><h1 class="page-title">Sunday long ride</h1>`).
  Code: coach_ride_screen.dart:50-52 uses `dateTime(ride.startTime ?? ride.uploadedAt)` as the title and passes no `parent`.
  Fix: Pass `parent: <athlete display name>` and `title: ride.title` (falling back to the date when the ride has no title).

- **[club/JoinClubPage.md] (small)** Design: JoinClubPage.html:7 holds the form in one card: `<article class="vm-card"><div class="vm-form">` with the Join code field, the Join button and "Continue without a club".
  Code: join_club_screen.dart:79-101 puts the code field and the skip button bare on the page (no card), and Join lives in the pinned `bottomAction` (:68).
  Fix: Wrap the field, the inline error and the skip button in a `SectionCard`/`AppCard` as the mock-up's form card.

- **[club/NearbyClubsPage.md] (small)** Design: NearbyClubsPage.html:7 lists the clubs as rows of one card (`<article class="vm-card"><div class="vm-rows">` with four `.vm-row`s), README.md:66.
  Code: nearby_clubs_screen.dart:299 renders one `_ClubRow` per club, and `_ClubRow` (:364) is an `AppCard` each.
  Fix: Render the clubs as `ListTile`s inside one `AppCard(padding: EdgeInsets.zero, child: Column(...))` (or a `SectionCard`) instead of one card per club.

- **[club/NoClubPage.md] (medium)** Design: NoClubPage.md:5 "Three ways forward, side by side"; NoClubPage.html:7 gives each way its own card in `<div class="vm-grid3">` — a title, a glyph, one sentence and one button per card.
  Code: club_screen.dart:404-426 puts the three ways in a single `AppCard` as a `ToolbarRow` of a `FilledButton`, an `OutlinedButton` and a `TextButton`, with no per-way sentence.
  Fix: Render three `SectionCard`s (title = clubs near you / join with a code / start a club, description = the explanatory sentence, one button each) inside `CardGrid(columns: 3, tabletColumns: 1)`, as in the mock-up.

- **[club/NoClubPage.md] (small)** Design: NoClubPage.md:5 "A pending join request shows \"Waiting for {club}\" with Cancel request instead" — instead of the three ways.
  Code: club_screen.dart:430 shows the pending-request `SectionCard` in addition to the three-ways card at :397-428, which stays on screen.
  Fix: Make the two exclusive: `if (nearby.request case final request?) <pending card> else <three ways>`.

- **[club/PlanRidePage.md] (small)** Design: PlanRidePage.html:7 puts Pace in a segmented control (`<div class="vm-seg" role="group">Easy / Steady / Fast</div>`); AGENTS.md:127 "every segmented choice is a `SegmentedControl`".
  Code: plan_ride_screen.dart:295-313 uses a `DropdownButtonFormField<String>` for the pace.
  Fix: Replace it with `SegmentedControl<String>(segments: [for (final p in ridePaceIds) ButtonSegment(value: p, label: Text(ridePaceName(l10n, p)))], selected: _pace, onChanged: (v) => setState(() => _pace = v))`.

- **[club/PlanRidePage.md] (medium)** Design: PlanRidePage.html:7 splits the form into three cards — the header fields, "Meeting point" (name, a map with the pin, "Pick the meeting point on the map") and "Details".
  Code: plan_ride_screen.dart:224-349 puts every field in a single `AppCard`, and the meeting point is only an `OutlinedButton` whose label is the raw coordinates (:267-283); no map of the chosen point is shown.
  Fix: Split the one card into the mock-up's three cards, and under the meeting-point name show the chosen point on `MeetingMap` (already in `club_ride_widgets.dart`) with the pick button under it.

- **[club/RouteDetailPage.md] (medium)** Design: RouteDetailPage.md:5 "Download GPX is the page's one action. Edit, Remove from club and Delete for good (danger, confirmed) are in the `⋯` menu, for the member who added it"; RouteDetailPage.html:7 shows `<button>Download GPX</button>` in `.vm-acts` before the `⋯`.
  Code: route_detail_screen.dart:188-203 makes Edit the header `primaryAction` (a filled button), keeps Download GPX as a `FilledButton.tonalIcon` inside the content (:242-249) next to a Share button (:251), and the menu (:119-177) has no Edit entry.
  Fix: Set `primaryAction` to a `FilledButton.icon` (`Icons.download`, `l10n.routeOpenGpx`). The ⋯ menu holds Edit (for the member who added it), Share, then the destructive entries after the divider. Remove the Download and Share buttons from the content.

- **[club/RouteDetailPage.md] (medium)** Design: RouteDetailPage.html:7 lays the page out as the map, then a "The route" card with four figures (distance, climbing, surface, club rides), then a "Description" card.
  Code: route_detail_screen.dart:208-230 renders a bare `Chip` for the surface, one `Text` joining distance/surface/author/date, the description as plain body text, then the map at :231.
  Fix: Keep the map at the top, then a `SectionCard(title: l10n.routeTheRoute)` holding `StatFigure`s for distance, climbing, surface and club-ride count, then a `SectionCard(title: l10n.routeDescription)` with the description; drop the loose chip and metadata line (the header subtitle already carries the distance line).

- **[club/StartClubPage.md] (medium)** Design: StartClubPage.html:7 splits the form into a "Name" card and a "Club location" card (each `<article class="vm-card">` with a card title).
  Code: start_club_screen.dart:101-152 puts the name field and the location controls bare on the page, with the location group announced by a raw `Text(l10n.clubLocation, style: titleMedium)` at :114.
  Fix: Use `SectionCard(title: l10n.startClubName, children: [name field])` and `SectionCard(title: l10n.clubLocation, description: l10n.clubLocationHelp, children: [map, toggle, change button])`.

- **[club/StartClubPage.md] (small)** Design: StartClubPage.html:7 shows the chosen club location on a map with a pin (`<div class="vm-mapbox short">` … `<circle class="pin">`).
  Code: start_club_screen.dart:121-135 shows only the sentence `clubLocationOnMap` / `clubLocationNone` and the pick button; no map of the chosen point is drawn.
  Fix: Render `MeetingMap(latitude: point.latitude, longitude: point.longitude, tileUrl: widget.tileUrl, attribution: widget.attribution)` under the pick button when `point != null`.

## Task 7: Routes library

The library shows each route's line on the dimmed map. The list response has no geometry today, so this task adds it: a simplified line (at most ~100 points, the same simplification the route detail uses if one exists; otherwise every n-th point) on each item of the routes list response, declared in the endpoint's `Description`, then `tools/generate-api-client.sh`. Add a server test that the list carries the line and that a route of another club is still not listed (isolation). Draw it with the existing `RoutePreview`/map widgets.

- **[club/RoutesPage.md] (large)** Design: RoutesPage.md:5 "… a grid of route cards, each with the line drawn on the dimmed map"; RoutesPage.html:7 draws the route polyline on `var(--map-ground)` inside every card.
  Code: routes_screen.dart:143-156 makes each card a `ListTile` with `leading: const Icon(Icons.route)` and no map preview.
  Fix: Build each grid card as `AppCard(padding: EdgeInsets.zero, child: Column(children: [RoutePreview(latitude: ..., longitude: ..., showElevation: false, tileUrl: ..., attribution: ...), title, surface chip, caption, ...]))`; the route geometry has to come with the list response or be loaded per card through `routeDetailViewModelProvider`.

- **[club/RoutesPage.md] (small)** Design: RoutesPage.html:7 draws the sort as a segmented control (`<div class="vm-seg">Newest / Shortest / Longest</div>`) after the surface chips; AGENTS.md:127 "every segmented choice is a `SegmentedControl`".
  Code: routes_screen.dart:42-57 uses a `DropdownButton<String>` for the sort and places it before the surface `ChoiceChip`s at :59.
  Fix: Use `SegmentedControl<String>(segments: [...routeSortIds...], selected: s.sort, onChanged: ...)` and put it after the chips.

## Task 8: Bikes

- **[bikes/BikeDetailPage.md] (medium)** Design: BikeDetailPage.md:6-7 list the parts and their wear first, then "Service reminders with Done, then the service log"; BikeDetailPage.html:7 renders Totals, the part groups, the Service card and the Service log card in that order.
  Code: bike_detail_screen.dart:354 inserts `ServiceSection(id: id)` before the parts heading at :355, so the reminders and the whole service log come above the parts.
  Fix: Move `ServiceSection(id: id)` after the part groups (after line 385's `for (final group in groupParts(...))` block) and keep the replaced-parts block after it.

- **[bikes/BikeDetailPage.md] (medium)** Design: BikeDetailPage.html:7 opens with a "Totals" card holding four figures — distance, rides, moving time and parts.
  Code: bike_detail_screen.dart:340-347 renders three `StatFigure`s in a bare `Wrap` with no card, and never shows the part count.
  Fix: Wrap them in `SectionCard(title: l10n.totals, children: [Wrap of four StatFigures including `l10n.parts` = `current.length`])`.

- **[bikes/BikeDetailPage.md] (medium)** Design: BikeDetailPage.md:6 "Parts are grouped (drivetrain, wheels, brakes…) with their wear as a bar: warning when getting worn, danger when worn out, always with the words"; BikeDetailPage.html:7 renders one card per group, a row per part with `2,140 of 3,000 km`, a right-aligned `71% worn` caption and the bar.
  Code: bike_detail_screen.dart:370 renders the group name as a bare `Text(..., style: labelLarge)` and then one `AppCard` per part (:434-…); the wear percentage exists only in the `Semantics` label at :480-484, never as visible text.
  Fix: Turn each group into a `SectionCard(title: group.name, children: [one row per part])`, with the part's name and spec line, a right-aligned `l10n.wearPercent` caption above the `LinearProgressIndicator`, and the existing status words beside the name.

- **[bikes/BikeDetailPage.md] (large)** Design: BikeDetailPage.html:7 keeps the reminders as rows of one "Service" card (icon, name, `Due · 312 of 300 km · last done 2 Nov`, a Done button, a `⋯` for the rare actions) and the log entries as rows of one "Service log" card, with "Add reminder" / "Add entry" links at the bottom of each card.
  Code: service_section.dart:225 and :266 announce the two groups with bare `Text` titles, every reminder (:251) and every entry (:323) is its own `AppCard`, and the add actions sit as `FilledButton`/`OutlinedButton` in the title row (:226-231).
  Fix: Make "Service" and "Service log" two `SectionCard`s whose children are rows (no `AppCard` per reminder/entry), and move `Add reminder` / `Add entry` to a `TextButton.icon` at the end of each card's children.

- **[bikes/BikesPage.md] (small)** Design: BikesPage.html:7 carries the parent as a caption above the title (`<p class="crumb caption">Profile</p><h1 class="page-title">Bikes</h1>`); README.md:89 "A sub-page's title row carries the parent's name as a `caption` above the `page-title`".
  Code: bikes_screen.dart:66-69 passes only `title: l10n.navBikes` and `subtitle: l10n.bikesSubtitle` — no `parent`.
  Fix: Add `parent: l10n.navProfile` to the `PageScaffold`.

## Task 9: Profile

- **[profile/PrivacyPage.md] (medium)** Design: Two titled cards: "Hide the start and end" and "Saved places", each a card head with a card-title (profile/PrivacyPage.html:7).
  Code: No cards: the two groups are separated by SectionHeading + Divider on the bare page (privacy_screen.dart:190-191, 224-225).
  Fix: Wrap each group in SectionCard(title: l10n.privacyTrimTitle / l10n.privacyZonesTitle), children = its fields/rows + its sentence, and drop the SectionHeadings and Dividers.

- **[profile/PrivacyPage.md] (medium)** Design: One Save block button after both cards, the page's single action (profile/PrivacyPage.html:7).
  Code: Save is a right-aligned FilledButton inside the trimming block, above the saved-places section (privacy_screen.dart:216-222).
  Fix: Pass Save as PageScaffold.bottomAction (BottomActionBar.button, key 'privacy-save') and remove the in-page FilledButton.

- **[profile/PrivacyPage.md] (small)** Design: Title row: caption "Profile" above the title "Ride privacy", and the sentence "What your club and coaches never see of your routes..." as the page sub (profile/PrivacyPage.html:7).
  Code: PageScaffold(title: l10n.privacyTitle) with no parent and no subtitle; the sentence is the first child of the content (privacy_screen.dart:173-189).
  Fix: Add parent: l10n.profileTitle and subtitle: l10n.privacyHelp to the PageScaffold and delete the Text(l10n.privacyHelp) child.

- **[profile/ProfilePage.md] (medium)** Design: A card of its own, "Preferences", holding Time zone, Weeks start on, Language and Units (profile/ProfilePage.html:7; guideline enumerates "Sections in cards: athlete, preferences, riding ..." profile/ProfilePage.md:6).
  Code: Time zone, first day, language and units are the last fields of the Athlete card (profile_screen.dart:439-440 card, fields at 545, 552, 570, 597).
  Fix: Move the time-zone/AppTextField, the first-day DropdownButtonFormField, the language and the units controls into a second SectionCard(title: l10n.preferences).

- **[profile/ProfilePage.md] (medium)** Design: Language is a two-value segmented control (Italiano | English) and Units likewise (Metric (km, kg) | Imperial (miles, lb)) (profile/ProfilePage.html:7, class vm-seg).
  Code: Both are DropdownButtonFormField<String>/<Units> (profile_screen.dart:570, 597).
  Fix: Replace both dropdowns with SegmentedControl<String>/<Units> (core/widgets/segmented_control.dart) with one segment per option.

- **[profile/ProfilePage.md] (small)** Design: Athlete field order: Name, Year of birth, FTP, Weight, Maximum heart rate, Threshold heart rate (profile/ProfilePage.html:7).
  Code: Name, FTP (+source note), Weight, Year of birth, Max HR, Threshold HR (profile_screen.dart:442, 450, 462, 476 ...).
  Fix: Move the _number('profile-birth-year', ...) call to sit directly after the Name AppTextField and before the FTP field.

- **[profile/ProfilePage.md] (medium)** Design: A "Riding" card with two rows: My bikes (with its "Due soon" badge) and Ride privacy (profile/ProfilePage.html:7).
  Code: No Riding card: My bikes is a standalone full-width AppCard above the grid (profile_screen.dart:831) and Ride privacy is a row inside the card titled l10n.privacy (privacy card at 693, row at 697-706).
  Fix: Add SectionCard(title: l10n.riding) containing the _MyBikesRow as a row plus the ride-privacy _SettingsRow, and remove the standalone _MyBikesRow above the CardGrid.

- **[profile/ProfilePage.md] (medium)** Design: A "Help improve Velomine" card: one sentence, then the Crash reports and Performance and usage data switches (profile/ProfilePage.html:7).
  Code: The telemetry switches live inside the card titled l10n.privacy ("Privacy"), sharing it with the ride-privacy row, with l10n.telemetryHelp as the card description (profile_screen.dart:693-741).
  Fix: Split the telemetry switches and l10n.telemetryHelp into their own SectionCard(title: l10n.telemetryTitle) placed after Notifications.

- **[profile/ProfilePage.md] (small)** Design: "Notifications" card with three switches (Email me my notifications, Account and club emails, Ride and gear emails), all drawn as toggles (profile/ProfilePage.html:7, three vm-switch/vm-toggle).
  Code: One SwitchListTile then two CheckboxListTile (profile_screen.dart:657, 671, 681).
  Fix: Make the account and training rows SwitchListTile like the first one.

- **[profile/ProfilePage.md] (small)** Design: "Your data": a sentence and a quiet button with a download icon, "Download my data" (profile/ProfilePage.html:7).
  Code: The download is a chevron settings row (_SettingsRow with Icons.download) inside the Your data card (profile_screen.dart:786-799).
  Fix: Render it as an OutlinedButton.icon (Icons.download, l10n.downloadMyData) under the card's sentence instead of a _SettingsRow.

- **[profile/ProfilePage.md] (small)** Design: The page's sections, in order: athlete, preferences, riding, notifications, telemetry opt-in, supporter, account, your data (profile/ProfilePage.md:6).
  Code: Two extra cards the design does not have: ZonesCard (the editable zone bounds) at profile_screen.dart:653 and SoloTrialBadge at 744.
  Fix: Keep the `ZonesCard`, placed right after the Athlete card, as the guideline now says. Move `SoloTrialBadge` inside the Supporter card. No other card the guideline does not list.

- **[profile/ProfilePage.md] (small)** Design: Caption "Account" above the page title "Profile" (profile/ProfilePage.html:7).
  Code: PageScaffold(title: l10n.profileTitle, menu: ...) with no parent (profile_screen.dart:801-805).
  Fix: Add parent: l10n.accountMenu (the caption the mock-up draws) to the PageScaffold.

- **[profile/ProfilePage.md] (small)** Design: The Supporter card shows the licence itself: "Supporter no. 128 · 3 Oct 2026" (profile/ProfilePage.html:7).
  Code: The badge is labelled l10n.supporter only, with an extra replay IconButton and a hide-badge switch (supporter_badge.dart:233, 236-249; wrapper at profile_screen.dart:748-758).
  Fix: In the Supporter card, label the badge with `l10n.supporterSerialNumber(...)` (as the celebration screen does), keep the hide-badge switch and turn the replay `IconButton` into a 'Play the celebration again' link, as the mock-up now draws it.

- **[profile/SessionsPage.md] (small)** Design: Caption "Profile" above the title "Devices and sessions" (profile/SessionsPage.html:7).
  Code: PageScaffold(title: l10n.sessionsTitle, subtitle: l10n.sessionsIntro) with no parent (sessions_screen.dart:37-39).
  Fix: Add parent: l10n.profileTitle to the PageScaffold.

- **[profile/SupporterPage.md] (medium)** Design: The page title is "Become a supporter", the key sentence is the page sub, and the card has no title: it holds only the Licence key field (profile/SupporterPage.html:7).
  Code: The header title is l10n.supporterSignInTitle ("Supporter") with no subtitle, and the card is titled l10n.supporterBecome ("Become a supporter") with l10n.supporterKeyHelp as its description (supporter_activation_screen.dart:74, 94-95).
  Fix: Use l10n.supporterBecome as the PageScaffold title, pass l10n.supporterKeyHelp as subtitle, and give the SectionCard no title (a plain AppCard with the AppTextField).

- **[profile/SupporterPage.md] (small)** Design: Caption "Profile" above the title (profile/SupporterPage.html:7).
  Code: PageScaffold without parent (supporter_activation_screen.dart:72-74).
  Fix: Add parent: l10n.profileTitle to the PageScaffold.

- **[profile/TwoFactorPage.md] (medium)** Design: Two cards, "Set up an authenticator" and "Recovery codes", each with a card-title and its sentence (profile/TwoFactorPage.html:7).
  Code: No cards: a SectionHeading of the state ("On"/"Off"), then bare Texts, fields and a Divider straight on the page (two_factor_screen.dart:85-95, 145-160).
  Fix: Use SectionCard(title: l10n.twoFactorSetupTitle, description: l10n.twoFactorKeyHelp) for the key/code/password group and SectionCard(title: l10n.twoFactorRecoveryTitle, description: l10n.twoFactorRecoveryHelp) for the codes, dropping the Divider.

- **[profile/TwoFactorPage.md] (small)** Design: Caption "Profile" above the title "Two-factor sign-in" (profile/TwoFactorPage.html:7).
  Code: PageScaffold(title: l10n.twoFactorTitle) with no parent (two_factor_screen.dart:51-52).
  Fix: Add parent: l10n.profileTitle to the PageScaffold.

## Task 10: Sign-in

- **[sign-in/ForgotPasswordPage.md] (small)** Design: Caption "Password help" above the page title "Reset your password" (sign-in/ForgotPasswordPage.html:7, caption vm-muted).
  Code: AuthPage renders the wordmark, then the title; there is no caption line and no parameter for one (auth_page.dart:82-94).
  Fix: Add a `caption` parameter to AuthPage rendered as a muted caption Text above the title, and pass l10n.forgotPasswordCaption ("Password help") from ForgotPasswordScreen.

- **[sign-in/RegisterPage.md] (small)** Design: Field order: Name, Email, Password (sign-in/RegisterPage.html:7).
  Code: Email first, then Name, then Password (register_screen.dart:98-129).
  Fix: Swap the Email and Name TextFields so Name comes first.

- **[sign-in/RegisterPage.md] (small)** Design: Caption "New account" above the page title "Create an account" (sign-in/RegisterPage.html:7).
  Code: No caption: AuthPage goes straight from the wordmark to the title (auth_page.dart:82-94; register_screen.dart:65-66 passes only title).
  Fix: Add the AuthPage `caption` parameter (see ForgotPasswordPage) and pass l10n.registerCaption ("New account").

- **[sign-in/RegisterPage.md] (small)** Design: The page title is the page-title style (sign-in/RegisterPage.html:7, class page-title; README: "The scale: page-title 40 ... Do not add sizes").
  Code: AuthPage draws the step title with textTheme.headlineMedium, a size outside the scale, while every other page title is drawn by PageScaffold with headlineLarge (auth_page.dart:90-94).
  Fix: Use the same title style as PageScaffold (Theme.of(context).textTheme.headlineLarge) for the AuthPage title.

- **[sign-in/ResetPasswordPage.md] (small)** Design: The page offers two fields and one button: "Set new password" (sign-in/ResetPasswordPage.html:7).
  Code: An extra "Forgot password?" TextButton sits under the fields (reset_password_screen.dart:98-102).
  Fix: Delete the reset-ask-again TextButton so the form ends at the pinned primary button.

- **[sign-in/ResetPasswordPage.md] (small)** Design: Caption "New password" above the page title "Choose a new password" (sign-in/ResetPasswordPage.html:7).
  Code: No caption line in AuthPage (auth_page.dart:82-94).
  Fix: Add the AuthPage `caption` parameter and pass l10n.resetPasswordCaption ("New password").

- **[sign-in/ServerSetupPhone.md] (small)** Design: Caption "Server" above the page title "Which server does your club use?" (sign-in/ServerSetupPhone.html:7).
  Code: No caption line in AuthPage (auth_page.dart:82-94; server_setup_screen.dart:117-119 passes only title/help).
  Fix: Add the AuthPage `caption` parameter and pass l10n.setupCaption ("Server").

- **[sign-in/SignInPage.md] (medium)** Design: The brand, then the page title "Welcome back", then the sentence "Sign in to see your rides and your form." (sign-in/SignInPage.html:7).
  Code: The wordmark is drawn as the only heading: SignInScreen passes help but no title, and AuthPage renders nothing between the wordmark and the sentence (sign_in_screen.dart:91-92; auth_page.dart:90-94).
  Fix: Pass title: l10n.signInTitle ("Welcome back") to AuthPage in SignInScreen so the page has its title above the help sentence.

- **[sign-in/SignInPage.md] (small)** Design: "Stay logged in" is a switch (sign-in/SignInPage.html:7, vm-switch with vm-toggle).
  Code: CheckboxListTile (sign_in_screen.dart:173-181).
  Fix: Replace it with a SwitchListTile (contentPadding: EdgeInsets.zero) keeping the 'stay-signed-in' key.

## Task 11: Admin

- **[admin/AdminAccountsPage.md] (medium)** Design: Two cards with card-titles: "Waiting for approval" and "Accounts" (admin/AdminAccountsPage.html:7, vm-card-head + card-title).
  Code: The titles are bare Text(titleMedium) above unlabelled AppCards (accounts_tab.dart:171-173 and 182, 191-193 and 196).
  Fix: Use SectionCard(title: l10n.waitingForApproval) and SectionCard(title: l10n.adminAccounts) and drop the two Text headings.

- **[admin/AdminAccountsPage.md] (small)** Design: An empty list is an empty state; the design has no bare sentence (admin/AdminAccountsPage.html:7 draws the card with its rows).
  Code: When nothing is waiting it renders a plain Text(l10n.nonePending) (accounts_tab.dart:176-179), not the shared EmptyState.
  Fix: Render EmptyState(message: l10n.nonePending, ...) in place of the Align+Text.

- **[admin/AdminClubsPage.md] (medium)** Design: Each club row carries its state as a badge ("Active", "Plan ended") next to the name, and the row's only actions are the ⋯ menu's Edit plan and Change owner (admin/AdminClubsPage.html:7; guideline admin/AdminClubsPage.md:5).
  Code: Every club row ends with a SwitchListTile "Active" that turns the club on and off, and there is no state badge (clubs_tab.dart:190-200).
  Fix: Replace the SwitchListTile with a state badge on the row (a Chip/badge reading l10n.adminClubActive or the plan-ended text) and keep the activate/deactivate action out of the row, or move it into the row's PageMenu as a confirmed entry.

- **[admin/AdminOverviewPage.md] (medium)** Design: Two cards with card-titles: "People and rides" (accounts, waiting, locked, rides) and "Server" (ride files, versions, re-read counts) (admin/AdminOverviewPage.html:7).
  Code: One undivided AppCard of nine identical ListTiles, with no titles and no grouping (overview_tab.dart:44-70).
  Fix: Split into SectionCard(title: peopleAndRides) with the four count tiles and SectionCard(title: server) with the five server tiles.

- **[admin/AdminOverviewPage.md] (small)** Design: A failed load is an error state with a way to try again (README visual language; every page).
  Code: A failed load renders a bare centred Text with the failure and no retry (overview_tab.dart:22-31).
  Fix: Render ErrorState(message: failureText(...), onRetry: ...) instead of the Text.

- **[admin/AdminSettingsPage.md] (medium)** Design: Three cards with card-titles: "Sign-up", "Set with environment variables", "Shared parts catalogue" (admin/AdminSettingsPage.html:7; guideline admin/AdminSettingsPage.md:5).
  Code: The three groups are bare Text(titleMedium) headings separated by Dividers, with their switches, sentences and buttons loose on the page (settings_tab.dart:56-57, 105, 161).
  Fix: Wrap each group in SectionCard(title: l10n.signUp / l10n.envVariables / l10n.sharedCatalogue, description: the group's sentence) and remove the Text headings and Dividers.

- **[admin/AdminSettingsPage.md] (small)** Design: The email and single sign-on facts are rows inside the "Set with environment variables" card, with the test-email button (admin/AdminSettingsPage.html:7, vm-rows/vm-row).
  Code: Each fact is its own AppCard through _StatusCard, so the section becomes a stack of unlabelled cards (settings_tab.dart:134, 148, 167; _StatusCard at 232-250).
  Fix: Render the two statuses as rows (ListTile with leading icon, title, detail subtitle) inside the environment SectionCard instead of separate AppCards.

- **[admin/AdminSettingsPage.md] (small)** Design: A failed load is an error state with a way to try again (README visual language; every page).
  Code: The failed load renders a bare centred Text with the failure and no retry (settings_tab.dart:33-42).
  Fix: Render ErrorState(message: failureText(...), onRetry: ...) instead of the Text.

## Done when
Every item is done or listed as skipped with a reason, each task is its own commit, the full `just check` passes once at the end, and the git status is clean. Report: the commits, the `just check` result (server and app test counts), and the skipped items with reasons.
