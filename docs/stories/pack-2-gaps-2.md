# Pack 2 gaps 2: close what the 21 Nov audit found

## Overview
An audit on 21 Nov 2026 read Pack 1 and Pack 2 at commit `beadd09` (now part of `dev`, with no code change since) against the original story files (`git show 0326b92^:docs/stories/pack-1.md`, `git show 4149821^:docs/stories/pack-2.md`, `git show 4149821^:docs/stories/pack-2-gaps.md`). Everything is built except the gaps below. Every task names the exact file and line on `beadd09`; line numbers may drift slightly.

Who sees the data: Task 10 changes what a coach sees: every number and stream of what the rider shares, with only the route's start, end and saved places still hidden (Decisions below). Task 11 tells the rider before they share.

## How to work
- **Start from `origin/dev`**: `git fetch && git switch -c fix/pack-2-gaps-2 origin/dev`. Commit this file first if it is not there. The pull request goes into `dev`.
- **Order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12.** One commit per task. `just check` must pass before each commit. Do not commit with a failing or skipped test.
- Follow `AGENTS.md`. Every test name is `Subject_ShouldDoSomething_WhenCondition`. Every new user-facing string goes in **both** `app/lib/l10n/app_en.arb` and `app_it.arb`, then `just codegen` (or `flutter gen-l10n`).
- **Raise `RideParserVersion.Current` only in Task 12**, once, by one. No other task changes how a file is read. If you think another one must, stop and ask.
- **Do not add a dependency.** Do not edit `app/packages/velomine_api/` by hand; run `tools/generate-api-client.sh` when Task 7 says so.
- Server tests live in `tests/Velomine.Server.Tests/`. Copy the setup of the existing test file named in each task (same fixture, same helpers). Do not invent new helpers when an existing one fits.
- If anything here does not match the code, stop and report it instead of guessing.

## Tasks

### Task 1: Estimated watts count toward fitness and fatigue
**Why:** Pack 2 Story 5 rule 3 says a ride's effort is "TSS (power) → hrTSS → feel score → estimated TSS → 0". The estimated step is missing, so a rider with no sensors and no rating gets 0 load even though `Ride.EstimatedTss` is stored.
**Change:**
1. `src/Velomine.Server/Features/Rides/TrainingLoad.cs`
   - `EffortSources`: add `public const string Estimated = "estimated";`.
   - `Effort(...)` (line ~206): add a fourth parameter `double? estimatedTss` and a fourth step after feel: `estimatedTss is { } estimated ? (estimated, EffortSources.Estimated)`. Update the `<summary>` to name the fourth step.
2. Pass the stored `EstimatedTss` at all three call sites (they are the only ones; check with `rg -n "TrainingLoad.Effort\(" src`):
   - `Features/Analytics/RideDays.cs` (~line 86): add `r.EstimatedTss` to the anonymous `select` (~line 63) and pass it.
   - `Features/Coach/CoachAthletes.cs` `SummariesAsync` (~line 258): add `r.EstimatedTss` to the `Select` (~line 210) and pass it.
   - `Features/Rides/GetRide.cs` (~line 41): pass `ride.EstimatedTss`.
3. App `app/lib/features/accounts/effort_source_text.dart`: add `'estimated' => l10n.effortFromEstimated,`. New key `effortFromEstimated`: en "From estimated watts", it "Dai watt stimati".
4. `README.md` and `site/status/index.html` describe the effort score as "power, otherwise heart rate, otherwise how hard it felt" (`rg -n "how hard it felt" README.md site`). Add ", otherwise watts estimated from speed and slope" in the same style in each place.

**Tests** (put them next to the existing Story 5 tests in `Analytics/HeartRateEffortTests.cs` and the Story 6 tests in `Rides/EstimatedPowerTests.cs`; copy their setup):
- `TrainingLoad_Effort_ShouldUseTheEstimatedTss_WhenThereIsNoPowerHeartRateOrFeel` (pure: `Effort(null, null, null, 42.0)` → `(42.0, "estimated")`).
- `TrainingLoad_Effort_ShouldPreferTheFeelScore_WhenTheRideAlsoHasAnEstimate` (pure).
- `Training_ShouldCountTheEstimatedTss_WhenARideHasNoSensors`: upload a GPX with speed and altitude, no power and no heart rate, rider with a weight, no rating. The daily load in `GET /api/v1/analytics/training` equals the ride's stored `EstimatedTss`.
- `GetRide_ShouldSayEstimated_WhenTheEffortComesFromEstimatedWatts`: `EffortSource == "estimated"` and `EffortScore == EstimatedTss` for the owner.
- App test in the existing ride detail test file: `RideDetail_ShouldSayFromEstimatedWatts_WhenTheEffortIsEstimated`.

**Done when:** all of the above pass and `just check` is green. If `DemoTests` changes because the demo rider without sensors now has load, update its expected numbers only after you have checked the new numbers equal that ride's `EstimatedTss`.

### Task 2: The coach's single-athlete summary uses the effort score
**Why:** `CoachQueries.SummaryAsync` (`Features/Coach/CoachAthletes.cs` ~lines 333–334) sums `r.Tss`, while the roster (`SummariesAsync`) sums `r.Load`. A heart-rate-only rider shows 0 on `GET clubs/{clubId}/athletes/{userId}` but a real number on the roster.
**Change:** in `SummaryAsync`:
1. Pass `includeFeel: sharesWellbeing` to `RideDays.LoadAsync`. This matters: the default is `true`, and the rider's rating is wellbeing data that a coach may only use with the wellbeing grant.
2. Sum `r.Load` instead of `r.Tss` for both numbers (`Tss7`, `Tss42`).

Do **not** touch the `privacy.HidePower` lines (~83 and ~123) here; Task 10 removes them.
**Tests** (in `Analytics/HeartRateEffortTests.cs`, next to the coach tests already there):
- `CoachAthlete_ShouldCountHeartRateLoad_WhenTheRideHasNoPower`: a heart-rate-only ride gives the same `Tss7` on `GET clubs/{clubId}/athletes/{userId}` as on the roster.
- `CoachAthlete_ShouldNotCountTheFeelScore_WhenThereIsNoWellbeingGrant`: a ride with only a rating gives 0 without the wellbeing grant, and the feel score with it.
- `CoachAthlete_ShouldShowNoLoad_WhenTheRequestComesFromAnotherClub` (isolation, required by AGENTS.md): a coach of another club gets 404.

### Task 3: The export carries every bike and ride field
**Why:** AGENTS.md: "Export and deletion cover every table a member owns." `bikes.json` (`Features/Accounts/AccountExport.cs` ~lines 126–140) leaves out `ModelYear`, `BuildSpec`, `FrameSize` and `WeightKg`. `rides.json` carries `EstimatedAvgPowerW` (through `RideResponse.From`) but not `EstimatedNormalizedPowerW` or `EstimatedTss`.
**Change:**
1. In the `bikes.json` projection add `b.ModelYear`, `b.BuildSpec`, `b.FrameSize`, `b.WeightKg` (after `b.Model`, `b.Kind` and `b.WheelCircumferenceMm`, keeping the entity's order).
2. In the `rides.json` projection (~line 176) add `r.EstimatedNormalizedPowerW` and `r.EstimatedTss` next to `r.LoadThresholdHeartRate`, with a one-line comment like the one above it. Do **not** add them to `RideResponse`: that would put them in the API.

**Tests** (in the existing export tests; find them with `rg -n "bikes.json" tests`):
- `AccountExport_ShouldIncludeTheBikesWeightAndSpec_WhenTheBikeHasThem`: a bike with all four fields set; the exported JSON has the same values.
- `AccountExport_ShouldIncludeTheEstimatedPower_WhenARideHasNoSensors`: a sensorless ride; `rides.json` has non-null `EstimatedNormalizedPowerW` and `EstimatedTss` equal to the stored ones.

### Task 4: The database checks the bike's weight
**Why:** AGENTS.md: "Constraints live in the database." The 3–40 kg range is only in the validator (`Features/Bikes/SaveBike.cs:108`).
**Change:**
1. `Features/Bikes/BikeConfiguration.cs`: change `bike.ToTable("bikes", "bikes");` to the overload with a table builder and add `t.HasCheckConstraint("ck_bikes_weight_kg", "weight_kg IS NULL OR weight_kg BETWEEN 3 AND 40");`. Copy the style of `ck_users_weight_kg` in `Data/VelomineDbContext.cs:116`.
2. Add a migration: `just migration BikeWeightCheck`. Read the generated file: it must only add this check. Never edit an older migration.

**Test** (in `Bikes/`): `BikeTable_ShouldRefuseAWeightOutsideTheRange_WhenWrittenDirectly`. Insert or update a bike with `weight_kg = 50` through raw SQL; expect a `PostgresException` with `ConstraintName == "ck_bikes_weight_kg"`.

### Task 5: The app words the heart-rate notifications and opens their ride
**Why:** the server sends `heart_rate_measured` and `heart_rate_suggested` with an English subject: `"Maximum 192 bpm"` or `"Threshold 165 bpm"` (`Features/Analytics/HeartRateSuggestion.cs` ~lines 256, 278, 308). The app has no case for them, so an Italian rider sees bare English, and tapping does nothing.
**Change (app only; do not change the server subject, because old notifications and email already use it):**
1. `app/lib/features/notifications/notifications_text.dart`
   - In `notificationText`, add `'heart_rate_measured'` and `'heart_rate_suggested'`. Parse the subject with `RegExp(r'^(Maximum|Threshold) (\d+) bpm$')`. On a match, use one of four new keys with an `int bpm` placeholder. When the subject does not match, return `n.subject` as today.
   - In `notificationTarget`, add both types to the `'/rides/${n.rideId}'` group (`when n.rideId != null`).
2. `app/lib/features/notifications/notifications_screen.dart`: add both types to `_groupOf` → `'rides'`, and to `_icon` → `Icons.favorite_border`.
3. New l10n keys:

   | Key | en | it |
   |---|---|---|
   | `notificationHeartRateMaxMeasured` | "Your maximum heart rate is now {bpm} bpm, measured on a ride." | "La tua frequenza cardiaca massima ora è {bpm} bpm, misurata in un'uscita." |
   | `notificationHeartRateThresholdMeasured` | "Your threshold heart rate is now {bpm} bpm, measured on a ride." | "La tua frequenza cardiaca di soglia ora è {bpm} bpm, misurata in un'uscita." |
   | `notificationHeartRateMaxSuggested` | "A ride suggests a maximum heart rate of {bpm} bpm." | "Un'uscita suggerisce una frequenza cardiaca massima di {bpm} bpm." |
   | `notificationHeartRateThresholdSuggested` | "A ride suggests a threshold heart rate of {bpm} bpm." | "Un'uscita suggerisce una frequenza cardiaca di soglia di {bpm} bpm." |

**Tests** (in the existing notifications test file; find it with `rg -ln "ftp_suggested" app/test`):
- `NotificationText_ShouldWordAMeasuredMax_WhenTheSubjectIsMaximum` (en and it).
- `NotificationText_ShouldWordASuggestedThreshold_WhenTheSubjectIsThreshold`.
- `NotificationText_ShouldShowTheSubject_WhenItCannotBeRead`.
- `NotificationTarget_ShouldOpenTheRide_WhenAHeartRateNotificationHasARide`.

### Task 6: Typing a heart rate closes the open suggestion
**Why:** a suggestion is made only when a ride beats a number the rider typed. If the rider then types a higher number, the old suggestion stays open, and accepting it **lowers** their number (`AcceptHeartRateSuggestion` in `Features/Analytics/HeartRateSuggestionEndpoints.cs` checks nothing about it).
**Change:** in `SetHeartRateValue` (`Features/Accounts/HeartRates.cs`, `SetAsync` ~line 136 and `ClearAsync`): when the source is `manual`, and on every clear, set every open `HeartRateSuggestion` of that user **and kind** to `HeartRateSuggestionStatuses.Dismissed` in the same save. Load them through `db.HeartRateSuggestions` with a `Where`, then change `Status`. Do not use `ExecuteUpdateAsync`, so the change goes in the same `SaveChangesAsync` as the history row. Do not add a new status value: that would need a migration and a check-constraint change.
**Tests** (in `Analytics/HeartRateDetectionTests.cs`):
- `HeartRateSuggestion_ShouldClose_WhenTheRiderTypesTheNumber`: type 180, a ride suggests 190, type 195 → the list is empty, and accepting the old id answers 404 with the max still 195.
- `HeartRateSuggestion_ShouldStayOpen_WhenTheRiderTypesTheOtherNumber`: a max suggestion stays open after the threshold is typed.

### Task 7: Accepting a heart-rate suggestion declares its 400
**Why:** `AcceptHeartRateSuggestion.Configure()` declares `200, 401, 404`, but the handler can answer 400 through `HeartRates.ThresholdProblem`. AGENTS.md: every endpoint declares what it really returns.
**Change:** add `.ProducesProblem(400)` to its `Description`, the same way `CoachPowerCurve` does. Run `tools/generate-api-client.sh` and commit the regenerated client in the same commit.
**Test** (in `Analytics/HeartRateDetectionTests.cs`): `AcceptHeartRateSuggestion_ShouldAnswer400_WhenTheThresholdIsNotBelowTheMax`. A ride suggests a threshold of 170 while the max is 185. The rider then types a max of 165 (allowed, see the first gaps file). Accepting answers 400, and the suggestion stays open. (Task 6 closes only suggestions of the kind that was typed, so typing the max leaves this threshold suggestion open.)

### Task 8: The new-maximum card does not promise new zones when zones come from the threshold
**Why:** decision "plan Q2" in the first gaps file: "The new-maximum card drops 'Your zones now use it' when the rider's zones come from the threshold." `app/lib/core/widgets/heart_rate_note_card.dart` always uses `heartRateMaxMeasured` ("… Your zones now use it.").
**Change:**
1. `HeartRateNoteCard`: add `this.zonesFromThreshold = false` (a `final bool`, with a doc comment). When `kind == 'max'` and `zonesFromThreshold` is true and there is no suggestion, use the new key `heartRateMaxMeasuredOnly`: en "New maximum heart rate: {bpm} bpm.", it "Nuova frequenza cardiaca massima: {bpm} bpm.".
2. `app/lib/features/rides/detail/ride_detail_screen.dart` (the two `HeartRateNoteCard(` calls, ~lines 509 and 526): pass `zonesFromThreshold: ride.heartRateZoneModel.orElse(null) == 'threshold'`. Check the generated field name in `velomine_api` first. The Progress and Fitness screens only show suggestions; leave them alone.

**Test** (in the ride detail test file, next to the two-card test): `RideDetail_ShouldNotSayZonesChanged_WhenANewMaxIsMeasuredAndZonesComeFromTheThreshold`, plus the opposite case for the max model.

### Task 9: The FTP reminder counts days on the rider's calendar
**Why:** `Features/Analytics/FtpReminder.cs:58` takes the day the FTP was set from `instant.UtcDateTime`, but "today" is the rider's local day (`clock.Today`). Near midnight, the 42-day limit is off by one for riders far from UTC.
**Change:** replace `DateOnly.FromDateTime(instant.UtcDateTime)` with `clock.LocalDateOf(instant, null)` (`Features/Accounts/MemberClock.cs:32`; `null` means "use the member's time zone").
**Test** (in `FtpReminderTests.cs`): `FtpCheck_ShouldCountDaysOnTheRidersCalendar_WhenTheFtpWasSetNearMidnight`. A rider in `Pacific/Auckland` sets the FTP at 23:30 UTC (the next local day). Exactly 42 local days later, the reminder is not stale yet; one local day after that, it is stale. Use the existing fake clock in that file.

### Task 10: A coach sees every number; only the route's start, end and saved places stay hidden
**Why:** owner rule of 21 Nov (Decisions D1 and D2). When a rider shares with their club's coaches, the coach sees all of the rider's numbers and streams: power, heart rate, cadence, speed, elevation, temperature, W′ balance, estimated watts, records, efficiency, and the daily load built from every ride. The six "hide this stream" switches go away. Only three things still protect the rider from a coach:
- the four sharing choices (Rides, Training, Routes, Wellbeing), exactly as today: nothing reaches a coach without its grant;
- the route: positions only with the Routes grant, as today, and then the start and end trim and the saved places (privacy zones) still hide those parts of the line;
- what is the rider's own, not a number about the ride: free-text wellbeing notes, the FTP suggestion, the heart-rate notes and the effort score stay owner only, as today.

The rider keeps full control of their own data: they edit, delete and stop sharing whenever they want. The coach only reads.

**Change:**
1. `src/Velomine.Server/Features/Privacy/Privacy.cs`
   - Remove the six `Hide*` members from the records `PrivacyDefaults` and `PrivacyProfile`, and `HidesPowerOrHeartRate`. Keep `TrimStartM`, `TrimEndM` and `Zones`. Then fix every compile error by **deleting** the hiding, never by adding a new switch:
   - `ForViewer(RideResponse…)`: delete every line that hides a field behind a `Hide*` switch, so those fields pass through. Keep the lines that set `FtpSuggestion*`, the three `HeartRate*Note` fields, `HrTss`, `EffortScore` and `EffortSource` to null, but **show** `HrTss` (a number about the ride, like `Tss`). `EstimatedAvgPowerW` passes through.
   - `ForViewer(LapResponse…)`: nothing is hidden any more. Delete the method and its callers' use of it (`Coach/CoachLaps.cs`), or make it return `lap`, whichever is the smaller diff.
   - `ForViewer(RideStreamsResponse…)`: delete the seven `Hide*` lines and the `EstimatedPower = null` line. Keep the route part (routes grant, trim, zones) exactly as it is.
   - Update the class and method doc comments: the function now applies only the start and end trim, the saved places and the routes grant.
2. `src/Velomine.Server/Features/Rides/Ride.cs`: the `Privacy` property now carries only the trim. Detect an old ride by `TrimStartM is null` instead of `HideHeartRate is null`. The setter keeps writing the six `Hide*` columns as `false`, so the columns stay valid for their last release. Leave the six properties on `Ride` and on `PrivacySettings` with the comment `// Unused since pack-2-gaps-2 Task 10; drop the column in the next release.` Do **not** write a migration that drops them (AGENTS.md: migrate forward).
3. Every other use the compiler shows: delete the hiding.
   - `Coach/CoachAthletes.cs`: the 404 in `GetCoachTraining` when power or heart rate is hidden; the `Tss7`/`Tss42` blanking in the roster (~line 83) and in the single athlete (~line 123), with the `privacy` loads that only served them.
   - `Coach/CoachPowerCurve.cs`: the 404 when power is hidden.
   - `Analytics/Intensity.cs` and `Analytics/Efficiency.cs`: the `viewer` hiding. If the `viewer` parameter then has no use, remove it and its arguments.
   - `Rides/WPrimeBalance.cs`, `Analytics/PowerRecords.cs` and the coach ride endpoints in `Coach/CoachRides.cs`: any `HidePower` check.
   - The coach streams endpoint now also returns `EstimatedPower`.
4. `Privacy/UpdatePrivacySettings.cs`: the six `Hide*` request fields become optional (`bool?`, not `required`) and are ignored, so an older app that still sends them keeps working (AGENTS.md: a released API is never broken). `PrivacyResponses.cs`: keep the six response fields and always return `false`; add a one-line comment saying why. Run `tools/generate-api-client.sh`.
5. `Accounts/AccountExport.cs`: keep exporting the stored values while the columns exist.
6. Documents:
   - `AGENTS.md` *Security and privacy in code*, first bullet: replace "which applies privacy zones, start and end trimming and per-stream switches to the summary fields and the streams" with "which applies privacy zones and start and end trimming to the route. A coach with a grant sees every number and stream of what was shared; the member's own notes, suggestions and effort score stay owner only."
   - `AGENTS.md` *Ride processing → Estimated watts*: replace "They are owner only." with "A coach sees them like the other numbers, always marked estimated."
   - `docs/architecture.md` line ~135: remove "per-stream switches,".
   - `rg -n -i "stream|privacy|hide" site README.md`: a public claim that a rider can hide a stream from a coach must go, in the same commit.

**Tests:**
- Run the whole server suite first and list what fails. Every test that expected a coach **not** to see a stream or a number because of a switch now fails. Change it to expect the value and rename it, for example `HidePower_ShouldHidePowerAndItsNumbers_WhenCoachReadsTheRide` becomes `CoachRide_ShouldShowPowerAndItsNumbers_WhenTheRiderSharesRides`. The ones found on 21 Nov: `Privacy/PrivacyTests.cs` (`HidePower_…`, `HideHeartRate_…`), `Analytics/WPrimeBalanceTests.cs` (`CoachRide_ShouldHideWPrimeBalance_WhenPowerIsHidden`), `Analytics/PowerRecordsTests.cs` (`CoachRide_ShouldHidePowerRecords_WhenPowerIsHidden`), `Analytics/EfficiencyTests.cs` (the three `…Hidden` ones), `Analytics/IntensityTests.cs` (`…FallBackToHeartRate_WhenPowerIsHidden`, `…SkipTheRide_WhenBothSignalsAreHidden`), `Rides/EstimatedPowerTests.cs` (`CoachRide_ShouldHideEstimatedPower_WhenTheRideHidesSpeed` and the coach-streams one), `Analytics/HeartRateEffortTests.cs` (`CoachTraining_ShouldCountAHiddenRidesLoad_WhenThePowerSwitchIsOff`). There may be more.
- Do **not** change tests about grants (no grant = nothing), the routes grant, trimming, privacy zones, wellbeing notes or another club: they must still pass unchanged.
- New: `CoachStreams_ShouldStillTrimTheStartAndEnd_WhenTheRiderSetATrim`, `CoachStreams_ShouldStillHideTheSavedPlaces_WhenTheRiderHasAZone`, `CoachStreams_ShouldHaveNoPositions_WhenThereIsNoRoutesGrant` (keep if one exists), `CoachRide_ShouldShowEstimatedPower_WhenTheRideHasNoSensors`, `UpdatePrivacy_ShouldAcceptAnOldApp_WhenItStillSendsTheSwitches` (200, switches ignored), and `CoachRide_ShouldNotBeVisible_WhenTheRequestComesFromAnotherClub` (isolation).

### Task 11: The app: no stream switches, and the rider is told before sharing
**Why:** same decisions. The switches no longer do anything, and the rider must know what a coach sees, and agree explicitly to share wellbeing.
**Change:**
1. **Design first** (AGENTS.md: a change to the design updates the mock-up first):
   - `docs/design/pages/profile/PrivacyPage.html` and its guideline `PrivacyPage.md`: delete the "What others see of each ride" card. The subtitle becomes "What your club and coaches never see of your routes. You always see everything." Keep the trim and saved-places cards.
   - `docs/design/pages/profile/ProfilePage.html`: the "Ride privacy" row's line becomes "The start, end and places your coach never sees."
2. `app/lib/features/privacy/privacy_screen.dart` and `privacy_view_model.dart`: remove the six switches and their state. The save sends only the trim. Follow the new mock-up.
3. `app/lib/features/club/widgets/club_sharing_card.dart`: before a choice goes from `'none'` to `'coaches'`, ask with `confirmAction` from `app/lib/core/confirm.dart`. Call `onChoose` only when it returns true, and check `context.mounted` after the await. Going back to `'none'` never asks. Routes does not ask (its own row already explains it).
   - **Rides** and **Training** (`share-rides-confirm`, `share-analytics-confirm`): an information prompt.
   - **Wellbeing** (`share-wellbeing-confirm`): an explicit consent prompt. It is health data.
4. New l10n keys:

   | Key | en | it |
   |---|---|---|
   | `shareStatsConfirmTitle` | "Share with your coaches?" | "Condividere con i tuoi allenatori?" |
   | `shareStatsConfirmBody` | "Your coaches will see every number of your rides: power, heart rate, speed, cadence, elevation, temperature, and the training built from them. They only read; your rides stay yours to change or delete. The map needs Routes, and even then the start, the end and your saved places stay hidden." | "I tuoi allenatori vedranno tutti i valori delle tue uscite: potenza, frequenza cardiaca, velocità, cadenza, dislivello, temperatura e l'allenamento che ne deriva. Possono solo guardare; le uscite restano tue da modificare o eliminare. La mappa richiede Percorsi, e anche allora l'inizio, la fine e i tuoi luoghi salvati restano nascosti." |
   | `shareWellbeingConfirmTitle` | "Share your wellbeing with your coaches?" | "Condividere il tuo benessere con i tuoi allenatori?" |
   | `shareWellbeingConfirmBody` | "Your coaches will see your daily check-in scores and how hard each ride felt. This is health data, so we ask you first. Your notes stay private, and you can stop sharing at any time." | "I tuoi allenatori vedranno i punteggi del tuo check-in giornaliero e quanto è stata dura ogni uscita. Sono dati sulla salute, per questo te lo chiediamo prima. Le tue note restano private e puoi smettere di condividere in qualsiasi momento." |
   | `shareConfirmAction` | "Share" | "Condividi" |

   Delete the l10n keys of the six switches from both files once nothing uses them.

**Tests** (`app/test/privacy_test.dart` and `app/test/club_test.dart`; copy their setup):
- `PrivacyScreen_ShouldNotShowStreamSwitches_WhenItOpens`, and the existing trim and places tests still pass.
- `ClubSharingCard_ShouldAskFirst_WhenRidesAreSharedWithCoaches`, the same for Training.
- `ClubSharingCard_ShouldAskForConsent_WhenWellbeingIsSharedWithCoaches`.
- `ClubSharingCard_ShouldNotShare_WhenTheRiderCancels`.
- `ClubSharingCard_ShouldNotAsk_WhenSharingStops`.
- `ClubSharingCard_ShouldNotAsk_WhenRoutesAreShared`.
- One Italian-locale run of the wellbeing test.

### Task 12: Estimate watts the way Strava does
**Why:** Decision D3. Strava's own description ("How Strava Calculates Power", support.strava.com article 216917107, archived copy: https://web.archive.org/web/2017/https://support.strava.com/hc/en-us/articles/216917107-Power-Calculations) says:
- P = rolling + wind + gravity + acceleration, computed **within each sampling window**, so per recorded sample. Velomine already does this, so the 1 Hz grid from Pack 2 Story 6 is **dropped**: keep `EstimatedPower.Compute` per sample, with average and NP from the held seconds as today.
- **No wind, and an outside temperature of 15 °C**, because air density during the ride is unknown. So: one constant air density of 1.225 kg/m³ (15 °C at sea level), with no altitude correction.
- The watts are those of the **rider-bike system, not at the crank**. So: no drivetrain loss.
- Rolling resistance and drag by bike type, a constant frontal area, gravity `m · g · sin(arctan(grade)) · v`, and acceleration `m · a · v`: Velomine already does all of this the same way.

**Change** in `src/Velomine.Server/Features/Rides/Ingestion/EstimatedPower.cs`:
1. Delete `DrivetrainEfficiency` and the division by it in `Watts`.
2. Replace `var density = 1.225 * Math.Exp(-altitudeM / 8434);` with a constant `AirDensity = 1.225` and its one-line why ("Strava assumes 15 °C and still air"). Delete the now unused `altitudeM` parameter from `Watts` and its caller. Altitude still gives the grade.
3. Update the class and `Watts` doc comments: name Strava's method, per sample, no drivetrain loss, 15 °C still air.
4. Raise `RideParserVersion.Current` by one (from 5 to 6), with a comment naming this change. Stored estimated watts, NP and TSS change, so every ride is read again.
5. `AGENTS.md` *Ride processing → Estimated watts*: after "by the standard cycling power model" add "the way Strava describes it: per recorded sample, still air at 15 °C (1.225 kg/m³), watts of the rider and bike with no drivetrain loss".

**Tests** (`Rides/EstimatedPowerTests.cs`): the known values change. Recompute each by hand, put the arithmetic in a one-line comment, and rename the test to the new value:
- `…ShouldBe186W_WhenClimbingFivePercentAt4MetresPerSecond` → **182 W** (80 kg, Crr 0.004, CdA 0.32: (784.8 · 0.05393 + 3.136) · 4 = 181.8).
- `…ShouldBe143W_WhenRidingFlatAt30KmPerHour` → **140 W** (139.6).
- `…ShouldBe89W_WhenRidingGravelFlatAt6MetresPerSecond` → **87 W** (86.7).
- The 1,500 m test (expects 184 today) becomes `EstimatedPower_ShouldIgnoreAltitude_WhenTheAirDensityIsFixed` and expects **182 W**, the same as at sea level.
- Any other test or `DemoTests` value that moves: recompute it, never just copy the new output.
- Keep `RideReparse_ShouldEstimateWatts_WhenTheParserVersionRises` passing.

## Decisions (owner, 21 Nov 2026)
- **D1 and D2 (one rule):** a rider who shares with their coaches lets them see every number and stream of what they share, and everything computed from all their rides. Only the route's start and end trim and the saved places stay hidden (and positions need the Routes grant, as before). The six stream switches are removed; their columns stay for one release. The rider keeps full control of their data, and the coach only reads. Sharing rides or training shows an information prompt, and sharing wellbeing asks for explicit consent. Nobody uses the app yet, so there is no notice for existing riders (Tasks 10 and 11).
- **D3:** estimated watts copy Strava's published method (Task 12). The 1 Hz grid is dropped.
- **D4 (21 Nov, after review):** sharing rides with the coaches gives them the training built from those rides too. There is no separate Training choice in the app any more; `DataTypes.GrantedBy` lets a rides grant answer for training, and an older training-only grant still works.

## Deliberately left out
- Duration words in the power-record notification ("5 s", "1 min") read correctly in Italian too.
- The event card counts days with the device clock. The whole app does this, and it is right whenever the phone's time zone is the rider's.
- Cosmetic differences the audit listed (the critical-power row split over lines, the unused `criticalPowerRow*` strings, screens moved by the UI restructure). Remove the unused strings only if you touch those files anyway.
