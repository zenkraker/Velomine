# UI redesign: the app in the new design

## Overview
Bring every screen of the app in line with the new visual language: four destinations (Rides · Progress · Goals · Club), Progress split into an overview and four sub-pages, and the calm one-accent style instead of "bold expressive". One story is one pull request, in the order below.

**Original request:** "Bring the app's screens in line with the new design. The design is `docs/design/language.md` (rules), `docs/design/tokens.json` (values, already implemented in `lib/core/theme.dart`) and `docs/design/pages/` (a mock-up and a guideline for every screen; index `docs/design/pages/README.md`). Where these differ from `docs/design/ui-refresh.md`, the new design wins."

**How to read a story.** Each names its mock-ups (in `docs/design/pages/`). The mock-up shows structure and order of content; its example names and numbers are invented. Criteria are written so the owner can check them in a screenshot of the phone (under 600 dp), a tablet (about 800 dp) and a desktop (1300 dp), in Night and Day. Layout is the architect's.

**Rules for every story** (from `AGENTS.md`, which wins over this file):
- No new dependency.
- Every user-facing string exists in `app_en.arb` and `app_it.arb`.
- Colours, sizes and spacing come from the theme and `core/tokens.dart`, never literals.
- Every widget `Key` a test finds is kept; tests change only where they tap.
- Test names follow `Subject_ShouldDoSomething_WhenCondition`.
- No server change. Where a mock-up shows data the app or server does not have today, the card is left out and the story's PR says which.
- `just check` passes before the PR.

## Stories

### Story 1: Shared widgets in the new design
**Priority:** High
**Mock-ups:** `cards/StatCard`, `cards/GoalGauge` (the card frame only), `charts/BarChart`, `charts/AreaChart`, `controls/Controls`. Rules: `language.md` → Principles, Content, Cards, Charts.
**Description:** As a rider, I want every card, empty state and chart to look the same on every page, so that I learn the app's look once.
**Acceptance criteria:**
- **Given** any page that showed a `StatTile`, **When** I open it, **Then** the fact is a `StatCard`: a title, one big number with its unit in a muted colour beside it, one sentence that wraps, and at most one link with an arrow; no icon tile, no uppercase label, no border and no shadow. `StatTile` no longer exists.
- **Given** a `StatCard` with a state word (for example "Go easy"), **When** it is shown, **Then** the word appears as a chip after the number.
- **Given** any page header or section title, **When** I look at it, **Then** it is in sentence case. No uppercase "eyebrow" text remains anywhere in the app, signed-in or signed-out, and the `Eyebrow` widget no longer exists. A sub-page's header shows the parent's name as a small caption above its title (used from Story 3).
- **Given** a `SectionCard` or `EmptyState`, **When** I look at it on Night and Day, **Then** it is a filled card on the page colour with no border or shadow, with the card padding, gap and corner radius of the mock-ups.
- **Given** a bar chart of totals, **When** it is shown, **Then** past bars are muted, the current bar is in the accent, and only the current and the peak bar carry a value; on a phone only every third bar is labelled, from 600 dp every second.
- **Given** an area chart, **When** it is shown, **Then** it has a line, a fading area, at most four faint gridlines at round values, and the latest point marked with its value.
- **Given** a chart with no data, **When** the page opens, **Then** it shows the empty state with a sentence, never empty axes.
- **Given** the period selector, sport filter and page menu, **When** I use them, **Then** they look and behave as `controls/Controls` shows: segments on a track with the chosen one raised, chosen chip on the soft accent ground, destructive menu entries last and red.
- **Given** the existing screens, **When** I open each one, **Then** it works as before with the new widgets (no screen is redesigned in this story beyond swapping widgets).
- **Given** the docs, **When** the story merges, **Then** `docs/design/ui-refresh.md` is deleted (owner decision 2026-11-20: `language.md` and `AGENTS.md` already hold what is worth keeping), and no document links to it.
**Dependencies:** None
**Size:** L

### Story 2: The shell: four destinations, glass pill, grouped sidebar
**Priority:** High
**Mock-ups:** `navigation/NavPill`, `navigation/Sidebar`. Rules: `language.md` → Navigation.
**Description:** As a rider, I want the same four destinations, in the same order, on the phone, tablet and desktop, so that I always know where things are.
**Acceptance criteria:**
- **Given** a phone, **When** I open the app signed in, **Then** a floating glass pill shows Rides, Progress, Goals and Club in that order, at most 420 px wide, with the selected one on the soft accent ground and its icon filled; the other icons are outlined.
- **Given** the pill, **When** I scroll a page down, **Then** it slides away, and returns on scroll up; with reduced motion it stays. The last card of every page clears it.
- **Given** a ride is being recorded on the phone, **When** I am on any destination, **Then** a banner above the pill shows it and opens the recorder; the web shows no banner and no Start ride.
- **Given** a width from 600 to 1199 dp, **When** I open the app, **Then** a collapsed rail shows the same four destinations as icons with labels.
- **Given** a width of 1200 dp or more, **When** I open the app, **Then** a sidebar shows the wordmark, Rides ▾ (All rides, Routes, Bikes), Progress ▾ (Overview, Fitness, Power, Totals, Wellbeing), Goals as one plain link, and the rider's club ▾ (Members, Club rides, Sharing); at the bottom the privacy note, profile and settings. The page I am on is on the soft accent ground; the section that holds it is open.
- **Given** a rider with no club, **When** the sidebar shows, **Then** the club entry reads "Club" and opens the join page.
- **Given** unread notifications, **When** the shell shows, **Then** they are the only badge anywhere in the navigation.
- **Given** a screen pushed over the shell (a bike, a ride), **When** it is open, **Then** no destination is highlighted, as today.
- **Given** `/progress/events` and every existing route, **When** a link or notification opens it, **Then** it still works.
- **Given** the docs, **When** the story merges, **Then** the navigation rule in `AGENTS.md` ("three tabs … one rail from 600 dp …") is updated to four destinations, the glass pill and the grouped sidebar from 1200 dp.
**Dependencies:** Story 1
**Size:** M

### Story 3: Progress: the overview and four sub-pages
**Priority:** High
**Mock-ups:** `progress/ProgressDesktop`, `progress/ProgressPhone`, `progress/FitnessPage`, `progress/PowerPage`, `progress/TotalsPage`, `progress/WellbeingPage`. Rules: `language.md` → Components and pages.
**Description:** As a rider, I want Progress to answer one question per page, so that I can see how I am today at a glance and open the page for the next question.
**Acceptance criteria:**
- **Given** a phone, **When** I open Progress, **Then** without scrolling I see the sub-page tabs (Overview, Fitness, Power, Totals, Wellbeing) as chips that scroll sideways, the sport as one chip that opens a sheet, and the Readiness card full width.
- **Given** a desktop, **When** I open Progress, **Then** the overview shows four stat cards in a row (Readiness, Form, This week, Next event) and below them Distance per week with its period control growing to the bottom of the window; each card links to its sub-page (Wellbeing, Fitness, Totals, Goals).
- **Given** a rider with no event planned, **When** the overview shows, **Then** the fourth card shows the latest record instead.
- **Given** a rider with no rides yet, **When** any Progress page opens, **Then** it shows an empty state that says what to do, not empty charts.
- **Given** Fitness, **When** I open it, **Then** one big chart shows fitness (line with area), fatigue (dashed) and form (bars round a zero line), with a sentence of the trend, and below it daily load, the easy/moderate/hard split, training load and aerobic efficiency; the range control (30 days, 90 days, 1 year) is the chart's only setting.
- **Given** Power, **When** I open it, **Then** cards for FTP, critical power with W′ and the VO2max estimate sit above the power curve (log time axis, FTP as a dashed line) and the best-efforts table; when the estimate differs from the FTP in use, the FTP card offers "Use … W".
- **Given** Totals, **When** I open it, **Then** one chart of the chosen measure (distance, time, climbing) per week, month or year, with the average as a dashed line, and one table below with the current period highlighted, eight rows and "Show earlier".
- **Given** Wellbeing, **When** I open it, **Then** only I can see it: readiness with the factors that raise or lower it, today's check-in and how I felt over 14 days; the Check-in button opens a sheet; Withdraw consent is in the `⋯` menu, last, red and confirmed. Before my first check-in, the consent card replaces the page, as today. Free-text notes and readiness are never shown to a coach.
- **Given** a sub-page, **When** I look at its header, **Then** "Progress" appears as a small caption above its title; on a phone the tabs replace it.
- **Given** the Progress page of today, **When** the story merges, **Then** goals and events no longer appear on any Progress page (they move to Story 5), and every old Progress link still opens a page.
- **Given** a mock-up card for which the app has no data today **When** the story is planned, **Then** the architect lists it and it is left out of this story. (Corrected 2026-11-20: critical power, VO2max, daily load and aerobic efficiency do exist in the app; the "latest record" fallback card and the Form and Next event data still need checking in Story 3's plan.)
**Dependencies:** Story 1, Story 2
**Size:** L (the architect may propose splitting it into the overview and the sub-pages; the owner decides)

### Story 4: Rides: ride detail first, then the list, recording and import
**Priority:** High
**Mock-ups:** `rides/RideDetailPage`, `maps/RouteMap`, `charts/AreaChart`, `rides/RidesPage`, `rides/RecordPhone`, `rides/RecordingLivePhone`, `rides/ImportPage`.
**Description:** As a rider, I want my rides, one ride and recording a ride in the new design, so that the main thing I do in the app feels as calm and clear as the rest.
**Acceptance criteria:**
- **Given** a ride, **When** I open it, **Then** the route is drawn on a dimmed map with a glowing line, the start as an accent dot and the finish as a tail-light dot, and the ride's name, date and up to three facts sit on a glass card at the bottom of the map; the whole card opens the full map.
- **Given** the ride's charts, **When** I look at them, **Then** power is always in the power colour and heart rate always in the heart-rate colour, with the area-chart style of Story 1.
- **Given** the ride page, **When** I open its `⋯` menu, **Then** edit text and edit type come first and Delete is last, red, after a divider, and confirmed. The keys `edit-ride-text`, `edit-ride-type` and `delete` are unchanged.
- **Given** a ride shared with a coach or a share link, **When** it is shown, **Then** it still goes through the privacy function: no route without its grant, zones and trimming applied.
- **Given** the Rides list, **When** I open it, **Then** it follows `rides/RidesPage`: newest first, one main action in the header (Start ride on the phone, Upload on the web), and Import a Strava export and filters in the `⋯` menu with a badge when a filter is on.
- **Given** a rider with no rides, **When** Rides opens, **Then** it shows the empty state with the main action.
- **Given** a phone, **When** I open Record, **Then** it matches `rides/RecordPhone`; **When** a ride is in progress, **Then** it matches `rides/RecordingLivePhone`; a ride saved only on the phone says that deleting it loses it for good. The web has no recorder.
- **Given** a Strava import, **When** I open its progress page, **Then** it matches `rides/ImportPage`.
**Dependencies:** Story 1, Story 2
**Size:** L (ride detail is built and reviewed first; the architect may propose splitting)

### Story 5: Goals as a destination
**Priority:** High
**Mock-ups:** `goals/GoalsPage`, `goals/EventsPage`, `cards/GoalGauge`.
**Description:** As a rider, I want my goals and events on a page of their own, so that I can see at a glance whether I am hitting them.
**Acceptance criteria:**
- **Given** a rider with goals, **When** I open Goals, **Then** one sentence sums them up ("Three goals running. One reached this month."), a "Next event" card shows the days to go, and a card per goal shows a half-circle gauge with the percentage, the value against the target and one sentence of what is left; three per row from 1200 dp, two from 600 dp, one on a phone; running goals first, then reached ones.
- **Given** a reached goal, **When** it shows, **Then** the arc is full, a "Reached" chip is on it and the sentence says by how much; the arc never draws past the end.
- **Given** a goal card, **When** I open its `⋯` menu, **Then** Edit comes first and Delete last, red, and confirmed; Add goal is the page's one filled button and opens a form sheet.
- **Given** a rider with no goals, **When** Goals opens, **Then** the empty state says what a goal is and offers Add goal.
- **Given** Events, **When** I open `/progress/events` from the Next event card or the Goals page, **Then** it matches `goals/EventsPage` and the route is unchanged.
- **Given** a sidebar or pill, **When** I am on Goals or Events, **Then** Goals is the highlighted destination.
**Dependencies:** Story 1, Story 2, Story 3
**Size:** M

### Story 6: Club
**Priority:** Medium
**Mock-ups:** `club/ClubPage`, `club/NoClubPage`, `club/StartClubPage`, `club/JoinClubPage`, `club/NearbyClubsPage`, `club/ClubRidesPage`, `club/ClubRideDetailPage`, `club/PlanRidePage`, `club/CalendarFeedPage`, `club/RoutesPage`, `club/RouteDetailPage`, `club/AddRoutePage`, `club/AthletesPage`, `club/AthletePage`, `club/CoachRidePage`.
**Description:** As a club member or coach, I want the club pages in the new design, so that the club feels part of the same app.
**Acceptance criteria:**
- **Given** a member of a club, **When** I open Club, **Then** it matches `club/ClubPage`, built from the shared cards; "Leave club" is in the `⋯` menu, red and confirmed, and the owner still sees the note that they cannot leave.
- **Given** a rider with no club, **When** I open Club, **Then** it matches `club/NoClubPage`, with the start and join choices.
- **Given** Club rides, Routes and Calendar, **When** I open each, **Then** it matches its mock-up and its one main action (Plan a ride, Add route) is a header button; Cancel ride, Stop calendar and Delete route are in `⋯`, last, red and confirmed.
- **Given** the full-page forms (Start a club, Join, Plan a ride, Add route), **When** I open them, **Then** the submit button is pinned at the bottom and Cancel is the back arrow.
- **Given** Nearby clubs and the location picker, **When** I open them, **Then** they are in the page frame with a back arrow, with no literal colours over the map.
- **Given** a coach, **When** I open Athletes, an athlete or a shared ride, **Then** I see only what that athlete shares through an active grant, as today; a view is recorded in the sharing log, and notes and readiness are not shown.
- **Given** a member of another club, **When** they open any of these pages, **Then** they see nothing of this club, as today.
**Dependencies:** Story 1, Story 2
**Size:** L (the architect may propose splitting it, for example club home and members / rides and routes / coach pages)

### Story 7: Bikes
**Priority:** Medium
**Mock-ups:** `bikes/BikesPage`, `bikes/BikeDetailPage`.
**Description:** As a rider, I want my bikes, their parts and their service in the new design, so that I can see what each bike needs.
**Acceptance criteria:**
- **Given** Bikes, **When** I open it from the sidebar's Rides group or from Profile → My bikes, **Then** it matches `bikes/BikesPage`, with Add bike (key `add-bike`) as the one header button.
- **Given** a bike, **When** I open it, **Then** it matches `bikes/BikeDetailPage`: parts with their wear and its service; Archive and Delete are in `⋯` (keys `toggle-archive` and `delete-bike`), Delete last, red and confirmed; row-level "Remove" is in each row's `⋯`.
- **Given** a bike with no parts, **When** I open it, **Then** the empty state offers to add a part.
- **Given** an old `/bikes/:id` link from a notification or a ride, **When** I open it, **Then** the bike opens.
**Dependencies:** Story 1, Story 2
**Size:** M

### Story 8: Profile
**Priority:** Medium
**Mock-ups:** `profile/ProfilePage`, `profile/PrivacyPage`, `profile/SessionsPage`, `profile/TwoFactorPage`, `profile/SupporterPage`, `profile/SupporterCelebration`.
**Description:** As a rider, I want my numbers, preferences, privacy and account in the new design, so that settings are as easy to read as my rides.
**Acceptance criteria:**
- **Given** Profile, **When** I open it, **Then** it matches `profile/ProfilePage`, with a My bikes row at the top; Delete my account is in the `⋯` menu, last, red, and keeps its password step.
- **Given** Privacy, Sessions and Two-factor, **When** I open each, **Then** it matches its mock-up; the two-factor submit is pinned at the bottom; removing a privacy zone is confirmed.
- **Given** Supporter, **When** I activate a key, **Then** the page matches `profile/SupporterPage`, and afterwards the celebration plays; the celebration stays bespoke but uses theme colours and radii.
- **Given** a rider changes their password or deletes their account, **When** the form opens, **Then** it is a sheet, not a dialog.
**Dependencies:** Story 1, Story 2
**Size:** M

### Story 9: Inbox
**Priority:** Low
**Mock-ups:** `inbox/NotificationsPage`.
**Description:** As a rider, I want my notifications in the new design, so that I can clear them quickly.
**Acceptance criteria:**
- **Given** unread notifications, **When** I open the inbox from the bell, **Then** it matches `inbox/NotificationsPage` and "Mark all as read" is the page's one header button.
- **Given** no notifications, **When** I open it, **Then** the empty state says so.
- **Given** a notification that links to a ride, bike or club page, **When** I tap it, **Then** that page opens.
**Dependencies:** Story 1, Story 2
**Size:** S

### Story 10: Sign-in and the signed-out screens
**Priority:** Medium
**Mock-ups:** `sign-in/SignInPage`, `sign-in/RegisterPage`, `sign-in/ForgotPasswordPage`, `sign-in/ResetPasswordPage`, `sign-in/VerifyEmailPage`, `sign-in/ServerSetupPhone`.
**Description:** As a new or returning rider, I want the first screens in the new design, so that my first minute with the app looks as good as the rest.
**Acceptance criteria:**
- **Given** each signed-out screen, **When** I open it, **Then** it matches its mock-up, in sentence case with the wordmark in the display type and the primary button pinned at the bottom.
- **Given** Forgot password, **When** I submit any address, **Then** the page says the same thing whether or not the address has an account.
- **Given** an expired confirmation link, **When** I open Verify email, **Then** it says so and offers "Send a new link".
- **Given** the web, **When** it opens, **Then** it skips the server setup screen, as today.
- **Given** a wrong password, **When** I sign in, **Then** the error says what happened and what to do.
**Dependencies:** Story 1
**Size:** M

### Story 11: Admin
**Priority:** Low
**Mock-ups:** `admin/AdminOverviewPage`, `admin/AdminAccountsPage`, `admin/AdminClubsPage`, `admin/AdminSettingsPage`.
**Description:** As a server admin, I want the admin pages in the new design, so that running the server feels like the rest of the app.
**Acceptance criteria:**
- **Given** an admin, **When** I open Admin from the account menu, **Then** the four tabs match their mock-ups in the page frame.
- **Given** an account row, **When** I open its `⋯` menu, **Then** its actions are there, Delete last, red and confirmed; the role, reset-link and club forms are sheets.
- **Given** a rider who is not an admin, **When** they open `/admin`, **Then** they are refused, as today.
**Dependencies:** Story 1, Story 2
**Size:** M

## Out of scope
- Server changes of any kind, and data a mock-up shows that the app lacks today.
- New dependencies, a chart or map library, and a native recorder change.
- The presentation site (`site/`), the demo and the mock-ups themselves: the mock-ups are the target and change first, by the owner.
- Moving routes: `/progress/events` and every existing route stay.
- A fifth destination, and any floating action button.

## Decisions
- 2026-11-20: The new design wins over `ui-refresh.md`. Retire its decisions 2, 3, 8 and 9 and its story list; keep the decisions `language.md` repeats and the rules for every story.
- 2026-11-20: `docs/design/ui-refresh.md` is deleted in Story 1 (supersedes the earlier "rewrite" decision); the `AGENTS.md` navigation rule is updated in Story 2.
- 2026-11-20: OWNER ORDER: Story 1 only repainted the shared widgets and the owner expected the whole refactor. Build Stories 2 to 11 non-stop, in order, with no questions to the owner: the architect decides each open question itself with its recommended option and records it as "Decided by default" in the plan; dev implements each plan in turn; dev still never commits. Also fix the Italian "Questo settimana" (should be "Questa settimana") in the first dev run.
- 2026-11-20: Story 1 overflow tests also run at 600 dp, the edge of the two-column layout (390, 600, 820, 1300).
- 2026-11-20: The new `AGENTS.md` rule for the shared widgets (the plan's Records line) lands in Story 1's last commit.
- 2026-11-20: Bikes appears in the sidebar under Rides, and stays reachable from Profile → My bikes.
- 2026-11-20: Goals and events keep their routes (`/progress/events`); only the navigation changes.
- 2026-11-20: Where a mock-up shows data the app lacks, the architect lists it in the plan and it is left out; no server work.
- 2026-11-20: Story 1 replaces every use of the uppercase `Eyebrow` and of `StatTile`.
- 2026-11-20: Work happens in this worktree (UI-Restructure) only, on the code and design files it holds after V2's uncommitted changes are brought in.
- 2026-11-20: Story 1 plan, owner accepted option A on all five questions: (1) page title becomes Instrument Serif 40 in Story 1; (2) training-load numbers are plain figures (`StatFigure`), not stat cards; (3) unit beside the big number is 13; (4) no screenshot harness: the owner reviews the web build and the APK against the mock-ups, the developer adds overflow tests at 390, 820 and 1300 dp; (5) one pull request with six ordered commits.

## Plan
### Status
Final
### What changed since the last version
- docs/design/ui-refresh.md is deleted in commit 6, not rewritten. The rewrite, its bullet list and the "third design doc" risk are gone.
- Overflow tests run at 390, 600, 820 and 1300 dp.
- The AGENTS.md rule from Records lands in commit 6, in the same PR. The commit list now says so.
- The plan is otherwise unchanged.
### Context
Story 1 swaps the app's shared widgets for the new look and changes no screen layout.
- StatTile (core/widgets/stat_tile.dart) is the old stat widget. The Progress dashboard builds it as an uppercase boxed headline tile.
- Eyebrow is used in page_scaffold.dart, stat_tile.dart and auth_page.dart. It is uppercase, with letter spacing.
- The theme already gives cards a fill, no border and no shadow (cardTheme in theme.dart). VelomineColors and VelomineText.kpi already exist.
- Bar and line charts are private painters, each with its own bar alpha, label rule and literal colours. They sit in totals_chart.dart (_BarsPainter), training_summary.dart (_LoadPainter, _FitnessPainter, hard-coded 0xFFE07A3F and 0xFF8E44AD), efficiency_card.dart and power_summary.dart.
- Segmented controls and chips are bare Material widgets. There are no tracks, no raised segment and no soft-accent chip look.
- Progress cards are plain Cards with AppSpacing.lg padding.
Facts that shape the plan:
- No server, API, migration or parser change. No club data is touched, so there is no second-club test. Every new string goes in both .arb files.
- Critical power, VO2max, daily load and aerobic efficiency all have data today. PowerCurveResponse.criticalPower and .vo2Max are used in power_summary.dart. TrainingResponse.days[].tss and .efficiency are used in training_summary.dart and efficiency_card.dart.
- This worktree has no just ui-shots and no test/ui_review/, although the ui-plan and ui-build skills assume both. So no screenshot check exists, and the Developer skips that step of ui-build.
- PageScaffold.eyebrow and AuthPage.eyebrow have callers I could not list, because neither CodeGraph nor grep was available to me. The Developer must grep (see Commands).
### Decision
Build one shared-widget layer in app/lib/core/widgets/. Land it as one pull request with six ordered commits, each green under just check, so a failure stays small:
1. Tokens and theme.
2. AppCard, SectionCard, EmptyState.
3. StatCard.
4. Charts.
5. Controls.
6. Eyebrow removal, PageScaffold, deleting docs/design/ui-refresh.md, and the AGENTS.md rule from Records.
1. Tokens and theme
- tokens.dart: delete AppStat. Add AppChart and AppStatCard (numbers in Files to change).
- theme.dart:
    - cardTheme.margin becomes EdgeInsets.zero, so the gap between cards is the page's spacing: lg.
    - chipTheme follows the mock-up:
        - Unselected: transparent ground, outlineVariant (hairline) outline, onSurfaceVariant caption label.
        - Selected: primaryContainer ground, onPrimaryContainer label, semibold, no outline.
        - Use WidgetStateBorderSide and WidgetStateColor. A theme test must prove the selected and unselected colours, because Flutter may ignore a state colour in labelStyle. If it does, set the style on the chips in the two places that build ChoiceChips.
    - segmentedButtonTheme keeps only the text style. The look moves into SegmentedControl, because a "raised card on a card" segment would be invisible inside a card.
    - PageMenu's IconButton uses onSurfaceVariant.
2. AppCard, SectionCard, EmptyState
- AppCard is a Card with padding defaulting to EdgeInsets.all(AppSpacing.xl).
- Rebuild SectionCard on AppCard:
    - Title in titleMedium.
    - Description in bodySmall, onSurfaceVariant.
    - Gap sm between title and description, md between children.
    - The menu sits at the card's right edge. Use Transform.translate(Offset(AppSpacing.md, 0)) on the menu, which mirrors the mock-up's -12px margin.
- EmptyState gets framed (default true). Framed means an AppCard with centred content, no ring around the icon, and the icon at 32 px in onSurfaceVariant. framed: false is for an empty state already inside a card or sheet. Examples are events.dart's ride picker sheet and any empty list inside a chart card. The Developer greps EmptyState( and decides each
  call site.
- Swap these progress cards onto AppCard:
    - ReadinessCard, EfficiencyCard, IntensityCard, TrainingSummary, PowerSummary, _TotalsCard.
    - GoalCard: AppCard(padding: EdgeInsets.fromLTRB(xl, md, md, xl)). It keeps its buttons and LinearProgressIndicator (the gauge is Story 5), and the "Reached" Chip gets side: BorderSide.none.
    - _TotalsTable: AppCard(padding: EdgeInsets.symmetric(vertical: AppSpacing.sm)), with each ListTile's horizontal contentPadding set to AppSpacing.xl.
- Replace the literal colours in readiness_card.dart:
  ┌─────────────────┬──────────────────┐
  │ Band / effect   │ Colour           │
  ├─────────────────┼──────────────────┤
  │ hard            │ accentStrong     │
  ├─────────────────┼──────────────────┤
  │ normal          │ scheme.primary   │
  ├─────────────────┼──────────────────┤
  │ easy            │ signal           │
  ├─────────────────┼──────────────────┤
  │ rest            │ error            │
  ├─────────────────┼──────────────────┤
  │ Positive effect │ accentStrong     │
  ├─────────────────┼──────────────────┤
  │ Negative effect │ signal           │
  ├─────────────────┼──────────────────┤
  │ Zero effect     │ onSurfaceVariant │
  └─────────────────┴──────────────────┘
3. StatCard
- The title is titleMedium.
- The number is one Text.rich: a value span in VelomineText.of(context).kpi, then a unit span in bodySmall (13, the caption token), onSurfaceVariant.
    - The space between value and unit belongs to the unit span (' W'). The concatenated text is then exactly 211 W, and find.text('211 W') still matches, because find.text matches a Text.rich by its plain text.
- The state chip goes after the number inside a Wrap.
    - It is 28 px high with a pill shape, caption semibold.
    - stateCare: true uses signalSoft ground and signal text. Otherwise it uses accentSoft and onAccentSoft.
- The sentence is bodyLarge, onSurfaceVariant, and wraps (no maxLines).
- The link is optional: caption, semibold, accentStrong, plus a trailing Icons.arrow_forward at 16 px. It is a TextButton with minimumSize 48×48 and zero padding, and the arrow is excluded from semantics.
- There is no icon tile, no uppercase and no border.
- StatCardRow replaces _MetricRow. It uses IntrinsicHeight and Expanded so cards in a row have equal height. At width ≥1200 it shows one row of up to four. From 600 to 1199 it shows two per row, and under 600 one column. A short last row's cards still fill the row. It holds only StatCards. Do not use it for chart cards, since LayoutBuilder breaks
  IntrinsicHeight.
- StatFigure(label, value, valueKey) is the stat-size number inside a chart card, with a caption label in onSurfaceVariant. TrainingSummary uses it for TSS, TRIMP, rides and distance, and keeps its keys training-tss, training-trimp, training-rides and training-distance.
- format.dart gets two pure helpers:
    - distanceParts returns the number and unit as separate strings ('69.7', 'km').
    - distanceIn returns the display-unit double.
    - km() is rebuilt on distanceParts, so its plain text stays identical.
- The dashboard metric cards in progress_screen.dart become StatCards. Keys stay: metric-readiness, metric-training, metric-power, metric-period. Links are omitted, because the target pages arrive in Story 3.
  ┌───────────────┬────────────────────────┬──────────────────────────────────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┬────────────────────────────────────┐
  │ Card          │ Title                  │ Value and unit                           │ State chip                                                                                                          │ Sentence                           │
  ├───────────────┼────────────────────────┼──────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼────────────────────────────────────┤
  │ Readiness     │ l10n.readiness         │ '50', no unit ('–' if the score is null) │ the band word: readinessHard, readinessNormal, readinessEasy or readinessRest. stateCare is true for easy and rest. │ the band's readinessAdvice* string │
  ├───────────────┼────────────────────────┼──────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼────────────────────────────────────┤
  │ Training load │ metricTrainingLoad     │ '123', unit TSS                          │ none                                                                                                                │ bikeRides(n)                       │
  ├───────────────┼────────────────────────┼──────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼────────────────────────────────────┤
  │ Power         │ metricPower            │ '211', unit W ('–' when the FTP is null) │ none                                                                                                                │ ftpCurrent                         │
  ├───────────────┼────────────────────────┼──────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼────────────────────────────────────┤
  │ This period   │ metricThisPeriod(word) │ from distanceParts                       │ none                                                                                                                │ periodTotals(...)                  │
  └───────────────┴────────────────────────┴──────────────────────────────────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┴────────────────────────────────────┘
    - The sentence for Training load was TSS · N rides and is now N rides. It is the one test assertion allowed to change.
4. Charts
- core/widgets/nice_ticks.dart holds niceTicks(min, max).
    - It returns ascending tick values, at most 4 (3 intervals), whose first value is ≤ min and last is ≥ max.
    - Steps are {1, 2, 4, 5} × 10^k. Pick the smallest step with ceil(span/step − 1e-9) ≤ 3, snap the bounds to it, and widen the step if snapping adds an interval.
    - Bars call it with min 0: 101 gives 0/40/80/120, and 120 gives 0/40/80/120, not 160.
- BarChart is a CustomPainter inside Semantics(label:) with ExcludeSemantics. No LayoutBuilder: the painter works from its Size, and the compact flag comes from MediaQuery.
    - Empty values or all zeros show EmptyState(framed: false, message: emptyMessage), never axes.
    - Gridlines are hairline at niceTicks(0, max). Y labels are axis style, onSurfaceVariant, with no unit.
    - Past bars are barMuted and the current bar (last by default) is accentStrong. Every bar has a top-to-bottom gradient from full colour to 55 % alpha and AppRadius.small top corners. Bar width is slot × AppChart.barFraction. Minimum bar height is 2 px for a non-zero value.
    - Value labels (current and peak only). The current and the peak bar always carry a value, whatever the label step. Zero-value bars carry none. The peak is the last index of the maximum. If peak equals current, draw it once, in ink. The current label is ink, the peak onSurfaceVariant. Skip the peak label if it would overlap the current one.
    - Axis labels (x). barLabelStep(slot, compact) returns max(compact ? 3 : 2, ceil(AppChart.minLabelWidth / slot)). Label the bars where (last − i) % step == 0, so the current bar is always labelled.
- AreaChart is a CustomPainter with the same wrapper.
    - The line is 2 px, with a 35 % to 0 vertical gradient area under it.
    - Gridlines come from niceTicks(min, max), at most 4.
    - X labels thin out by width. The last point has a dot with a card-coloured 3 px ring and its value in axis style, ink.
    - A single point draws only the dot and its value. No values shows the empty state.
    - Colour defaults to accentStrong; the caller may pass a series token.
- TotalsChart is rebuilt on BarChart: values via distanceIn, labels via periodLabel, format via km, existing totalsSemantics, and a new totalsEmpty sentence.
- TrainingSummary's daily load becomes a BarChart and keeps the key tss-chart (paintKey). It uses dailyLoadSemantics, a new dailyLoadEmpty sentence, and height AppProgress.loadChartHeight.
- EfficiencyCard becomes an AreaChart and keeps the key efficiency-chart, efficiencyEmpty and efficiencyHint.
- _FitnessPainter stays in TrainingSummary until Story 3 rebuilds it, but its literals go:
    - Fitness is accentStrong.
    - Fatigue is VelomineColors.series['power'].
    - Form is VelomineColors.series['cadence'].
    - PowerSummary's curve painter is untouched.
5. Controls
- SegmentedControl<T> lives in core/widgets/segmented_control.dart.
    - It draws a track pill with AppSpacing.xs padding around a SegmentedButton<T>.
    - The inner button has side none, a stadium shape per segment, a chosen segment on surfaceContainer (the card colour) with onSurface, and others transparent with onSurfaceVariant. Label style is caption semibold, showSelectedIcon: false, and the minimum height keeps 48 px of tap area.
    - buttonKey goes on the inner SegmentedButton, so find.byKey, tester.widget<SegmentedButton> and taps all keep working.
- Every SegmentedButton in app/lib moves onto it: the progress period (twice), RangeSelector, the wellbeing score rows, and any others the grep finds. RangeSelector keeps its API (segmentKey goes to buttonKey) and its Wrap layout.
- The sport filter stays ChoiceChips, styled by the chip theme.
6. Eyebrow removal, PageScaffold, docs, AGENTS.md
- Delete eyebrow.dart. In PageScaffold and AuthPage, drop the eyebrow parameter.
- Add PageScaffold.parent, replacing eyebrow: a sentence-case bodySmall line in onSurfaceVariant above the title, sized into _largeBlock. Story 1's acceptance criteria require it ("used from Story 3").
- The page title becomes headlineLarge (Instrument Serif 40, the page-title token), including in _HeaderDelegate._largeBlock's size calculation.
- Delete eyebrowProgress and every other eyebrow* key from both .arb files, with their @ metadata. Then run flutter gen-l10n.
- Resolve every remaining Eyebrow(, toUpperCase and letterSpacing hit. A section label becomes sentence-case titleMedium or bodySmall.
- Delete docs/design/ui-refresh.md. The PO has checked that nothing else links to it. The Developer reruns grep -rn "ui-refresh" . (excluding .git) and fixes any hit, including comments in app/lib and app/test.
- Add the rule from Records to AGENTS.md, Screens and layout, in this same commit.
### Screens
The question each changed page answers is unchanged. Only the Progress page and the shared frames visibly change. The mock-ups are cards/StatCard, charts/BarChart, charts/AreaChart and controls/Controls. There is no layout work on any route.
Route map. No route or tab changes. Pages that change look:
- /progress: stat cards, chart cards, and the goal and wellbeing cards.
- Every page that used SectionCard, EmptyState, a segmented control, a chip or PageScaffold.
- The signed-out AuthPage.
Progress dashboard.
Compact, under 600 dp (one column; each card has the same inner order):
```
  Progress                      (title, serif 40)   ⋯
  [Road ▾ chips ...]                      (wide only today)
  ┌ Readiness ──────────────┐
  │ 50  [Go easy]           │
  │ Keep it easy: ...       │
  └─────────────────────────┘
  ┌ Training load ┐ … then Power, This week, one per row
```
Expanded, 1200 dp and up (up to 4 across, equal height):
```
  ┌ Readiness ┐┌ Training load ┐┌ Power ┐┌ This week ┐
  └───────────┘└───────────────┘└───────┘└───────────┘
```
At 600–1199 dp the four cards sit two and two.
Chart card (Totals).
```
  ┌ Distance per week ────────────────┐
  │ 101 km                            │
  │ ▂▃▅▂▂▃▆▂▃▂▇█ (current accent)     │
  │  31 Aug   14 Sep   28 Sep   ...   │
  └───────────────────────────────────┘
```
Phone labels every 3rd bar, 600 dp and up every 2nd.
Data states.
┌────────────────────────┬─────────────────────────────────────────────────────────────────────────────────┬──────────────────────────┬────────────────────────────────┐
│ Widget                 │ Loading                                                                         │ Empty                    │ Error                          │
├────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┼──────────────────────────┼────────────────────────────────┤
│ Stat cards             │ the page already omits them while loading and shows totals-loading placeholders │ n/a                      │ the page's existing ErrorState │
├────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┼──────────────────────────┼────────────────────────────────┤
│ BarChart (totals)      │ the page's placeholders                                                         │ totalsEmpty              │ page ErrorState                │
├────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┼──────────────────────────┼────────────────────────────────┤
│ BarChart (daily load)  │ none                                                                            │ dailyLoadEmpty           │ page ErrorState                │
├────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┼──────────────────────────┼────────────────────────────────┤
│ AreaChart (efficiency) │ none                                                                            │ existing efficiencyEmpty │ page ErrorState                │
└────────────────────────┴─────────────────────────────────────────────────────────────────────────────────┴──────────────────────────┴────────────────────────────────┘
New strings. Add them to app_en.arb and app_it.arb, then regenerate:
- totalsEmpty
    - EN: "No rides yet. Upload or record a ride to see your totals."
    - IT: "Ancora nessun giro. Carica o registra un giro per vedere i tuoi totali."
- dailyLoadEmpty
    - EN: "No training load in this range. Rides with power or heart rate add to it."
    - IT: "Nessun carico di allenamento in questo periodo. I giri con potenza o frequenza cardiaca lo aumentano."
Shared pieces. PageScaffold already handles max width, gutters and the pill's clearance, so the plan adds nothing there beyond parent and the title style.
Cards left out, and why. No mock-up card of Story 1 is left out for missing data. The PR description says so.
- The links "Why →", "All weeks →" and "Power →" are not wired. Their target pages come in Story 3, and StatCard supports link and onLink for then.
- The trend sentence "Rising for 12 weeks: 4 to 18" is not computed. No trend code exists. EfficiencyCard keeps efficiencyHint, and the Fitness page (Story 3) writes its own.
- The goal gauge and its "to go by Sunday" sentence are Story 5. Story 1 changes only GoalCard's frame.
- Story 3's overview cards (Form, Next event) are Story 3. I did not verify that data exists for the "latest record" fallback card. The Story 3 plan must check.
ui_review. ui_review_test.dart and just ui-shots do not exist here, so no page is added to them. The overflow guard is the widget tests at 390, 600, 820 and 1300 dp listed under Tests.
### Files to change
- app/lib/core/tokens.dart — delete AppStat. Add AppChart (height 180, barFraction 0.52, maxGridLines 4, gutterLeft, valueLabelHeight, dotRadius 6, lineWidth 2, minLabelWidth 48, compactLabelStep 3, mediumLabelStep 2). Add AppStatCard.stateHeight 28.
- app/lib/core/theme.dart — cardTheme.margin zero, chipTheme, and trimmed segmentedButtonTheme.
- app/lib/core/widgets/app_card.dart (new) — AppCard.
- app/lib/core/widgets/section_card.dart, empty_state.dart — rebuilt as above.
- app/lib/core/widgets/stat_card.dart (new) — StatCard, StatCardRow, StatFigure. Delete stat_tile.dart.
- app/lib/core/widgets/nice_ticks.dart, bar_chart.dart, area_chart.dart, segmented_control.dart (new).
- app/lib/core/widgets/range_selector.dart — use SegmentedControl. page_menu.dart — icon colour.
- app/lib/core/widgets/page_scaffold.dart — parent, title style, no Eyebrow. Delete eyebrow.dart.
- app/lib/core/format.dart — add distanceParts and distanceIn; km() built on distanceParts.
- app/lib/features/auth/auth_page.dart and every auth screen that passes eyebrow: — drop the parameter.
- app/lib/features/progress/progress_screen.dart — StatCards in StatCardRow (delete _MetricRow and _metricCard), SegmentedControl, AppCard totals cards, drop eyebrow:.
- app/lib/features/progress/totals_chart.dart (→ BarChart), training_summary.dart, efficiency_card.dart, readiness_card.dart, intensity_card.dart, power_summary.dart, goals.dart (GoalCard frame), wellbeing_card.dart (SegmentedControl for scores).
- app/lib/l10n/app_en.arb, app_it.arb — remove the eyebrow* keys; add totalsEmpty and dailyLoadEmpty. Regenerate the l10n output.
- Any other file the grep below finds using StatTile, Eyebrow, SegmentedButton or a framed empty state.
- docs/design/ui-refresh.md — deleted.
- AGENTS.md — add the rule from Records under Screens and layout.
### Anchors (keep exactly)
- AppCard({super.key, required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.xl)})
- StatCard({super.key, required String title, required String value, String? unit, String? sentence, String? state, bool stateCare = false, String? link, VoidCallback? onLink, Key? valueKey}). link and onLink come together or not at all.
- StatCardRow({super.key, required List<Widget> children}), StatFigure({super.key, required String label, required String value, Key? valueKey})
- ({String value, String? unit}) distanceParts(Units, double? metres), which returns value: '–', unit: null for null. double distanceIn(Units, double metres).
- List<double> niceTicks(double min, double max); int barLabelStep({required double slot, required bool compact})
- BarChart({super.key, required List<double> values, required List<String> labels, required String Function(double) format, required String semanticLabel, required String emptyMessage, int? currentIndex, double height = AppChart.height, Key? paintKey})
- AreaChart({super.key, required List<double> values, required List<String> labels, required String Function(double) format, required String semanticLabel, required String emptyMessage, Color? color, double height = AppChart.height, Key? paintKey})
- SegmentedControl<T>({super.key, Key? buttonKey, required List<ButtonSegment<T>> segments, required T selected, required ValueChanged<T> onChanged})
- EmptyState({..., bool framed = true}); PageScaffold({..., String? parent}), with eyebrow gone.
- Keys that must stay: metric-readiness, metric-training, metric-power, metric-period, progress-period, progress-filter-*, training-range, power-range, training-tss, training-trimp, training-rides, training-distance, tss-chart, efficiency-chart, efficiency-empty, fitness-chart, goal-*, totals-more, total-N, totals-loading, wellbeing-*.
### Tests
Pure functions:
- niceTicks_ShouldReturn0_40_80_120_WhenMaxIs101
- niceTicks_ShouldKeepTopAt120_WhenMaxIsExactly120
- niceTicks_ShouldReturnZeroToOne_WhenMaxIsZero
- niceTicks_ShouldUseFractions_WhenMaxIsBelowOne
- niceTicks_ShouldSnapToRoundBounds_WhenRangeDoesNotStartAtZero
- niceTicks_ShouldReturnAtMostFourLines_WhenRangeIsAnything, looping over many ranges including a single value
- barLabelStep_ShouldBeThree_WhenCompactAndBarsAreWide
- barLabelStep_ShouldBeTwo_WhenMediumOrWider
- barLabelStep_ShouldGrow_WhenBarsAreNarrow
- distanceParts_ShouldSplitValueAndUnit_WhenMetric, and for imperial and null
- km_ShouldKeepItsText_WhenBuiltOnDistanceParts
Widgets:
- StatCard_ShouldFindPlainText_WhenUnitIsSplit (find.text('211 W'))
- StatCard_ShouldShowStateChipAfterNumber_WhenStateGiven
- StatCard_ShouldCallBack_WhenLinkIsTapped
- StatCard_ShouldWrapSentence_WhenTextScaleIsTwo (no overflow at 390 dp)
- StatCardRow_ShouldGiveEqualHeights_WhenOneSentenceIsLong
- StatCardRow_ShouldShowFourAcross_WhenWidthIs1300, plus two across at 600 and 820, and one at 390
- EmptyState_ShouldDrawFilledCard_WhenFramed and EmptyState_ShouldDrawNoCard_WhenNotFramed
- SectionCard_ShouldShowMenuAtCardEdge_WhenMenuGiven
- PageScaffold_ShouldShowParentCaptionAboveTitle_WhenParentGiven
- PageScaffold_ShouldKeepTitleInSentenceCase_WhenTitleGiven
- BarChart_ShouldShowEmptyState_WhenValuesAreEmptyOrAllZero
- BarChart_ShouldNotOverflow_WhenWidthIs390_600_820And1300
- BarChart_ShouldExposeSemanticLabel_WhenShown
- AreaChart_ShouldShowEmptyState_WhenNoValues
- AreaChart_ShouldDrawDotOnly_WhenOneValue
- SegmentedControl_ShouldKeepButtonKey_WhenWrapped
- SegmentedControl_ShouldCallOnChanged_WhenSegmentIsTapped
- ProgressScreen_ShouldNotOverflow_WhenWidthIs390_600_820And1300, with fake data for every card: stat cards, totals chart and table, training, efficiency, intensity, power, goals and wellbeing
- ChoiceChip_ShouldUseSoftAccentGround_WhenSelected, in the theme test
- design_tokens_test and contrast_test stay green.
Existing tests:
- Re-run the progress, goals, training, efficiency, wellbeing, auth and events tests. Taps change only where a control moved.
- Chart painters no longer expose text, so any test that finds bar or axis text switches to the Semantics label.
- The Training load sentence is the only allowed text edit.
Isolation: no club data is touched, so no second-club test.
### Commands the Developer must run
- Before starting, confirm the current theme changes are green: cd app && flutter test test/design_tokens_test.dart test/theme_test.dart test/contrast_test.dart.
- Resolve every hit of each of these, in app/lib and app/test:
    - grep -rn "StatTile\|statRowSpacing\|AppStat\|Eyebrow\|eyebrow\|toUpperCase\|letterSpacing" app/lib app/test
    - grep -rn "SegmentedButton" app/lib app/test
    - grep -rn "EmptyState(" app/lib
    - grep -rn "Color(0x\|Colors\." app/lib/features/progress app/lib/core/widgets
- In commit 6, after deleting docs/design/ui-refresh.md: grep -rn "ui-refresh" . --exclude-dir=.git and resolve every hit.
- Edit app/lib/l10n/app_en.arb and app_it.arb (remove the eyebrow* keys and metadata, add the two new keys). Then run cd app && flutter gen-l10n and commit the output if it is tracked. Check that no orphan eyebrow getter remains.
- just codegen only if a @riverpod declaration changed, which is not expected.
- just ui-dupes before and after, and put the numbers in the PR.
- just check last, and after each of the six commits.
- The visual check is manual: open the Progress page on web and on the phone, in Night and Day, at 390, 600, 820 and 1300 dp. Compare with cards/StatCard, charts/BarChart, charts/AreaChart and controls/Controls, and list what you checked in the PR. The owner reviews the web build and the APK.
### Risks and mitigations
- No screenshots. The mock-up match is unverified by tooling. The overflow widget tests plus the owner's visual pass on the web and the APK are the gate, and the PR lists what the owner should look at.
- Callers I could not see. Other files may use StatTile, Eyebrow, a bare SegmentedButton or EmptyState. The grep list above must come back clean.
- cardTheme.margin zero shifts every Card. Spacing in the app narrows by 8 px between adjacent cards. Check Progress, Club and Rides at 600 dp for overflow.
- AppCard's 24 px padding grows the Progress cards. 600 dp is the narrowest two-column width, so it is now in the overflow tests.
- ChipThemeData state colours. Flutter may ignore WidgetStateColor inside labelStyle. The theme test catches it, and the fallback is setting the style on the two ChoiceChip builders.
- Plain Chips (such as status chips) pick up the hairline outline. GoalCard's is fixed here. List any other that looks wrong in the PR instead of redesigning it.
- IntrinsicHeight in StatCardRow breaks if a child holds a LayoutBuilder. StatCard has none, and the row accepts only StatCards.
- A duplicate number persists on the Progress page. The Readiness score shows in a stat card and in ReadinessCard. Story 3 removes it.
- A stale reference to ui-refresh.md. The PO checked the docs. The Developer's grep covers code comments.
- Size. This is a large story for the Developer model. The commit order keeps each failure small.
- Left out, in line with the story: MapAttribution and MapControl literal colours in chart_chrome.dart (Stories 4 and 6), IntensityCard and PowerSummary's curve (Story 3), and the ChartHeader redesign.
- Not checked by me: which test files break, how many SegmentedButton, EmptyState and Chip call sites exist, and how Flutter in this repo handles chip state colours. The Developer's greps and the theme test settle these.
### Alternatives considered
- A StatCard(inline: true) variant for the numbers inside the training card. Rejected: it would be a card with no card. StatFigure is honest (owner choice 2A).
- Four StatCards for TSS, TRIMP, rides and distance above the training chart. Rejected: it changes the page structure and adds four cards to an already full page.
- Putting the segmented look only in segmentedButtonTheme. Rejected: the chosen segment would be invisible inside a card, and a theme cannot draw the track.
- Equal-height rows inside CardGrid. Rejected: its children may hold LayoutBuilders. Only StatCardRow does this.
- Deferring PageScaffold.parent to Story 3. Rejected: Story 1's acceptance criterion asks for it, and it replaces eyebrow in the same lines.
- A golden-image test for StatCard and BarChart. Not added: the project keeps goldens git-ignored, and the fonts make them flaky in CI.
- Rewriting docs/design/ui-refresh.md. Rejected by the owner: it is deleted, because language.md and pages/ hold the design.
- Leaving the page title for a later story. Rejected by the owner (1A).
- A unit size of 15, as in the mock-up CSS. Rejected by the owner (3A). The unit is 13 per language.md.
- Splitting the story into two pull requests. Rejected by the owner (5A).
### Records
- Add to AGENTS.md, Screens and layout, in commit 6 of this PR: "A fact is a StatCard; a card in the page flow is an AppCard or SectionCard; a total per period is a BarChart; one value over time is an AreaChart; every segmented choice is a SegmentedControl; uppercase eyebrow text does not exist."
- No docs/architecture.md change.
### Questions for the owner
None

## Plan — Story 3 (current)
### Status
Final
### Decided by default
- One L PR, not split: splitting leaves the phone unable to reach the sub-pages or duplicates the deep cards on the overview.
- Sub-pages are `/progress/fitness`, `/progress/power`, `/progress/totals`, `/progress/wellbeing`; Overview stays `/progress`.
- "Latest record" fallback is left out (no record data): the fourth card is Next event, and with no event it shows a new "no event planned" sentence.
- Form card: today's form number (last TrainingDay.form), sentence "Fitness X · Fatigue Y", no chip.
- This week card: latest week's distance against the average of the 11 earlier weeks (weeks already load 12).
- Sport filter = the existing discipline chips; on a phone one "Road ▾" chip opens the existing filter sheet.
- Totals measure (Distance/Time/Climbing) is view-local state; the average is a dashed ink-muted line with its value.
- Fitness trend sentence is "rising/falling" from first vs last fitness value, not a full trend computation.
- Wellbeing "How you feel" is the existing check-in history extended to 14 rows, not a new chart.
- Wellbeing: Check in is the page's primaryAction; Withdraw consent moves to the header ⋯ menu (last, red, confirmed); the card's own menu is removed.
- Sub-page headers show "Progress" as the parent caption (PageScaffold.parent); on a phone the shared tabs replace it.
- Coach view keeps working: the TrainingSummary/PowerSummary upgrades are visual only, so the athlete page inherits them.
### Decision (ordered commits)
1. Add the four sub-page routes in app.dart, each a PageScaffold with parent "Progress".
2. FitnessScreen: one fitness/fatigue/form chart (fitness line+area accent, fatigue dashed series-power, form bars round zero accent/signal, last-point labels, trend sentence) + daily-load BarChart + IntensityCard + EfficiencyCard + training StatFigures + range control.
3. PowerScreen: move PowerSummary unchanged (FTP/critical power/VO2max/log curve/best efforts/Use W).
4. TotalsScreen: measure control + TotalsChart with the average dashed line + _TotalsTable.
5. WellbeingScreen: move ReadinessCard + WellbeingCard, header Check in + withdraw menu, history to 14 rows.
6. Rebuild ProgressScreen as the overview: four StatCards (Readiness, Form, This week, Next event) + sport chips + distance-per-week card; drop the deep cards and their message listeners.
7. Sidebar: add the five Progress children and extend _sectionPages['progress']; add the shared ProgressTabs chip row on all five Progress pages.
8. l10n: add fitness-trend, no-event and 12-week-average strings to both .arb files and regenerate.
### Files
- app.dart — four sub-page routes.
- features/progress/fitness_screen.dart, power_screen.dart, totals_screen.dart, wellbeing_screen.dart, progress_tabs.dart (new).
- features/progress/progress_screen.dart — overview rebuild.
- features/progress/training_summary.dart — fitness chart upgrade.
- features/progress/totals_chart.dart — measure + average line.
- features/progress/wellbeing_card.dart — history to 14, drop the card menu.
- home_shell.dart — Progress section children + _sectionPages.
- app/lib/l10n/app_en.arb, app_it.arb + generated files.
### Tests
- ProgressScreen_ShouldShowFourStatCardsAndNoDeepCards_WhenOpened.
- Each sub-page opens from its sidebar child and phone tab, with the "Progress" caption above its title.
- FitnessScreen_ShouldDrawDashedFatigueAndFormBars_WhenTrainingHasDays.
- TotalsScreen_ShouldSwitchMeasureAndDrawTheAverage_WhenMeasureChanges.
- WellbeingScreen_ShouldGateOnConsentCheckInAndWithdraw_WhenConfirmed.
- PowerScreen_ShouldKeepUseFtp_WhenEstimateDiffers.
- NextEventCard_ShouldShowFallback_WhenNoEventPlanned.
- Overflow at 390/600/820/1300 and 2× text for the overview and all four sub-pages.
- Existing progress tests change only where they tap; widget keys stay.
### Risks
- The coach athlete screen inherits the fitness chart change; verify no member-only data is shown there.
- ProgressScreen must stop watching the deep providers after the strip, so sub-pages and the overview do not double-load; keep the keepAlive providers.
- Time measure needs a formatter (h/min) consistent with the member's units.
- The discipline filter flows to every card through ProgressFiltersViewModel.
### Records
- Update the navigation rule in AGENTS.md: Progress is one overview plus four sub-pages (Overview, Fitness, Power, Totals, Wellbeing), each a page reached from the sidebar section and the phone tabs.
### Questions for the owner
None

## Plans — Stories 4 to 11 (architect, decided by default: owner not available)
 Plan — Story 4: Rides (detail first, then the list, recording, import)
 ### Status
 Final
 ### Decided by default
 - Five commits in the story's order: ride detail, then Rides list, then Record, then Import.
 - The route map leads the ride page only when the ride has a route and the caller may see it: it uses the existing route_painter.dart and the privacy function, unchanged.
 - Charts take series['power'] and series['heartrate']; no new painter.
 ### Decision
 - Commit 1: ride_detail_screen.dart — route map card on top (dimmed tiles, glow, start accent dot, finish signal dot with card ring), glass fact card at its bottom holding name, date and up to three facts, the card opens the full map; keep the header ⋯ order edit text, edit type, divider, delete last.
 - Commit 2: ride chart colours move to the series tokens; zones card keeps its heart-rate/power switch.
 - Commit 3: rides_screen.dart — one header action (start-ride on phone, upload on web), import-strava/handling in the ⋯ with a badge when a filter is on; ride cards already carry only the facts the ride has.
 - Commit 4: recording_screen.dart — layout per RecordPhone/RecordingLivePhone; keys unchanged; the local-ride row keeps its menu and the "deleting it loses it for good" sentence.
 - Commit 5: import_screen.dart — one card, counts, "Import finished" plus Back to rides.
 ### Files
 - app/lib/features/rides/detail/ride_detail_screen.dart, detail/route_painter.dart, chart cards under detail/.
 - app/lib/features/rides/rides_screen.dart, rides/import/import_screen.dart, recording/recording_screen.dart.
 - One new glass-card widget in core/widgets/ if SectionCard cannot carry the overlay.
 - Both .arb files for any new sentence.
 ### Tests
 - RideDetailScreen_ShouldLeadWithTheRouteMap_WhenTheRideHasARoute.
 - RideDetailScreen_ShouldHideTheRoute_WhenTheCallerHasNoRouteGrant (privacy function, coach/share view).
 - RideDetailScreen_ShouldKeepMenuOrderAndDeleteLast_WhenTheMenuOpens.
 - RideDetailScreen_ShouldPaintPowerInSeriesPower_WhenTheChartShows.
 - RidesScreen_ShouldOfferOneMainAction_WhenTheWindowIsAPhoneOrWeb.
 - RecordingScreen_ShouldWarnThatDeletingIsFinal_WhenTheRideIsOnlyOnThePhone.
 - Overflow at 390/600/1300 and 2× text on detail, list and record.
 ### Risks
 - The map on top changes what a shared/coach view fetches; the privacy test must come with it.
 - Recording is Android-only in tests; guard with kIsWeb/platform as today.
 ### Records
 - None.
 Plan — Story 5: Goals as a destination
 ### Status
 Final
 ### Decided by default
 - GoalGauge is a new CustomPainter in core/widgets/goal_gauge.dart, half circle, drawArc with round caps, arc never past 100 %.
 - The two existing icon buttons become one PageMenu per card, keeping keys goal-edit-<id> and goal-delete-<id>; tests change only where they tap.
 - The summary sentence is a new plural-aware l10n string; with no goals it is not shown (the empty state speaks).
 - Events keeps /progress/events; Goals is lit when on it (pill, rail, sidebar _sectionPages).
 ### Decision
 - Commit 1: GoalGauge + GoalCard rewritten (title, gauge with percentage in the middle, value against target, one sentence, ⋯ menu, "Reached" chip on the soft accent ground).
 - Commit 2: goals_screen.dart — summary sentence under the title, next-event card above the goals, CardGrid three per row from 1200 dp, two from 600, one on a phone, running goals first then reached.
 - Commit 3: highlight Goals for /progress/events in home_shell.dart.
 ### Files
 - app/lib/core/widgets/goal_gauge.dart (new), features/goals/goals.dart, features/goals/goals_screen.dart, home_shell.dart, both .arb files.
 ### Tests
 - GoalGauge_ShouldDrawAFullArcAndNoMore_WhenTheGoalIsReachedAndOver.
 - GoalCard_ShouldSayWhatIsLeft_WhenRunningAndByHowMuch_WhenReached.
 - GoalsScreen_ShouldOrderRunningGoalsFirst_WhenSomeAreReached.
 - GoalsScreen_ShouldShowTheEmptyStateAndAddGoal_WhenThereAreNoGoals.
 - HomeShell_ShouldLightGoals_WhenOnTheEventsPage.
 ### Risks
 - GoalCard keys are used by progress/goals tests; keep names exactly.
 ### Records
 - None.
 Plan — Story 6: Club
 ### Status
 Final
 ### Decided by default
 - Split into two PRs, this plan covers both: 6a club home, no-club, start, join, nearby; 6b club rides and routes, calendar feed, athletes and coach.
 - The club location picker stays a bespoke page with the page frame, as today.
 - Sharing stays the card on /club; no new route.
 ### Decision
 - Commit 1 (6a): club_screen.dart rebuilt on AppCard/SectionCard per ClubPage, owner and coach blocks kept, Leave club last in the ⋯, owner note kept.
 - Commit 2 (6a): NoClubPage, StartClubScreen, JoinClubScreen, NearbyClubsScreen — page frame, submit pinned on bottomAction, no literal colours over the map.
 - Commit 3 (6b): club_rides_screen.dart, route forms, club_route/route_detail_screen.dart — one header action (Plan a ride, Add route), Cancel ride/Delete route last in ⋯, confirmed.
 - Commit 4 (6b): calendar_feed_screen.dart, coach_athletes_screen.dart, coach_athlete_screen.dart, coach_ride_screen.dart — grants unchanged, notes and readiness still hidden, views still logged.
 ### Files
 - app/lib/features/club/*, features/calendar/*, features/routes/*, features/coach/*, features/sharing/* if the card moves, both .arb files.
 ### Tests
 - ClubScreen_ShouldKeepLeaveLastInTheMenu_WhenTheRiderIsAMember, ..._ShouldShowTheOwnerNote_WhenTheRiderOwns.
 - ClubPages_ShouldNotShowAnotherClubsData_WhenTheClubDiffers (isolation, existing fakes).
 - CoachAthleteScreen_ShouldHideNotesAndReadiness_WhenTheCoachHasAGrant.
 - Overflow at 390/600/820/1300 for club home, club rides and coach pages.
 ### Risks
 - Largest story; the two PRs keep the review small. Coach pages must not gain member-only data from the shared cards.
 ### Records
 - None.
 Plan — Story 7: Bikes
 ### Status
 Final
 ### Decided by default
 - Wear colours are warning and danger from VelomineColors, always beside the words, never colour alone.
 - Bike cards stay AppCard rows on the grid CardGrid gives; two per row from 600 dp.
 ### Decision
 - Commit 1: bikes_screen.dart per BikesPage — add-bike as the header action and the empty state's action, cards with kind, model, default or archived marker, service marker, totals.
 - Commit 2: bike_detail_screen.dart per BikeDetailPage — Add part as the one action, bike-actions menu order kept, parts grouped with a wear bar, service section with Done and the log.
 ### Files
 - app/lib/features/bikes/bikes_screen.dart, bike_detail_screen.dart, service_section.dart, both .arb files.
 ### Tests
 - BikesScreen_ShouldShowTheServiceMarker_WhenAJobIsDue.
 - BikeDetailScreen_ShouldGroupPartsAndShowWearWithWords_WhenPartsExist.
 - BikeDetailScreen_ShouldKeepDeleteLastInTheMenu_WhenTheMenuOpens.
 - Overflow at 390/600/1300 and 2× text.
 ### Risks
 - bike_detail_screen.dart is large; change layout only, keep the wear maths and its tests.
 ### Records
 - None.
 Plan — Story 8: Profile
 ### Status
 Final
 ### Decided by default
 - Change password and Delete account become sheets (they already end in confirmation dialogs; the form moves into FormSheet).
 - The supporter celebration keeps its bespoke drawing but drops literal colours for theme tokens and rider/accent radii.
 - Profile shows the existing Settings destinations (password, two-factor, sessions, export) as rows; no new route.
 ### Decision
 - Commit 1: profile_screen.dart per ProfilePage — My bikes row (profile-my-bikes) at the top, sections in cards, Delete my account last in profile-actions.
 - Commit 2: privacy_screen.dart, sessions_screen.dart, two_factor_screen.dart per their mock-ups; removing a privacy zone confirmed; the two-factor submit on bottomAction.
 - Commit 3: supporter_activation_screen.dart and supporter_celebration_screen.dart — themed colours, no uppercase, radii from tokens.
 ### Files
 - app/lib/features/profile/*, features/privacy/privacy_screen.dart, features/supporter/*, both .arb files.
 ### Tests
 - ProfileScreen_ShouldOpenMyBikes_WhenTheRowIsTapped.
 - ProfileScreen_ShouldUseSheetsForPasswordAndDelete_WhenOpened.
 - PrivacyScreen_ShouldConfirmBeforeRemovingAZone_WhenRemoveIsTapped.
 - SupporterCelebration_ShouldUseThemeColours_WhenShown.
 ### Risks
 - The celebration is the one bespoke screen; keep its animation through core/motion.dart so reduced motion stops it.
 ### Records
 - None.
 Plan — Story 9: Inbox
 ### Status
 Final
 ### Decided by default
 - Grouping is by the notification's existing area field; unread first within the page, not a second sort control.
 - No new route or provider work.
 ### Decision
 - One commit: notifications_screen.dart per NotificationsPage — Mark all read as the one header action (key kept), rows as AppCard list rows grouped by area, unread marked by ink weight and a dot, empty state kept.
 ### Files
 - app/lib/features/notifications/notifications_screen.dart, both .arb files.
 ### Tests
 - NotificationsScreen_ShouldGroupByArea_WhenNotificationsSpanTwoAreas.
 - NotificationsScreen_ShouldOpenTheTarget_WhenARowIsTapped (ride, bike, club).
 - Overflow at 390/600/1300.
 ### Risks
 - Deep links must survive the rewrite; the existing tap handler stays.
 ### Records
 - None.
 Plan — Story 10: Sign-in and the signed-out screens
 ### Status
 Final
 ### Decided by default
 - AuthPage (already restyled in Story 1) gains a primaryAction slot pinned at the bottom; screens move their submit there.
 - The wordmark uses the display style already used by the sidebar; no new type token.
 ### Decision
 - Commit 1: auth_page.dart gains the pinned button and the brand block; sign-in, register, forgot, reset move their submit onto it.
 - Commit 2: verify_email_screen.dart and server_setup_screen.dart per their mock-ups; expired link offers "Send a new link"; the web still skips server setup.
 - Commit 3: copy pass over the signed-out screens, both languages.
 ### Files
 - app/lib/features/auth/*, both .arb files.
 ### Tests
 - SignInScreen_ShouldExplainWrongPassword_WhenSignInFails (existing, kept).
 - ForgotPasswordScreen_ShouldSayTheSame_WhenTheAddressIsUnknownOrKnown.
 - VerifyEmailScreen_ShouldOfferANewLink_WhenTheLinkExpired.
 - ServerSetupScreen_ShouldBeSkipped_WhenTheWindowIsTheWeb.
 ### Risks
 - The pinned button shrinks the keyboard-visible area on a phone; test with the keyboard inset.
 ### Records
 - None.
 Plan — Story 11: Admin
 ### Status
 Final
 ### Decided by default
 - The four tabs become sideways-scrolling chips in the page frame, with the existing tab-overview/tab-accounts/tab-clubs/tab-settings keys kept on the taps.
 - Role, reset-link and club forms become sheets; delete stays last, red, confirmed.
 ### Decision
 - Commit 1: admin_screen.dart frame and tab chips.
 - Commit 2: overview_tab.dart, accounts_tab.dart, clubs_tab.dart, settings_tab.dart per their mock-ups, row menus via PageMenu.
 ### Files
 - app/lib/features/admin/*, both .arb files.
 ### Tests
 - AdminScreen_ShouldKeepTheFourTabs_WhenOpenedByAnAdmin.
 - AccountsTab_ShouldConfirmBeforeDeleting_WhenDeleteIsPicked.
 - AdminScreen_ShouldRefuse_WhenTheRiderIsNotAnAdmin (existing, kept).
 ### Risks
 - Admin tests tap tab-* keys in five files; keep them on the chips.
 ### Records
 - None.
 ### Questions for the owner
 None
