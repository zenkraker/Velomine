# Pack 2: every rider's effort counts

Nine user stories that make Velomine understand riders **without a power meter** as well as riders with one, and that lay the ground for auto training (Pack 3). Today a rider with only a heart-rate strap gets an empty fitness chart and zones guessed from age. After this pack:

- every ride has an effort score: from power, otherwise heart rate, otherwise watts estimated from speed and slope;
- the rider's maximum and threshold heart rate are learned from their rides;
- heart-rate zones come from the threshold, and every zone can be adjusted by hand;
- races and events have a date, the weekly load says when it is too monotonous or too heavy, and one card shows the rider's numbers.

Prior art: [Domestique](https://github.com/platypus45/domestique) (Apache-2.0) has some of these features. Build every formula **from the cited source and the definitions in this file**, never by translating Domestique's code, and credit it as inspiration in the commit message where a story says so.

## How to work through this file

- Do the stories **in order**. Each lists what it depends on.
- One story is one commit on `main` (or a few, if it is large). Never push; the owner pushes.
- Before each commit: `just check` passes, and the commit message ends with the attribution line from the session.
- "On read" means computed in the request and stored nothing. "At read" means when a ride is read from its file: store it on the ride and raise `RideParserVersion.Current` in the same change.
- A decision not written here is not yours to invent. If something is truly ambiguous, stop and ask the owner.
- When a story changes a rule in `AGENTS.md`, edit that rule in the same commit (each story says which).

## Rules that apply to every story

1. **Slices.** Server code lives in `src/Velomine.Server/Features/<Area>/`, one file per use case, FastEndpoints, `VelomineDbContext` used directly. Heart-rate numbers go in `Features/Accounts/`, analytics in `Features/Analytics/`, events in a new area `Features/Training/` with its own schema `training` (Pack 3 builds plans there).
2. **API.** Every endpoint declares what it accepts and returns with `Description(...)`; DTOs stay flat. Adding fields to an existing response is allowed; never remove or rename one. After any endpoint change run `tools/generate-api-client.sh` and commit the regenerated client. Never edit `app/packages/velomine_api/` by hand.
3. **Data.** New tables live in the area's schema, use `uuid` keys, `timestamptz` instants, snake_case names and database constraints. Add a migration with `just migration Name` and read its SQL. Migrations are additive.
4. **Member data.** Any new table that holds a member's data is added to `AccountExport` and `AccountDeletion` in the same change, with a test for each.
5. **Coaches and privacy.** Unless a story says otherwise, everything new is **owner only** in Pack 2; coaches come in Pack 3b. Where a value already reaches coaches today (the training range), the story says how the new value follows the existing rule.
6. **App.** Riverpod + MVVM, data through the feature's `*_data.dart`, `Result<T>`, shared widgets from `lib/core/widgets/` (use `SourceNote` from Pack 1 for every "where this came from" line). Every new string in **both** `app_en.arb` and `app_it.arb`; `just codegen` after changing a `@riverpod` provider.
7. **Tests.** Names follow `Subject_ShouldDoSomething_WhenCondition`. Server tests use the real PostgreSQL fixture. **Every formula has a test against the known values written in the story.**
8. **Logging.** Never log heart rate, watts, weight, FTP or any member value.
9. **Words.** Plain language in the UI. The rider-facing words for the terms in this file are:

| Term in this file | Words in the app (en) |
|---|---|
| maximum heart rate | Maximum heart rate |
| threshold heart rate (LTHR) | Threshold heart rate — "the highest you can hold for about an hour" |
| effort score (TSS, hrTSS) | Effort score |
| estimated power | Estimated watts (always with the word "estimated") |
| monotony | "Every day about as hard" |
| strain | "A heavy week" |

---

## Story 1: maximum and threshold heart rate, with where they came from

**As a rider**, I want to set my maximum and threshold heart rate, or let Velomine estimate them, and always see where each came from, **so that** my zones and effort score start from numbers I trust.

Depends on: nothing.

### Rules

1. Each rider has two heart-rate numbers, each **set** (by the rider or from a ride) or **estimated**:
   - **Maximum**: set value, else Tanaka from the birth year (208 − 0.7 × age, as today), else none.
   - **Threshold**: set value, else round(0.89 × the maximum in use), else none. (A Velomine choice: threshold heart rate sits around 85–92 % of maximum for most trained riders; 0.89 is the middle.)
2. A set value has a source: `manual` (typed) or `measured` (from a ride, Story 2). An estimate has the source `estimate` and is never stored.
3. Bounds: maximum 120–230 bpm, threshold 90–220 bpm, and a set threshold must be below the maximum in use (400 otherwise).

### Server

1. `User` gains `MaxHeartRateBpm int?` and `ThresholdHeartRateBpm int?` (the set values; null = estimated). Do **not** reuse `LegacyMaxHeartRate`, which stays unread until it is dropped.
2. New table `accounts.heart_rate_history`: `id uuid`, `user_id uuid not null` (cascade), `kind text not null` (`max`, `threshold`), `bpm integer not null` (80–230), `set_at timestamptz not null`, `source text not null` (`manual`, `measured`, `cleared`), `ride_id uuid null` (→ rides, `on delete set null`, only for `measured`). Index (`user_id`, `kind`, `set_at` desc). A row is written in the same `SaveChanges` as every change of a set value; `cleared` (with the old bpm) when the rider goes back to the estimate.
3. One helper, `HeartRates.For(user, time)` in `Features/Accounts/HeartRates.cs`, returns `(Max, MaxSource, Threshold, ThresholdSource)`. **Every** place that reads `User.EstimateMaxHeartRate` today (ride ingestion, `Intensity.cs`, the profile, zones) uses it instead; `User.MaxHeartRate` is removed or made to call it.
4. `PUT /api/v1/accounts/me/heart-rate/{kind}` (`max` or `threshold`), body `{ bpm }`, operation `setHeartRate`: sets it with source `manual`. `DELETE` on the same path, operation `clearHeartRate`: back to the estimate. Both return `ProfileResponse`.
5. `ProfileResponse` keeps `MaxHeartRate` (now the value in use) and gains `MaxHeartRateSource`, `MaxHeartRateSetAt`, `ThresholdHeartRate`, `ThresholdHeartRateSource`, `ThresholdHeartRateSetAt`.
6. Export: `heart-rate-history.json`. Deletion: rows go with the account.
7. `AGENTS.md`, *Ride processing → Zones*: say the maximum is the member's own (typed or measured) or the Tanaka estimate, and name the threshold estimate.

### App

1. Profile: two fields, "Maximum heart rate" and "Threshold heart rate", each empty-able ("Leave empty to estimate"), with a `SourceNote`: `manual` "Set by you on {date}" · `measured` "Measured on your ride of {date}" (tappable, opens the ride) · `estimate` (max) "Estimated from your age (208 − 0.7 × age)" · `estimate` (threshold) "Estimated as 89 % of your maximum".
2. Under the threshold field, one help line: "The highest heart rate you can hold for about an hour."

### Acceptance tests

- `HeartRates_ShouldEstimateMaxFromAge_WhenNothingIsSet` (born 1986, today 2026 → 208 − 28 = 180)
- `HeartRates_ShouldEstimateThresholdFromMax_WhenOnlyMaxIsKnown` (max 180 → 160; max 192 → 171)
- `HeartRates_ShouldUseTheSetValues_WhenTheRiderTypedThem`
- `SetHeartRate_ShouldWriteHistory_WhenTheValueChanges` and `…_ShouldNotWriteHistory_WhenTheValueIsTheSame`
- `SetHeartRate_ShouldRefuse_WhenTheThresholdIsNotBelowTheMax` (400)
- `ClearHeartRate_ShouldGoBackToTheEstimate_WhenCalled` (and writes a `cleared` row)
- `RideIngestion_ShouldUseTheTypedMax_WhenTheRiderSetOne` (zones of a new ride follow the typed max)
- Export and deletion tests.

---

## Story 2: Velomine learns my heart rate from my rides

**As a rider without a lab test**, I want Velomine to notice a higher maximum or threshold heart rate in my rides and use it, **so that** my numbers become my own without a test.

Depends on: Story 1.

### Rules (decided by the owner)

| Number | Current source | A ride shows a higher value → |
|---|---|---|
| Maximum | `estimate` or `measured` | **used automatically**, with a note |
| Maximum | `manual` | a **suggestion**: the rider decides |
| Threshold | `estimate` or `measured` | **used automatically**, with a note |
| Threshold | `manual` | a **suggestion** |

A lower value never replaces anything and never makes a suggestion.

### Detection

Runs **once per ride**, when it becomes `ready` for the first time (never on a re-read, never for a duplicate), from the ingestion path like `FtpSuggestionDetection`. Heart rate is first resampled to 1 Hz over moving time (the same resampling as Pack 1 Story 7), then smoothed with a **5-second rolling median** (this removes single-sample strap spikes).

1. **Maximum candidate** = the highest smoothed value, rounded. Valid only when:
   - it is between 120 and 220 bpm;
   - in the 10 seconds before it, the smoothed heart rate never rises by more than 10 bpm from one second to the next (a strap losing contact jumps; a heart does not);
   - the ride's local date is within the last 365 days (an imported ride from years ago says little about today).
2. **Threshold candidate** (Friel's 30-minute test, applied to any ride): the 30-minute window with the highest mean smoothed heart rate, with **no pause inside it** and heart rate present for at least 90 % of it; candidate = round(mean of the **last 20 minutes** of that window). Valid only when the ride is within the last 42 days and the candidate is below the maximum in use (after step 1 has run for this ride).
3. Replace when the candidate is **at least 1 bpm higher** than the value in use.

### Server

1. Automatic use: set `MaxHeartRateBpm` / `ThresholdHeartRateBpm`, write a `measured` history row with the ride id, and create a notification `heart_rate_measured` (training group, subject e.g. "Maximum 192 bpm") unless the ride is quiet.
2. Suggestion: new table `analytics.heart_rate_suggestions` with the shape of `ftp_suggestions` (`kind`, `bpm`, `ride_id`, `created_at`, `status` open/accepted/dismissed/replaced; one open row per user **and kind**). Notification `heart_rate_suggested`. Endpoints `GET /api/v1/analytics/heart-rate-suggestions` (open ones, possibly empty), `POST …/{id}/accept` (sets the value as `measured` with the ride, returns `ProfileResponse`), `POST …/{id}/dismiss`.
3. `RideResponse` gains `HeartRateNote` (`string?`, owner only): `max_measured`, `threshold_measured`, `max_suggested` or `threshold_suggested` when this ride caused one.
4. Export: `heart-rate-suggestions.json`. Deletion with the account and the ride.

### App

1. Ride detail, when `heartRateNote` is set: a small card. Measured: "New maximum heart rate: 192 bpm. Your zones now use it." Suggested: "This ride reached 192 bpm, above the 185 you set. Use 192?" [Use 192] [Keep 185].
2. Progress: open suggestions shown as the same card, like the FTP suggestion.

### Acceptance tests

- `MaxHeartRate_ShouldBeUsedAutomatically_WhenARideIsHigherThanTheEstimate` (estimate 180, ride peaks at 192 held 10 s → 192, `measured`)
- `MaxHeartRate_ShouldBeSuggested_WhenTheRiderTypedALowerOne` (typed 185, ride 192 → suggestion, value stays 185)
- `MaxHeartRate_ShouldIgnoreASpike_WhenTheStrapJumps` (140 bpm steady, one sample at 230 → no change)
- `MaxHeartRate_ShouldIgnoreAJump_WhenItRisesTooFastBeforeThePeak` (140 → 200 within 2 s and held → no change)
- `ThresholdHeartRate_ShouldBeTheLastTwentyMinutes_WhenAThirtyMinuteEffortIsFound` (30 min: first 10 at 150, last 20 at 165 → 165)
- `ThresholdHeartRate_ShouldNotBeLowered_WhenARideIsEasier` (threshold 165 measured, ride gives 158 → stays 165, no suggestion)
- `ThresholdHeartRate_ShouldSkipTheWindow_WhenItHasAPause`
- `HeartRateDetection_ShouldNotRun_WhenTheRideIsReadAgain` and `…_ShouldNotNotify_WhenTheRideIsQuiet`
- `AcceptHeartRateSuggestion_ShouldReturn404_WhenItBelongsToAnotherRider`
- Export and deletion tests.

---

## Story 3: heart-rate zones from the threshold

**As a rider**, I want my heart-rate zones built on my threshold when Velomine knows it, **so that** "easy" and "hard" fit my heart, not an average one.

Depends on: Stories 1–2.

### Rules

1. Two zone models, five zones each:
   - **From maximum** (today's): floor 50 %, upper bounds 60 / 70 / 80 / 90 % of the maximum.
   - **From threshold** (Friel, cycling, with his zones 5a–5c merged into one): floor 68 %, upper bounds 81 / 90 / 94 / 100 % of the threshold heart rate. (Friel's Z2 is 81–89 % and Z3 90–93 %, so as half-open bounds: Z1 < 81, Z2 81–89.x, Z3 90–93.x, Z4 94–99.x, Z5 ≥ 100.)
2. The model in use: **from threshold** when the threshold source is `manual` or `measured`; **from maximum** otherwise (an estimated threshold is only 0.89 × max, so it would add nothing).
3. Zone seconds stay computed on every request (as today); Pack 1's easy/moderate/hard split keeps mapping Z1–Z2 / Z3 / Z4–Z5. TRIMP stays as stored at read, on the maximum model (it is a separate, older score).

### Server

1. `TrainingLoad` gains the threshold model's floor and bounds; one function picks the model per rider. Every endpoint that returns heart-rate zones uses it and returns `HeartRateZoneModel` (`max` or `threshold`) with the zones.
2. `AGENTS.md`, *Ride processing → Zones*: name both models and the rule that picks one.

### App

1. Under the heart-rate zones of a ride and on Progress: `SourceNote` "Zones from your threshold heart rate (165 bpm)" or "Zones from your maximum heart rate (180 bpm, estimated)".

### Acceptance tests

- `HeartRateZones_ShouldUseTheThreshold_WhenItWasMeasured` (threshold 160 → Z2 from 130 to 143, Z5 from 160)
- `HeartRateZones_ShouldUseTheMax_WhenTheThresholdIsOnlyEstimated` (max 180 → Z2 from 108 to 125)
- `Intensity_ShouldCountTheThresholdZones_WhenTheModelIsThreshold`

---

## Story 4: zones I can adjust

**As a rider or a coach-guided rider**, I want to move my zone limits by hand and go back to automatic, **so that** zones from a lab test or a coach can be used.

Depends on: Story 3.

### Rules

1. Custom bounds are stored **as fractions of the reference**, so they move when the FTP or heart rate changes: one set for power (7 zones, 6 bounds, of FTP), one for heart rate **per model** (5 zones, 4 bounds, of max or of threshold). Null = automatic.
2. Valid: strictly rising, the first above the floor, each between 0.30 and 2.00, two decimals. 400 otherwise.
3. Custom bounds apply wherever zones are computed on read (ride zones, Progress, the easy/moderate/hard split). Values stored at read (TRIMP) keep the standard bounds.

### Server

1. `User` gains `PowerZoneBounds double precision[] null`, `HeartRateMaxZoneBounds double precision[] null`, `HeartRateThresholdZoneBounds double precision[] null`.
2. `PUT /api/v1/accounts/me/zones/{set}` (`power`, `heart-rate-max`, `heart-rate-threshold`), body `{ bounds: [..] }`, operation `setZones`; `DELETE` same path, `resetZones`. `GET /api/v1/accounts/me/zones`, operation `getZones`: for each set, the bounds in use, whether they are custom, and the absolute watts or bpm they give today.
3. Export: the bounds are part of the profile in the export.

### App

1. Profile → "Zones": the zones in use as a list (name, from–to in W or bpm). "Edit" opens a `FormSheet` where the rider edits the **upper limit of each zone in W or bpm** (the app converts to fractions); "Back to automatic" in the `PageMenu`.

### Acceptance tests

- `SetZones_ShouldMoveTheZones_WhenBoundsAreValid` (FTP 250, custom first bound 0.60 → Z1 up to 149 W)
- `SetZones_ShouldRefuse_WhenBoundsAreNotRising` (400)
- `Zones_ShouldFollowTheFtp_WhenCustomBoundsExist` (custom 0.60 and FTP from 250 to 300 → Z1 up to 179 W)
- `ResetZones_ShouldGoBackToAutomatic_WhenCalled`

---

## Story 5: heart-rate rides count in fitness and fatigue

**As a rider with a heart-rate strap and no power meter**, I want my rides to build my fitness and fatigue chart, **so that** Velomine (and later auto training) can see how fit and how tired I am.

Depends on: Story 1.

### Rules

1. New per-ride **heart-rate effort score** (hrTSS), computed at read, on the same scale as TSS (one hour at threshold = 100):
   hrTSS = Σ over consecutive samples (hr / threshold)² × dt / 3600 × 100
   - `hr` is the sample's heart rate, `dt` the time to the next sample;
   - an interval longer than 30 s is skipped (as in `ZoneSeconds`) and paused time is left out;
   - heart rate outside 40–230 bpm is skipped;
   - `threshold` is the threshold heart rate **in use at the ride's first read** (Story 1, including the estimate).
   Rounded to one decimal; null without heart rate or without a threshold.
2. A ride's **effort score** for fitness, fatigue, form and readiness is the first that exists: TSS (power) → hrTSS → estimated TSS (Story 6) → 0.
3. Coaches: the daily effort reaches a coach's training view under the same rule TSS follows today.

### Server

1. `Ride` gains `HrTss double?` and `LoadThresholdHeartRate int?` (stamped at first read next to `LoadMaxHeartRate`; on a re-read, kept; when null on a re-read, the threshold in use now is stamped). Raise `RideParserVersion.Current`.
2. `RideDays` / `TrainingRange`: each day gains `Load` (the sum of the rides' effort scores per rule 2); fitness and fatigue use `Load`. The existing `Tss` and `Trimp` fields stay as they are. `GetReadiness`'s recent load uses `Load`.
3. `RideResponse` gains `HrTss` and `EffortScore` + `EffortSource` (`power`, `heart_rate`, `estimated`).
4. `AGENTS.md`, *Data*: hrTSS is stored at read from the threshold of the ride's first read; fitness and fatigue use the effort score with the order of rule 2.

### App

1. Ride detail: "Effort score 64" with `SourceNote` "From your heart rate" / "From your power" / "From estimated watts".
2. Progress, fitness chart: when some rides in the range were scored from heart rate, a `SourceNote` "Includes rides scored from heart rate."
3. The empty state that says "Set your FTP… to see training load" now also accepts heart rate: "Set your FTP or wear a heart-rate strap…".

### Acceptance tests

- `HrTss_ShouldBe100_WhenOneHourAtThreshold` (3,600 s at 160 bpm, threshold 160 → 100.0)
- `HrTss_ShouldBe64_WhenOneHourAt80PercentOfThreshold` (128 bpm → 64.0)
- `HrTss_ShouldBe62Point5_WhenHalfAtThresholdAndHalfAtHalf` (1,800 s at 160 + 1,800 s at 80 → 62.5)
- `HrTss_ShouldSkipTheGap_WhenSamplesAreMoreThan30SecondsApart`
- `Training_ShouldCountHeartRateRides_WhenThereIsNoPower` (a heart-rate-only rider: fitness above 0 after a week of rides)
- `Training_ShouldPreferPower_WhenARideHasBoth` (effort = TSS, not hrTSS)
- `Readiness_ShouldUseTheEffortScore_WhenTheRiderHasNoPowerMeter`
- `RideReparse_ShouldKeepTheFirstThreshold_WhenTheRiderChangedIt`

---

## Story 6: estimated watts for rides without sensors

**As a rider with no power meter and no heart-rate strap**, I want Velomine to estimate my watts from speed, slope and weight, the way Strava does, **so that** my rides still count, clearly marked as estimates.

Depends on: Story 5.

### Rules

1. **When.** Computed at read only when the ride has **no power** at all, has speed, distance and altitude streams, is outdoors (`Environment` not `indoor` or `virtual`), is not an e-bike ride (`Assist` ≠ `ebike`: the motor's share is unknown), and the rider has a weight.
2. **Formula** (standard cycling power model, as in Martin et al. 1998), per sample at 1 Hz:
   P = [ m·g·(Crr·cos θ + sin θ) + ½·ρ·CdA·v² + m·a ] · v / η
   - m = rider weight + bike weight; g = 9.81 m/s²; η = 0.976 (drivetrain);
   - v = speed after the existing 5-sample median; a = its change per second, limited to ±1.5 m/s²;
   - θ = atan(grade), grade = altitude change / distance over a 10-second window centred on the sample, limited to ±25 %, 0 when the window covers under 5 m; altitude first smoothed as the elevation-gain pipeline does;
   - ρ = 1.225 × exp(−altitude / 8434) kg/m³;
   - Crr and CdA by bike kind (Velomine's defaults, no wind):

     | Kind | Crr | CdA (m²) | Default bike weight (kg) |
     |---|---|---|---|
     | road | 0.004 | 0.32 | 8.5 |
     | timetrial, track | 0.004 | 0.25 | 9 |
     | gravel | 0.008 | 0.36 | 9.5 |
     | mountain | 0.012 | 0.45 | 13 |
     | city | 0.008 | 0.55 | 15 |
     | other, no bike | 0.006 | 0.40 | 11 |
   - P below 0 (coasting, braking, descending) is 0; stopped (speed < 0.5 m/s) is 0; capped at 2,000 W.
3. **Estimated watts never feed** power bests, the power curve, FTP estimates or suggestions, records, critical power, W′ balance, decoupling, efficiency or power zones. They are only shown, and used for the estimated TSS.
4. **Estimated TSS** = the usual TSS formula with the estimated NP and the FTP at first read. **Without an FTP there is no estimated TSS**; the ride still counts in hours, distance and climbing.

### Server

1. `Bike` gains `WeightKg double?` (3–40, one decimal), editable with the bike; null uses the table's default for its kind.
2. `RideStreams` gains `EstimatedPower short?[]?`, aligned with the other signals. `Ride` gains `EstimatedAvgPowerW`, `EstimatedNormalizedPowerW` (the usual NP algorithm on the estimated stream) and `EstimatedTss`. Raise `RideParserVersion.Current`. A re-read uses the rider's and bike's weights at that time.
3. Privacy: estimated watts and their stream are hidden from anyone but the owner when the ride hides power, speed **or** elevation (`PrivacyRules.ForViewer`).
4. `AGENTS.md`, *Ride processing*: a bullet for estimated power with rule 1 and rule 3.

### App

1. Ride detail: "Estimated average power 142 W" and an "Estimated watts" chart, always with the word **estimated** and a `SourceNote` "From your speed, the slope and your weight with the bike. No wind, so it can be far off on the flat."
2. Bike form: optional "Weight (kg)" with helper "Used to estimate watts on rides without a power meter."
3. Profile: when the rider has no weight and has rides without power: "Add your weight to estimate watts on rides without a power meter."

### Acceptance tests (sea level unless said; m = 70 kg rider + 10 kg bike unless said)

- `EstimatedPower_ShouldBe186W_WhenClimbingFivePercentAt4MetresPerSecond` (road: 186.3 → 186)
- `EstimatedPower_ShouldBe143W_WhenRidingFlatAt30KmPerHour` (8.333 m/s → 143.0)
- `EstimatedPower_ShouldBe89W_WhenRidingGravelFlatAt6MetresPerSecond` (83 kg, gravel → 88.8 → 89)
- `EstimatedPower_ShouldBeZero_WhenDescending` (−6 %, 12 m/s → 0)
- `EstimatedPower_ShouldBeLower_WhenTheAirIsThinner` (the 5 % climb at 1,500 m → 184.2 → 184)
- `EstimatedPower_ShouldNotBeComputed_WhenTheRideHasPower` / `…_WhenItIsAnEbikeRide` / `…_WhenItIsIndoors` / `…_WhenTheRiderHasNoWeight`
- `EstimatedPower_ShouldNotChangeThePowerCurve_WhenARideHasOnlyEstimatedWatts`
- `EstimatedTss_ShouldBeNull_WhenTheRiderHasNoFtp`
- `CoachRide_ShouldHideEstimatedPower_WhenTheRideHidesSpeed`

---

## Story 7: races and events on my calendar

**As a rider**, I want to add the events I am training for, with their date, **so that** I see how far away they are (and Pack 3 can plan toward them).

Depends on: nothing.

### Rules

1. An event: name (1–100 characters), date (local), kind (`race`, `sportive`, `tour`, `other`), optional distance (km) and climbing (m), optional notes (≤ 500 characters).
2. After its date, an event can be linked to the ride that was it: automatically when the rider has **exactly one** ride on that local date, otherwise the rider picks one of that day's rides.

### Server

1. New table `training.events`: `id uuid`, `user_id uuid not null` (cascade), `name text not null`, `date date not null`, `kind text not null` (check), `distance_m double precision null`, `elevation_gain_m double precision null`, `notes text null`, `ride_id uuid null` (→ rides, `on delete set null`), `created_at timestamptz not null`. Index (`user_id`, `date`).
2. `GET /api/v1/training/events` (`listEvents`, upcoming first, then past, at most 100), `POST` (`addEvent`), `PUT /{id}` (`updateEvent`), `DELETE /{id}` (`deleteEvent`), `PUT /{id}/ride` with `{ rideId }` or null (`setEventRide`). 404 for another rider's event or ride.
3. Automatic link: when a ride becomes ready for the first time, link it to an unlinked event of the same local date if it is that date's only ride.
4. Export: `events.json`. Deletion with the account.

### App

1. Progress: a card "Next event: {name} in {n} days" (or "today"), with "All events" opening a list; add and edit in a `FormSheet`; delete in the `PageMenu` with `confirmDestructive`.
2. Ride detail: when linked, "Your event: {name}".

### Acceptance tests

- `AddEvent_ShouldBeListed_WhenValid` and `…_ShouldRefuse_WhenTheNameIsEmpty` (400)
- `Event_ShouldLinkTheRide_WhenItIsTheOnlyRideThatDay` and `…_ShouldNotLink_WhenThereAreTwoRides`
- `Events_ShouldNotBeVisible_WhenAnotherMemberAsks`
- Export and deletion tests.

---

## Story 8: "every day about as hard" and "a heavy week"

**As a rider**, I want to be told when my week has no easy days or is much heavier than usual, **so that** I rest before I get run down.

Depends on: Story 5 (it uses the effort score).

### Rules (Foster 1998; same as Domestique's `compute_monotony_strain` except where noted)

1. Over the **last 7 local days** including today, daily load = the sum of that day's effort scores (Story 5); a day without rides is 0.
2. **Monotony** = mean / sample standard deviation of the 7 loads, two decimals, capped at 7.0 (Domestique uses 7.0 only when the deviation is 0; capping also tames tiny deviations). None when the week's load is 0.
3. **Strain** = weekly load × monotony, one decimal.
4. "Every day about as hard": monotony ≥ 2.0 (Foster's warning level).
5. "A heavy week" (a Velomine rule): strain above 1.5 × the mean strain of the previous 8 seven-day blocks, counting only blocks with load; needs at least 4 such blocks.
6. On read, never stored.

### Server

1. `TrainingResponse` gains `Monotony`, `Strain`, `StrainUsual` (the mean of rule 5, or null), `Monotonous` and `HeavyWeek` (booleans). The coach's training view gets them under the same grant as the rest of the training range.

### App

1. Progress, training card: when either flag is true, an `InlineError`-styled note (not an error colour; a caution): "Every day was about as hard this week. An easy day helps you adapt." / "This week was much heavier than usual."
2. The numbers, under "Details": "Monotony 2.27 · Strain 817".

### Acceptance tests

- `Monotony_ShouldBe1Point07_WhenHardAndRestDaysAlternate` (100, 0, 100, 0, 100, 0, 100 → mean 57.14, SD 53.45, monotony 1.07, strain 428.0)
- `Monotony_ShouldWarn_WhenSixEqualDaysAndOneRest` (60 × 6, 0 → 2.27, strain 817.2, monotonous)
- `Monotony_ShouldBeCappedAt7_WhenEveryDayIsTheSame` (50 × 7 → 7.0, strain 2,450.0)
- `Monotony_ShouldBeNone_WhenTheWeekHasNoLoad`
- `Monotony_ShouldBe0Point94_WhenTheWeekIsVaried` (120, 30, 0, 90, 40, 0, 200 → 0.94, strain 451.2)
- `HeavyWeek_ShouldBeFlagged_WhenStrainIsAboveOneAndAHalfTimesUsual` and `…_ShouldNotBeFlagged_WhenThereAreFewerThanFourWeeks`

---

## Story 9: my rider card

**As a rider**, I want one card with all my numbers and where each came from, **so that** I know where I stand at a glance.

Depends on: Stories 1–8 and Pack 1.

### Content (each value with its `SourceNote`, a dash when unknown)

| Row | Value |
|---|---|
| FTP | W and W/kg (with weight) |
| Critical power, W′, peak power | Pack 1 Story 5 |
| Best 5 s, 1 min, 5 min, 20 min in the last 90 days | W, each tappable to its ride |
| Maximum and threshold heart rate | bpm, with source |
| Efficiency factor trend | the last 8 weeks, Pack 1 Story 7 |
| Last 90 days | rides, hours, distance, climbing |
| Fitness and form today | from the effort score |
| Next event | Story 7 |

### Server

1. `GET /api/v1/analytics/rider-card`, operation `getRiderCard`, owner only: one flat response with the rows above, all computed on read from what already exists. No new table.

### App

1. Top of Progress: the card, compact on a phone (FTP, W/kg, threshold HR, fitness, next event) with "More" opening the full card.

### Acceptance tests

- `RiderCard_ShouldShowEveryNumberWithItsSource_WhenTheRiderHasThem`
- `RiderCard_ShouldShowDashes_WhenTheRiderIsNew`
- `RiderCard_ShouldNotBeVisible_WhenAnotherMemberAsks`
- App: `RiderCard_ShouldOpenTheRide_WhenABestIsTapped`

---

## Closing the pack

When all nine are on `main`: update the status page (`site/`) and `README.md` with what riders without a power meter now get, give the demo seed a heart-rate-only rider and a rider with no sensors (with tests that the stored values equal the reader's, as Pack 1 did), and delete this file.
