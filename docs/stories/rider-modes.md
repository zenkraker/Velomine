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
- **Given** an account that never chose, **When** it loads, **Then** it shows Just riding.
- **Given** the server receives a mode it does not know, **When** I save, **Then** it answers 400 and keeps the old mode.
- **Given** I export my data, **When** the ZIP is built, **Then** my mode is in it. **Given** I delete my account, **Then** it is deleted with the rest.
- The mode is returned only to its owner.
- **Given** the app talks to an older server without rider modes, **When** it opens, **Then** it shows the full app, never asks the question and has no "How I ride" row.
**Dependencies:** None
**Size:** S

### Story 2: Choose how I ride, with a short explanation
**Priority:** High
**Description:** As a new member, I want one plain question about how I ride, with a line explaining each answer, so that I pick without knowing training words.
**Acceptance criteria:**
- **Given** I sign in for the first time and have not chosen, **When** the app opens, **Then** I am asked "How do you ride?" with three answers, each with a one-sentence explanation (draft below).
- **Given** I am not sure, **When** I tap "Decide later", **Then** Just riding is saved on my account, the question closes and does not come back; I can change it in Settings.
- **Given** "Decide later" cannot be saved (for example offline), **Then** the question stays open with the error, and I can retry or close it.
- **Given** I close the question without choosing (back, swipe or tap outside), **Then** it closes at once and Just riding is saved in the background. If that save fails, I still see Just riding and am asked again at my next sign-in or app start. (Deliberate: "Decide later" waits for the save, closing does not. Do not "fix" it.)
- **Given** I chose a mode on another device, **When** I sign in here, **Then** I am not asked.
- **Given** I am in Settings, **When** I open "How I ride", **Then** I see the same three answers and explanations, and the one I use is marked.
- **Given** I change my mode, **When** I go back to Rides, Progress or a ride, **Then** they already follow the new mode, without signing out.
- The text is in English and Italian. The choice is readable with a screen reader and each option is at least 48×48.
- If saving fails, I see the error under the choice and the old mode stays.
**Dependencies:** Story 1
**Size:** M

Modes:
- **Just riding:** "I ride for fun, with family or friends. I want my routes, my distance and how the ride went."
- **Riding with goals:** "I ride often and like to see my progress: weekly totals, goals, and how hard I rode in plain words."
- **Training:** "I train or race. I want power, training load, fitness and form, and every number."

### Story 3: The Progress tab follows my mode
**Priority:** High
**Description:** As a member, I want Progress to open with what matters to me, so that I am not met with a training lab I did not ask for.
**Acceptance criteria:**
- **Given** mode Just riding, **When** I open Progress, **Then** I see my totals (distance, time, climbing, rides) per week, month or year, and my goals. FTP prompts, readiness, training load, intensity, efficiency, power curve and the daily check-in are not shown first.
- **Given** mode Riding with goals, **When** I open Progress, **Then** I see totals, goals and the easy / moderate / hard split of my riding (from power when I have it, otherwise heart rate); power analysis and load cards are folded away.
- **Given** mode Training, **When** I open Progress, **Then** I see everything as today.
- **Given** a folded part, **When** I tap "Show more analysis", **Then** the cards appear and I can use them. Nothing needs a mode change.
- **Given** I ride without a power meter, **When** the mode is Training, **Then** power cards still follow today's rules for empty data.
- **Given** one source fails to load, **When** the page opens, **Then** only that part shows a retry (as today); a folded part shows its retry once I open it.
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
- **Given** the ride has no heart rate or power, **When** I open it, **Then** the missing parts do not appear in any mode, and nothing shows an empty chart or a guessed effort word.
- **Given** a ride I opened to check or delete, **Then** edit, bike, type, privacy and delete work the same in every mode.
- A coach or club member who views my ride through a grant sees what the grant allows, whatever my mode (my mode never changes what others see).
**Dependencies:** Story 1
**Size:** M

### Story 5: The Rides list follows my mode
**Priority:** Medium
**Description:** As a member, I want each ride in my list to show what I care about, so that I can find "the Sunday ride" or "the hard interval day" at a glance.
**Acceptance criteria:**
- **Given** mode Just riding, **When** I open Rides, **Then** each ride shows its title, date, distance and time.
- **Given** mode Riding with goals, **Then** each ride adds average heart rate when it exists.
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
- A route preview on each ride in the Rides list: it needs its own story and a privacy decision.
- Plain words for numbers beyond the one effort line on a ride.

## Decisions
- 2026-11-19: The difference matters on all three places: the Rides list, the ride detail and the Progress tab.
- 2026-11-19: The member chooses their mode with one plain question on first launch.
- 2026-11-19: Modes, not a switch list: the owner wants several named modes with tiny explanations, including a middle one for hobbyists who want "some more".
- 2026-11-19: No migration; nobody uses the app yet.
- 2026-11-19: Member's own screens first; recorder and club/coach views later.
- 2026-11-19: The owner asked the architect to retry the Advisor; it answered and its points are in the Plan.
- 2026-11-19: Three modes: Just riding, Riding with goals, Training (slugs `just_riding`, `with_goals`, `training`).
- 2026-11-19: The default is Just riding. "Decide later" (or dismissing the sheet) saves Just riding on the account, so the member is not asked again; Settings changes it.
- 2026-11-19: Plain words only for the one effort line on a ride ("mostly easy", "steady", "hard"); real terms elsewhere.
- 2026-11-19: No route preview on the Rides list in this feature; a later story with its own privacy decision.
- 2026-11-19: Riding with goals uses the existing easy / moderate / hard split on Progress; no new heart-rate-only chart.

- 2026-11-19: Owner said go. Build in two runs: run 1 = Stories 1 and 2 (server, API client, setting, prompt, Settings row; the Rides, ride detail and Progress screens are NOT touched, so `RiderModeLayout` and `riderLayoutProvider` exist but no screen uses them yet); run 2 = Stories 3, 4 and 5 (the three screens, `MoreDetails`, `effortWord`, required `layout` parameters).
- 2026-11-19: Demo accounts keep `training`.

## Plan
### Status
Final. The owner answered all five questions, so nothing is left for the owner. The Advisor answered this time. It saw only my summary, and it verified nothing in the code.

### What changed since the last version

**From the owner's answers**
- **Three modes, slugs unchanged.** The migration is no longer blocked.
- **The default is just riding.**
  - A never-chosen account (`rider_mode` null) shows the just-riding layout.
  - "Decide later" or dismissing the sheet saves `just_riding` on the account. The prompt then never returns.
- **The effort line is the only plain-word change.** There is no route preview on the Rides list.
- **With goals uses the existing `IntensityCard`.** The "Questions for the owner" section is now "None".
- **The old "default may be training" and "pinning" questions are removed.** The owner chose a pinned `just_riding`.
- **Demo seeding stays on `training`.**
  - The accounts are a shared showcase.
  - The default does not affect them, because they carry an explicit value.
  - The plan states the shared-account effect and records the decision.

**Advisor findings on this revision**
- **Adopted: capability comes from the read, not from a failed save.**
  - On an old server a missing `riderMode` key reads as `null` in the generated client, the same as "never chosen".
  - `MeResponse` therefore also carries `bool? RiderModeSupported`, always `true` from a new server. It is nullable on purpose, so an old server reads as `null` and does not break parsing of `/me`.
  - When it is not `true`, the app shows the full layout, no prompt and no Settings row.
  - The `unavailable` flag and the 404/405 handling are removed. A save failure is an ordinary failure, because a proxy error or a deleted account also give 404.
- **Adopted: first paint.**
  - A not-yet-loaded `session.me` is not treated as "never chosen". It gives the full layout and no prompt.
  - `session.me` is the single source. The view model derives `chosen` from it and keeps no copy or cache. There is no per-account cache, because a signed-in session has already read `/me`.
- **Adopted: unknown slug.** A non-null slug this build does not know (a newer server) gives the full layout and no prompt. It never crashes, because the field is a plain string.
- **Adopted: dismiss-save race.**
  - Saves go through one serialised queue in the view model.
  - The dismiss-save is conditional: it is skipped if `chosen != null` when it runs. A later choice in Settings is never overwritten.
  - The prompt reads the value from the sign-in `/me`, so a mode chosen on another device is not asked again.
  - The asymmetry is deliberate and is written into the plan: "Decide later" waits for the save, a dismiss does not.
- **Adopted: the fake server matches the real one.** Registering through the fake gives `riderMode: null`, so a registration test sees the prompt. The shared seeded fixtures set `'training'` explicitly.
- **Adopted: demo.**
  - A deliberate call, recorded in the plan: the mode save is allowed in demo and not added to `DemoLock.Refused`.
  - The nightly remake sets `training` again, and a test proves it after a change.
- **Adopted: the database constraint and "no backfill" are stated explicitly.**
  - The mode is a nullable column with a check constraint, and the validator gives the 400.
  - Existing accounts are not migrated, which matches "nobody uses the app yet".
  - Existing accounts would be prompted and see just riding until they choose.
- **Adopted as a Developer check:** if `site/` has a status page that lists features, add a line for this one. Otherwise do nothing.
- **Rejected:** a separate `GET` for the mode as the capability probe, and a per-account cached mode. Both are heavier than the one nullable flag.

### Context
- The rider mode is the member's own display setting, stored like `Language` and `Units` and read from `GET /accounts/me`.
- The server never filters by it. Coach, club and share views never read it. The server needs a column, one endpoint, and the export and deletion rules.
- The app has no per-mode layout today.
  - `ProgressScreen` builds one `analysis` list and always shows the metric cards and `WellbeingCard` (`progress_screen.dart`).
  - `RideDetailScreen._body` shows everything (`ride_detail_screen.dart`).
  - `RideCard.facts` lists every number the ride has (`rides_screen.dart:480-520`).
- The three screens need one decision table, so none of them branches on the enum.
- Precedent:
  - `SetMyUnits` and `UnitsChoiceViewModel` (`core/units.dart`)
  - `ck_users_units` (`VelomineDbContext.cs:121`)
  - the export at `AccountExport.cs:103`
  - the fake server's units handler (`app/test/fake_server.dart:1020`)
- Story 2 needs a visible save failure and an unchanged old mode. `Session.setLanguage` and `setUnits` swallow errors, so I do not copy them. The new view model uses `Result<T>` and `CommandState`, like `ProfileViewModel`.
- The generated `MeResponse.fromJson` asserts that nullable-but-required keys such as `language` exist, but only in debug builds. In release a missing key reads as null. That is why capability needs a value, not an absent key.
- The web app is the same Flutter codebase, so the mode applies there too. `site/` is untouched, except for the status-page check above.

### Decision
**Server (additive, one migration)**
- `User.RiderMode` is a `string?`. Null means the member never chose. The server does not know the default.
- Column `rider_mode` in `accounts.users`, max length 16, with check constraint `ck_users_rider_mode`: `rider_mode IS NULL OR rider_mode IN ('just_riding','with_goals','training')`.
- There is no backfill. Existing accounts stay null.
- The slugs are stable. Names and explanations live only in l10n. A later change of the slug set means expand, backfill, contract. An applied migration is never edited.
- `PUT /api/v1/accounts/me/rider-mode` (`SetMyRiderMode`) takes `SetMyRiderModeRequest(string RiderMode)`.
  - A FastEndpoints validator accepts only the three slugs.
  - An unknown value gets 400 as ProblemDetails, and the old value stays.
  - It returns `MeResponse`, like `SetMyUnits`.
- `MeResponse` appends, last and in this order, `string? RiderMode` and `bool? RiderModeSupported`.
  - `MeResponse.From` fills them, and `RiderModeSupported` is always `true`.
  - A code comment says the flag is nullable on purpose, so a newer app can tell an older server.
  - It is owner-only because `/accounts/me` is the caller's own. No coach, club or share DTO carries it.
  - After regeneration, check that the Dart field is `bool?`.
- The export adds `user.RiderMode` to `profile.json` next to `user.Language` and `user.Units`. Deletion needs no code, because the column is on the user row.
- Demo mode:
  - `Features/Demo/DemoData.cs` seeds `RiderMode = "training"` on every remake. The Developer checks whether `demo-seed.sql` also creates users.
  - The endpoint is **not** added to `DemoLock.Refused`. It locks nobody out.
  - A visitor's change shows to the next visitor until the 03:00 UTC remake. That is the same as language and units.
  - This is recorded in the Decisions table.
- Cross-device: the second device keeps its old mode until `/me` is read again (sign-in or `refreshMe`). The last write wins.
- No change to `RideParserVersion`. The effort word is computed in the app from the zone seconds the server already returns, and it is never stored or sent.

**App: one source, one decision table**
- `lib/core/rider_mode.dart` holds:
  - `enum RiderMode { justRiding, withGoals, training }`
  - `knownRiderMode(String?)`, which returns null for an unknown slug
  - `const defaultRiderMode = RiderMode.justRiding`
  - `RiderModeLayout`, a pure const class built by `RiderModeLayout.of(mode)`, plus `RiderModeLayout.full`
  - `riderLayoutProvider`, a `Provider<RiderModeLayout>`
- The single source of truth is `session.me`.
  - `Session` gets one small method, `adoptMe(MeResponse)`. It sets `me` and calls `_notify()`, as `setUnits` already does, and it never swallows errors.
  - The Developer reads how `sessionProvider` notifies Riverpod, and makes `riderLayoutProvider` and the view model rebuild when `me` changes.
- `RiderModeSituation` is the one rule table. It is a pure function of `session.me`. It is used by both `riderLayoutProvider` and the prompt:

| `session.me` | Layout | Prompt | Settings row |
|---|---|---|---|
| null (not loaded) | `full` | no | hidden |
| `riderModeSupported != true` (old server) | `full` | no | hidden |
| `riderMode` null | `of(justRiding)` | yes, once, until a save succeeds | shown, nothing marked until chosen |
| a known slug | `of(thatMode)` | no | shown, that mode marked |
| an unknown non-null slug | `full` | no | shown, none marked |

- `RiderModeViewModel` is a keepAlive notifier in `lib/features/profile/rider_mode_view_model.dart`.
  - Its state is `RiderModeState { bool promptHandled; CommandState<void> save }`.
  - `build()` watches `signedInUserIdProvider`, so a sign-out or an account switch rebuilds it empty.
  - `choose(RiderMode mode, {bool onlyIfUnset = false})` goes through one serialised queue. It calls `ProfileData.setRiderMode`, which wraps `accounts.setMyRiderMode` and returns `Result<MeResponse>`.
  - On `Ok` it calls `session.adoptMe`. On `Failed` the old mode stays and `save.failure` is set.
  - With `onlyIfUnset` it first re-reads `session.me` and skips the call if `riderMode != null`. This stops a dismiss-save overwriting a later choice in Settings.
- **Structural rule.** `RideCard` and `RideDetailScreen` take a **required** `layout` parameter and never read the provider themselves.
  - Only the member's own call sites pass `ref.watch(riderLayoutProvider)`: `RidesScreen`, and the `/rides/:id` builder in `app.dart`, which becomes a `Consumer` like `/rides`.
  - Any coach, club or share caller passes `RiderModeLayout.full`.
- `RiderModeLayout` fields:
  - `foldAdvanced`: true for just riding and with goals.
  - `showZonesAndCharts`: with goals and training.
  - `showIntensity`: with goals and training.
  - `rideListFacts`: a set of fact ids.
  - `rideChartIds`: elevation, speed and heartrate for with goals; all for training and `full`.
  - `effortWord`: true for just riding and with goals.
- `MoreDetails({label, children})` in `lib/core/widgets/more_details.dart` renders the fold.
  - It shows a button ("Show more analysis" or "Show all details"). Its open state is a view-local `bool`, reset on every screen visit.
  - Any animation goes through `lib/core/motion.dart`.
  - In training and `full` the folded list is empty and everything stays in today's place.
- **Folded sources still load eagerly.** The screens keep watching every view model, so loading is unchanged. A hidden source that fails shows no `ErrorState` until the member opens the fold.

**Progress** (`progress_screen.dart`)
- Core in every mode:
  - the "this period" `_metricCard`
  - `_TotalsCard`, `_TotalsTable` and `NextEventCard`
  - goals
  - the period and discipline filters
- With goals adds `IntensityCard`, the existing easy, moderate and hard split.
- Advanced, folded in the two simple modes and shown as today in training and `full`:
  - `FtpSuggestionCard`, `HeartRateNoteCard`, `FtpReminderCard`
  - `ReadinessCard`, `TrainingSummary`, `EfficiencyCard`, `PowerSummary`
  - `IntensityCard` in just riding
  - `WellbeingCard`
  - the FTP-history menu entry
- The readiness, training and power `_metricCard`s are omitted in the simple modes.
- The `failures` list counts only sources whose widget is visible.
- The wellbeing check-in keeps its consent rule. A simple mode never shows it first.

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
  - The wording is "mostly easy", "steady" or "hard".
  - A ride with no zones (no heart rate, or no maximum heart rate) shows no word. It never says "easy" by default.
- With goals shows the basic block, the heart-rate zones card, and the charts in `rideChartIds`.
- Advanced, folded in the simple modes:
  - `FtpSuggestionCard`, `HeartRateNoteCard`, `PowerRecordChips`, `LapTable`
  - the power zones card
  - `RideFeelCard` (RPE and notes are wellbeing data, and its consent prompt stays out of the simple modes)
  - the training hint, the advanced stats, and the charts not in `rideChartIds`
- Training and `full` keep all of this in today's order.

**Rides list** (`rides_screen.dart`, `RideCard`)
- `RideCard` filters `facts` by `layout.rideListFacts`.
  - Just riding: distance and time. The title and date are always shown.
  - With goals: distance, time and average heart rate.
  - Training and `full`: as today.
- The existing `> 0` guards stay, so a missing number is left out. Switching mode rebuilds the cards and does not reload the rides.
- There is no route preview.

**First launch and Settings**
- `RiderModePrompt` is a small `ConsumerStatefulWidget` mounted in `HomeShell` (`home_shell.dart:26`).
  - It opens the sheet when the table says "prompt yes" and `!promptHandled`.
  - It sets `promptHandled` as soon as the sheet opens, so it opens at most once per signed-in session.
- The sheet is `showRiderModeSheet(context, {required bool firstTime})` in `features/profile/rider_mode_sheet.dart`, a `SheetFrame`.
  - It has three selectable tiles. Each has a name, a one-sentence explanation, a selected mark, `Semantics(selected:)`, and at least 48 dp height.
  - An `InlineError` with `failureText` shows under the choice when `save.failure` is set.
- Choosing a tile calls `choose(mode)`, waits, and closes on `Ok`. On `Failed` the sheet stays open with the error.
- **"Decide later" waits.** It calls `choose(defaultRiderMode)`. On failure, such as offline, the sheet stays open with the inline error and the member can retry or dismiss.
- **A dismiss does not wait.** A tap on the barrier, the back button or a swipe closes the sheet at once. It then fires `choose(defaultRiderMode, onlyIfUnset: true)` without awaiting it.
  - If that save fails, the account stays null and the screens still show just riding.
  - The prompt does not reopen in this session. It returns on the next sign-in or app start.
  - The prompt stops for good only after a successful save.
- The asymmetry between "Decide later" and a dismiss is deliberate. The PO writes it into the story so nobody "fixes" it.
- `profile_screen.dart` gets a "How I ride" row, key `profile-rider-mode`, under the units dropdown. It shows the current mode name, or the default's name while the account is null, and opens the sheet with `firstTime: false`. It is hidden when the table says so.
- l10n goes in both `app_en.arb` and `app_it.arb`: the question, the three names and explanations, "Decide later", "How I ride", "Show more analysis", "Show all details", and the three effort words.

### Files to change
- `src/Velomine.Server/Features/Accounts/User.cs` — add `RiderMode`.
- `src/Velomine.Server/Data/VelomineDbContext.cs` — max length and `ck_users_rider_mode`.
- `src/Velomine.Server/Data/Migrations/*AddRiderMode*` — generated, never hand-edited.
- `src/Velomine.Server/Features/Accounts/SetMyRiderMode.cs` — new endpoint, request and validator.
- `src/Velomine.Server/Features/Accounts/GetMe.cs` — `MeResponse.RiderMode` and `RiderModeSupported`. Grep every `new MeResponse(` caller.
- `src/Velomine.Server/Features/Accounts/AccountExport.cs` — add `user.RiderMode` to `profile.json`.
- `src/Velomine.Server/Features/Demo/DemoData.cs` — `RiderMode = "training"` on the seeded users. Check `demo-seed.sql` as well.
- `app/packages/velomine_api/**` — regenerated, never hand-edited.
- `app/lib/core/session.dart` — `adoptMe(MeResponse)`.
- `app/lib/core/rider_mode.dart` — enum, `defaultRiderMode`, `RiderModeLayout`, the situation rule, `riderLayoutProvider`.
- `app/lib/core/widgets/more_details.dart` — `MoreDetails`.
- `app/lib/features/profile/profile_data.dart` — `setRiderMode` returning `Result<MeResponse>`.
- `app/lib/features/profile/rider_mode_view_model.dart`, `rider_mode_state.dart` and the generated `.g.dart`.
- `app/lib/features/profile/rider_mode_sheet.dart` — the sheet.
- `app/lib/features/profile/profile_screen.dart` — the "How I ride" row.
- `app/lib/app.dart` — the `/rides/:id` builder wrapped in a `Consumer` that passes the layout.
- `app/lib/home_shell.dart` — mount `RiderModePrompt`.
- `app/lib/features/progress/progress_screen.dart` — tag core and advanced, filter `failures`, fold.
- `app/lib/features/rides/detail/ride_detail_screen.dart` and the new `effort_word.dart` — required `layout`, `_Stats` filter, fold, effort line.
- `app/lib/features/rides/rides_screen.dart` — `RideCard` takes a required `layout`, and `RidesScreen` passes it.
- Every other `RideCard(` and `RideDetailScreen(` caller, found by grep — pass `RiderModeLayout.full` for other people's data.
- `app/lib/l10n/app_en.arb`, `app_it.arb` — new strings.
- `app/test/fake_server.dart`:
  - The account gets `riderMode`, default **null**, like the real server.
  - The registration handler creates the account with null.
  - The shared seeded accounts, such as `rider@example.com`, set `'training'` explicitly.
  - All three `/me` bodies (about lines 647, 1033, 1048) emit `riderMode` and `riderModeSupported: true`.
  - A switch `riderModeSupported = false` makes `/me` omit both keys, to emulate an old server.
  - A `PUT /api/v1/accounts/me/rider-mode` handler answers 400 on an unknown slug.
- Existing tests that build `RideCard` or `RideDetailScreen` directly — pass a layout.
- `site/` — only if a status page lists features: add one line.

### Anchors (keep exactly)
- Slugs: `just_riding`, `with_goals`, `training`. They are never renamed.
- Column `rider_mode`, constraint `ck_users_rider_mode`.
- `PUT /api/v1/accounts/me/rider-mode`, endpoint `SetMyRiderMode`, request `SetMyRiderModeRequest(string RiderMode)`, response `MeResponse`.
- `Description(d => d.Accepts<SetMyRiderModeRequest>("application/json").Produces<MeResponse>(200).ProducesProblem(400).Produces(401), clearDefaults: true)`.
- `MeResponse` appends `string? RiderMode, bool? RiderModeSupported` last, in that order. `RiderModeSupported` is always `true` from the server.
- Dart: `RiderMode`, `defaultRiderMode = RiderMode.justRiding`, `RiderModeLayout` (`.of`, `.full`), `riderLayoutProvider`, `RiderModeViewModel` (`riderModeViewModelProvider`), `MoreDetails`, `Session.adoptMe`. `layout` is a required parameter of `RideCard` and `RideDetailScreen`.
- The situation table above is the whole rule. Do not add a second source of the mode.
- Widget keys: `rider-mode-prompt`, `rider-mode-just_riding`, `rider-mode-with_goals`, `rider-mode-training`, `rider-mode-later`, `rider-mode-error`, `profile-rider-mode`, `more-details`, `ride-effort`.
- Existing keys stay: `metric-*`, `training-*`, `stat-*`, `heart-rate-zones`, `power-zones`.

### Tests
- Server (`ProfileTests`, `DataOwnershipTests`, demo tests):
  - `SetMyRiderMode_ShouldSaveAndReturnMode_WhenSignedInOnAnotherDevice`
  - `SetMyRiderMode_ShouldAnswer400AndKeepOldMode_WhenModeIsUnknown`
  - `GetMe_ShouldReturnNullRiderModeAndSupportedTrue_WhenMemberNeverChose`
  - `AccountExport_ShouldContainRiderMode_WhenMemberChose`
  - `AccountDeletion_ShouldRemoveRiderMode_WhenAccountIsDeleted`
  - `RiderMode_ShouldNotAppearInAnyOtherMembersView_WhenCoachOrClubMemberReadsTheRide`
  - `DemoData_ShouldSeedTraining_WhenDemoIsRemadeAfterAVisitorChangedTheMode`
  - A second-club test is not needed. The mode is not club data and has no `club_id`.
- Dart pure tests:
  - `RiderModeLayout_ShouldHideLoadFacts_WhenModeIsJustRiding`, and the same for the other two modes.
  - `RiderModeSituation_ShouldGiveJustRidingAndPrompt_WhenAccountNeverChose`
  - `RiderModeSituation_ShouldGiveFullLayoutAndNoPrompt_WhenServerDoesNotSupportModes`
  - `RiderModeSituation_ShouldGiveFullLayoutAndNoPrompt_WhenMeIsNotLoaded`
  - `RiderModeSituation_ShouldGiveFullLayoutAndNoPrompt_WhenSlugIsUnknown`
  - `EffortWord_ShouldBeEasy_WhenMostTimeIsInZonesOneToThree`
  - `EffortWord_ShouldBeHard_WhenTieBetweenModerateAndHard`
  - `EffortWord_ShouldBeNull_WhenNoZones`
- Dart view model and widget tests:
  - `RiderModeViewModel_ShouldKeepOldMode_WhenSaveFails`
  - `RiderModeViewModel_ShouldStartEmpty_WhenAnotherMemberSignsInAfterSignOut`
  - `RiderModeViewModel_ShouldSkipDismissSave_WhenModeWasChosenMeanwhile`
  - `RiderModePrompt_ShouldAskOnce_WhenAccountJustRegistered`
  - `RiderModePrompt_ShouldNotAsk_WhenModeWasChosenOnAnotherDevice`
  - `RiderModePrompt_ShouldNotAsk_WhenServerDoesNotSupportModes`, with no Settings row either
  - `RiderModePrompt_ShouldSaveJustRiding_WhenDecideLaterIsTapped`
  - `RiderModePrompt_ShouldSaveJustRiding_WhenSheetIsDismissed`
  - `RiderModePrompt_ShouldKeepSheetOpenWithError_WhenDecideLaterFails`
  - `RiderModePrompt_ShouldNotReopenThisSession_WhenDismissSaveFails`, and it reopens after the next sign-in
  - `RiderModeSheet_ShouldShowInlineError_WhenSaveFails`
  - `ProgressScreen_ShouldFoldAnalysis_WhenModeIsJustRiding`
  - `ProgressScreen_ShouldAddIntensity_WhenModeIsWithGoals`
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
- Existing Dart tests stay green because the shared seeded fixtures carry `riderMode: 'training'` and `riderModeSupported: true`. Nobody is prompted and nothing is folded. Only the registration and prompt tests start from null.

### Commands the Developer must run
- `just migration AddRiderMode`
- `tools/generate-api-client.sh`
- `just codegen` (Riverpod `.g.dart` and `gen-l10n`)
- `just check`, last.

### Risks and mitigations
- **Old server with a new app.** `riderModeSupported` reads null, so the app shows the full layout with no prompt and no Settings row. A test covers it. There is no trap, and there is no flash of just riding.
- **A cold or offline start before `/me` is read.** `me` is null, so the full layout shows and nothing is prompted. A training rider never sees a wrong prompt. Nothing is cached, and nothing is lost.
- **A rider who dismisses the sheet while offline.** The account stays null. They see just riding and are asked again at the next sign-in or app start.
- **Existing accounts on upgrade.** They are null, so they are prompted and see just riding until they choose. This is intended: the owner decided there is no migration.
- **A newer server adds a fourth slug.** An older app shows the full layout and does not crash.
- **A hidden source fails.** `failures` counts visible sources only. Tests cover the folded and unfolded cases.
- **Someone else's data follows the viewer's mode.** The required `layout` parameter makes this structural, and the Developer passes `RiderModeLayout.full` for others' data.
- **The dismiss-save overwrites a later choice.** It is serialised and conditional on `riderMode == null`. A cross-device race inside one request window is accepted, and the last write wins.
- **Demo visitors share accounts.** The mode save is allowed, as for language and units, and the nightly remake restores `training`. This is recorded.
- **Prompt in every widget test.** Fixtures carry `'training'`, and the registration path is the only one that starts from null.
- **Unrelated, not planned.** `Session.setLanguage` and `setUnits` swallow errors, so a failed save is invisible.

### Alternatives considered
- **Server-filtered responses per mode.** Rejected: two data shapes, a risk of leaking into coach and share views, and the story says nothing is removed.
- **A switch list per feature.** Rejected: the owner chose named modes.
- **Infer the mode from data.** Rejected by the stories and by values.
- **Mode stored per device.** Rejected: Story 1 wants it on the account.
- **Prompt on every launch until the member chooses.** Rejected: it nags. The owner chose a saved default.
- **The server returns the default instead of null.** Rejected: the app could no longer tell "never chose" and could not prompt.
- **Detecting an old server from a 404 or 405 on save.** Rejected after the Advisor's point: it is too late, and it conflates a proxy error or a deleted account. The read-side `RiderModeSupported` replaces it.
- **A separate `GET` probe for the mode.** Rejected: a second endpoint for what one nullable field does.
- **A per-account cached mode for first paint.** Rejected: `session.me` is already read before the member is signed in, so a cache has nothing to add.
- **`Session.setRiderMode` in the `setLanguage` style.** Rejected: it swallows errors, and Story 2 needs a visible failure.
- **Lazy-load folded sources.** Rejected for now: filtering `failures` is a smaller diff with the same user result.
- **Optional `layout` on `RideCard` and `RideDetailScreen`, defaulting to the provider.** Rejected: a forgotten argument would silently follow the viewer's mode.

### Records
- `docs/architecture.md` Decisions table: "Rider mode: a per-account display setting in `accounts.users.rider_mode`, like language and units. Null means never chosen, and the app shows just riding by default. The server never filters by it, and no coach, club or share view reads it. In demo the mode may be changed, and the nightly remake restores `training`."
- `AGENTS.md`, App section: "Screens read the rider mode through `riderLayoutProvider` and pass the layout down. A widget that can show someone else's data takes the layout as a required parameter and gets `RiderModeLayout.full` there; a view never branches on the mode enum. An optional new `/me` field that must be told apart from a missing key on an older server gets a nullable capability flag, never inference from null."
- `docs/stories/rider-modes.md`: note that "Decide later" waits for the save while a dismiss does not. This is deliberate.

### Questions for the owner
None.
