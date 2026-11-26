---
title: Every screen matches its design page
milestone: 0.1.35
area: design
status: ready
value: rider
effort: 6 days
risk: medium  # the shared widgets and the theme, so every screen moves at once
---

## Story

As a rider, I want every screen to look and read the way the approved design says, so the app feels like one product and no number, size or word is off.

An audit of all 45 routes over 44 screen classes, the 55 pages under `docs/design/pages/` and all 136 widget-bearing files found four root causes and about forty page-level debts. The root causes explain most of the difference, so fixing them first is cheaper than forty small fixes.

**The authority is the design page and these criteria; the evidence is the ledger.** Every deviation, every dead end and the library investigations are in [`docs/design/audit-2026-11-25.md`](../design/audit-2026-11-25.md) — read the section for the area you are about to touch, and mark an entry done there when you fix it. Reproduce a deviation before changing a page, and drop any criterion the code turns out not to support.

## Acceptance criteria

**A · The owner's three decisions, written before the code that follows them**

- [x] **One body size, 15, everywhere**: the design's `body` is 15 and there is no 14; both body slots carry it, and a test fails if either drifts. *Landed:* `docs/design/pages/README.md` (Type), `docs/design/tokens.json`, `app/lib/core/theme.dart`, `app/test/design_tokens_test.dart`.
- [x] **The page menu is never centred**: the page's main action and its ⋯ sit at the end of the title row, level with the title, at every width; the scaffold owns the placement and a test holds it at 390 and 1300 dp. *Landed:* `docs/design/pages/README.md` (Navigation), `.pi/skills/ui-build/SKILL.md`, `app/lib/core/widgets/page_scaffold.dart`, `app/test/page_scaffold_test.dart`.
- [x] **Charts are drawn by `fl_chart`, not by hand.** Approved by the owner on 25 Nov because it is free (MIT); it lives behind our own chart widgets, and every colour, label and tick still comes from the design tokens. *Landed:* the `AGENTS.md` row, `app/pubspec.yaml`, `app/lib/core/widgets/bar_chart.dart`; the per-file work list is
[`docs/design/audit-2026-11-25.md` §6b](../design/audit-2026-11-25.md).
- [ ] Nothing else in this story starts until each of those three is written down — in the design page, the dependency doc or this file — and not after the code.

**0 · The check itself, so the rest can be seen**

- [x] `dart run tools/screenshots.dart --routes … --widths 390,600,820,1300` signs in once to `http://localhost:8080` from `just up` and writes one non-blank PNG per route and width into `.dev/screens/` — **added and run against the dev stack in this change**.
- [x] `--theme day|night` renders that theme; without it the browser's own scheme decides. **Done.**
- [x] A route that redirects (a destination whose setting is off, such as `/training` with auto training off) is reported as such, never passed off as that page. **In the tool; keep it.**
- [ ] Chrome is in the dev container at a pinned version, named in `AGENTS.md`'s dependency table with its reason, and `docs/development.md` says how to take screenshots and which dev account they use.
- [ ] `.pi/skills/ui-build/SKILL.md` step 2 names that command, and a missing Chrome or script is reported as a failed check, never as a pass.

**1 · The four root causes**

- [ ] In a grid, the cards of one row are the same height and a row is full; 600–1199 dp shows the two columns the size classes name. **Blocked, not skipped:** `IntrinsicHeight` overflowed by 10 px on the Club page at 1300 dp, and a one-row `Table` broke hit testing (a tap on `open-athletes` missed; 61 tests). Two causes were suspected and **neither reproduces on Flutter 3.50** (probes with a `Wrap` of chips, a `ListTile` with a trailing `Wrap`, and a `LinearProgressIndicator` inside `IntrinsicHeight`): the 10 px is still undiagnosed, so the next attempt bisects the Club grid's cards before choosing a mechanism. The framework's own note still holds — *"the child will get less height than it otherwise would"* — and `Table`'s doc still says a single row is a `Row`, which the hit-test failure bore out. The column change cannot ship alone either — at 600 dp half-width rows crash `ListTile` ("trailing widget consumes the entire tile width", club members) — so it lands with the Phase 4 row rework, and the next attempt starts from those two dead ends.
- [x] Every number a rider reads is formatted for the language (`69,7 km` in Italian, `69.7 km` in English) from one shared helper. **Done:** `decimal()` is public in `core/format.dart`, the 24 display sites use it, `format_test.dart` holds the Italian comma; text-field values that are parsed back keep `toStringAsFixed`.
- [ ] No feature builds its own card, labelled field or badge where `AppCard`, `AppTextField` or `AppBadge` exists.
- [ ] `just ui-dupes` reports zero for `Card(`, `TextField(`, `TextStyle(`, `Color(0x`, `EdgeInsets.all(n)` and `spacing: n` outside `core/widgets/`.

**1b · Every chart drawn by `fl_chart`**

- [x] `BarChart` is fl_chart's, behind the same API: gradient bars with `radius-sm` tops, the current bar in `accent-strong` and past bars `bar-muted`, round ticks ≤ 4, the label step from the width, the dashed average, the empty state, and value labels from `BarChartRodLabel` (1.2.0) rather than a tooltip. No touch tooltip is shown. **Done**, seen at 1300 dp.
- [ ] `AreaChart` is fl_chart's `LineChart`: 2 px line, area faded 35 % → 0, the latest point marked with its value, round ticks ≤ 4, the empty state, the same semantics label.
- [ ] `GoalGauge` is fl_chart's `GaugeChart` (shipped in 1.3.0): `accent-strong` arc on `track`, 14 px, clamped at 100 %, a Reached chip on `accent-soft`, no hand-drawn arc.
- [ ] The Fitness chart is fl_chart's: fitness as a line with a faded area, fatigue dashed in `series-power`, form as bars round a zero line (`accent-strong` above, `signal` below) — which also ends the legend collision at 390 dp.
- [ ] The power curve and the ride page's signal charts are fl_chart's `LineChart`; `series-*` colours, the cursor and the empty state stay as they are.
- [ ] Nothing outside `app/lib/core/widgets/` imports `fl_chart`, no chart relies on fl_chart's own theme, and the decorative painters (route, celebration, check, chevron, readiness effect) stay as they are.
- [ ] The two nits recorded in the ledger's F12 are settled: the "1" tick touching the average line, and x labels now appearing for periods with no rides.

**2 · The chrome every screen shares**

- [x] The nav pill and the sidebar label destinations at `nav-label` 15 px and never shrink them. **Done:** `navLabel` in `VelomineText` (15/500, asserted in `design_tokens_test`), the pill's `FittedBox` removed, the sidebar's sections, destinations and collapsed rail switched over, and the rail widened 88 → 104 so "Progress"/"Progressi" fits on one line (seen at 820 dp).
- [ ] The sidebar's foot ends on the privacy note, Profile and Settings; the theme control is not there.
- [x] Every Progress sub-page carries the "Progress" caption at every width. **Done:** fitness, power, totals and wellbeing; seen on the 390 dp screenshot.
- [ ] A page's sub-line wraps instead of ending in an ellipsis.
- [ ] Every data widget's first load is `LoadingState`, and every empty list, table or chart is `EmptyState` — no skeletons with literal sizes, no `LinearProgressIndicator`, no blank page, no header-only table. *Started:* events (LoadingState), Progress's chart skeleton (tokens), the service log's nested empty state (`framed: false`). Remaining: fitness, power, totals, wellbeing, notifications, calendar feed, admin accounts and clubs, supporter, bike templates, header-only table.

**3 · The latest feature: auto training**

- [ ] The goal card names the rider's chosen goal with that goal's own line, and says when the plan was set.
- [ ] A moved day says which day it moved from.
- [ ] The setup's event goal offers the rider's events, and "Add an event" opens the events page.
- [ ] The setup's sentence and its feedback link sit under the page title, as its mock-up draws them.
- [ ] The next-week preview is read-only.

**3b · The rule sweep, so the whole tree is covered at once**

The sweep in [`audit-2026-11-25.md` §10](../design/audit-2026-11-25.md) crawls all 288 files against
every rule of `.pi/skills/ui-build/SKILL.md` and lists what it found beyond the page debts below:
admin's literal 720/640 widths, three `fontSize` literals, the map chip's `Colors.white`, 8 `ChoiceChip`
controls, 5 strings missing from the `.arb` files, 13 hand-rolled `DateFormat`s, `BarChart.currentIndex`
never passed, 4 in-page spinners, 20 screens without a state and 6 without a width test. Work them with
the page debts, not as a separate pass.

**4 · The page debts, each against its own design page**

- [ ] Rides, ride, import, record: the drop area is on the page; the ride card is `AppCard` with the date as its caption; the import card is titled "Reading the archive"; recorded rides are rows in one card with a badge per upload state; the ride-type chips are the mock-up's five; zone rows are named; laps use the mock-up's columns; the ride's bike is the Bike card.
- [ ] Progress, Fitness, Power, Totals, Wellbeing: the Form card carries its state word; readiness, form and period show an empty state rather than vanishing; the sport filter is not also in the ⋯ menu; intensity is three labelled rows; card titles are `card-title`; the FTP estimate and its button live in the FTP card; "Best efforts" links to all durations; the table has its heading, tabular figures and the average on the chart line; "How you feel" has its sentence and the 14-day list; the "Why" card has its sentence; and the Fitness chart's legend no longer lets "Form" run into "Fatigue" (seen at 390 dp).
- [ ] Club, no club, join, nearby, start, club rides, club ride, plan a ride: the hero card carries the club's name; upcoming rides are date-block rows with pace and the rider's own state; no second filled action; members have avatars, role badges and "Show all N"; the location card has its map with the switch before the button; a form's failure is `InlineError`; not-found and error branches are inside a `PageScaffold`.
- [ ] Routes, route, add route: the "Club routes" caption; the map after the title; no "Not shared" badge; the add-route heading and the ride's own name; the privacy note under the map; no distance printed twice.
- [ ] Athletes, athlete, coach ride: avatars, share badges under the name, row dividers; the mock-up's chip order and card set; wellbeing as the mock-up's table.
- [ ] Bikes and bike detail: the wear bar as the mock-up draws it; part actions in the row's menu; no extra "Replaced parts" card.
- [ ] Profile, privacy, sessions, two-factor, supporter: athlete fields in pairs; the time-zone picker; each row's state subtitle; the narrow measure; two-factor's field order and a copyable key; the supporter page's loading state; the celebration as its mock-up draws it.
- [ ] Notifications, calendar feed, admin: "Mark all read" always visible; a loading state; the narrow measure; the big-number and tile cards; avatars and role badges; one caption line per club; no literal widths.

**5 · The design pages that are wrong, settled one way**

- [ ] `SessionPage.md` (the gentle base block's targets), `RideDetailPage.md` against its own mock-up (the Bike card), `ClubPage.html` (the club's name twice), `GoalGauge.md` (a 30 px percentage the type scale forbids), `RecordingLivePhone` (full-width or two-column Pause and Stop), `AdminClubsPage.md` (Activate and Change owner), and the week's distance appearing on both the Progress card and the current bar are each decided in one change, page and code together.

**6 · Tests**

- [ ] Every screen has `<Screen>_ShouldNotOverflow_WhenWidthIs<N>` at 390, 600, 820 and 1300 dp; `ImportScreen`, `EditRouteScreen`, `BikeDetailScreen`, `RoutesScreen`, `VerifyEmailScreen` and `SupporterCelebrationScreen` gain theirs.
- [ ] `CardGrid` has a test for equal heights and for the medium column count; the theme has one for the 15 px body.
- [ ] Screenshots for every changed page at the four widths, compared with its mock-up, are in the change's report.
- [ ] `just check` passes.

## Work list — every open point, and the files it edits

This replaces the coarse file grouping. **One row per audit point** (`docs/design/audit-2026-11-25.md`
§4, §5, §6b and §10), with the files that must change and the test that proves it. Status: ⬜ open,
⛔ blocked, ✅ done. A shared fix is listed once, in the row that owns it.

### A. Systemic (S1–S15) and the rule sweep (R1–R17)

| # | Point | Files to edit | Test |
|---|---|---|---|
| S1 ⛔ | `CardGrid`: equal heights, no half row | `app/lib/core/widgets/card_grid.dart` (custom `RenderBox`) | **new** `app/test/card_grid_test.dart` |
| S2 ⛔ | two columns at 600–1199 dp | `card_grid.dart`, then the eight call sites: `features/bikes/bikes_screen.dart`, `features/club/club_screen.dart`, `features/routes/routes_screen.dart`, `features/progress/power_summary.dart`, `features/rides/rides_screen.dart`, `features/profile/profile_screen.dart` | each screen's width test |
| S3 ⬜ | first loads that are not `LoadingState` (see per-area rows P2, F1, W1, O5, N3, E4) | `features/progress/progress_screen.dart`, `features/rides/detail/ride_detail_screen.dart`, `features/progress/training_summary.dart` (`days.length < 2` blank chart), `features/admin/accounts_tab.dart`, `features/admin/clubs_tab.dart`, `features/notifications/notifications_screen.dart`, `features/calendar/calendar_feed_screen.dart`, `features/supporter/supporter_activation_screen.dart` | `progress_test.dart`, `notifications_test.dart`, `admin_test.dart`, `loading_state_test.dart` |
| S4 ⬜ | shared `AppTextField` bypassed (19 files) | `app/lib/core/widgets/app_text_field.dart` (grow a variant), then `features/progress/events.dart`, `features/profile/two_factor_screen.dart`, `features/privacy/privacy_screen.dart`, `features/admin/clubs_tab.dart`, `features/goals/goals.dart`, `features/club/nearby_clubs_screen.dart`, `features/club/join_club_screen.dart`, `features/rides/ride_filters.dart`, `features/rides/detail/ride_feel_card.dart`, `features/auth/password_field.dart`, `features/auth/forgot_password_screen.dart` | `app_text_field_test.dart` |
| S5 ⬜ | hand-built `Card(` | `features/rides/rides_screen.dart`, `features/progress/ftp_reminder_card.dart`, `features/club/location_picker.dart` → `core/widgets/app_card.dart` | `rides_test.dart` |
| S6 ⬜ | hand-built badges | `features/profile/solo_trial_badge.dart`, `features/supporter/supporter_badge.dart` → `core/widgets/badge.dart` | `badge_test.dart`, `solo_trial_test.dart` |
| S7 ⬜ | floating elements not glass | `features/recording/live_ride_banner.dart`, `features/rides/bulk/ride_drop_area.dart`, `features/rides/detail/full_route_map.dart` → `core/widgets/glass_card.dart` | `recording_test.dart`, `bulk_upload_test.dart` |
| S8 ⬜ | literal measures where tokens exist | `core/theme.dart`, `core/tokens.dart` (add the missing tokens), then `features/club/widgets/club_plan_card.dart`, `features/rides/detail/ride_detail_screen.dart`, `features/rides/detail/lap_table.dart`, `features/rides/detail/route_map.dart`, `core/widgets/chart_chrome.dart`, `features/progress/totals_screen.dart`, `features/admin/clubs_tab.dart`, `features/admin/settings_tab.dart`, `features/progress/power_summary.dart`, `features/notifications/notifications_screen.dart`, `features/profile/two_factor_screen.dart`, `features/bikes/bike_detail_screen.dart`, `features/progress/training_summary.dart`, `features/progress/wellbeing_card.dart`, `app/lib/home_shell.dart` | `design_tokens_test.dart` |
| S9 ⬜ | sport filters are `ChoiceChip`, not `FilterChip` | `features/rides/rides_screen.dart`, `features/rides/rides_screen.dart` (sheet), `features/progress/progress_screen.dart`, `features/routes/routes_screen.dart`; then `docs/design/pages/controls/Controls.md` | `rides_test.dart`, `progress_test.dart`, `club_rides_routes_test.dart` |
| S10 ⬜ | typographic quotes hardcoded | `features/club/club_screen.dart`, `features/club/widgets/club_requests_card.dart`, `features/club/nearby_clubs_screen.dart` → new keys in `l10n/app_en.arb`, `l10n/app_it.arb` | `l10n_test.dart` |
| S11 ⬜ | two date formats on one page | `core/format.dart` (one helper per page kind), `features/progress/totals_screen.dart`, `features/calendar/club_ride_widgets.dart`, `features/training/session_screen.dart` | `format_test.dart` |
| S12 ⬜ | a number shown twice | `features/club/widgets/club_hero_card.dart`, `features/club/widgets/club_plan_card.dart`, `features/rides/detail/ride_detail_screen.dart`, `features/progress/progress_screen.dart` (Power FTP is a design conflict, see §7) | `club_test.dart`, `ride_detail_test.dart` |
| S13 ⬜ | sidebar foot lacks Settings, has an unlisted theme button | `app/lib/home_shell.dart`; `docs/design/pages/navigation/Sidebar.html` (design first) | `home_shell_test.dart` |
| S14 ⬜ | width-test gaps | `app/test/import_test.dart`, `rides_test.dart`, `bikes_test.dart`, `club_rides_routes_test.dart`, `verify_email_test.dart`, `supporter_test.dart`, `recording_test.dart`, plus `card_grid_test.dart` and a 599/600 and 1199/1200 boundary test in `page_scaffold_test.dart` | those files |
| S15 ⬜ | undocumented UI | **new** pages under `docs/design/pages/` for `LocationPickerScreen` and the unrouted sheets/banners (`features/club/location_picker.dart`, `features/recording/recorder_settings.dart`, `features/rides/ride_title.dart`, `features/rides/ride_text_sheet.dart`, `features/rides/bulk/bulk_upload_card.dart`, `features/rides/bulk/ride_drop_area.dart`, `features/recording/live_ride_banner.dart`) | — |
| R1 ⬜ | `admin` literal widths | `features/admin/clubs_tab.dart` (`720` → `AppLayout.contentNarrow`), `features/admin/settings_tab.dart` (`640`) | `admin_test.dart` |
| R2 ⬜ | three `fontSize` literals | `core/widgets/chart_chrome.dart` (11 → axis 12), `core/widgets/source_note.dart` (12 → caption 13), `features/progress/power_summary.dart` (11 → caption) | `design_tokens_test.dart` |
| R3 ⬜ | map chip's unstyled colours | `core/widgets/chart_chrome.dart` → `VelomineColors`; design page needs the chip (Q4) | `design_tokens_test.dart` |
| R4 ⬜ | 5 single-choice `ChoiceChip` sites | `features/routes/routes_screen.dart`, `features/club/nearby_clubs_screen.dart`, `features/recording/recording_screen.dart`, `features/training/session_screen.dart`, `features/admin/admin_screen.dart` → `core/widgets/segmented_control.dart` or `progress_tabs.dart` | those screens' tests |
| R5 ⬜ | 4 strings missing from `.arb` | `features/rides/detail/route_map.dart`, `features/recording/recording_screen.dart`, `features/rides/detail/ride_detail_screen.dart`, `features/profile/zones_card.dart`, `features/progress/wellbeing_card.dart` + `l10n/app_en.arb`, `l10n/app_it.arb` | `l10n_test.dart` |
| R6 ⬜ | 13 hand-rolled `DateFormat`s | `core/format.dart` (add `weekdayShort`, `monthShort`, `dayNumber`), then `features/calendar/club_ride_widgets.dart`, `features/training/session_screen.dart`, `features/notifications/notifications_text.dart`, `features/training/training_text.dart` | `format_test.dart` |
| R7 ⬜ | `BarChart.currentIndex` never passed | `features/progress/totals_chart.dart` (pass the real current period), `core/widgets/bar_chart.dart` (make it required or derive it) | `bar_chart_test.dart`, `totals_test.dart` |
| R8 ⬜ | 4 in-page `CircularProgressIndicator`s | `features/auth/verify_email_screen.dart`, `features/rides/detail/ride_detail_screen.dart`, `features/rides/rides_screen.dart` → `LoadingState` / button state | `verify_email_test.dart`, `rides_test.dart` |
| R9 ⬜ | web tap targets shrink (`materialTapTargetSize` unset) | `core/theme.dart` (one line), then re-run the width tests | `design_tokens_test.dart`, `segmented_control_test.dart` |
| R10 ⬜ | a view calls a data source | `features/auth/verify_email_screen.dart` (`:40,49`) + **new** `features/auth/verify_email_view_model.dart` beside `features/auth/auth_view_models.dart` | `verify_email_test.dart` |

### B. Charts (C1–C7, from §6b)

| # | Point | Files to edit | Test |
|---|---|---|---|
| C1 ✅ | `BarChart` on `fl_chart` | `core/widgets/bar_chart.dart`, `app/pubspec.yaml`, `AGENTS.md` | `bar_chart_test.dart` |
| C2 ⬜ | `AreaChart` on `LineChart` | `core/widgets/area_chart.dart`; callers `features/progress/efficiency_card.dart`, `features/progress/wellbeing_card.dart` | `bar_chart_test.dart`, `efficiency_test.dart`, `wellbeing_test.dart` |
| C3 ⬜ | `GoalGauge` on `GaugeChart` | `core/widgets/goal_gauge.dart`; caller `features/goals/goals.dart` | `goals_test.dart` (the painter cast at `:227` goes) |
| C4 ⬜ | Fitness chart on `LineChart` (+ legend overlap at 390) | `features/progress/training_summary.dart` | `fitness_test.dart` |
| C5 ⬜ | power curve on `LineChart` | `features/progress/power_summary.dart` | `power_test.dart` |
| C6 ⬜ | ride signal charts on `LineChart` | `features/rides/detail/series_chart.dart` | `ride_detail_test.dart`, `chart_semantics_test.dart` |
| C7 ⬜ | readiness ± bar | `features/progress/readiness_card.dart` (only if it reads as a chart) | `fitness_test.dart` |

### C. Training

| # | Point | Files to edit | Test |
|---|---|---|---|
| T1 ⬜ | suggested goal's reason under any goal; `trainingGoalLine` dead | `features/training/training_screen.dart`, `features/training/training_text.dart` | `training_page_test.dart` |
| T2 ⬜ | no "Set on <date>" | server `src/Velomine.Server/Features/Training/` (+ migration in `Data/Migrations/`), `app/packages/velomine_api/` (regenerate), `features/training/training_screen.dart`, `training_text.dart` | `training_page_test.dart` + a server test |
| T3 ⬜ | "Moved" badge loses the day | server `Features/Training/` + migration, `app/packages/velomine_api/`, `features/training/training_screen.dart` | `training_page_test.dart` |
| T4 ⬜ | setup's event goal is a dead end | `features/training/training_setup_screen.dart`, `training_setup_view_model.dart`, `features/progress/events.dart` | `training_setup_test.dart` |
| T5 ⬜ | intro sentence in the body, not the sub-line | `features/training/training_setup_screen.dart` | `training_setup_test.dart` |
| T6 ⬜ | next-week preview rows tappable | `features/training/training_screen.dart` | `training_page_test.dart` |
| T7 ⬜ | base-block targets disagree with `SessionPage.md` | `docs/design/pages/training/SessionPage.md` (design first), `features/training/session_screen.dart`, `training_text.dart` | `training_page_test.dart` |

### D. Rides, import and recording

| # | Point | Files to edit | Test |
|---|---|---|---|
| D1 ⬜ | drop area only exists as a drag overlay | `features/rides/rides_screen.dart`, `features/rides/bulk/ride_drop_area.dart`, `features/rides/bulk/drop_source.dart` | `rides_test.dart`, `bulk_upload_test.dart` |
| D2 ⬜ | ride card is a hand-built `Card` with `lg` padding | `features/rides/rides_screen.dart` → `core/widgets/app_card.dart` | `rides_test.dart` |
| D3 ⬜ | date is its own line, not a right-hand caption | `features/rides/rides_screen.dart`, `core/format.dart` | `rides_test.dart` |
| D4 ⬜ | empty state shows import buttons | `features/rides/rides_screen.dart` | `rides_test.dart` |
| D5 ⬜ | filter row lacks Indoor/Commute | `features/rides/ride_filters.dart`, `features/rides/rides_screen.dart` | `rides_test.dart` |
| D6 ⬜ | detail: no header subtitle, file name/device, "Add a description" | `features/rides/detail/ride_detail_screen.dart`, `features/rides/detail/ride_detail_state.dart` | `ride_detail_test.dart` |
| D7 ⬜ | event is a card, not a badge | `features/rides/detail/ride_detail_screen.dart` | `ride_detail_test.dart` |
| D8 ⬜ | charts bare, not in one "Along the ride" card | `features/rides/detail/ride_detail_screen.dart`, `core/widgets/section_card.dart` | `ride_detail_test.dart` |
| D9 ⬜ | ride area fill 12 %, design says 35 %→0 | `core/widgets/area_chart.dart` (with C2) | `bar_chart_test.dart` |
| D10 ⬜ | zones card prints the total twice, "Z2" not "Z2 Endurance" | `features/rides/detail/ride_detail_screen.dart`, `features/profile/zones_card.dart`, `core/heart_rate_zones.dart` (add `zoneName`), `l10n/app_en.arb`, `l10n/app_it.arb` | `ride_detail_test.dart`, `profile_zones_test.dart` |
| D11 ⬜ | laps column order and caption size | `features/rides/detail/lap_table.dart` | `ride_detail_test.dart` |
| D12 ⚠️ | bike as a dropdown where the mock-up has a Bike card | `docs/design/pages/rides/RideDetailPage.md` vs its `.html` (design first), then `features/rides/detail/ride_detail_screen.dart` | `ride_detail_test.dart` |
| D13 ⬜ | import card title repeats the page title | `features/rides/import/import_screen.dart`, `l10n/app_en.arb`, `l10n/app_it.arb` | `import_test.dart` |
| D14 ⬜ | outcome rows plain, only after the import stops | `features/rides/import/import_screen.dart` | `import_test.dart` |
| D15 ⬜ | "On this phone" is a heading over one card per ride | `features/rides/incoming/incoming_rides_area.dart`, `features/rides/import/import_screen.dart` | `incoming_rides_test.dart` |
| D16 ⬜ | row title is a full timestamp; upload state in the caption | `features/rides/incoming/incoming_rides_area.dart`, `features/rides/bulk/bulk_upload_card.dart` | `incoming_rides_test.dart`, `bulk_upload_test.dart` |
| D17 ⬜ | ride-type chips add Track and Virtual | `features/rides/ride_type_chips.dart`, `features/recording/recording_screen.dart` | `recording_test.dart` |
| D18 ⬜ | live card lacks the ride name, "Moving" and the screen-off sentence | `features/recording/recording_screen.dart`, `features/recording/live_ride_banner.dart`, `l10n/app_en.arb`, `l10n/app_it.arb` | `recording_test.dart` |

### E. Progress, fitness, power, totals, wellbeing

| # | Point | Files to edit | Test |
|---|---|---|---|
| P1 ⬜ | Form card has no state word ("Building") | `features/progress/training_summary.dart`, `l10n/app_en.arb`, `l10n/app_it.arb` | `fitness_test.dart` |
| P2 ⬜ | readiness, form and period vanish instead of an empty state | `features/progress/progress_screen.dart`, `readiness_card.dart`, `training_summary.dart` | `progress_test.dart`, `fitness_test.dart` |
| P3 ⬜ | `⋯` repeats the sport filter the chips draw | `features/progress/progress_screen.dart` | `progress_test.dart` |
| P4 ⬜ | chart card does not grow to the window bottom | `features/progress/progress_screen.dart`, `core/tokens.dart` | `progress_test.dart` |
| P5 ⬜ | 12-week average sentence loses ride count and time | `features/progress/training_summary.dart`, `l10n/app_en.arb`, `l10n/app_it.arb` | `fitness_test.dart` |
| F1 ⬜ | Fitness has no `⋯` menu | `features/progress/fitness_screen.dart` | `fitness_test.dart` |
| F2 ⬜ | intensity is one stacked bar; design has three labelled rows | `features/progress/intensity_card.dart`, `core/widgets/bar_chart.dart` | `fitness_test.dart` |
| F3 ⬜ | card titles at `titleSmall` | `features/progress/fitness_screen.dart`, `power_summary.dart`, `core/theme.dart` | `design_tokens_test.dart` |
| F4 ⬜ | extra monotony/strain cautions and a `HeartRateNoteCard` | `features/progress/training_summary.dart`, `core/widgets/heart_rate_note_card.dart`, `features/progress/fitness_screen.dart` | `fitness_test.dart` |
| F5 ⬜ | trend sentence differs from the guideline | `features/progress/training_summary.dart`, `l10n/app_en.arb`, `l10n/app_it.arb` | `fitness_test.dart` |
| F6 ⬜ | legend overlap at 390 dp | `features/progress/training_summary.dart` (with C4) | `fitness_test.dart` |
| W1 ⬜ | FTP estimate and "Use 2xx W" live outside the FTP card | `features/progress/power_summary.dart`, `features/progress/ftp_reminder_card.dart`, `core/widgets/ftp_suggestion_card.dart` | `power_test.dart`, `ftp_history_test.dart` |
| W2 ⬜ | "Best efforts" has no all-durations link | `features/progress/power_summary.dart`, `l10n/app_en.arb`, `l10n/app_it.arb` | `power_test.dart` |
| W3 ⬜ | empty copy and "Current FTP" title differ | `features/progress/power_summary.dart`, `l10n/app_en.arb`, `l10n/app_it.arb` | `power_test.dart` |
| O1 ⬜ | table has no heading, says "Weeks" for "Week" | `features/progress/totals_screen.dart`, `l10n/app_en.arb`, `l10n/app_it.arb` | `totals_test.dart` |
| O2 ⬜ | cells lack tabular figures | `features/progress/totals_screen.dart`, `core/theme.dart` (a `figures` text style) | `totals_test.dart` |
| O3 ⬜ | the average sits in the title, not on the chart line | `features/progress/totals_screen.dart`, `features/progress/totals_chart.dart`, `core/widgets/bar_chart.dart` | `totals_test.dart`, `bar_chart_test.dart` |
| O4 ⬜ | current row half-styled, no table empty state | `features/progress/totals_screen.dart` | `totals_test.dart` |
| O5 ⬜ | two date formats on Totals | `features/progress/totals_screen.dart`, `core/format.dart` | `totals_test.dart`, `format_test.dart` |
| E1 ⬜ | "Why" card lacks its sentence | `features/progress/wellbeing_screen.dart`, `l10n/app_en.arb`, `l10n/app_it.arb` | `wellbeing_test.dart` |
| E2 ⬜ | no "How you feel" sentence; the list prints all 14 days | `features/progress/wellbeing_card.dart`, `l10n/app_en.arb`, `l10n/app_it.arb` | `wellbeing_test.dart` |
| E3 ⬜ | privacy and disclaimer copy differ | `features/progress/wellbeing_card.dart`, `l10n/app_en.arb`, `l10n/app_it.arb` | `wellbeing_test.dart` |
| E4 ⬜ | no "no check-ins" empty state | `features/progress/wellbeing_card.dart`, `core/widgets/empty_state.dart` | `wellbeing_test.dart` |

### F. Club, club rides, routes, athletes

| # | Point | Files to edit | Test |
|---|---|---|---|
| K1 ⬜ | hero card has no club-name title | `features/club/widgets/club_hero_card.dart` | `club_test.dart` |
| K2 ⬜ | upcoming rides lead with an icon and a date string | `features/club/club_screen.dart`, `features/calendar/club_ride_widgets.dart` | `club_test.dart` |
| K3 ⬜ | "Plan a ride" and "Add a route" are extra filled actions | `features/club/club_screen.dart`, `features/routes/routes_screen.dart` | `club_test.dart`, `club_rides_routes_test.dart` |
| K4 ⬜ | members lack avatars, role badges, "Show all N", an empty state | `features/club/widgets/club_members_card.dart`, **new** `core/widgets/avatar.dart` | `club_test.dart` |
| K5 ⬜ | location card has no map and puts the button before the switch | `features/club/widgets/club_location_card.dart` | `club_test.dart` |
| K6 ⬜ | sharing is a hand-built dropdown, not switch rows | `features/club/widgets/club_sharing_card.dart` | `club_test.dart` |
| K7 ⬜ | "New code" belongs in the `⋯` menu | `features/club/widgets/club_join_code_card.dart`, `features/club/club_screen.dart` | `club_test.dart` |
| K8 ⬜ | join code at `headlineSmall` with `letterSpacing: 4` | `features/club/widgets/club_join_code_card.dart`, `core/theme.dart` | `club_test.dart` |
| K9 ⚠️ | no-club h1 is "Your club", the mock-up says "Club" | `features/club/club_screen.dart`, `l10n/app_en.arb`, `l10n/app_it.arb` | `club_test.dart` |
| K10 ⬜ | three ways use three button styles, collapse to two | `features/club/club_screen.dart`, `core/widgets/section_card.dart` | `club_test.dart` |
| K11 ⬜ | 3-way grid leaves dead space | `core/widgets/card_grid.dart` (S1), `features/club/club_screen.dart` | `club_test.dart`, `card_grid_test.dart` |
| L1 ⬜ | raw `Chip`s with `errorContainer` for cancelled | `features/calendar/club_ride_widgets.dart`, `features/calendar/club_rides_screen.dart` | `club_rides_routes_test.dart` |
| L2 ⬜ | `titleMedium` row titles, `isThreeLine` subtitles, date at card-title size | `features/calendar/club_ride_widgets.dart` | `club_rides_routes_test.dart` |
| L3 ⬜ | two date formats across club rides | `features/calendar/club_ride_widgets.dart`, `core/format.dart` | `format_test.dart` |
| L4 ⬜ | detail: no primary action, facts as one line, meeting name above the map, names not avatars | `features/calendar/club_ride_detail_screen.dart`, `core/widgets/avatar.dart` | `club_rides_routes_test.dart` |
| L5 ⬜ | bare `EmptyState`/`ErrorState` without `PageScaffold` | `features/calendar/club_ride_detail_screen.dart` | `club_rides_routes_test.dart` |
| U1 ⬜ | no "Club routes" caption | `features/routes/routes_screen.dart` | `club_rides_routes_test.dart` |
| U2 ⬜ | map before title, extra "Not shared" badge, `ChoiceChip` filter | `features/routes/routes_screen.dart`, `features/routes/route_widgets.dart` | `club_rides_routes_test.dart` |
| U3 ⬜ | "Club rides 3" fact is not in the API | server `src/Velomine.Server/Features/Routes/`, `app/packages/velomine_api/` (regenerate), `features/routes/route_detail_screen.dart` | `club_rides_routes_test.dart` + a server test |
| U4 ⬜ | extra "Remove from club" | `features/routes/route_detail_screen.dart` | `club_rides_routes_test.dart` |
| U5 ⬜ | unstyled 14 px body, bare states, `PageScaffold` gap | `features/routes/route_detail_screen.dart` | `club_rides_routes_test.dart` |
| U6 ⬜ | add route: heading replaced by the segment label, rides by file name + radio, failed load says "no rides", privacy note above the map, distance twice | `features/routes/route_forms.dart` | `club_rides_routes_test.dart` |
| U7 ⬜ | Edit has no design page | **new** `docs/design/pages/routes/EditRoutePage.md` + `.html`, then `features/routes/route_forms.dart` | `club_rides_routes_test.dart` |
| H1 ⬜ | generic person icon instead of initials; `ListTile` 16/14; no dividers | `features/coach/coach_athletes_screen.dart`, **new** `core/widgets/avatar.dart` | `coach_test.dart` |
| H2 ⬜ | share badges as trailing, not under the name; chip order; extra cards; wellbeing before rides; hand-built table | `features/coach/coach_athlete_screen.dart` | `coach_test.dart` |
| H3 ⬜ | coach ride adds ride-type chips, laps and a chart per stream | `features/coach/coach_ride_screen.dart` | `coach_test.dart` |

### G. Bikes, profile, notifications, admin, auth, goals

| # | Point | Files to edit | Test |
|---|---|---|---|
| B1 ⬜ | wear bar is not the mock-up's 180 px column; literal `minHeight: 8`, `circular(4)` | `features/bikes/bike_detail_screen.dart`, `features/bikes/service_section.dart`, `core/tokens.dart` | `bikes_test.dart` |
| B2 ⬜ | Edit/Replace visible on every part row; three buttons on a reminder row | `features/bikes/row_menu.dart`, `features/bikes/service_section.dart` | `bikes_test.dart`, `service_test.dart` |
| B3 ⬜ | extra "Replaced parts" card; status as bare `TextStyle` | `features/bikes/bike_detail_screen.dart`, `features/bikes/service_section.dart` | `bikes_test.dart` |
| V1 ⬜ | extra "How I ride" row; fields one per row, not pairs; field order | `features/profile/profile_screen.dart` | `profile_test.dart` |
| V2 ⬜ | time zone free text instead of a picker | `features/profile/profile_screen.dart`, `core/device_time_zone.dart` | `profile_test.dart` |
| V3 ⬜ | 2FA/devices rows lack state subtitles and device glyphs; full date instead of relative | `features/profile/two_factor_screen.dart`, `features/profile/sessions_screen.dart`, `core/format.dart` | `security_test.dart` |
| V4 ⬜ | page is `contentMax` where the mock-up is narrow; grid columns unequal | `features/profile/profile_screen.dart`, `core/widgets/card_grid.dart` | `profile_test.dart` |
| V5 ⬜ | supporter badge hardcodes colours | `features/supporter/supporter_badge.dart`, `core/theme.dart` | `supporter_test.dart` |
| V6 ⬜ | privacy and two-factor hand-built `TextField`s; setup key without copy; "Set up an authenticator" on the SSO branch | `features/privacy/privacy_screen.dart`, `features/profile/two_factor_screen.dart` → `core/widgets/app_text_field.dart` | `privacy_test.dart`, `security_test.dart` |
| V7 ⬜ | place subtitle "800 m" vs "Radius 800 m" | `features/profile/profile_screen.dart`, `l10n/app_en.arb`, `l10n/app_it.arb` | `profile_test.dart` |
| V8 ⬜ | celebration screen: extra line and chip, literal layout, scaled `headlineMedium`, `'serif'` fallback, own `Scaffold`, own `AnimationController` | `features/supporter/supporter_celebration_screen.dart`, `core/tokens.dart`, `core/motion.dart` | `supporter_test.dart` |
| N1 ⬜ | "Mark all read" vanishes; group header hand-built; no `LoadingState`; `contentMax` not narrow | `features/notifications/notifications_screen.dart` | `notifications_test.dart` |
| N2 ⬜ | hand-built tab chips though `ProgressTabs` exists | `features/admin/admin_screen.dart`, `features/progress/progress_tabs.dart` | `admin_test.dart` |
| N3 ⬜ | accounts: no avatars/Member badge, no `⋯` for waiting accounts, absolute date, search on the left without a hint | `features/admin/accounts_tab.dart`, `core/format.dart`, `core/widgets/avatar.dart` | `admin_test.dart` |
| N4 ⬜ | clubs tab: one caption split into four, extra owner-email line, Activate/Deactivate, hidden "Change owner" | `features/admin/clubs_tab.dart` | `admin_test.dart` |
| N5 ⬜ | settings tab: literal widths, filled Save inside a card, rejected contributions inline | `features/admin/settings_tab.dart` | `admin_test.dart` |
| N6 ⬜ | "Create the address" is a content button, not the header action | `features/calendar/calendar_feed_screen.dart` | `notifications_test.dart` |
| A1 ⬜ | `auth_page.dart` disagrees with its mock-up (wordmark 56 accent vs 28 ink; 720 top-aligned vs 440 centred) | `features/auth/auth_page.dart`, `core/tokens.dart`, `docs/design/pages/auth/` | `sign_in_test.dart`, `register_test.dart` |
| A2 ⬜ | "Forgot password?" above the primary, right-aligned; eye icon instead of the word "Show"; Register has no help sentence | `features/auth/sign_in_screen.dart`, `features/auth/password_field.dart`, `features/auth/register_screen.dart`, `l10n/app_en.arb`, `l10n/app_it.arb` | `sign_in_test.dart`, `register_test.dart` |
| A3 ⬜ | Forgot lacks "Back to sign in"; Verify says the wrong thing and adds a back arrow; the `http://` warning appears only after typing | `features/auth/forgot_password_screen.dart`, `features/auth/verify_email_screen.dart`, `features/auth/auth_page.dart` | `password_test.dart`, `verify_email_test.dart` |
| G1 ✅ | goal card states the reached count first | `features/goals/goals_screen.dart` | `goals_test.dart` |

### H. Tooling

| # | Point | Files to edit | Test |
|---|---|---|---|
| Z1 ✅ | screenshot harness | `tools/screenshots.dart`, `.pi/skills/ui-build/SKILL.md` | run against `just up` |
| Z2 ⬜ | Chrome is not pinned in the image | `.devcontainer/Dockerfile` (pinned, checksummed), `docs/development.md:45` | `tools/check-versions.sh` |
| Z3 ⬜ | `just ui-dupes` is not a gate | `justfile`, `.github/workflows/ci.yml` | CI run |

### The whole-tree index

If you are touching a file to satisfy one row, check whether another row names it too: `core/widgets/`
carries S1, S2, S4–S8, R2, R3, R7, R9, C1–C3, C7, F2, F3, O2, O3, K4, K10, K11, V4, V6, N3, A3.
`core/theme.dart`, `core/tokens.dart` and `core/format.dart` are touched by roughly a third of the rows
— do those three first, in their own change, so the rest is mechanical.

## Out of scope

- New features, screens, routes or endpoints; the API changes only for the plan's set date and the moved day.
- What the app computes; this story changes presentation only.
- Re-drawing mock-ups for taste; only the contradictions in criterion 5.
- The 149 files that hold no widget code, beyond the two training fields.

## Open questions

- The architect: does the sidebar foot gain a Settings entry, or does the theme control stay and the design page change?
- The CEO: `docs/business.md` is not in the repository, so `value:` cannot cite a band here — confirm `rider`.
- The CEO: does `just ui-dupes` become a gate with a budget that may only fall, or stay a report?
