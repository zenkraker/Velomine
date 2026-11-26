# Velomine design

The design of every screen and component in the app: the visual language below, and a mock-up with a guideline for each page and building block. **Every screen and every shared widget follows it**, and nothing else describes the design.

- **The code follows these pages.** Where a mock-up or guideline and the code differ, the page is right and the code is a bug. Build from the shared widgets in `app/lib/core/widgets/`.
- **A new screen or component gets its guideline and mock-up here first**, in the same change as the code or before it, and is listed below. A design change lands here first, then in the code.
- **Before changing a screen**, read its guideline and its mock-up. The mock-up shows the structure and the order of the content; the example names and numbers are invented.
- **Open a mock-up in a browser** to see it: it reads `tokens.css` (generated from [`../tokens.json`](../tokens.json), Night by default, Day with the system setting) and `bundle.css` (the shared classes). The pieces under Cards, Charts, Controls, Maps and Navigation are the building blocks the pages are made of.

## The visual language

The rules every screen follows. The values are in `docs/design/tokens.json`; `app/lib/core/theme.dart` and `app/lib/core/tokens.dart` implement them, and `app/test/design_tokens_test.dart` keeps the theme equal to the tokens. Change a value in `tokens.json` and the theme in the same change.

Velomine is a cycling app for riders and their clubs: rides, progress, bikes and a club, on the phone and on the web. It is dark first, calm and data-rich. One colour, volt, carries the energy; everything else stays quiet so the rider's numbers lead.

### Principles

1. **One question per page.** Each page answers one question ("How am I this week?", "What is my power profile?"). A second question gets its own page, tab or detail route.
2. **One fact per card.** A card has four parts, in this order: a title, one number, one sentence that explains it, and at most one link to the details ("Power →"). A card never repeats a number shown elsewhere on the page.
3. **Summary first, details one tap away.** An overview page is a grid of fact cards; each links to its detail page. Long explanations live behind an info button, never in the card.
4. **One accent, used sparingly.** Volt (`accent`, `accent-strong`) marks what is current, selected or the main action. Everything else is `ink`, `ink-muted` and the surfaces.
5. **Surfaces, not lines.** Cards are set apart by their fill (`card` on `canvas`): no borders, no shadows. Dividers (`hairline`) only inside a card.
6. **Glass only where something floats.** The nav pill, sheets and the info card over a map use `glass` with `blur-glass` and `shadow-float`. Cards in the page flow are never glass.
7. **The route glows.** On a map the route is the brightest thing: the tiles dimmed toward `map-ground`, a blurred `route-glow` stroke under a sharp `accent-strong` line.

### Content

- Write in plain, short sentences, in English and Italian; every string exists in both.
- Sentence case everywhere: titles, buttons, nav. No uppercase eyebrows, no emoji.
- Speak to the rider as "you" ("Your best 20 minutes"). Name things as riders do: ride, climb, effort, not "activity entity".
- Numbers carry their unit with a thin gap, formatted for the language: `69.7 km`, `2 h 35`, `1,416 m` in English; `69,7 km`, `1.416 m` in Italian. Store SI; format only in the view.
- A card's sentence says what the number means, not how it was computed: "Keep it easy: endurance pace, no hard efforts."
- Errors say what happened and what to do: "Couldn't load your rides. Check the connection and try again."

### Colour

- Page: `canvas`. Cards, sidebar, sheets: `card`. A hovered row or an inset block: `card-raised`.
- Text: `ink` for titles, numbers and body; `ink-muted` for units, details, captions and axis labels.
- The main action is a filled pill in `accent` with `on-accent` text. There is one per screen.
- Links, the gauge arc, the current bar and the route line use `accent-strong`. By day this is olive (`#4e6300`), because volt on white is unreadable.
- Selected nav item, segment or chip: `accent-soft` ground, `on-accent-soft` text.
- Past bars: `bar-muted`. The current period: `accent-strong`. Only the current and the peak bar carry a value label.
- `signal` (tail light) marks the finish and states that ask for care; `warning` and `danger` always come with a word or an icon, never colour alone.
- Ride charts use the `series-*` colours so a signal looks the same everywhere: power is always `series-power`, heart rate always `series-heartrate`.
- Both themes are first class. Night is the default look; Day follows the system setting.

### Type

- Two families: Geist (`sans`) for everything you read and every number; Instrument Serif (`display`) only for the page title and the wordmark.
- The scale: `page-title` 40, `kpi` 40, `stat` 24, `card-title` 17, `body` and `nav-label` 15, `caption` 13, `axis` 12. Do not add sizes.
- **One body size, 15, everywhere.** Any running text, a card's explaining sentence or a row's main line is `body` 15; there is no 14 in this design. In Flutter both `bodyLarge` and `bodyMedium` carry the 15, so a widget cannot land off the scale by choosing the other body slot; `design_tokens_test` fails if either drifts.
- Big numbers are `kpi` at regular weight with tabular figures; the unit beside them is `caption` size in `ink-muted`.
- Card titles are `card-title`, one line, sentence case.

### Space and layout

- The spacing scale is `space-xs` 4 · `space-sm` 8 · `space-md` 12 · `space-lg` 16 · `space-xl` 24 · `space-xxl` 32 · `space-xxxl` 48. Never a literal.
- Cards: padding `space-xl`, gap between cards `space-lg`, corners `radius-lg`.
- Size classes: compact under 600 dp (one column, gutter `space-lg`, floating nav pill), medium 600–1199 dp (two columns, gutter `space-xl`, collapsed rail), expanded from 1200 dp (up to four columns, gutter `space-xxl`, expanded sidebar). Content is at most 1160 px wide, centred in the space beside the sidebar.
- In a row, cards are the same height; a grid row is full: no card alone with empty space beside it.
- Touch targets are at least 48 × 48.

### Cards

- **Stat card** (`StatCard`): title, `kpi` number with unit, one `caption` or `body` sentence, one `accent-strong` link with an arrow. Optional state chip after the number.
- **Chart card**: title, one chart, an optional control (period) in the title row, at most one sentence under the chart.
- **List card**: title, rows with `body-strong` and `caption`, row actions appear on hover (web) or in the row's `⋯` menu, "All … →" link at the bottom.

### Charts

- Drawn with `fl_chart` through the app's chart widgets (`AreaChart`, `BarChart`, `GoalGauge`), so values, axes and interaction come from one library. A chart the library cannot express is a special case for the owner; the app never hand-draws a chart with a painter without that answer.
- Faint `hairline` grid at round values (0, 40, 80, 120), at most four lines; axis labels in `axis` and `ink-muted`.
- Bars have `radius-sm` tops and a vertical fade from full colour at the top to 55 % at the base.
- Area charts: a 2 px line, the area under it faded to transparent, the last point marked with a dot and its value.
- Fewer labels on a phone: compute the label step from the width so labels never touch.
- No data: show the empty state with a sentence, never empty axes.

### Maps

- Tiles from the server's tile address, dimmed toward `map-ground` and desaturated, in both themes.
- The route: a 14 px `route-glow` stroke blurred by 6 px, then a 4 px `accent-strong` line. Start: an `accent` dot. Finish: a `signal` dot with a `card` ring.
- Facts about the ride sit in a `glass` card at the bottom of the map, `radius-xl`.

### Navigation

- Four main destinations, in this order everywhere: Rides, Progress, Goals, Club. A rider who turned auto training on gets a fifth, Training, after Rides: Rides, Training, Progress, Goals, Club.
- Phone: a floating `glass` pill with the destinations; the selected one sits on `accent-soft`. Sub-pages of a destination are tabs at the top of its page.
- From 1200 dp: the sidebar on `card`, with the `brand` wordmark, destinations that expand (Rides ▾, Progress ▾, Club ▾; Training and Goals are one page each), and the account, settings and privacy note at the bottom. The current page is `accent-soft`.
- Progress has one overview and four sub-pages, each built around one main chart: Overview ("How am I today and this week?"), Fitness (fitness, fatigue and form), Power (power curve and FTP), Totals (weeks, months, years) and Wellbeing (readiness and check-ins).
- A sub-page's title row carries the parent's name as a `caption` above the `page-title`.
- An overview page fits in about one screen. When it grows past that, a card moves to its own sub-page, not further down the page.
- One main action per screen, as a filled pill in the page header. Rare and destructive actions go in the header's `⋯` menu, destructive last, in `danger`.
- The action and the `⋯` menu sit at the **end of the title row, level with the title**. They are never centred, never float over the content and never get a row of their own: a page whose buttons sit halfway across the header is a bug in the page scaffold, not a layout choice.

### Motion

- Durations 120, 220 and 320 ms; a small spring for things that arrive (sheet, pill, chip), fast-out-slow-in for things that move.
- Everything stops when the system asks to reduce motion.

### Iconography

- Material Symbols, outlined at rest and filled when selected, 24 px, in `ink` or `ink-muted`; `on-accent-soft` when selected.
- Every icon-only button has a label for screen readers.
- The previews in this system draw simplified line icons in place of Material Symbols.

### In Flutter

- Colours map to `ColorScheme` as each token's note says; the rest live in the `VelomineColors` theme extension.
- Spacing and radii are `AppSpacing` and `AppRadius` in `lib/core/tokens.dart`; never a literal `EdgeInsets` or radius.
- Text styles come from `Theme.of(context).textTheme`; `kpi` and `stat` are added there as named styles.

## Rides

- [ImportPage](rides/ImportPage.html) ([guideline](rides/ImportPage.md)): Import from Strava: the progress of reading a Strava export ZIP on the server. Route `/rides/import/:id`, `features/rides/import/import_screen.dart`.
- [RecordPhone](rides/RecordPhone.html) ([guideline](rides/RecordPhone.md)): Record: start a ride on the phone, and the rides saved on it. Route `/record`, `features/recording/recording_screen.dart`. Phone only; the web has no recorder.
- [RecordingLivePhone](rides/RecordingLivePhone.html) ([guideline](rides/RecordingLivePhone.md)): Recording, live: the same Record page while a ride is in progress. `features/recording/recording_screen.dart` (`_LiveCard`).
- [RideDetailPage](rides/RideDetailPage.html) ([guideline](rides/RideDetailPage.md)): Ride: one ride with everything read from its file. Route `/rides/:id`, `features/rides/detail/ride_detail_screen.dart`.
- [RidesPage](rides/RidesPage.html) ([guideline](rides/RidesPage.md)): Rides: the rider's list of rides, newest first. Route `/rides`, `features/rides/rides_screen.dart`.

## Progress

- [FitnessPage](progress/FitnessPage.html) ([guideline](progress/FitnessPage.md)): Progress → Fitness answers "Is my fitness going up?" with one big chart of fitness, fatigue and form, and below it the things that drive them.
- [PowerPage](progress/PowerPage.html) ([guideline](progress/PowerPage.md)): Progress → Power answers "What is my power profile?": the numbers riders train by on top, the power curve and best efforts under them.
- [ProgressDesktop](progress/ProgressDesktop.html) ([guideline](progress/ProgressDesktop.md)): The Progress overview from 1200 dp: it answers only "How am I today and this week?", and every card opens the sub-page that answers the next question.
- [ProgressPhone](progress/ProgressPhone.html) ([guideline](progress/ProgressPhone.md)): The Progress overview on a phone (under 600 dp): the same cards as on the desktop in one column, the sub-pages as tabs at the top, and the glass nav pill floating over the bottom.
- [TotalsPage](progress/TotalsPage.html) ([guideline](progress/TotalsPage.md)): Progress → Totals answers "What did I do each week, month and year?" with one chart and one table.
- [WellbeingPage](progress/WellbeingPage.html) ([guideline](progress/WellbeingPage.md)): Progress → Wellbeing answers "How do I feel, and why is my readiness what it is?". Wellbeing is health data: only the owner sees this page.

## Goals

- [EventsPage](goals/EventsPage.html) ([guideline](goals/EventsPage.md)): Events: the rider's races and sportives. Route `/progress/events`, opened from Goals, `features/progress/events_screen.dart`.
- [GoalsPage](goals/GoalsPage.html) ([guideline](goals/GoalsPage.md)): Goals as a main destination: it answers "Am I hitting my goals?" with one GoalGauge card per goal and Add goal as the page's one main action.

## Training

Shown only to a rider who turned auto training on.

- [TrainingPage](training/TrainingPage.html) ([guideline](training/TrainingPage.md)): Training: today's session, this week, the goal. Route `/training`, `features/training/training_screen.dart`.
- [SessionPage](training/SessionPage.html) ([guideline](training/SessionPage.md)): one planned session, and how it went. Route `/training/sessions/:id`, `features/training/session_screen.dart`.
- [TrainingSetupPage](training/TrainingSetupPage.html) ([guideline](training/TrainingSetupPage.md)): three questions before auto training starts. Route `/training/setup`, `features/training/training_setup_screen.dart`.

## Club

- [AddRoutePage](club/AddRoutePage.html) ([guideline](club/AddRoutePage.md)): Add a route: a full-page form. Routes `/club/routes/new` and `/club/routes/:id/edit`, `features/routes/route_forms.dart`.
- [AthletePage](club/AthletePage.html) ([guideline](club/AthletePage.md)): Athlete: what one athlete shares with their coach. Route `/club/athletes/:id`, `features/coach/coach_athlete_screen.dart`.
- [AthletesPage](club/AthletesPage.html) ([guideline](club/AthletesPage.md)): Athletes: for a coach, the members who share with them. Route `/club/athletes`, `features/coach/coach_athletes_screen.dart`.
- [CalendarFeedPage](club/CalendarFeedPage.html) ([guideline](club/CalendarFeedPage.md)): Calendar subscription: a private iCalendar address for the club's rides. Route `/club/calendar`, `features/calendar/calendar_feed_screen.dart`.
- [ClubPage](club/ClubPage.html) ([guideline](club/ClubPage.md)): Club: the rider's club. Route `/club`, `features/club/club_screen.dart` and `features/club/widgets/`.
- [ClubRideDetailPage](club/ClubRideDetailPage.html) ([guideline](club/ClubRideDetailPage.md)): Club ride: one planned ride. Route `/club/rides/:id`, `features/calendar/club_ride_detail_screen.dart`.
- [ClubRidesPage](club/ClubRidesPage.html) ([guideline](club/ClubRidesPage.md)): Club rides: the club calendar. Route `/club/rides`, `features/calendar/club_rides_screen.dart`.
- [CoachRidePage](club/CoachRidePage.html) ([guideline](club/CoachRidePage.md)): Shared ride: one ride an athlete shared, as their coach sees it. Route `/club/athletes/:id/rides/:rideId`, `features/coach/coach_ride_screen.dart`.
- [JoinClubPage](club/JoinClubPage.html) ([guideline](club/JoinClubPage.md)): Join a club: with the code the owner shared. Route `/join`, `features/club/join_club_screen.dart`.
- [NearbyClubsPage](club/NearbyClubsPage.html) ([guideline](club/NearbyClubsPage.md)): Clubs near you: discoverable clubs on this server, nearest first. Route `/clubs`, `features/club/nearby_clubs_screen.dart`.
- [NoClubPage](club/NoClubPage.html) ([guideline](club/NoClubPage.md)): Club, without a club: the same route `/club` for a rider who is in none. `features/club/club_screen.dart`.
- [PlanRidePage](club/PlanRidePage.html) ([guideline](club/PlanRidePage.md)): Plan a ride: a full-page form. Routes `/club/rides/new` and `/club/rides/:id/edit`, `features/calendar/plan_ride_screen.dart`.
- [RouteDetailPage](club/RouteDetailPage.html) ([guideline](club/RouteDetailPage.md)): Route: one club route. Route `/club/routes/:id`, `features/routes/route_detail_screen.dart`.
- [RoutesPage](club/RoutesPage.html) ([guideline](club/RoutesPage.md)): Routes: the club's route library. Route `/club/routes`, `features/routes/routes_screen.dart`.
- [StartClubPage](club/StartClubPage.html) ([guideline](club/StartClubPage.md)): Start a club: name, location and whether riders nearby can find it. Route `/club/start`, `features/club/start_club_screen.dart`.

## Bikes

- [BikeDetailPage](bikes/BikeDetailPage.html) ([guideline](bikes/BikeDetailPage.md)): Bike: one bike, its parts and their wear, and its service. Route `/bikes/:id`, `features/bikes/bike_detail_screen.dart`, `service_section.dart`.
- [BikesPage](bikes/BikesPage.html) ([guideline](bikes/BikesPage.md)): Bikes: every bike and what it needs. Route `/bikes`, opened from Profile → My bikes, `features/bikes/bikes_screen.dart`.

## Profile

- [PrivacyPage](profile/PrivacyPage.html) ([guideline](profile/PrivacyPage.md)): Ride privacy: what others see of the rider's rides. Route `/privacy`, `features/privacy/privacy_screen.dart`.
- [ProfilePage](profile/ProfilePage.html) ([guideline](profile/ProfilePage.md)): Profile: the rider's numbers, preferences and account. Route `/profile`, `features/profile/profile_screen.dart`.
- [SessionsPage](profile/SessionsPage.html) ([guideline](profile/SessionsPage.md)): Devices and sessions: every signed-in device. Route `/profile/sessions`, `features/profile/sessions_screen.dart`.
- [SupporterCelebration](profile/SupporterCelebration.html) ([guideline](profile/SupporterCelebration.md)): Licence activated: the one bespoke screen, shown once after a supporter key is accepted. Route `/profile/supporter/activated`, `features/supporter/supporter_celebration_screen.dart`.
- [SupporterPage](profile/SupporterPage.html) ([guideline](profile/SupporterPage.md)): Supporter: activate a supporter licence. Route `/profile/supporter`, `features/supporter/supporter_activation_screen.dart`. After it the bespoke celebration screen plays (`supporter_celebration_screen.dart`, route `/profile/supporter/activated`).
- [TwoFactorPage](profile/TwoFactorPage.html) ([guideline](profile/TwoFactorPage.md)): Two-factor sign-in: turn the authenticator on or off. Route `/profile/two-factor`, `features/profile/two_factor_screen.dart`.

## Inbox

- [NotificationsPage](inbox/NotificationsPage.html) ([guideline](inbox/NotificationsPage.md)): Notifications: the rider's inbox. Route `/notifications`, opened from the bell in the rail or the phone header, `features/notifications/notifications_screen.dart`.

## Sign-in

- [ForgotPasswordPage](sign-in/ForgotPasswordPage.html) ([guideline](sign-in/ForgotPasswordPage.md)): Reset your password. Route `/forgot-password`, `features/auth/forgot_password_screen.dart`. Never says whether the address has an account.
- [RegisterPage](sign-in/RegisterPage.html) ([guideline](sign-in/RegisterPage.md)): Create an account. Route `/register`, `features/auth/register_screen.dart`. After it: "Your account is ready", or that an admin has to approve it, or the email link to confirm.
- [ResetPasswordPage](sign-in/ResetPasswordPage.html) ([guideline](sign-in/ResetPasswordPage.md)): Choose a new password, from the emailed link. Route `/reset-password`, `features/auth/reset_password_screen.dart`.
- [ServerSetupPhone](sign-in/ServerSetupPhone.html) ([guideline](sign-in/ServerSetupPhone.md)): Server: the phone's first screen, choosing which Velomine server to use. `features/auth/server_setup_screen.dart`. The web app is always on its own server and skips it.
- [SignInPage](sign-in/SignInPage.html) ([guideline](sign-in/SignInPage.md)): Sign in. Route `/sign-in`, `features/auth/sign_in_screen.dart` inside `auth_page.dart`.
- [VerifyEmailPage](sign-in/VerifyEmailPage.html) ([guideline](sign-in/VerifyEmailPage.md)): Confirm your email: the link from the sign-up email. Route `/verify-email`, `features/auth/verify_email_screen.dart`. While it checks: "Confirming your address…"; an expired link offers Send a new link.

## Admin

- [AdminAccountsPage](admin/AdminAccountsPage.html) ([guideline](admin/AdminAccountsPage.md)): Admin → Accounts. `features/admin/accounts_tab.dart`.
- [AdminClubsPage](admin/AdminClubsPage.html) ([guideline](admin/AdminClubsPage.md)): Admin → Clubs. `features/admin/clubs_tab.dart`.
- [AdminOverviewPage](admin/AdminOverviewPage.html) ([guideline](admin/AdminOverviewPage.md)): Admin → Overview. Route `/admin`, `features/admin/admin_screen.dart` and `overview_tab.dart`. For server admins only, from the account menu.
- [AdminSettingsPage](admin/AdminSettingsPage.html) ([guideline](admin/AdminSettingsPage.md)): Admin → Settings. `features/admin/settings_tab.dart`.

## Cards

- [GoalGauge](cards/GoalGauge.html) ([guideline](cards/GoalGauge.md)): One goal on one card: a half-circle gauge with the percentage, the current value against the target, and one sentence that says what is left.
- [StatCard](cards/StatCard.html) ([guideline](cards/StatCard.md)): One fact on a card: a title, one big number, one sentence that explains it, and one link to its details.

## Charts

- [AreaChart](charts/AreaChart.html) ([guideline](charts/AreaChart.md)): One value over time as a line with a fading area under it, the latest point marked with its value.
- [BarChart](charts/BarChart.html) ([guideline](charts/BarChart.md)): A total per period (week, month, year) as rounded bars that fade toward the base, with the current period in the accent.

## Controls

- [Controls](controls/Controls.html) ([guideline](controls/Controls.md)): The four controls every page draws from: the main action, the period selector, the sport filter and the page menu.

## Maps

- [RouteMap](maps/RouteMap.html) ([guideline](maps/RouteMap.md)): A ride's route on a dimmed map, drawn as a glowing line, with the ride's facts on a glass card over the bottom of the map.

## Navigation

- [NavPill](navigation/NavPill.html) ([guideline](navigation/NavPill.md)): The phone's main navigation: a floating glass pill with Rides, Progress, Goals and Club, above the content and the safe area.
- [Sidebar](navigation/Sidebar.html) ([guideline](navigation/Sidebar.md)): The navigation from 1200 dp: the wordmark, the main destinations, and the privacy note, profile and settings at the bottom.
