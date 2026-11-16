# UI refresh: audit and user stories

The owner chose a new layout for the app in November 2026. This document records those decisions, what the code does today against them, and the user stories that bring every screen in line. Each story is sized for one agent and one pull request.

## The decisions

| # | Topic | Decision |
|---|-------|----------|
| 1 | Phone navigation | A **floating pill** above the content, translucent, shrinking while the page scrolls down. |
| 2 | Tabs | Three: **Rides · Progress · Club**. |
| 2a | Recording | Not a tab. A **Start ride** button in the Rides header on the phone; a ride in progress shows as a **banner above the pill** that opens `/record`. The web has neither. |
| 2b | Bikes | Leaves the bar. Reached from **Profile → My bikes**; the `/bikes` routes stay. |
| 3 | Page top | A **large title that collapses** into a small bar on scroll, the same on every screen, with no divider line. |
| 4 | Main action | **One filled button in the page header** (`+ Add bike`), in the same place on every screen, on every width. No floating action buttons. |
| 5 | Full-page forms | A **full-width primary button pinned to the bottom**, above the keyboard. Cancel is the back arrow. |
| 6 | Short tasks | **Bottom sheets** for short tasks (a form of a few fields, a picker, filters). Full pages only for long flows (import, start a club, plan a ride). |
| 7 | Rare and destructive actions | A **`⋯` menu** in the page or card header. Delete, Remove, Leave and Cancel ride are red, last in the menu, after a divider, and always confirmed. No destructive action is a visible button. |
| 8 | Tablet and desktop | **One navigation rail**: collapsed (icons and labels) from 600 dp, expanded (brand, labels, club, account) from 1200 dp. It replaces both today's rail and today's sidebar. |
| 9 | Visual style | **Bold expressive**: strong colour, big type, tonal surfaces instead of outlined cards, springy motion that stops when the system asks to reduce motion. |
| — | Rollout | Small pull requests in the order below, each producing an APK to try. |

## What the code does today

The audit covered `app/lib/` (34,500 lines, 56 test files) on 2026-11-16.

### The frame

- `home_shell.dart` draws three different frames: a phone `AppBar` with a bottom border and a `NavigationBar` of five tabs; a `NavigationRail` from 600 dp; and a hand-built `_Sidebar` from 1200 dp. The phone title repeats the tab's name ("Rides" over the Rides tab).
- Tab icons mix filled and outlined glyphs, and none has a `selectedIcon`. Rides and Bikes use two different bike icons.
- Screens publish phone title-bar buttons through `pageActionsProvider` / `publishPhoneActions` (`core/page_actions.dart`). Only `rides_screen.dart` and `progress_screen.dart` use it.

### Where the main action lives

There are four patterns for one concept:

| Pattern | Screens |
|---------|---------|
| FAB on the phone, header button from 600 dp (`wide ? null : add`) | `bikes/bikes_screen.dart`, `routes/routes_screen.dart`, `calendar/club_rides_screen.dart` |
| FAB always, plus phone title-bar icons | `rides/rides_screen.dart` (upload FAB, filter and import icons via `publishPhoneActions`) |
| Phone title-bar icon | `progress/progress_screen.dart` (filters) |
| A button somewhere in the body | most other screens |

### Pages that build their own frame

These do not use `PageScaffold` (`core/widgets/page_scaffold.dart`):

- `recording/recording_screen.dart`: its own `Scaffold` and `ListView` with raw padding `fromLTRB(16, 8, 16, 96)`, a hand-styled section title ("On this phone"), and an empty list as a bare `Text` instead of `EmptyState`.
- `admin/admin_screen.dart` and its four tabs.
- `club/nearby_clubs_screen.dart` and `club/location_picker.dart`: their own `Scaffold` and `AppBar`. Both sit outside the shell route, so they need a frame, just not a hand-made one.
- `auth/auth_page.dart` and the six auth screens: a frame of their own, and it re-implements the eyebrow style.
- `supporter/supporter_celebration_screen.dart`: a bespoke celebration. It may stay bespoke.

### Hand-rolled copies of shared widgets

| Shared widget | Re-implemented in |
|---------------|-------------------|
| `FormSheet` (handle, padding `20, 8, 20, 16`, title, Cancel/Save) | `bikes/bike_forms.dart` twice (bike form ~L240, part form ~L795), `recording/recording_screen.dart` (`_SettingsSheet` ~L268) |
| `SectionCard` (Card, title in `titleMedium`, rows) | `club/club_screen.dart`: `_planCard`, `_joinCodeCard`, `_membersCard`, `_athletesCard`, `_requestsCard`, `_locationCard`, `_ClubHeader`, `_SharingCard` |
| `StatTile` | `progress/progress_screen.dart` ~L420 (uppercase label and value in a `Card`) |
| The page eyebrow style (`toUpperCase`, `letterSpacing: 1.76`) | `core/widgets/page_scaffold.dart`, `auth/auth_page.dart`, and a variant in `progress/progress_screen.dart` (`letterSpacing: 1.3`) |
| A confirmation dialog | 15 hand-written `AlertDialog`s: `admin/accounts_tab.dart` ×2, `club/club_screen.dart` ×3, `club/nearby_clubs_screen.dart`, `rides/detail/ride_detail_screen.dart`, `privacy/privacy_screen.dart`, `calendar/calendar_feed_screen.dart`, `calendar/club_ride_detail_screen.dart`, `bikes/service_section.dart` ×2, `bikes/bike_detail_screen.dart` ×2, `routes/route_detail_screen.dart`. There are four local helpers, `_confirm` / `_confirmDelete`, and no shared one. |
| An inline error line (`TextStyle(color: scheme.error)`) | about 15 places, including `FormSheet`, `club_screen.dart` ×4, `profile_screen.dart` ×2, `recording_screen.dart` ×2, `bike_forms.dart` ×3, `privacy_screen.dart`, `start_club_screen.dart`, `admin/clubs_tab.dart` |
| A loading state (`Center(child: CircularProgressIndicator())`) | 21 places across 25 files, while `core/placeholder_block.dart` exists for skeletons |

### Forms in dialogs (decision 6 wants sheets)

`admin/accounts_tab.dart` (`_RolesDialog`, `_ResetLinkDialog`), `admin/clubs_tab.dart` (`_CreateClubDialog`, `_OwnerDialog`, `_PlanDialog`), `club/nearby_clubs_screen.dart` (`_JoinRequestDialog`), `profile/profile_screen.dart` (`_ChangePasswordDialog`, `_DeleteAccountDialog`), `progress/goals.dart` (goal editor), `privacy/privacy_screen.dart` (`_ZoneDialog`), `bikes/service_forms.dart` (`_DoneDialog`), and `bikes/bike_forms.dart` (~L533 and the template picker ~L611).

### Destructive actions shown as visible buttons (decision 7 wants a `⋯` menu)

- `club/club_screen.dart` `_leaveCard`: a red "Leave club" text button.
- `profile/profile_screen.dart` ~L580: a red "Delete my account" outlined button.
- `calendar/club_ride_detail_screen.dart` ~L193: a red "Cancel ride" button.
- `calendar/calendar_feed_screen.dart` ~L160: a red "Stop calendar" button.
- `progress/wellbeing_card.dart` ~L208: a red "Withdraw consent" text button.
- `bikes/service_section.dart` ~L445, ~L520 and `bikes/bike_detail_screen.dart` ~L580: "Remove" text buttons on rows.
- `recording/recording_screen.dart` ~L674: a delete icon on each local ride.

Already right: `rides/detail/ride_detail_screen.dart` and `bikes/bike_detail_screen.dart` put Delete in a `PopupMenuButton`, red and after a divider. Use them as the reference.

### Full-page forms (decision 5 wants a pinned bottom button)

The submit button is the last child of the scrolling body in `calendar/plan_ride_screen.dart` (~L322), `club/start_club_screen.dart` (~L144), `club/join_club_screen.dart` (~L88), `routes/route_forms.dart` (~L210, ~L323), `supporter/supporter_activation_screen.dart` (~L102), `profile/two_factor_screen.dart` (~L81, ~L133), `rides/import/import_screen.dart` (~L95) and every auth screen.

### Hard-coded numbers instead of `core/tokens.dart`

- Raw `EdgeInsets`: `recording_screen.dart` (6), `bike_forms.dart` (5), `club_screen.dart` (3, `EdgeInsets.all(8)`), `goals.dart` (2), `coach_athlete_screen.dart` (2), `nearby_clubs_screen.dart`, `location_picker.dart`, `route_forms.dart`, `training_summary.dart`, `wellbeing_card.dart`, `readiness_card.dart`, `lap_table.dart`, `ride_detail_screen.dart`, `rides_screen.dart`, `ride_type_chips.dart`, `route_map.dart`, `home_shell.dart`.
- Numeric `SizedBox` gaps: 25, mostly in `progress/` (`readiness_card.dart` 7, `training_summary.dart` 4, `power_summary.dart` 4) and `recording_screen.dart` (3).
- Literal colours: `club/location_picker.dart` (`Colors.white`, `Colors.black87` over the map) and `rides/detail/full_route_map.dart` (`Colors.black`).

### Already consistent, to keep

- `core/tokens.dart`: spacing, radius, breakpoints and layout.
- `EmptyState`, `ErrorState`, `SectionCard`, `SectionHeading`, `StatTile`, `CardGrid`, `ToolbarRow`, `AppTextField`, `RangeSelector` and the chart chrome. About 25 screens use `PageScaffold`.
- `core/motion.dart` already honours the reduced-motion setting.
- `test/contrast_test.dart` guards the colour pairs; a theme change must keep it green.

## Rules for every story

The agent reads `AGENTS.md` and `.claude/skills/flutter/SKILL.md` first. Those win over this document.

- **No new dependencies.** The pill, the rail and the expressive theme are built from Flutter's own widgets. Community packages (for example `m3e_*` on pub.dev) need the approval process in `AGENTS.md`.
- **Keep every existing widget `Key`** that a test finds. When a button moves (FAB → header, body → `⋯` menu), its key moves with it, and the test changes only where it taps.
- **Every new user-facing string** goes in `app_en.arb` and `app_it.arb`.
- **Layout numbers come from `core/tokens.dart`**; add a token rather than a literal. Colours come from the theme or `VelomineColors`.
- **Every animation goes through `core/motion.dart`.** Tap targets stay at least 48×48, and icon-only buttons carry a tooltip or `Semantics` label.
- **Test names follow `Subject_ShouldDoSomething_WhenCondition`.** Update widget tests in `app/test/` for what moved, and add one test for each new shared widget.
- **Run `just codegen`** after changing a `@riverpod` provider and commit the generated files. Run **`just check`** before every commit.
- **Every page uses `PageScaffold`.** A screen with its own `Scaffold`, `AppBar` or hand-made header moves onto `PageScaffold`, inside the shell or outside it (with `onBack`). Only a screen that needs something `PageScaffold` cannot give stays bespoke, such as the supporter celebration, and the story says why.
- **Build for web and phone.** No `dart:io` in shared code.
- **One story is one pull request.** Its description lists the story id and what a reviewer should try on the phone.

## Stories

Stories in a phase can run in parallel unless one names another under **Depends on**.

### Phase 0 — Foundations: shared widgets and theme

#### UI-01 Bold expressive theme

*As a rider, I want the app to look confident and current, so it feels like a sports app made this year.*

- **Files:** `core/theme.dart`, `core/tokens.dart`, `test/contrast_test.dart`.
- **Do:**
  - Cards lose their outline border and use tonal surfaces (`surfaceContainer*`, and `primaryContainer` for highlighted cards).
  - Raise the radius scale: cards `AppRadius.large` → 28, sheets 28 at the top.
  - Make headline and display type larger. Keep Instrument Serif for display and Geist for text.
  - Use a stronger primary for filled buttons and selection.
  - Add `AppMotion` spring curves, used through `core/motion.dart`.
  - Remove the AppBar bottom border from the theme.
- **Done when:** the light and dark themes both pass `contrast_test.dart`; no screen file changes; the phone screenshots in the PR show Rides, Progress, Club and a bike in both themes.

#### UI-02 Collapsing page header in `PageScaffold`

*As a rider, I want every screen to start with a big clear title that gets out of the way when I scroll, so I always know where I am without losing space.*

- **Files:** `core/widgets/page_scaffold.dart`, a new test `test/page_scaffold_test.dart`.
- **Do:**
  - Rebuild `PageScaffold` on a `CustomScrollView` with a large collapsing title (`SliverAppBar.large`-style) at every width. The eyebrow and subtitle show under the large title and hide when it collapses.
  - Add parameters: `primaryAction` (one widget, the header button), `menu` (the `⋯` menu items), `onBack` (shows a back arrow), and `trailing` (notifications and account, supplied by the shell).
  - Keep `controller`, `refresh` (pull to refresh) and `maxWidth`.
  - Add a shared `Eyebrow` widget in `core/widgets/`, used by the header.
- **Done when:**
  - Existing screens compile unchanged: the old `actions` parameter still works and is marked deprecated.
  - Tests cover: the title collapses on scroll; the back arrow shows when `onBack` is set; `primaryAction` appears at phone and desktop widths.

#### UI-03 Page menu and destructive confirmation

*As a rider, I want rare and dangerous actions in one predictable `⋯` menu that always asks before deleting, so I never delete something by accident.*

- **Files:** new `core/widgets/page_menu.dart` and `core/confirm.dart`, tests.
- **Do:**
  - `PageMenu`: a `⋯` `MenuAnchor` built from a list of entries `(key, label, icon?, onSelected, destructive)`. Destructive entries come last, after a divider, in `colorScheme.error`.
  - `Future<bool> confirmDestructive(context, {title, body, action, key})`: one dialog with Cancel and a red filled action, so the action is named, not "OK".
  - Port the four local helpers (`_confirm` / `_confirmDelete` in `ride_detail_screen.dart`, `bike_detail_screen.dart`, `calendar_feed_screen.dart`, `route_detail_screen.dart`) onto it in this story.
- **Done when:** tests prove a destructive entry sits last and in red, and that `confirmDestructive` returns false on Cancel and on a barrier tap.

#### UI-04 Sheets: `FormSheet` v2 and `SheetFrame`

*As a rider, I want every short task to slide up in the same kind of sheet, with the Save button in the same place, so short edits feel the same everywhere.*

- **Files:** `core/widgets/form_sheet.dart`, `bikes/bike_forms.dart`, `recording/recording_screen.dart`, `rides/ride_type_sheet.dart`, `rides/ride_text_sheet.dart`, `core/page_actions.dart` (`showFiltersSheet`).
- **Do:**
  - Split `FormSheet` into `SheetFrame` (the handle, title, scrolling body, padding from tokens) and `FormSheet` (a `SheetFrame` plus a full-width Save button pinned at the bottom, kept above the keyboard; dismissing is the cancel).
  - Replace the hand-rolled copies: the bike form and part form in `bike_forms.dart`, and `_SettingsSheet` and `_SensorSheet` in `recording_screen.dart`. Ride type, ride text and the filter sheets move onto `SheetFrame`.
- **Done when:** no file outside `form_sheet.dart` draws a sheet handle, and the bike, recording and ride tests pass with only their tap targets updated.

#### UI-05 Pinned bottom action for full-page forms

*As a rider, I want the button that finishes a form always under my thumb, even with the keyboard open, so I never scroll to find Save.*

- **Files:** new `core/widgets/bottom_action_bar.dart`, `PageScaffold` (a `bottomAction` parameter), a test.
- **Do:** add a full-width primary button pinned to the bottom of the page, above the keyboard and the safe area. On wide windows it right-aligns at its natural width under the content. The page's scroll view gets bottom padding so the last field is never hidden.
- **Done when:** a test shows the button stays visible with the keyboard inset and with large text scaling.

#### UI-06 Small shared states: `InlineError` and `LoadingState`

*As a rider, I want errors and loading to look the same on every screen, so I learn them once.*

- **Files:** new `core/widgets/inline_error.dart` and `core/widgets/loading_state.dart`; replace the uses listed in the audit.
- **Do:**
  - `InlineError(text, key)` for the error line under a form or a section; `FormSheet` uses it.
  - `LoadingState()` for a first load: a centred indicator in a block whose height is a token, or skeleton rows built on `PlaceholderBlock` when the page knows its shape.
  - Replace all 21 `Center(child: CircularProgressIndicator())` and about 15 `TextStyle(color: scheme.error)` lines.
- **Done when:** `grep -rn "CircularProgressIndicator()" app/lib/features` finds only progress inside buttons, and the existing loading tests (`test/loading_placeholder_test.dart`) pass.

### Phase 1 — Navigation frame

#### UI-10 Floating pill with three tabs

*As a rider, I want three clear tabs in a modern floating bar, so the app is quick to move around with one thumb.*

- **Depends on:** UI-01, UI-02.
- **Files:** `home_shell.dart`, `app.dart` (routes), `test/home_shell_test.dart`, `l10n/*.arb`.
- **Do:**
  - Below 600 dp, replace the `NavigationBar` with a floating pill: rounded, inset from the screen edges and the safe area, translucent over the content (a blur where supported), a pill indicator behind the selected tab.
  - The pill hides while scrolling down and returns when scrolling up, through `core/motion.dart`, and stays put under reduced motion.
  - Tabs: Rides, Progress, Club. Each has an outlined `icon` and a filled `selectedIcon` from one family.
  - Remove the shell's phone `AppBar`. Every page now names itself through `PageScaffold` (UI-02), and the shell passes notifications and the account menu into the header's `trailing`.
  - Remove `_title()` and the `pageActionsProvider` path once the Rides and Progress stories no longer use it, or leave a note for UI-30 and UI-32.
  - Pages get bottom padding equal to the pill's height.
- **Done when:**
  - `home_shell_test.dart` covers: three tabs on the phone; Record is not a tab; Bikes is not a tab; the selected tab is highlighted; a pushed screen highlights none.
  - The web build shows the same three tabs.

#### UI-11 One rail for tablet and desktop

*As a rider on a tablet or computer, I want one navigation rail that grows with the window, so the app looks the same on every screen.*

- **Depends on:** UI-10.
- **Files:** `home_shell.dart`, `core/tokens.dart`, `test/home_shell_test.dart`.
- **Do:**
  - From 600 dp, a collapsed rail (icons with labels). From 1200 dp, the expanded rail: brand, labels, the club by name as today's sidebar shows it, the privacy note, and at the foot the theme, notifications and account.
  - Build it from one widget with an `expanded` flag. Delete `_Sidebar` and its helpers.
  - Keep the back arrow for pushed screens: in the page header from UI-02, not the rail.
- **Done when:** tests at 800 and 1300 dp find the same three destinations, and the club entry shows the club's name when the rider has one.

#### UI-12 Start ride and the live-ride banner

*As a rider with my phone, I want to start a ride from the Rides tab and always see a ride in progress, so recording is one tap away and never lost.*

- **Depends on:** UI-10, UI-02.
- **Files:** `rides/rides_screen.dart`, `home_shell.dart`, `recording/recording_providers.dart` (read only), `test/rides_test.dart`, `test/recording_test.dart`.
- **Do:**
  - On the phone (not the web), the Rides header's `primaryAction` is **▶ Start ride**: it opens `/record` and starts nothing by itself.
  - While `recorderSnapshotViewModelProvider` reports `recording` or `paused`, the shell shows a banner just above the pill (the elapsed time and distance in tabular figures, a pause indicator) that opens `/record`, on every tab.
  - `/record` becomes a pushed screen with a back arrow.
- **Done when:** tests prove the banner appears when recording and when paused, disappears when stopped, is absent on the web, and Start ride is absent on the web.

#### UI-13 My bikes in Profile

*As a rider, I want to find my bikes in my profile, so the bar only holds what I use every ride.*

- **Depends on:** UI-10.
- **Files:** `profile/profile_screen.dart`, `bikes/bikes_screen.dart`, `app.dart`, `test/profile_test.dart`, `test/bikes_test.dart`.
- **Do:**
  - Add a **My bikes** row at the top of Profile, with the bike count and any part that is due. It opens `/bikes`, which is now a pushed screen with a back arrow.
  - Keep every `/bikes` and `/bikes/:id` link working: notifications and ride details link there.
- **Done when:** a test goes from Profile to the bike list and back, and an old `/bikes/:id` link still opens the bike.

### Phase 2 — Write the rules down

#### UI-20 Layout rules in `AGENTS.md`

- **Depends on:** UI-02 to UI-06 merged.
- **Do:**
  - Add the rules under **App** in `AGENTS.md`, worded as rules for the code as it now is: every routed screen uses `PageScaffold`; one `primaryAction` in the header; rare and destructive actions in `PageMenu`, confirmed with `confirmDestructive`; short tasks in `FormSheet` / `SheetFrame`; full-page forms use the bottom action bar; no `FloatingActionButton`; `InlineError` and `LoadingState` for errors and loading.
  - Update `.claude/skills/flutter/SKILL.md` (*New screen*) to match.
- **Done when:** the rules match the merged widgets' names exactly.

### Phase 3 — Bring every screen in line

Every story in this phase depends on UI-02 to UI-06. For each screen it also covers: raw numbers → tokens, hand-styled section titles → `SectionHeading` / `SectionCard`, loading → `LoadingState`, error lines → `InlineError`, confirmations → `confirmDestructive`.

#### UI-30 Rides list

- **Files:** `rides/rides_screen.dart`, `rides/ride_filters.dart`, `test/rides_test.dart`, `test/bulk_upload_test.dart`.
- **Do:**
  - Remove the upload `FloatingActionButton` and `_phoneAppBar` / `publishPhoneActions`.
  - The header holds Start ride (phone, from UI-12) or **Upload** (web and wide).
  - The `⋯` menu holds Upload (on the phone), Import a Strava export and Filters. A filter badge shows on the `⋯` button when a filter is active.
  - Replace the raw padding at ~L327.

#### UI-31 Ride detail

- **Files:** `rides/detail/ride_detail_screen.dart`, `lap_table.dart`, `route_map.dart`, `ride_feel_card.dart`, `test/ride_detail_test.dart`.
- **Do:**
  - Move the existing popup onto `PageMenu`, keeping its keys `edit-ride-text`, `edit-ride-type` and `delete`.
  - Delete goes through `confirmDestructive`.
  - Replace the raw paddings and the numeric `SizedBox`.

#### UI-32 Progress

- **Files:** `progress/progress_screen.dart`, `goals.dart`, `wellbeing_card.dart`, `readiness_card.dart`, `training_summary.dart`, `power_summary.dart`, `test/progress_test.dart`.
- **Do:**
  - Filters move from the phone title bar to the header's `⋯` menu (or a header filter button) at every width.
  - The hand-built KPI card (~L420) becomes `StatTile` with a surface.
  - The goal editor moves from `showDialog` to `FormSheet`.
  - "Withdraw consent" moves into the wellbeing card's `⋯` menu, as a destructive entry with a confirmation.
  - Replace the 17 numeric gaps and paddings in `readiness_card.dart`, `training_summary.dart`, `power_summary.dart`, `wellbeing_card.dart` and `goals.dart` with tokens.

#### UI-33 Club home

- **Files:** `club/club_screen.dart`, `test/club_test.dart`, `test/club_plan_test.dart`.
- **Do:**
  - `_planCard`, `_joinCodeCard`, `_membersCard`, `_athletesCard`, `_requestsCard`, `_locationCard`, `_ClubHeader` and `_SharingCard` become `SectionCard`s, or a club hero card built from tokens for the header.
  - "Leave club" leaves `_leaveCard` for the page `⋯` menu as a destructive entry, keeping the key `leave-club`. The owner's "cannot leave" note stays visible where it is.
  - Three dialogs move onto `confirmDestructive`.
  - Replace `EdgeInsets.all(8)` ×3 and the error lines with `InlineError`.
  - The file is 1,111 lines: move the cards into `club/widgets/` files, one per card, in the same PR.

#### UI-34 Club rides and the calendar

- **Files:** `calendar/club_rides_screen.dart`, `plan_ride_screen.dart`, `club_ride_detail_screen.dart`, `calendar_feed_screen.dart`, `club_ride_widgets.dart`, `test/club_rides_routes_test.dart`.
- **Do:**
  - Club rides: the FAB becomes the header's **Plan a ride**.
  - Plan ride: the submit button moves to the bottom action bar.
  - Club ride detail: **Cancel ride** moves into `⋯` as a destructive entry (key `cancel-ride`); Edit stays as a header action.
  - Calendar feed: **Stop calendar** moves into `⋯`.

#### UI-35 Club routes

- **Files:** `routes/routes_screen.dart`, `route_detail_screen.dart`, `route_forms.dart`, `test/club_rides_routes_test.dart`.
- **Do:**
  - The FAB becomes the header's **Add route**.
  - The two submit buttons in `route_forms.dart` move to the bottom action bar.
  - Delete goes into `⋯` with `confirmDestructive`.
  - Replace `EdgeInsets.all(8)`.

#### UI-36 Bikes, parts and service

- **Files:** `bikes/bikes_screen.dart`, `bike_detail_screen.dart`, `bike_forms.dart`, `service_forms.dart`, `service_section.dart`, `test/bikes_test.dart`, `test/part_identity_test.dart`.
- **Do:**
  - Bike list: the FAB becomes the header's **Add bike** (key `add-bike`).
  - The bike detail popup moves onto `PageMenu` (keys `toggle-archive` and `delete-bike`).
  - The row-level "Remove" buttons (`service_section.dart` ~L445 and ~L520, `bike_detail_screen.dart` ~L580) move into a `⋯` per row.
  - The template picker (~L611), the dialog at ~L533 and `_DoneDialog` become `FormSheet`s.
  - Replace the 5 raw paddings and the 3 error lines in `bike_forms.dart`.

#### UI-37 Recording

- **Depends on:** UI-12.
- **Files:** `recording/recording_screen.dart`, `test/recording_test.dart`.
- **Do:**
  - Move onto `PageScaffold` with a back arrow; drop its own `Scaffold` and the `fromLTRB(16, 8, 16, 96)`.
  - "On this phone" becomes a `SectionHeading`; an empty list becomes `EmptyState` (key `no-local-rides`).
  - A local ride's delete icon (~L674) moves into a `⋯` per ride with `confirmDestructive`. Deleting a ride kept only on the phone loses it for good, so the confirmation says that.
  - The live card and the start card keep their big controls. Restyle them with the expressive theme and replace their raw paddings.

#### UI-38 Profile, security, sessions and privacy

- **Files:** `profile/profile_screen.dart`, `two_factor_screen.dart`, `sessions_screen.dart`, `privacy/privacy_screen.dart`, `test/profile_test.dart`, `test/privacy_test.dart`, `test/security_test.dart`.
- **Do:**
  - **Delete my account** moves from a visible red button to the Profile `⋯` menu (key `delete-account`). It keeps its password step, now in a `FormSheet` instead of `_DeleteAccountDialog`.
  - `_ChangePasswordDialog` becomes a `FormSheet`.
  - Two-factor: the enrol and disable submit buttons move to the bottom action bar.
  - Privacy: `_ZoneDialog` becomes a `FormSheet`, and "remove zone" goes through `confirmDestructive`.

#### UI-39 Coach and notifications

- **Files:** `coach/coach_athletes_screen.dart`, `coach_athlete_screen.dart`, `coach_ride_screen.dart`, `notifications/notifications_screen.dart`, `test/coach_test.dart`, `test/notifications_test.dart`.
- **Do:**
  - Replace the raw paddings (`coach_athlete_screen.dart` ~L152 and ~L165) and the loading states.
  - Notifications: "Mark all as read" becomes the header's `primaryAction`.

#### UI-40 Admin

- **Files:** `admin/admin_screen.dart`, `accounts_tab.dart`, `clubs_tab.dart`, `overview_tab.dart`, `settings_tab.dart`, `test/admin_test.dart`.
- **Do:**
  - Move the admin screen onto `PageScaffold`, with the tabs under the header.
  - `_RolesDialog`, `_CreateClubDialog`, `_OwnerDialog` and `_PlanDialog` become `FormSheet`s. `_ResetLinkDialog` becomes a `SheetFrame` that shows the link with a copy button.
  - The two delete and reset confirmations move onto `confirmDestructive`.
  - Each account row's actions move into a `⋯` per row, with Delete last and in red.

#### UI-41 Joining and starting a club, nearby clubs

- **Files:** `club/join_club_screen.dart`, `start_club_screen.dart`, `nearby_clubs_screen.dart`, `location_picker.dart`, `test/club_nearby_test.dart`, `test/club_test.dart`.
- **Do:**
  - Join and Start club: the submit button moves to the bottom action bar.
  - Nearby clubs and the location picker sit outside the shell: they move onto `PageScaffold` with `onBack` instead of their own `Scaffold` and `AppBar`.
  - `_JoinRequestDialog` becomes a `FormSheet`.
  - Replace the literal colours over the map in `location_picker.dart` (`Colors.white`, `Colors.black87`) with theme surfaces.

#### UI-42 Sign-in and the signed-out screens

- **Files:** `auth/auth_page.dart`, `sign_in_screen.dart`, `register_screen.dart`, `forgot_password_screen.dart`, `reset_password_screen.dart`, `server_setup_screen.dart`, `verify_email_screen.dart`, `password_field.dart`, `test/sign_in_test.dart` and the other auth tests.
- **Do:**
  - `AuthPage` is built on `PageScaffold` (no shell, no tabs, `onBack` where a step has a way back) instead of its own frame.
  - It uses the shared `Eyebrow` and the bottom action bar for each step's primary button (Sign in, Create account, Continue). Secondary links stay in the body.
  - Use the bold expressive look for the wordmark.

#### UI-43 Supporter screens and maps

- **Files:** `supporter/supporter_activation_screen.dart`, `supporter_badge.dart`, `supporter_celebration_screen.dart`, `rides/detail/full_route_map.dart`.
- **Do:**
  - Activation: the submit button moves to the bottom action bar.
  - The celebration stays bespoke but takes its colours and radii from the theme and tokens.
  - In `full_route_map.dart`, `Colors.black` becomes a theme surface.

## Suggested order

1. **UI-01 to UI-06**, in parallel: nothing visible changes yet except the theme.
2. **UI-10**, then **UI-11, UI-12 and UI-13** in parallel. Each produces an APK worth trying.
3. **UI-20.**
4. **UI-30 to UI-43**, in parallel, one agent per story. UI-37 waits for UI-12.

**Checks for each story:** an agent runs `just check`, then pushes. The PR's CI builds the APK, and the owner tries it on a phone before the next phase starts.
