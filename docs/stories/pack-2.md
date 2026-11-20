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
- "On read" means computed in the request and stored nothing. "At read" means when a ride is read from its file: store it on the ride and raise `RideParserVersion.Current` in the same change (except Story 5: its bump is in Story 6, see its server item 1).
- A decision not written here is not yours to invent. If something is truly ambiguous, stop and ask the owner.
- **Status (20 Nov 2026):** Stories 1, 2 and 7 are **built and on `main`** (with the gap fixes of `pack-2-gaps.md`, PR #20). Do not redo them; where their text below differs from the code, the code and the notes under their headings win. Story 3 is built; it is committed once the owner commits it. Stories 4, 5, 6, 8 and 9 are open, in that order; Stories 5 and 6 are pushed together. Decisions taken after this text was written are in *Decisions* at the end.
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

## Story 1: maximum and threshold heart rate, with where they came from (DONE)

**Built differently from this text:** the history index is (`user_id`, `kind`, `set_at` desc, `sequence` desc), the table has a `sequence` column. The profile save only sets; clearing goes through `DELETE /accounts/me/heart-rate/{kind}`. A typed maximum below a set threshold is **not** refused (only a threshold at or above the maximum is a 400; zones follow the maximum). An estimated field is empty with the estimate as its hint. The wording is "Estimated from your age"; a number measured on a deleted ride says "Measured on a ride you deleted".

**As a rider**, I want to set my maximum and threshold heart rate, or let Velomine estimate them, and always see where each came from, **so that** my zones and effort score start from numbers I trust.

Depends on: nothing.

### Rules

1. Each rider has two heart-rate numbers, each **set** (by the rider or from a ride) or **estimated**:
   - **Maximum**: set value, else Tanaka from the birth year (208 − 0.7 × age, as today), else none.
   - **Threshold**: set value, else round(0.89 × the maximum in use), else none. (A Velomine choice: threshold heart rate sits around 85–92 % of maximum for most trained riders; 0.89 is the middle.)
2. A set value has a source: `manual` (typed) or `measured` (from a ride, Story 2). An estimate has the source `estimate` and is never stored.
3. Bounds: maximum 120–230 bpm, threshold 90–220 bpm, and a set threshold must be below the maximum in use (400 otherwise).

### Server

1. `User` gains `MaxHeartRateBpm int?` and `ThresholdHeartRateBpm int?` (the set values; null = estimated), and with each a source (`MaxHeartRateSource`, `ThresholdHeartRateSource`: `manual` or `measured`, set exactly when its bpm is) and the ride that measured it (`MaxHeartRateRideId`, `ThresholdHeartRateRideId`, only when the source is `measured`, emptied when the ride is deleted). Do **not** reuse `LegacyMaxHeartRate`, which stays unread until it is dropped.
2. New table `accounts.heart_rate_history`: `id uuid`, `user_id uuid not null` (cascade), `kind text not null` (`max`, `threshold`), `bpm integer not null` (80–230), `set_at timestamptz not null`, `source text not null` (`manual`, `measured`, `cleared`), `ride_id uuid null` (→ rides, `on delete set null`, only for `measured`). Index (`user_id`, `kind`, `set_at` desc). A row is written in the same `SaveChanges` as every change of a set value; `cleared` (with the old bpm) when the rider goes back to the estimate.
3. One helper, `HeartRates.For(user, time)` in `Features/Accounts/HeartRates.cs`, returns `(HeartRate? Max, HeartRate? Threshold)`; each `HeartRate(Bpm, Source, RideId)` carries the truth read from those columns: `manual` or `measured` and the ride, or `estimate` for a number the rider never set. **Every** place that reads `User.EstimateMaxHeartRate` today (ride ingestion, `Intensity.cs`, the profile, zones) uses it instead; `User.MaxHeartRate` is removed or made to call it.
4. `PUT /api/v1/accounts/me/heart-rate/{kind}` (`max` or `threshold`), body `{ bpm }`, operation `setHeartRate`: sets it with source `manual`. `DELETE` on the same path, operation `clearHeartRate`: back to the estimate. Both return `ProfileResponse`.
5. `ProfileResponse` keeps `MaxHeartRate` (now the value in use) and gains `MaxHeartRateSource`, `MaxHeartRateSetAt`, `MaxHeartRateRideId`, `ThresholdHeartRate`, `ThresholdHeartRateSource`, `ThresholdHeartRateSetAt`, `ThresholdHeartRateRideId`.
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

## Story 2: Velomine learns my heart rate from my rides (DONE)

**Built differently from this text:** heart rate is a 1 Hz series by wall-clock second with zero-order hold, plus a paused flag per second (not "moving time, the Pack 1 Story 7 resampling"). A threshold window is exactly 1,800 s, stepped every 60 s, valid with no paused second and at least 1,620 values present; the candidate is the rounded mean of the last 1,200 s. A ride checks both numbers; the threshold is judged against the maximum this ride leaves in use. `RideResponse` carries `HeartRateNote` (the maximum's note, else the threshold's) plus `HeartRateMaxNote` and `HeartRateThresholdNote` (column `rides.rides.heart_rate_threshold_note`); all three are cleared for coaches and share viewers. A ride that changes both numbers sends two `heart_rate_measured` notifications. The new-maximum card drops "Your zones now use it" when the rider's zones come from the threshold.

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

1. Automatic use: set `MaxHeartRateBpm` / `ThresholdHeartRateBpm` with its source `measured` and the ride on the account, write a `measured` history row with the same ride id, and create a notification `heart_rate_measured` (training group, subject e.g. "Maximum 192 bpm") unless the ride is quiet.
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

## Story 3: heart-rate zones from the threshold (BUILT, waiting for the owner's commit)

**As a rider**, I want my heart-rate zones built on my threshold when Velomine knows it, **so that** "easy" and "hard" fit my heart, not an average one.

Depends on: Stories 1–2 and the gap stories 3–5b of `pack-2-gaps.md` (all built).

### Rules

1. Two zone models, five zones each:
   - **From maximum** (today's; the 0.50 floor now survives only in stored TRIMP, which `RideMetrics.Compute` still computes with `TrainingLoad.HeartRateFloor`: keep that constant, the zone chart and the split use no floor, see rule 4): floor 50 %, upper bounds 60 / 70 / 80 / 90 % of the maximum.
   - **From threshold** (Friel, cycling, with his zones 5a–5c merged into one): upper bounds 81 / 90 / 94 / 100 % of the threshold heart rate. **Neither model has a chart floor.** A beat below the first bound is Z1 from 0; the 0.50 floor survives only in stored TRIMP. (Friel's Z2 is 81–89 % and Z3 90–93 %, so as half-open bounds: Z1 < 81, Z2 81–89.x, Z3 90–93.x, Z4 94–99.x, Z5 ≥ 100.)
2. The model in use: **from threshold** when the threshold source is `manual` (typed) or `measured` (from a ride, whether used automatically or accepted as a suggestion); **from maximum** otherwise (an estimated threshold is only 0.89 × max, so it would add nothing). A typed maximum below a set threshold is allowed; the threshold model then ignores the maximum, and the top zone is simply reached earlier.
3. Zone seconds stay computed on every request (as today). The easy/moderate/hard split maps **per model**: maximum model Z1–Z3 / Z4 / Z5 (unchanged, as `Intensity.FromHeartRate` does today); threshold model Z1–Z2 / Z3 / Z4–Z5. TRIMP stays as stored at read, on the maximum model (it is a separate, older score).
4. **Below the first bound** counts as easy: Z1 with `From = 0` in the ride's zone chart and in the split (drop any "time below the floor is not training time"; neither model keeps a floor). TRIMP is unchanged.
5. **Who sees it:** coaches and share links see the same zones and `HeartRateZoneModel` as the rider, under the existing grants. This overrides rule 5 of this file for zones. The heart-rate privacy switch hides them.

### Server

1. `TrainingLoad` gains the threshold model's bounds; one function picks the model per rider. Every endpoint that returns heart-rate zones uses it and returns `HeartRateZoneModel` (`max` or `threshold`) with the zones. `IntensityResponse` gains the model and the reference bpm. Parser version: not raised (nothing stored changes; only valid while `RideMetrics` is not edited).
2. `AGENTS.md`, *Ride processing → Zones*: name both models and the rule that picks one.

### App

1. On the ride's heart-rate zones card and on the Progress intensity card (no new chart): `SourceNote` "Zones from your threshold heart rate (165 bpm)" or "Zones from your maximum heart rate (180 bpm)", with ", estimated" added only when the maximum's source is `estimate` (so `IntensityResponse` and the zones responses carry the reference's source). On Progress it shows only when heart-rate rides were counted. The neutral wording for a coach or share viewer is deferred to Pack 3b, because no coach screen shows zones yet. The server already returns the same zones and model to them.

### Acceptance tests

- `HeartRateZones_ShouldUseTheThreshold_WhenItWasMeasured` (threshold 160 → Z2 from 130 to 143, Z5 from 160)
- `HeartRateZones_ShouldUseTheMax_WhenTheThresholdIsOnlyEstimated` (max 180 → Z2 from 108 to 125)
- `Intensity_ShouldCountTheThresholdZones_WhenTheModelIsThreshold`
- `HeartRateZones_ShouldUseTheThreshold_WhenItWasTyped` and `…_WhenASuggestionWasAccepted`
- `HeartRateZones_ShouldUseTheThresholdModel_WhenACoachViewsTheRide`
- `HeartRateZones_ShouldCountBelowTheFloorAsEasy_WhenTheRideIsEasy`
- `HeartRateZones_ShouldFollowTheThreshold_WhenTheTypedMaximumIsBelowIt`

---

## Story 4: zones I can adjust

**As a rider or a coach-guided rider**, I want to move my zone limits by hand and go back to automatic, **so that** zones from a lab test or a coach can be used.

Depends on: Story 3.

### Rules

1. Custom bounds are stored **as fractions of the reference**, so they move when the FTP or heart rate changes: one set for power (7 zones, 6 bounds, of FTP), one for heart rate **per model** (5 zones, 4 bounds, of max or of threshold). Null = automatic.
2. Valid: strictly rising, each between 0.30 and 2.00, two decimals. 400 otherwise. There is no floor check: below the first bound is Z1 (see Story 3, rule 4).
2b. Coaches and share links see the same zones as the rider (the bounds are fractions, not member values), under the existing grants and the privacy switches.
3. Custom bounds apply wherever zones are computed on read (ride zones, Progress, the easy/moderate/hard split). Values stored at read (TRIMP) keep the standard bounds. Dev greps every use of `TrainingLoad.PowerBounds` and `HeartRateBounds` first; `RideMetrics` keeps the standard bounds.
3b. **Parser version: not raised in Story 4.** It adds only columns read on request; `RideMetrics` and every stored value are untouched (stored TRIMP keeps the standard bounds). If dev finds it must edit `RideMetrics`, stop and ask.
4. Precision: two-decimal fractions can move a typed watt or bpm value by one (a typed 155 W on FTP 250 comes back as 154 W). After saving, the sheet shows the values in use.

### Server

1. `User` gains `PowerZoneBounds double precision[] null`, `HeartRateMaxZoneBounds double precision[] null`, `HeartRateThresholdZoneBounds double precision[] null` (columns `power_zone_bounds`, `heart_rate_max_zone_bounds`, `heart_rate_threshold_zone_bounds`), with check constraints `cardinality = 6` for power and `= 4` for each heart-rate column. "Strictly rising" is checked by the validator only (the one writer).
2. `PUT /api/v1/accounts/me/zones/{set}` (`power`, `heart-rate-max`, `heart-rate-threshold`), body `{ bounds: [..] }`, operation `setZones`; `DELETE` same path, `resetZones`. `GET /api/v1/accounts/me/zones`, operation `getZones`: for each set, the bounds in use, whether they are custom, and the absolute watts or bpm they give today. Flat response: `ZonesResponse(ZoneSetResponse[] Sets, string? HeartRateModel)` with `ZoneSetResponse(string Set, double[] Bounds, bool Custom, int? Reference, string? ReferenceSource, ZoneTime[] Zones)`. An unknown set answers 404. Dev checks whether the FTP and heart-rate setters are in `DemoLock.Refused` and treats the zone endpoints the same way.
3. Export: the bounds are part of the profile in the export (with a test).

### App

1. Profile → "Zones": the zones in use as a list (name, from–to in W or bpm). "Edit" opens a `FormSheet` where the rider edits the **upper limit of each zone in W or bpm** (the app converts to fractions); "Back to automatic" in the `PageMenu`. The list shows power and only the heart-rate set in use; the server accepts all three sets, so a bound saved for the other model applies when the rider's model changes.

### Acceptance tests

- `SetZones_ShouldRefuse_WhenABoundHasThreeDecimals`, `…_WhenBoundsAreOutOfRange`, `…_WhenTheCountIsWrong`, and `SetZones_ShouldReturn404_WhenTheSetIsUnknown`
- `RideZones_ShouldUseCustomBounds_WhenTheRiderSetThem` and `Intensity_ShouldUseCustomBounds_WhenTheRiderSetThem`
- `RideTrimp_ShouldKeepTheStandardBounds_WhenCustomBoundsExist`
- `HeartRateZones_ShouldUseCustomThresholdBounds_WhenACoachViewsTheRide`
- An export test, and an app test under the Italian locale for the sheet. No second-club test: the data is the member's own, not club data.
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
2. New **feel score**, from the rider's own 1–10 rating of the ride (`RideFeel.Rpe`, Foster's session RPE put on the TSS scale; a Velomine choice: an hour that feels 7/10 is an hour at threshold):
   feel score = moving minutes / 60 × (RPE / 7)² × 100, one decimal.
   Computed **on read** (the rating can be given or changed after the ride is read), never stored.
3. A ride's **effort score** for fitness, fatigue, form and readiness is the first that exists: TSS (power) → hrTSS → feel score → estimated TSS (Story 6) → 0.
4. Coaches: the daily effort reaches a coach's training view under the same rule TSS follows today, except the feel score: the rating is wellbeing data, so a coach's view uses it only with the wellbeing grant and otherwise falls through to the next score. `TrainingRange.LoadAsync` takes only a `PrivacyProfile?` viewer today, so the story must pass it whether the wellbeing grant exists. **The coach's daily load follows the same rule TSS follows today: hrTSS counts like TSS, and the hide switches do not redact the daily total (owner, 20 Nov).** Only the feel score needs the wellbeing grant. The coach role alone gives nothing: the daily load reaches a coach only through an active grant for that club and audience, as the training range does today.

### Server

1. `Ride` gains `HrTss double?` and `LoadThresholdHeartRate int?` (stamped at first read next to `LoadMaxHeartRate`; on a re-read, kept; when null on a re-read, the threshold in use now is stamped). `RideParserVersion.StampRead(ftpW, maxHeartRate)` becomes `StampRead(ftpW, maxHeartRate, thresholdHeartRate)`. **Do not raise `RideParserVersion.Current` here**: the one bump is in Story 6's commit (Q15), so push Stories 5 and 6 together; until then older rides have no hrTSS.
2. `RideDays` / `TrainingRange`: each day gains `Load` (the sum of the rides' effort scores per rule 3); fitness and fatigue use `Load`. The existing `Tss` and `Trimp` fields stay as they are. `GetReadiness`'s recent load uses `Load`. So does the coach roster (`CoachQueries.SummariesAsync`, which reads only `Tss` today; without this a coach would see zero for a heart-rate rider). `TrainingRange.LoadAsync` gains `includeFeel`: true for the owner, and for a coach only with the wellbeing grant.
3. `RideResponse` gains `HrTss` and `EffortScore` + `EffortSource` (`power`, `heart_rate`, `feel`, `estimated`), set in `GetRide` for the owner only; `WithoutTrainingLoad` and `ForViewer` clear them. Dev checks the ride export carries `HrTss` and `LoadThresholdHeartRate`.
4. `AGENTS.md`, *Data*: hrTSS is stored at read from the threshold of the ride's first read; the feel score is computed on read; fitness and fatigue use the effort score with the order of rule 3.

### App

1. Ride detail: "Effort score 64" with `SourceNote` "From your heart rate" / "From your power" / "From how hard it felt" / "From estimated watts".
2. Progress, fitness chart: when some rides in the range were scored from heart rate, a `SourceNote` "Includes rides scored from heart rate."
3. The empty state that says "Set your FTP… to see training load" now also accepts heart rate: "Set your FTP or wear a heart-rate strap…".

### Acceptance tests

- `HrTss_ShouldBe100_WhenOneHourAtThreshold` (3,600 s at 160 bpm, threshold 160 → 100.0)
- `HrTss_ShouldBe64_WhenOneHourAt80PercentOfThreshold` (128 bpm → 64.0)
- `HrTss_ShouldBe62Point5_WhenHalfAtThresholdAndHalfAtHalf` (1,800 s at 160 + 1,800 s at 80 → 62.5)
- `HrTss_ShouldSkipTheGap_WhenSamplesAreMoreThan30SecondsApart`
- `FeelScore_ShouldBe100_WhenAnHourFeltSeven` (60 min, RPE 7 → 100.0)
- `FeelScore_ShouldBe49_WhenNinetyMinutesFeltFour` (90 min, RPE 4 → 49.0)
- `FeelScore_ShouldBe102_WhenHalfAnHourFeltTen` (30 min, RPE 10 → 102.0)
- `Training_ShouldUseTheFeelScore_WhenARideHasNoPowerAndNoHeartRate` and `…_ShouldPreferHeartRate_WhenARideHasBoth`
- `CoachTraining_ShouldSkipTheFeelScore_WhenThereIsNoWellbeingGrant`
- `Training_ShouldCountHeartRateRides_WhenThereIsNoPower` (a heart-rate-only rider: fitness above 0 after a week of rides)
- `Training_ShouldPreferPower_WhenARideHasBoth` (effort = TSS, not hrTSS)
- `Readiness_ShouldUseTheEffortScore_WhenTheRiderHasNoPowerMeter`
- `RideReparse_ShouldKeepTheFirstThreshold_WhenTheRiderChangedIt`
- `RideReparse_ShouldStampTheCurrentThreshold_WhenTheRideHadNone` (sets `ParserVersion` below `Current` by hand, since the bump comes in Story 6)
- `CoachTraining_ShouldCountFeel_WhenTheWellbeingGrantExists`
- `CoachRoster_ShouldUseTheEffortScore_WhenTheAthleteHasNoPower`, with a club-isolation test: a rider in another club never appears
- `RideResponse_ShouldNotCarryTheEffortScore_WhenAViewerReadsIt`
- `CoachTraining_ShouldCountAHiddenRidesLoad_WhenThePowerSwitchIsOff` (the owner's rule) and `…_ShouldNotCountItsFeel_WhenThereIsNoWellbeingGrant`
- `ClubData_ShouldNotBeVisible_WhenRequestComesFromAnotherClub` for the coach training view with heart-rate-only riders

---

## Story 6: estimated watts for rides without sensors

**As a rider with no power meter and no heart-rate strap**, I want Velomine to estimate my watts from speed, slope and weight, the way Strava does, **so that** my rides still count, clearly marked as estimates.

Depends on: Story 5.

### Rules

0. **Names checked against the code (20 Nov):** bike kinds are `road`, `gravel`, `mountain`, `ebike`, `timetrial`, `track`, `city`, `other` (`Bike.cs`); `Environment` is `outdoor`, `indoor`, `virtual` or null; `Assist` is `none`, `ebike` or null; rider weight is `User.WeightKg` (kg, 20–300). `Bike.WeightKg` does not exist yet. There is no smoothed speed series (the 5-sample median only finds the maximum speed) and the elevation-gain smoothing is private, so this story writes a new speed median and extracts the altitude smoothing into a shared function that keeps alignment with time (`ElevationChange` calls it, so gain and loss do not change). Samples are the file's own times, not a 1 Hz grid: put speed and altitude on a 1 Hz wall-clock grid with a held value, as Story 2 does for heart rate; a paused second is 0 W.
1. **When.** Computed at read only when the ride has **no power** at all, has speed (the stored speed stream, **or speed built from the positions** the way `SpeedSeries` does, at read, not stored), has altitude, is outdoors (`Environment` is `outdoor` **or null**; not `indoor` or `virtual`), is not an e-bike ride (`Assist` is not `ebike`, null counts as not assisted; and the bike's kind is not `ebike`: the motor's share is unknown), and the rider has a weight. The distance stream is not required (positions give it).
   **Which row:** with a bike, its kind picks the Crr, CdA and default weight; with no bike, the ride's own discipline does; the "other" row applies only when that is also unknown.
2. **Formula** (standard cycling power model, as in Martin et al. 1998), per sample at 1 Hz:
   P = [ m·g·(Crr·cos θ + sin θ) + ½·ρ·CdA·v² + m·a ] · v / η
   - m = rider weight + bike weight; g = 9.81 m/s²; η = 0.976 (drivetrain);
   - v = speed after a new 5-sample median pass; a = its change per second, limited to ±1.5 m/s²;
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
     | other, or unknown kind and discipline | 0.006 | 0.40 | 11 |
   - P below 0 (coasting, braking, descending) is 0; stopped (speed < 0.5 m/s) is 0; capped at 2,000 W.
3. **Estimated watts never feed** power bests, the power curve, FTP estimates or suggestions, records, critical power, W′ balance, decoupling, efficiency or power zones. They are only shown, and used for the estimated TSS.
4. **Estimated TSS** = the usual TSS formula with the estimated NP and the FTP at first read. **Without an FTP**, a stand-in FTP of round(2.5 W/kg × the rider's weight at read) is used (a Velomine choice: a typical value for a recreational rider). The stand-in is never stored as the rider's FTP and never shown as one. It only matters when the ride has no power, no heart rate and no 1–10 rating (Story 5, rule 3).

### Server

1. `Bike` gains `WeightKg double?` (3–40, one decimal), editable with the bike; null uses the table's default for its kind.
2. `RideStreams` gains `EstimatedPower short?[]?`, aligned with the other signals. `Ride` gains `EstimatedAvgPowerW`, `EstimatedNormalizedPowerW` (the usual NP algorithm on the estimated stream) and `EstimatedTss`. Raise `RideParserVersion.Current` **once, here**, for this story and Story 5's new stored fields. A re-read uses the rider's and bike's weights at that time.
3. Privacy: estimated power is **owner only** and is not on the coach streams endpoint. The estimated summary fields are hidden from anyone but the owner when the ride hides power, speed **or** elevation (`PrivacyRules.ForViewer`).
3b. The parser bump to `RideParserVersion.Current = 5` is in this commit only. The commit message says that old rides get the threshold in use on the day of the re-read.
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
- `EstimatedPower_ShouldNotBeComputed_WhenTheBikeIsAnEbike`, `EstimatedPower_ShouldBeComputed_WhenSpeedComesFromPositions` and `EstimatedPower_ShouldBeComputed_WhenEnvironmentIsUnknown`
- `EstimatedPower_ShouldNotBeComputed_WhenTheRideHasPower` / `…_WhenItIsAnEbikeRide` / `…_WhenItIsIndoors` / `…_WhenTheRiderHasNoWeight`
- `EstimatedPower_ShouldNotChangeThePowerCurve_WhenARideHasOnlyEstimatedWatts`
- `EstimatedTss_ShouldUseTwoAndAHalfWattsPerKilo_WhenTheRiderHasNoFtp` (70 kg → stand-in 175 W; the rider's FTP stays null)
- `CoachRide_ShouldHideEstimatedPower_WhenTheRideHidesSpeed`
- `RideReparse_ShouldEstimateWatts_WhenTheParserVersionRises`
- `EstimatedPower_ShouldUseTheBikeWeight_WhenTheBikeHasOne`
- `CoachStreams_ShouldNotCarryEstimatedPower_WhenACoachReadsTheRide`

---

## Story 7: races and events on my calendar (DONE)

**As a rider**, I want to add the events I am training for, with their date, **so that** I see how far away they are (and Pack 3 can plan toward them).

Depends on: nothing.

### Rules

1. An event: name (1–100 characters), date (local), kind (`race`, `sportive`, `tour`, `other`), optional distance (km) and climbing (m), optional notes (≤ 500 characters).
2. After its date, an event can be linked to the ride that was it: automatically when the rider has **exactly one** ride on that local date and it is the only unlinked event of that date, otherwise the rider picks one of that day's rides. Only a ride on the event's own local date can be linked, and a moved date drops a link that no longer fits.

### Server

1. New table `training.events`: `id uuid`, `user_id uuid not null` (cascade), `name text not null`, `date date not null`, `kind text not null` (check), `distance_m double precision null`, `elevation_gain_m double precision null`, `notes text null`, `ride_id uuid null` (→ rides, `on delete set null`), `created_at timestamptz not null`. Index (`user_id`, `date`).
2. `GET /api/v1/training/events` (`listEvents`, upcoming first, then past, at most 100), `POST` (`addEvent`), `PUT /{id}` (`updateEvent`), `DELETE /{id}` (`deleteEvent`), `PUT /{id}/ride` with `{ rideId }` or null (`setEventRide`). 404 for another rider's event or ride; 400 when the ride is not on the event's local date.
3. Automatic link: when a ride becomes ready for the first time, link it to an unlinked event of the same local date if it is that date's only ride **and it is the only unlinked event of that date**. Adding an event or moving it to another date does the same from the event's side: exactly one ready ride of the member on that date, not already another event's ride. A moved date drops a link to a ride that is not on the new date first; changing only the name never re-links an event the rider unlinked. Manual linking may still pick a ride another event uses.
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

1. Over the **last 7 local days ending today, or ending yesterday when the member has no ready ride on today's local date** (owner, 20 Nov: otherwise a rider who trains six days a week shows a warning every morning before the ride). Today is the member's local date (`MemberClock`). Daily load = the sum of that day's effort scores (Story 5); a day without rides is 0.
2. **Monotony** = mean / sample standard deviation of the 7 loads, two decimals, capped at 7.0 (Domestique uses 7.0 only when the deviation is 0; capping also tames tiny deviations). None when the week's load is 0.
3. **Strain** = weekly load × the monotony rounded to two decimals, one decimal. (Only this reproduces the test values: 400 × 1.07 = 428.0, 360 × 2.27 = 817.2, 480 × 0.94 = 451.2.) A standard deviation of 0 with load above 0 gives 7.0; weekly load 0 gives none; use the sample standard deviation (n − 1); never divide by zero.
4. "Every day about as hard": monotony ≥ 2.0 (Foster's warning level).
5. "A heavy week" (a Velomine rule): strain above 1.5 × the mean strain of the previous 8 seven-day blocks, counting only blocks with load; needs at least 4 such blocks. The previous 8 blocks end the day before the window starts, so they shift with the window: `MonotonyFrom`/`MonotonyTo`, the monotony, the strain and the 8 blocks all use the same window.
6. On read, never stored.

### Server

1. `TrainingResponse` gains `Monotony`, `Strain`, `StrainUsual` (the mean of rule 5, or null), `Monotonous` and `HeavyWeek` (booleans), plus `MonotonyFrom` and `MonotonyTo` (the window's dates). All fields are null and false under a ride filter. The range loads at least 63 days (the week plus 8 blocks), more than the 42-day warm-up gives when `days` is under 22. The coach's training view gets them under the same grant as the rest of the training range. The calculation is a pure `TrainingStrain` function in `Features/Analytics/`.

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
- `Monotony_ShouldNeverBeInfinite_WhenEveryDayIsEqual`
- `Monotony_ShouldEndYesterday_WhenThereIsNoRideToday` and `…_ShouldEndToday_WhenARideIsReady`
- `Monotony_ShouldEndYesterday_WhenTodaysOnlyRideIsStillProcessing`
- `Monotony_ShouldUseTheMembersLocalDate_WhenTheirTimeZoneIsAheadOfUtc` (a ride just after local midnight)
- `Training_ShouldHaveNoMonotony_WhenAFilterIsSet`
- `HeavyWeek_ShouldNeedSixtyThreeDays_WhenTheRangeIsShort` (a 7-day range still sees the 8 blocks)
- `CoachTraining_ShouldCarryMonotony_WhenTheAnalyticsGrantExists`

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

1. `GET /api/v1/analytics/rider-card`, operation `getRiderCard`, no parameters, owner only: one flat response with the rows above, all computed on read from what already exists. No new table. It reuses `ProfileOfAsync` (FTP, weight, heart-rate sources), `FitnessQueries.CriticalPowerAsync`, the power bests of the personal-records slice (5 s, 1, 5, 20 min with their ride ids), `Efficiency.LoadAsync` (8 weeks), the 90-day totals from `RideDays`, `TrainingRange.LoadAsync(days: 1)` for fitness and form, and the next event. Estimated watts feed no row. If "peak power" does not exist from Pack 1 Story 5, its row shows a dash and the PO is told.

### App

1. Top of Progress: the card, compact on a phone (FTP, W/kg, threshold HR, fitness, next event) with "More" opening the full card.

### Acceptance tests

- `RiderCard_ShouldShowEveryNumberWithItsSource_WhenTheRiderHasThem`
- `RiderCard_ShouldShowDashes_WhenTheRiderIsNew`
- `RiderCard_ShouldNotBeVisible_WhenAnotherMemberAsks`
- `RiderCard_ShouldNotUseEstimatedWatts_WhenARideHasOnlyEstimatedPower`
- `RiderCard_ShouldShowMyNumbersOnly_WhenAnotherMemberAsks` (the real isolation test)
- App: `RiderCard_ShouldOpenTheRide_WhenABestIsTapped`

---

## Decisions

- 2026-11-20: Story 4 has no floor check on custom bounds (valid = strictly rising, each 0.30–2.00, two decimals); coaches and share links see custom zones like the rider's, under the existing grants.
- 2026-11-20: A typed maximum below a set threshold is not refused; the threshold model ignores the maximum (one test in Story 3).
- 2026-11-20: The parser-version bump is in Story 6's commit only; Stories 5 and 6 are pushed together.
- 2026-11-20: Story 6 builds speed from the positions at read when the ride has no stored speed, without storing it.
- 2026-11-20: Story 6 treats a null `Environment` as outdoor and a null `Assist` as not assisted; a bike of kind `ebike` blocks the estimate.
- 2026-11-20: Story 6 picks the Crr/CdA row from the bike's kind, else from the ride's discipline, else "other".
- 2026-11-20: The coach zone-note wording ("not your") is deferred to Pack 3b; the server already returns the zones and model to coaches.
- 2026-11-20: `ThresholdHeartRateFloor` is deleted; neither zone model has a chart floor.
- 2026-11-20: The coach's daily load is not redacted by the hide switches (hrTSS follows the rule TSS follows today); the feel score needs the wellbeing grant.
- 2026-11-20: Story 8's window ends yesterday when the member has no ready ride on today's local date.
- 2026-11-20: Story 8's strain uses the monotony rounded to two decimals.
- 2026-11-20: Story 8's fields are empty under a ride filter.

## Closing the pack

When all nine are on `main`: update the status page (`site/`) and `README.md` with what riders without a power meter now get, give the demo seed a heart-rate-only rider and a rider with no sensors (with tests that the stored values equal the reader's, as Pack 1 did), and delete this file.
