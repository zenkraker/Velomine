# Page mock-ups

A mock-up of every screen in the app, drawn in the visual language of [`../language.md`](../language.md) with the values of [`../tokens.json`](../tokens.json). Each page has an HTML mock-up and a guideline (`.md`) that names its route and the Flutter file that builds it.

- **Before changing a screen**, read its guideline and its mock-up. The mock-up shows the structure and the order of the content; the example names and numbers are invented.
- **The mock-ups are a target, not the code.** Where a mock-up and the code differ, the mock-up is the intended design; build it from the shared widgets in `app/lib/core/widgets/`.
- **Open a mock-up in a browser** to see it: it reads `tokens.css` (generated from `tokens.json`, Night by default, Day with the system setting) and `bundle.css` (the shared classes).
- **A design change lands here first**, then in the code. The pieces under Cards, Charts, Controls, Maps and Navigation are the building blocks the pages are made of.

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
- [Sidebar](navigation/Sidebar.html) ([guideline](navigation/Sidebar.md)): The navigation from 1200 dp: the wordmark, four main destinations, and the privacy note, profile and settings at the bottom.
