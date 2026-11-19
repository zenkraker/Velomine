# Rider modes

## Overview
Velomine welcomes sporty racers and everyday riders, but every screen today speaks the language of training. Each member picks a rider mode that decides what the app shows first on the Rides list, the ride detail and the Progress tab; nothing is locked or removed.

**Original request (owner):** "We need to overhaul the UI. Some riders are very sporty and race at weekends, so their training and data matter and all the latest features are for them. Others ride with family and friends, register their route, maybe check heart rate, and don't care about training detail. Discuss the difference and find a UI solution."

## Principles for this feature
- Same app, same data, same features for everyone (values: no feature paywall). A mode only decides what is shown first. Everything hidden is one tap away.
- The member chooses; nothing is inferred from their data (values: no hidden defaults).
- The mode is the member's own display setting. It is not shared with the club or a coach, and it changes no grant and no coach view.
- No gamification for the simple modes (values: no engagement traps).

## Stories

### Story 1: A rider mode on my account
**Priority:** High
**Description:** As a member, I want my rider mode saved on my account, so that the app looks the same on my phone and on the web.
**Acceptance criteria:**
- **Given** I am signed in, **When** I choose a mode, **Then** it is saved on my account and every device I sign in on shows that mode.
- **Given** an account that never chose, **When** it loads, **Then** it shows the default mode (see Decisions).
- **Given** the server receives a mode it does not know, **When** I save, **Then** it answers 400 and keeps the old mode.
- **Given** I export my data, **When** the ZIP is built, **Then** my mode is in it. **Given** I delete my account, **Then** it is deleted with the rest.
- The mode is returned only to its owner.
**Dependencies:** None
**Size:** S

### Story 2: Choose how I ride, with a short explanation
**Priority:** High
**Description:** As a new member, I want one plain question about how I ride, with a line explaining each answer, so that I pick without knowing training words.
**Acceptance criteria:**
- **Given** I sign in for the first time and have not chosen, **When** the app opens, **Then** I am asked "How do you ride?" with three answers, each with a one-sentence explanation (draft below).
- **Given** I am not sure, **When** I tap "Decide later", **Then** the default mode applies and I can change it in Settings.
- **Given** I am in Settings, **When** I open "How I ride", **Then** I see the same three answers and explanations, and the one I use is marked.
- **Given** I change my mode, **When** I go back to Rides, Progress or a ride, **Then** they already follow the new mode, without signing out.
- The text is in English and Italian. The choice is readable with a screen reader and each option is at least 48×48.
- If saving fails, I see the error under the choice and the old mode stays.
**Dependencies:** Story 1
**Size:** M

Draft modes (names are open, see Decisions):
- **Just riding:** "I ride for fun, with family or friends. I want my routes, my distance and how the ride went."
- **Riding with goals:** "I ride often and like to see my progress: weekly totals, goals, and heart rate zones in plain words."
- **Training:** "I train or race. I want power, training load, fitness and form, and every number."

### Story 3: The Progress tab follows my mode
**Priority:** High
**Description:** As a member, I want Progress to open with what matters to me, so that I am not met with a training lab I did not ask for.
**Acceptance criteria:**
- **Given** mode Just riding, **When** I open Progress, **Then** I see my totals (distance, time, climbing, rides) per week, month or year, and my goals. FTP prompts, readiness, training load, intensity, efficiency, power curve and the daily check-in are not shown first.
- **Given** mode Riding with goals, **When** I open Progress, **Then** I see totals, goals and heart-rate time in zones; power analysis and load cards are folded away.
- **Given** mode Training, **When** I open Progress, **Then** I see everything as today.
- **Given** a folded part, **When** I tap "Show more analysis", **Then** the cards appear and I can use them. Nothing needs a mode change.
- **Given** I ride without a power meter, **When** the mode is Training, **Then** power cards still follow today's rules for empty data.
- **Given** one source fails to load, **When** the page opens, **Then** only that part shows a retry (as today).
- The wellbeing check-in keeps its explicit-consent rule in every mode; a simple mode never asks for it.
**Dependencies:** Story 1
**Size:** M

### Story 4: The ride detail follows my mode
**Priority:** High
**Description:** As a member, I want a ride to open with its route and how it went, so that I can enjoy it without reading NP, IF and TSS.
**Acceptance criteria:**
- **Given** mode Just riding, **When** I open a ride, **Then** I see the map, distance, time, climbing, average speed and my heart rate as a simple line with a plain-word summary (for example "mostly easy"). Power analysis, NP, IF, TSS and TRIMP, FTP and heart-rate suggestions are folded away.
- **Given** mode Riding with goals, **When** I open a ride, **Then** I also see heart rate zones and the main charts; power analysis stays folded.
- **Given** mode Training, **When** I open a ride, **Then** I see everything as today.
- **Given** a folded part, **When** I tap "Show all details", **Then** every metric and chart shows.
- **Given** the ride has no heart rate or power, **When** I open it, **Then** the missing parts do not appear in any mode, and nothing shows an empty chart.
- **Given** a ride I opened to check or delete, **Then** edit, bike, type, privacy and delete work the same in every mode.
- A coach or club member who views my ride through a grant sees what the grant allows, whatever my mode (my mode never changes what others see).
**Dependencies:** Story 1
**Size:** M

### Story 5: The Rides list follows my mode
**Priority:** Medium
**Description:** As a member, I want each ride in my list to show what I care about, so that I can find "the Sunday ride" or "the hard interval day" at a glance.
**Acceptance criteria:**
- **Given** mode Just riding, **When** I open Rides, **Then** each ride shows its title, date, route preview, distance and time.
- **Given** mode Riding with goals, **Then** each ride adds average heart rate or the zone summary when it exists.
- **Given** mode Training, **Then** each ride shows what it shows today (including load numbers).
- **Given** a ride has no data for a number, **Then** that number is left out; the card never shows a blank or a zero as if measured.
- **Given** I switch mode, **Then** the list changes without reloading my rides.
**Dependencies:** Story 1
**Size:** S

## Out of scope
- The phone recorder's live screen (a later feature, once these screens are settled).
- Club and coach views, the club calendar and share views.
- Anything that locks a feature behind a mode or a plan; a mode only changes what is shown first.
- Automatic mode switching from the member's data.
- Per-feature switches inside a mode (we start with named modes; see Decisions).
- Migrating existing members: nobody uses the app yet.

## Decisions
- 2026-11-19: The difference matters on all three places: the Rides list, the ride detail and the Progress tab.
- 2026-11-19: The member chooses their mode with one plain question on first launch.
- 2026-11-19: Modes, not a switch list: the owner wants several named modes with tiny explanations, including a middle one for hobbyists who want "some more".
- 2026-11-19: No migration; nobody uses the app yet.
- 2026-11-19: Member's own screens first; recorder and club/coach views later.
- 2026-11-19: The owner asked the architect to retry the Advisor; it answered and its points are in the Plan.

Open, for the owner (see the Plan's questions):
- Three modes or another number? Names for them? (The migration waits for this.)
- Which mode is the default, and does "Decide later" save it on the account?
- Does the mode also change the words for numbers (e.g. "mostly easy" instead of "zone 2")?
- Route preview on the Rides list: drop from this feature or build it here?
- Story 3: is the existing easy/moderate/hard split acceptable instead of "heart-rate time in zones"?

## Plan
### Status
Proposed. The owner's questions are still open. The Advisor answered this time and its points are folded in below.

### What changed since the last version
The Advisor was not refused this time. It saw only my summary, not the stories file. It found six gaps and five smaller points.

**Adopted**
- **Old server loops the prompt.** The prompt is now shown once per signed-in session. A 404 or 405 from the save marks the feature unavailable for the session: no prompt, default layout. I also added a test. This was the most serious point, and my one-line risk understated it.
- **Demo mode.** The seed decision and the `DemoLock.Refused` decision are now written out in the plan. The mode is seeded and the endpoint stays out of `Refused`.
- **keepAlive view model across accounts.** `RiderModeViewModel` now watches `signedInUserIdProvider`, as `ProfileViewModel` does, and reads its start value from `session.me`. This follows the AGENTS rule that a ViewModel holding member data watches the signed-in identity. I dropped the hand-written `forget()` wiring. I added a test for sign-out then sign-in as another member.
- **Other people's data cannot inherit the viewer's mode.** `layout` is now a required parameter of `RideCard` and `RideDetailScreen`. Only the member's own call sites read `riderLayoutProvider`. This replaces my earlier "optional parameter plus a grep".
- **The effort word stays display-only.** It is derived in the app from the zone seconds the server already returns. It is never a server field, so `RideParserVersion.Current` does not rise.
- **"Decide later saves the default" pins the member.** This is now part of the default-mode question for the owner.
- **Migration waits on the owner's count.** The migration is blocked on the mode-count question. The slug set is part of the schema, and a later change means expand, backfill, contract.
- **Folded sources load eagerly.** The plan now states this and says why.
- **Cross-device staleness and the web app.** Both are now stated in the plan.
- **Validator.** The plan already used the FastEndpoints validator, so a 400 is a ProblemDetails response and not a database exception. This is now explicit.

**Rejected**
- None.

### Context
- The rider mode is the member's own display setting. It is stored like `Language` and `Units` and is read from `GET /accounts/me`.
- The server never filters by it. Coach, club and share views never read it. The server needs a column, one endpoint, and the export and deletion rules.
- The app has no per-mode layout today.
  - `ProgressScreen` builds one `analysis` list and always shows the `_metricCard`s and `WellbeingCard` (`progress_screen.dart`).
  - `RideDetailScreen._body` shows everything (`ride_detail_screen.dart`).
  - `RideCard.facts` lists every number the ride has (`rides_screen.dart:480-520`).
- The three screens need one shared decision table, so none of them branches on the enum.
- Precedent:
  - `SetMyUnits` and `UnitsChoiceViewModel` (`core/units.dart`)
  - `ck_users_units` (`VelomineDbContext.cs:121`)
  - the export at `AccountExport.cs:103`
  - the fake server's units handler (`app/test/fake_server.dart:1020`)
- Story 2 needs a visible save failure and an unchanged old mode. `Session.setLanguage` and `setUnits` swallow errors, so I do not copy them. The new view model uses `Result<T>` and `CommandState`, like `ProfileViewModel`.
- The web app is the same Flutter codebase, so the mode applies there too. The presentation site in `site/` is untouched.

### Decision
**Server (additive, one migration, blocked until the owner fixes the number of modes)**
- `User.RiderMode` is a `string?`. Null means the member never chose.
- Column `rider_mode` in `accounts.users`, max length 16, with check constraint `ck_users_rider_mode`: `rider_mode IS NULL OR rider_mode IN ('just_riding','with_goals','training')`.
- The slugs are stable. Display names and explanations live only in l10n, so renaming a mode never touches the server. Changing the number of modes later means expand, backfill, contract. An applied migration is never edited.
- `PUT /api/v1/accounts/me/rider-mode` (`SetMyRiderMode`) takes `SetMyRiderModeRequest(string RiderMode)`.
  - A FastEndpoints validator accepts only the three slugs.
  - An unknown value gets 400 as ProblemDetails, and the old value stays.
  - It returns `MeResponse`, like `SetMyUnits`.
- `MeResponse` gets `string? RiderMode` appended last, filled in `MeResponse.From`. It is owner-only because `/accounts/me` is the caller's own. No coach, club or share DTO carries it.
- The export adds `user.RiderMode` to `profile.json` next to `user.Language` and `user.Units`. Deletion needs no code, because the column is on the user row.
- Demo mode:
  - `Features/Demo/DemoData.cs` seeds `RiderMode = "training"`, so visitors are not prompted.
  - The endpoint is **not** added to `DemoLock.Refused`, like language and units. It locks nobody out.
  - One visitor's later choice is visible to the next visitor until the 03:00 UTC reset. That is the same as language and units today.
- Cross-device: the second device keeps its old mode until `/me` is read again (sign-in or `refreshMe`). The last write wins.
- No change to `RideParserVersion`. The effort word is computed in the app, from the zone seconds the server already returns, and is never stored or sent.

**App: one provider, one decision table**
- `enum RiderMode { justRiding, withGoals, training }` and `knownRiderMode(String?)` live in `lib/core/rider_mode.dart`.
- `RiderModeViewModel` is a keepAlive notifier in `lib/features/profile/rider_mode_view_model.dart`.
  - Its state is `RiderModeState { RiderMode? chosen; bool promptHandled; bool unavailable; CommandState<void> save }`.
  - `build()` watches `signedInUserIdProvider`, so a sign-out or an account switch rebuilds it empty. It starts from `ref.read(sessionProvider).me?.riderMode`.
  - The Developer checks that `me` is set when the identity emits. If it is not, `app.dart` adopts the mode in `_applyAccountLanguage`, beside the units call.
  - `choose(RiderMode)` calls `ProfileData.setRiderMode`, which returns `Result<MeResponse>`. State changes only on `Ok`.
  - On `Failed`, `chosen` stays as it was and `save.failure` is set.
  - A 404 or 405 sets `unavailable = true`. The Developer reads `core/failure.dart` for the matching failure kind.
- `lib/core/rider_mode.dart` also holds:
  - `const defaultRiderMode` (owner decision).
  - `RiderModeLayout`, a pure const class built by `RiderModeLayout.of(mode)`, plus `RiderModeLayout.full`.
  - `riderLayoutProvider`, a `Provider<RiderModeLayout>`. It uses `chosen ?? defaultRiderMode`, and the default also applies when `unavailable`.
- `RiderModeLayout` booleans and sets:
  - `foldAdvanced`: true for the two simple modes.
  - `showZonesAndCharts`: with goals and training.
  - `showIntensity`: with goals and training.
  - `rideListFacts`: a set of fact ids.
  - `rideChartIds`: elevation, speed and heartrate for with goals; all for training.
  - `effortWord`: true for the two simple modes.
- **Structural rule.** `RideCard` and `RideDetailScreen` take a **required** `layout` parameter. They never read the provider themselves.
  - Only the member's own call sites pass `ref.watch(riderLayoutProvider)`: `RidesScreen` and the `/rides/:id` route builder in `app.dart`, which becomes a `Consumer` like `/rides`.
  - Any coach, club or share caller passes `RiderModeLayout.full`.
- A shared `MoreDetails({label, children})` widget goes in `lib/core/widgets/`.
  - It renders a button ("Show more analysis" or "Show all details").
  - Its open state is a view-local `bool`, reset on every screen visit. Any animation goes through `lib/core/motion.dart`.
  - In training mode the folded list is empty and everything stays in today's place.
- **Folded sources still load eagerly.** The screens keep watching every view model, so loading is unchanged. A hidden source that fails shows no `ErrorState` until the member opens the fold. A lazy load would be a larger diff for the same result; see Alternatives.

**Progress** (`progress_screen.dart`)
- Core in every mode: the "this period" `_metricCard`, `_TotalsCard`, `_TotalsTable`, `NextEventCard`, goals, and the period and discipline filters.
- With goals adds `IntensityCard`, the existing easy, moderate and hard split, with no new endpoint.
- Advanced, folded in the simple modes and shown as today in training:
  - `FtpSuggestionCard`, `HeartRateNoteCard`, `FtpReminderCard`
  - `ReadinessCard`, `TrainingSummary`, `EfficiencyCard`, `PowerSummary`
  - `IntensityCard` in just riding
  - `WellbeingCard`
  - the FTP-history menu entry
- The readiness, training and power `_metricCard`s are omitted in the simple modes.
- The `failures` list counts only sources whose widget is visible.

**Ride detail** (`ride_detail_screen.dart`)
- Core in every mode:
  - header, description, `EventLinkCard`, load, processing and failed states
  - `RideTypeChips`, `RouteMap`
  - `_BikePicker`, `_ViewsCard`, and the menu (edit, type, delete)
- `_Stats` gets a filter. Each tile is tagged basic or advanced.
  - Basic: `distance`, `moving-time`, `elapsed-time`, `climbing`, `average-speed`, `average-heart-rate`, `max-heart-rate`, and the speed-from-GPS note.
  - Advanced: everything else (descending, top speed, power, NP, IF, TSS, efficiency, decoupling, TRIMP, cadence, the W′ note, the load hint).
- Just riding shows the basic stats and one effort line, key `ride-effort`.
  - `effortWord(zones)` is a new pure function in `rides/detail/effort_word.dart`, computed from `ride.heartRateZones`.
  - It groups the zones as `Intensity.cs` does for heart rate: Z1–3 easy, Z4 moderate, Z5 hard.
  - The largest share wins, and a tie goes to the harder bucket.
  - It returns `easy`, `moderate` or `hard`, and the wording is "mostly easy", "steady" or "hard".
  - A ride with no heart rate, or no max heart rate so no zones, shows no heart-rate line and no word. It never says "easy" by default.
- With goals shows the basic block, the heart-rate zones card, and the charts in `rideChartIds`.
- Advanced, folded in the simple modes:
  - `FtpSuggestionCard`, `HeartRateNoteCard`, `PowerRecordChips`, `LapTable`
  - the power zones card
  - `RideFeelCard` (RPE and notes are wellbeing data, and its consent prompt stays out of the simple modes)
  - the training hint, the advanced stats, and the charts not in `rideChartIds`
- Training keeps all of this in today's order.

**Rides list** (`rides_screen.dart`, `RideCard`)
- `RideCard` filters `facts` by `layout.rideListFacts`.
  - Just riding: distance and time.
  - With goals: distance, time and average heart rate.
  - Training: as today.
- The existing `> 0` guards stay, so a missing number is left out. Switching mode rebuilds the cards and does not reload the rides.

**First launch and Settings**
- `RiderModePrompt` is a small `ConsumerStatefulWidget` mounted in `HomeShell` (`home_shell.dart:26`).
  - It opens the choice sheet when `chosen == null && !promptHandled && !unavailable`.
  - It sets `promptHandled` as soon as the sheet opens, so it shows at most once per signed-in session.
  - The flag is reset by the identity watch.
- The sheet is `showRiderModeSheet(context, {required bool firstTime})` in `features/profile/rider_mode_sheet.dart`, a `SheetFrame`.
  - It has three selectable tiles. Each has a name, a one-sentence explanation, a selected mark, `Semantics(selected:)`, and at least 48 dp height.
  - An `InlineError` with `failureText` shows under the choice when `save.failure` is set.
- First time, a "Decide later" button calls `choose(defaultRiderMode)`. Dismissing the sheet counts as "Decide later".
- If a save fails, the sheet stays open with the error, and `chosen` stays null.
- If a save answers 404 or 405, the sheet closes, `unavailable` is set, and the default layout applies for the session. The Settings row is hidden while `unavailable`.
- `profile_screen.dart` gets a "How I ride" row, key `profile-rider-mode`, under the units dropdown. It shows the current mode name and opens the sheet with `firstTime: false`.
- l10n goes in both `app_en.arb` and `app_it.arb`: the question, the three names and explanations, "Decide later", "How I ride", "Show more analysis", "Show all details", and the three effort words.

### Files to change
- `src/Velomine.Server/Features/Accounts/User.cs` — add `RiderMode`.
- `src/Velomine.Server/Data/VelomineDbContext.cs` — max length and `ck_users_rider_mode`.
- `src/Velomine.Server/Data/Migrations/*AddRiderMode*` — generated, never hand-edited.
- `src/Velomine.Server/Features/Accounts/SetMyRiderMode.cs` — new endpoint, request and validator.
- `src/Velomine.Server/Features/Accounts/GetMe.cs` — `MeResponse.RiderMode`. Grep every `new MeResponse(` caller.
- `src/Velomine.Server/Features/Accounts/AccountExport.cs` — add `user.RiderMode` to `profile.json`.
- `src/Velomine.Server/Features/Demo/DemoData.cs` — `RiderMode = "training"` on the seeded users.
- `app/packages/velomine_api/**` — regenerated, never hand-edited.
- `app/lib/core/rider_mode.dart` — enum, `defaultRiderMode`, `RiderModeLayout`, `riderLayoutProvider`.
- `app/lib/core/widgets/more_details.dart` — `MoreDetails`.
- `app/lib/features/profile/profile_data.dart` — `setRiderMode` returning `Result`.
- `app/lib/features/profile/rider_mode_view_model.dart`, `rider_mode_state.dart` and the generated `.g.dart`.
- `app/lib/features/profile/rider_mode_sheet.dart` — the sheet.
- `app/lib/features/profile/profile_screen.dart` — the "How I ride" row.
- `app/lib/app.dart` — the `/rides/:id` builder wrapped in a `Consumer` that passes the layout. It adopts the mode only if the identity watch is not enough.
- `app/lib/home_shell.dart` — mount `RiderModePrompt`.
- `app/lib/features/progress/progress_screen.dart` — tag core and advanced, filter `failures`, fold.
- `app/lib/features/rides/detail/ride_detail_screen.dart` and the new `effort_word.dart` — required `layout`, `_Stats` filter, fold, effort line.
- `app/lib/features/rides/rides_screen.dart` — `RideCard` takes a required `layout`, and `RidesScreen` passes it.
- Every other `RideCard(` and `RideDetailScreen(` caller, found by grep — pass `RiderModeLayout.full` for other people's data.
- `app/lib/l10n/app_en.arb`, `app_it.arb` — new strings.
- `app/test/fake_server.dart` — `riderMode` on the caller (default `'training'`), in all three `/me` bodies (about lines 647, 1033, 1048), and a `PUT /api/v1/accounts/me/rider-mode` handler that answers 400 on an unknown slug. It also needs a switch that makes the route answer 404.
- Existing tests that build `RideCard` or `RideDetailScreen` directly — pass a layout.
- `docs/stories/rider-modes.md` — the PO updates the plan.

### Anchors (keep exactly)
- Slugs: `just_riding`, `with_goals`, `training`. They are never renamed.
- Column `rider_mode`, constraint `ck_users_rider_mode`.
- `PUT /api/v1/accounts/me/rider-mode`, endpoint `SetMyRiderMode`, request `SetMyRiderModeRequest(string RiderMode)`, response `MeResponse`.
- `Description(d => d.Accepts<SetMyRiderModeRequest>("application/json").Produces<MeResponse>(200).ProducesProblem(400).Produces(401), clearDefaults: true)`.
- `MeResponse` appends `string? RiderMode` as its last parameter.
- Dart: `RiderMode`, `RiderModeLayout` (`.of`, `.full`), `riderLayoutProvider`, `RiderModeViewModel` (`riderModeViewModelProvider`), `MoreDetails`. `layout` is a required parameter of `RideCard` and `RideDetailScreen`.
- Widget keys: `rider-mode-prompt`, `rider-mode-just_riding`, `rider-mode-with_goals`, `rider-mode-training`, `rider-mode-later`, `rider-mode-error`, `profile-rider-mode`, `more-details`, `ride-effort`.
- Existing keys stay: `metric-*`, `training-*`, `stat-*`, `heart-rate-zones`, `power-zones`.

### Tests
- Server (`ProfileTests`, `DataOwnershipTests`):
  - `SetMyRiderMode_ShouldSaveAndReturnMode_WhenSignedInOnAnotherDevice`
  - `SetMyRiderMode_ShouldAnswer400AndKeepOldMode_WhenModeIsUnknown`
  - `GetMe_ShouldReturnNullRiderMode_WhenMemberNeverChose`
  - `AccountExport_ShouldContainRiderMode_WhenMemberChose`
  - `AccountDeletion_ShouldRemoveRiderMode_WhenAccountIsDeleted`
  - `RiderMode_ShouldNotAppearInAnyOtherMembersView_WhenCoachOrClubMemberReadsTheRide`
  - `DemoData_ShouldSeedRiderMode_WhenDemoIsReset`
  - A second-club test is not needed. The mode is not club data and has no `club_id`.
- Dart pure tests:
  - `RiderModeLayout_ShouldHideLoadFacts_WhenModeIsJustRiding`, and the same for the other two modes.
  - `EffortWord_ShouldBeEasy_WhenMostTimeIsInZonesOneToThree`
  - `EffortWord_ShouldBeHard_WhenTieBetweenModerateAndHard`
  - `EffortWord_ShouldBeNull_WhenNoZones`
- Dart view model and widget tests:
  - `RiderModeViewModel_ShouldKeepOldMode_WhenSaveFails`
  - `RiderModeViewModel_ShouldStartEmpty_WhenAnotherMemberSignsInAfterSignOut`
  - `RiderModeViewModel_ShouldMarkUnavailable_WhenSaveAnswers404`
  - `RiderModePrompt_ShouldAskOnce_WhenMemberNeverChose`
  - `RiderModePrompt_ShouldNotAskAgain_WhenServerHasNoRiderModeEndpoint`
  - `RiderModePrompt_ShouldSaveDefault_WhenDecideLaterIsTapped`
  - `RiderModeSheet_ShouldShowInlineError_WhenSaveFails`
  - `ProgressScreen_ShouldFoldAnalysis_WhenModeIsJustRiding`
  - `ProgressScreen_ShouldShowEverything_WhenModeIsTraining`
  - `ProgressScreen_ShouldRevealCards_WhenShowMoreIsTapped`
  - `ProgressScreen_ShouldNotShowError_WhenOnlyAFoldedSourceFails`
  - `ProgressScreen_ShouldShowError_WhenFailedSourceIsUnfolded`
  - `ProgressScreen_ShouldNotShowWellbeingCard_WhenModeIsSimple`
  - `RideDetailScreen_ShouldShowEffortWordAndHeartRate_WhenModeIsJustRiding`
  - `RideDetailScreen_ShouldHideChartsAndLoad_WhenFolded`
  - `RideDetailScreen_ShouldShowAllMetrics_WhenShowAllDetailsIsTapped`
  - `RideDetailScreen_ShouldNotShowEmptyHeartRate_WhenRideHasNone`
  - `RideDetailScreen_ShouldKeepEditAndDelete_WhenModeIsSimple`
  - `RideCard_ShouldShowOnlyDistanceAndTime_WhenLayoutIsJustRiding`
  - `RideCard_ShouldAddHeartRate_WhenLayoutIsWithGoals`
  - `RideCard_ShouldRebuildWithoutReload_WhenModeChanges`
  - `ProfileScreen_ShouldMarkCurrentMode_WhenSheetOpens`
  - `RiderModeSheet_ShouldHaveTapTargetsOf48_WhenOpened`, in the style of `text_scale_test`.
- Existing Dart tests stay green because `fake_server` defaults `riderMode` to `'training'`, so nobody is prompted and nothing is folded.

### Commands the Developer must run
- `just migration AddRiderMode`, only after the owner fixes the number of modes.
- `tools/generate-api-client.sh`
- `just codegen` (Riverpod `.g.dart` and `gen-l10n`)
- `just check`, last.

### Risks and mitigations
- **Prompt in every widget test.** `fake_server` defaults to `'training'`. Only the prompt tests use null.
- **An old server with a new app.** `RiderMode` reads as null and the save answers 404 or 405. The prompt shows once, the failure marks the feature unavailable, and the default applies. A test covers it.
- **A hidden source fails.** `failures` counts visible sources only. Tests cover the folded case and the unfolded case.
- **Someone else's data follows the viewer's mode.** The required `layout` parameter makes this structural. The Developer greps `RideCard(` and `RideDetailScreen(` and passes `RiderModeLayout.full` for others' data.
- **The with-goals card does not match the story wording.** `IntensityCard` splits easy, moderate and hard from power when the ride has power and an FTP, and from heart rate otherwise. The story says "heart-rate time in zones". Owner question below.
- **Release order.** The column is additive and nullable. One release is backward-compatible with no backfill.
- **Save failure while offline.** The first-launch sheet stays with the error, and the member can retry or dismiss. The mode is not saved and the default shows.
- **Cross-device staleness.** A second device shows the old mode until `/me` is read again. The last write wins.
- **Unrelated, not planned.** `Session.setLanguage` and `setUnits` swallow errors, so a failed save is invisible.

### Alternatives considered
- **Server-filtered responses per mode.** Rejected: two data shapes, a risk of leaking into coach and share views, and the story says nothing is removed.
- **A switch list per feature.** Rejected: the owner chose named modes.
- **Infer the mode from data.** Rejected by the stories and by values.
- **Mode stored per device.** Rejected: Story 1 wants it on the account.
- **Prompt on every launch until the member chooses.** Rejected: it nags. "Decide later" saves the default instead (see the pinning question).
- **`Session.setRiderMode` in the `setLanguage` style.** Rejected: it swallows errors, and Story 2 needs a visible failure.
- **Lazy-load folded sources.** Rejected for now: filtering `failures` is a smaller diff with the same user result. It is a follow-up if load cost matters.
- **Optional `layout` on `RideCard` and `RideDetailScreen`, defaulting to the provider.** Rejected after the Advisor's point: a forgotten argument would silently follow the viewer's mode.

### Records
- `docs/architecture.md` Decisions table: "Rider mode: a per-account display setting in `accounts.users.rider_mode`, like language and units. The server never filters by it, and no coach, club or share view reads it."
- `AGENTS.md`, App section: "Screens read the rider mode through `riderLayoutProvider` and pass the layout down. A widget that can show someone else's data takes the layout as a required parameter and gets `RiderModeLayout.full` there; a view never branches on the mode enum."

### Questions for the owner
- **Number and names of the modes.** Options: three (just riding, riding with goals, training) as drafted, or another number or names. Recommendation: three with the drafted names. The migration waits for this answer. Only l10n changes if names change.
- **The default mode, and whether "Decide later" pins it.** These two decisions go together.
  - Which mode applies for an account that never chose or taps "Decide later"?
    - Training: nothing is hidden and it equals today. Recommended.
    - Riding with goals.
    - Just riding.
  - "Decide later" saves the default on the account, which stops the prompt for good. If the default later changes, those members stay on the old one.
  - Option A: save it, as planned. Recommended: it never nags, and Settings is one tap away.
  - Option B: save nothing and ask again at the next launch. A member who never decides is prompted forever.
- **Does the mode also change the words for numbers?** My plan changes the words only for the one heart-rate effort word on the ride detail in the two simple modes. "Zone 2" wording stays elsewhere. Options: that, nothing, or a wider rewrite later. Recommendation: the one word now.
- **Route preview on the Rides list.** Story 5 asks for it, but `RideCard` has none and the list API has no geometry. Options:
  - Drop it from this feature and add a later story. A preview needs a simplified line from the server, served through the privacy function, and it is a separate decision.
  - Build it here.
  - Recommendation: drop it for now.
- **Story 3 wording for with goals.** The story says "heart-rate time in zones". Is the existing easy, moderate and hard split acceptable instead? Recommendation: yes.
