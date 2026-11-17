# Pack 1: power and endurance analysis

Nine user stories that deepen what Velomine already measures: FTP, the power curve, zones and training load. No new data is collected from the rider; everything is computed from rides and the profile Velomine already has.

Prior art: [Domestique](https://github.com/platypus45/domestique) (Apache-2.0) implements similar features. Build every formula **from the cited paper and the definitions in this file**, never by translating Domestique's code, and credit it as inspiration in the commit message.

## How to work through this file

- Do the stories **in order**. Each lists what it depends on.
- One story is one commit on `main` (or a few, if it is large). Never push; the owner pushes.
- Before each commit: `just check` passes, and the commit message ends with the attribution line from the session.
- When a story says "on read", compute it in the request and store nothing. When it says "at read" (when a ride is read from its file), store it on the ride and raise `RideParserVersion.Current` in the same change.
- A decision not written here is not yours to invent. If something is truly ambiguous, stop and ask the owner.

## Rules that apply to every story

These come from `AGENTS.md`; they are repeated so nothing is missed.

1. **Slices.** Server code lives in `src/Velomine.Server/Features/<Area>/`, one file per use case, FastEndpoints, `VelomineDbContext` used directly. Analytics go in `Features/Analytics/`, FTP history in `Features/Accounts/`.
2. **API.** Every endpoint declares what it accepts and returns with `Description(...)`; DTOs stay flat. Adding fields to an existing response is allowed; never remove or rename one. After any endpoint change run `tools/generate-api-client.sh` and commit the regenerated client. Never edit `app/packages/velomine_api/` by hand.
3. **Data.** New tables live in the area's schema, use `uuid` keys, `timestamptz` instants, snake_case names and database constraints. Add a migration with `just migration Name` and read its SQL. Migrations are additive.
4. **Member data.** Any new table that holds a member's data is added to `AccountExport` (`Features/Accounts/AccountExport.cs`) and to `AccountDeletion` (`Features/Accounts/AccountDeletion.cs`) in the same change, with a test for each.
5. **Coaches and privacy.** A coach sees a member's numbers only with a grant (`SharingRules.CanViewAsync` and `DataTypes`), and every per-ride value derived from power or heart rate is hidden when the ride's effective privacy hides that signal (`PrivacyRules.ForViewer` in `Features/Privacy/Privacy.cs`). Each story says exactly which grant and which signal apply. A coach view is recorded in the sharing view log as it is today; reuse the existing `ViewKinds`.
6. **App.** Riverpod + MVVM, data through the feature's `*_data.dart`, `Result<T>` from data sources, shared widgets from `lib/core/widgets/`. Every new string goes in **both** `app/lib/l10n/app_en.arb` and `app_it.arb`; run `just codegen` after changing a `@riverpod` provider.
7. **Tests.** Names follow `Subject_ShouldDoSomething_WhenCondition`. Server tests use the real PostgreSQL fixture. **Every formula has a test against known values written in the story.** Every coach-visible value has a test proving another club cannot see it and a test proving the privacy switch hides it.
8. **Logging.** Never log watts, heart rate, FTP or any member value.
9. **Words.** Plain language in the UI, English and Italian. Units: watts as `W`, energy as `kJ` with one decimal, percentages with one decimal unless the story says otherwise.

---

## Story 1: FTP history and where the FTP came from

**As a rider**, I want Velomine to remember every FTP I have had, when it was set and how, **so that** I can trust the number my zones and TSS come from.

Depends on: nothing.

### Server

1. New table `accounts.ftp_history`:
   - `id uuid` primary key
   - `user_id uuid not null` → users, cascade on delete
   - `watts integer not null`, check 30 ≤ watts ≤ 1000
   - `set_at timestamptz not null`
   - `source text not null`, check in (`manual`, `estimate`, `test`, `earlier`)
   - `ride_id uuid null` → rides, `on delete set null` (only for `test`)
   - index on (`user_id`, `set_at` desc)
2. Meaning of `source`:
   - `manual`: the rider typed it (profile form or `PUT /accounts/me/ftp` without a source).
   - `estimate`: the rider adopted the power-curve estimate.
   - `test`: the rider accepted a suggestion from a ride (Story 4); `ride_id` is that ride.
   - `earlier`: set before Velomine kept history (migration backfill only).
3. Migration backfill: one row per user whose `FtpW` is not null, `source = 'earlier'`, `set_at` = the migration's time, `ride_id` null.
4. Every change of `User.FtpW` writes a row **in the same `SaveChanges`**, and only when the value actually changes (saving the same number writes nothing). This applies to:
   - `PUT /accounts/me/ftp` (`Features/Accounts/SetFtp.cs`)
   - the profile update (`Features/Accounts/UpdateProfile.cs`) when `FtpW` changes
   - Story 4's accept action.
5. `SetFtpRequest` gains one optional field, `Source`: `manual` or `estimate`, default `manual`; any other value is 400. Story 4 adds its own endpoint for `test`.
6. `ProfileResponse` (`Features/Accounts/GetProfile.cs`) gains `FtpSetAt` (`DateTimeOffset?`) and `FtpSource` (`string?`), from the newest history row; both null when the rider has no FTP.
7. New endpoint `GET /api/v1/accounts/me/ftp-history`, operation `getFtpHistory`, owner only: `{ entries: [{ watts, setAt, source, rideId }] }` newest first, at most 100.
8. Export: `ftp-history.json` in the export ZIP. Deletion: rows go with the account.
9. Coaches: not visible to coaches in Pack 1.

### App

1. Profile screen: under the FTP field, a line saying where it came from, using Story 2's `SourceNote`.
2. Progress, power card (`app/lib/features/progress/power_summary.dart`): adopting the estimate calls `setFtp` with `source: estimate`.
3. A small "FTP history" sheet opened from the power card's menu or a text button "History": a list of date, watts and source in words ("You typed it", "From the estimate", "From your ride on 12 Nov", "Before history was kept"). Empty state when there is one entry or none.

### Acceptance tests

- `SetFtp_ShouldWriteHistory_WhenTheValueChanges`
- `SetFtp_ShouldNotWriteHistory_WhenTheValueIsTheSame`
- `SetFtp_ShouldRecordEstimate_WhenTheSourceIsEstimate`
- `SetFtp_ShouldRefuse_WhenTheSourceIsTest` (400)
- `UpdateProfile_ShouldWriteHistory_WhenFtpChanges`
- `Profile_ShouldSayWhenAndHowFtpWasSet_WhenItHasHistory`
- `AccountExport_ShouldContainFtpHistory_WhenTheMemberHasIt`
- `AccountDeletion_ShouldRemoveFtpHistory_WhenTheAccountIsDeleted`
- Migration test: a user with `FtpW = 250` gets one `earlier` row.

---

## Story 2: every number says where it came from

**As a rider**, I want each computed number to say whether it was measured, estimated or set by me, and when, **so that** I never mistake a guess for a test.

Depends on: Story 1.

### App

1. New shared widget `lib/core/widgets/source_note.dart`: `SourceNote(text)`, one line of small muted text with an info icon, `Semantics` label equal to the text. Use it for every line below; no screen builds its own.
2. Show these notes (en; translate to it):

| Number | Where | Note |
|---|---|---|
| Current FTP | Progress power card, profile | `manual`: "Set by you on {date}" · `estimate`: "From your estimate, adopted on {date}" · `test`: "From your ride on {ride date}" (tappable, opens the ride) · `earlier`: "Set before {date}" |
| Estimated FTP | Progress power card | "95 % of your best 20 minutes, on {date}" or "90 % of your best 8 minutes, on {date}" (from `FtpEstimate.Method` and `From`) |
| VO2max | Progress power card | "From your best 5 minutes on {date} and your weight" |
| Max heart rate | Profile | "Estimated from your year of birth (208 − 0.7 × age)" |
| Critical power, W′, peak power | Story 5 | as Story 5 says |
| Decoupling, efficiency factor | Story 7 | as Story 7 says |

3. Dates use the rider's locale, short form ("12 Nov 2026").

### Acceptance tests

- `SourceNote_ShouldReadItsTextToScreenReaders_WhenShown`
- `PowerSummary_ShouldSayTheFtpWasSetByTheRider_WhenTheSourceIsManual`
- `PowerSummary_ShouldOpenTheRide_WhenTheFtpCameFromATest`
- `PowerSummary_ShouldExplainTheEstimate_WhenAnEstimateExists`

---

## Story 3: a reminder when the FTP is out of date

**As a rider**, I want to be told when my FTP is probably wrong, **so that** my zones and TSS stay honest.

Depends on: Stories 1 and 2.

### Rules

The reminder shows when **either** is true, checked on the rider's own calendar (`MemberClock`):

- **Stale:** the FTP was set 42 or more days ago (newest `ftp_history.set_at`), **and** the rider has at least one ready ride with power whose local date is in the last 28 days.
- **Estimate higher:** the power-curve estimate over the last 42 days (same method as `FitnessQueries.PowerCurveAsync` with `days = 42`) is at least 5 % above the current FTP.

If both are true, the reason is `estimate_higher`. A rider with no FTP at all and an estimate gets reason `missing`. A rider with no FTP and no estimate gets nothing.

### Server

1. `User` gains `FtpReminderSnoozedUntil` (`date`, null). Migration adds the column.
2. New endpoint `GET /api/v1/analytics/ftp-check`, operation `getFtpCheck`, owner only. Response:
   `{ reason: "stale" | "estimate_higher" | "missing" | null, ftpW, ftpAgeDays, estimateW, estimateMethod }`.
   `reason` is null when nothing applies **or** today < `FtpReminderSnoozedUntil`.
3. New endpoint `POST /api/v1/analytics/ftp-check/snooze`, operation `snoozeFtpCheck`: sets `FtpReminderSnoozedUntil` = today + 14 days; 204.
4. Setting the FTP (any source) clears `FtpReminderSnoozedUntil`.
5. Never shown to coaches.

### App

1. On Progress, first card of the analysis grid when `reason` is not null:
   - `stale`: "Your FTP is {n} weeks old" / "Zones and TSS use it. Ride a test, or use the estimate if it looks right."
   - `estimate_higher`: "You may be stronger than your FTP says" / "Your best efforts suggest {estimate} W; your FTP is {ftp} W."
   - `missing`: "Set your FTP" / "Your best efforts suggest {estimate} W."
2. Actions: "Use {estimate} W" (only with an estimate; calls `setFtp` with `source: estimate`), "How to test" (a sheet, text below), "Not now" (snooze).
3. "How to test" sheet text (en; translate to it): "Warm up for 15 minutes, with three short hard efforts. Ride 5 minutes hard, then 10 minutes easy. Then ride 20 minutes as hard as you can hold evenly. Velomine will notice the effort and suggest your new FTP (95 % of the 20 minutes)." No other protocol in Pack 1.

### Acceptance tests (use a fixed `TimeProvider`)

- `FtpCheck_ShouldSayStale_WhenTheFtpIs42DaysOldAndTheRiderRodeWithPower`
- `FtpCheck_ShouldSayNothing_WhenTheFtpIs41DaysOld`
- `FtpCheck_ShouldSayNothing_WhenTheRiderHasNoPowerRideIn28Days`
- `FtpCheck_ShouldSayEstimateHigher_WhenTheEstimateIsFivePercentAbove` (FTP 250, estimate 263 → reason; estimate 262 → null)
- `FtpCheck_ShouldSayMissing_WhenThereIsNoFtpButAnEstimate`
- `FtpCheck_ShouldStaySilent_WhenSnoozed` and `…_WhenTheSnoozeHasEnded`
- `SetFtp_ShouldClearTheSnooze_WhenTheFtpChanges`
- App: `ProgressScreen_ShouldShowTheFtpReminder_WhenTheCheckHasAReason`, `…_ShouldHideIt_WhenSnoozed`

---

## Story 4: Velomine notices a new FTP in a ride

**As a rider**, I want Velomine to notice when a ride shows a higher FTP, **so that** I can accept it in one tap.

Depends on: Stories 1–3.

### Rules

1. Runs **once per ride**, when a ride becomes `ready` for the first time (never on a re-read by `RideReparseService`, never for a duplicate).
2. Skipped when the ride's `Assist` is `ebike`, or the ride has no power bests, or its local date is more than 42 days before today.
3. Candidate FTP = the largest of (scaling factors as in Domestique's `FTP_SCALING_FACTORS`; shorter efforts are too variable to suggest an FTP from):
   - round(0.95 × the ride's 1,200 s best) (method `20min`)
   - round(0.97 × the ride's 1,800 s best) (method `30min`)
   - the ride's 3,600 s best (method `60min`)
   A missing best is skipped. On a tie, the longer duration wins.
4. A suggestion is created when the candidate is **at least 3 % above** the current FTP, or the rider has no FTP.
5. At most **one open suggestion** per rider: a new higher candidate replaces the open one (the old row becomes `replaced`); a lower or equal candidate is ignored.
6. Ramp tests are **not** detected in Pack 1.

### Server

1. New table `analytics.ftp_suggestions`: `id uuid`, `user_id uuid not null` (cascade), `ride_id uuid not null` (cascade), `watts integer not null` (30–1000), `method text not null` (`20min`, `30min`, `60min`), `effort_watts integer not null` (the 20-, 30- or 60-minute best), `created_at timestamptz not null`, `status text not null` (`open`, `accepted`, `dismissed`, `replaced`). Partial unique index: one `open` row per `user_id`.
2. Detection is called from the ingestion path right after power bests are stored for a new ride (`RideIngestionService`), in the same transaction as the ride becoming ready.
3. Notification: new type `ftp_suggested` in `NotificationTypes`, referring to the ride, subject `"{watts} W"`, in the **training** group. Not created when the ride is quiet (`Bulk-Import: true` or from a Strava import); the suggestion itself is still created.
4. `GET /api/v1/analytics/ftp-suggestion`, operation `getFtpSuggestion`: the open suggestion or 204.
5. `POST /api/v1/analytics/ftp-suggestion/{id}/accept`, operation `acceptFtpSuggestion`: sets `FtpW`, writes an `ftp_history` row with `source = 'test'` and the ride id, marks the suggestion `accepted`, returns `ProfileResponse`. 404 if not the caller's or not open.
6. `POST /api/v1/analytics/ftp-suggestion/{id}/dismiss`, operation `dismissFtpSuggestion`: marks it `dismissed`; 204.
7. `RideResponse` gains `FtpSuggestionW` (`int?`) and `FtpSuggestionMethod` (`string?`): set on the owner's ride when that ride has an `open` suggestion; always null for coaches.
8. Export: `ftp-suggestions.json`. Deletion: rows go with the account and with the ride.
9. Never shown to coaches.

### App

1. Ride detail: when `ftpSuggestionW` is set, a card at the top: "This ride suggests an FTP of {w} W" / "95 % of your best 20 minutes ({effort} W)", "97 % of your best 30 minutes ({effort} W)" or "Your best 60 minutes" / buttons "Use {w} W" and "Dismiss".
2. Progress: the same card above the Story 3 reminder when an open suggestion exists; Story 3's reminder is hidden while a suggestion is open.

### Acceptance tests

- `FtpSuggestion_ShouldBeCreated_WhenTwentyMinutesAt280WAndFtpIs250` (a 25-minute ride, so no 30- or 60-minute best; candidate 266 → suggestion, method `20min`)
- `FtpSuggestion_ShouldNotBeCreated_WhenTheCandidateIsLessThanThreePercentAbove` (FTP 260, candidate 266 → none, since 266 < 267.8)
- `FtpSuggestion_ShouldUseTheHour_WhenSixtyMinutesIsHigher` (FTP 250; best 20 min 280, best 30 min 276, best 60 min 270 → 266, 268 and 270 → `60min`, 270 W)
- `FtpSuggestion_ShouldUseHalfAnHour_WhenThirtyMinutesIsHighest` (FTP 250; a 40-minute ride, best 20 min 280, best 30 min 280 → 266 and 272 → `30min`, 272 W)
- `FtpSuggestion_ShouldBeCreated_WhenTheRiderHasNoFtp`
- `FtpSuggestion_ShouldReplaceTheOpenOne_WhenAHigherRideArrives` and `…_ShouldKeepIt_WhenALowerRideArrives`
- `FtpSuggestion_ShouldBeSkipped_WhenTheRideIsAnEbike` / `…_WhenTheRideIsOlderThan42Days` / `…_WhenTheRideIsReadAgain`
- `FtpSuggestion_ShouldNotNotify_WhenTheRideIsQuiet`
- `AcceptFtpSuggestion_ShouldSetFtpAndWriteATestHistoryRow_WhenOpen`
- `AcceptFtpSuggestion_ShouldReturn404_WhenItBelongsToAnotherRider`
- `CoachRide_ShouldNotShowTheFtpSuggestion_WhenACoachReadsTheRide`
- Export and deletion tests as in Story 1.

---

## Story 5: critical power, W′ and peak power

**As a rider with a power meter**, I want my critical power, W′ and peak power, **so that** I know my sustainable power and how much hard effort I have above it.

Depends on: Story 2 (for the note).

### Formula (Monod & Scherrer 1965; Poole et al. 2016)

The two-parameter model `P(t) = CP + W′ / t`, fitted by **ordinary least squares on the points (x = 1/t, y = P)**: the intercept is CP (watts), the slope is W′ (joules).

1. Points: the best power for **120, 300, 600 and 1,200 s** in the power curve's range (`PowerCurvePoint`s already computed in `FitnessQueries.PowerCurveAsync`).
2. Fit only with **at least 3** of those 4 points.
3. Reject the fit (return null) when R² < 0.90, CP ≤ 0, W′ ≤ 0, CP outside 50–600 W, or W′ outside 3,000–50,000 J.
4. Peak power = the 1 s best in the range (null if none).
5. Round CP to whole watts, W′ to whole joules, R² to 3 decimals.

This is Domestique's `compute_cp_wprime` with two deliberate differences: it fits 180 s instead of 120 s (Velomine stores no 180 s best, and 2 minutes is inside the 2–15 minute range Poole recommends), and its ranges are narrower (CP 100–500 W, W′ 5,000–40,000 J). Keep the rules above.

### Server

1. `PowerCurveResponse` gains a flat object `CriticalPower` (`null` when the fit is rejected): `{ cpW, wPrimeJ, peakW, r2, durations: [int] }` where `durations` lists the seconds actually used.
2. The coach power curve (`Features/Coach/CoachPowerCurve.cs`) returns the same object under the same rules it already applies to the power curve; nothing new to check.
3. Computed on read; nothing stored.

### App

1. Progress power card: a row "Critical power {cp} W · W′ {w′ in kJ, one decimal} kJ · Peak {peak} W", with a `SourceNote`: "Fitted from your best 2, 5, 10 and 20 minutes in this range" (list only the durations used).
2. When null and the rider has power data: "Not enough hard efforts of 2 to 20 minutes in this range to work out critical power."
3. The coach's power view shows the same row.

### Acceptance tests (known values)

- `CriticalPower_ShouldRecoverTheModel_WhenTheBestsFollowIt`: bests 120 s = 416.7 → 417, 300 s = 316.7 → 317, 600 s = 283.3 → 283, 1,200 s = 266.7 → 267 (from CP 250 W, W′ 20,000 J): result CP 250 ± 1 W, W′ 20,000 ± 300 J, R² ≥ 0.999.
- `CriticalPower_ShouldUseThreePoints_WhenOneDurationIsMissing` (drop 1,200 s): CP 250 ± 2, `durations` = [120, 300, 600].
- `CriticalPower_ShouldBeNull_WhenOnlyTwoDurationsExist`
- `CriticalPower_ShouldBeNull_WhenTheFitIsPoor` (bests 120 = 300, 300 = 310, 600 = 200, 1,200 = 290)
- `CriticalPower_ShouldBeNull_WhenWPrimeIsOutOfRange`
- `CoachPowerCurve_ShouldIncludeCriticalPower_WhenTheAnalyticsGrantExists` and `…_ShouldNotBeVisible_WhenRequestComesFromAnotherClub`

---

## Story 6: W′ balance during a ride

**As a rider**, I want to see how much of my W′ was left through a ride, **so that** I see where I went into the red.

Depends on: Story 5.

### Formula (Skiba et al. 2015, differential form)

On the ride's power at 1 Hz (the stored streams, resampled to 1 s the same way normalized power does; samples inside pauses are skipped and the balance carries over the pause unchanged):

- start: `bal = W′`
- each second with power `P`:
  - if `P > CP`: `bal = bal − (P − CP)`
  - else: `bal = bal + (W′ − bal) × (CP − P) / W′`
- `bal` is never above `W′`; it may go below 0 (that means the rider beat the model).

Domestique uses Skiba's 2012 exponential recovery (τ = 546 · e^(−0.01 · (CP − P)) + 316) and stops the balance at 0. Velomine uses the 2015 differential form above, which intervals.icu also uses, and lets the balance go below 0. Keep the rules above.

CP and W′ are the rider's **current** fit: Story 5 over the last 90 days as of the request. No fit → no W′ balance.

### Server

1. `RideStreamsResponse` gains an optional array `WPrimeBalanceJ` (`int[]?`, whole joules), downsampled with the same indices as the other streams. Null when the ride has no power or the rider has no fit.
2. `RideResponse` gains `MinWPrimeBalanceJ` (`int?`) and `WPrimeJ` (`int?`, the W′ used).
3. Computed on read.
4. Coaches: present on the coach ride and streams only when the coach has the **analytics** grant **and** the ride's effective privacy does not hide power; otherwise null. Add both fields to `PrivacyRules.ForViewer` (hidden with power) and to `RideResponse.WithoutTrainingLoad()`.

### App

1. Ride detail charts: a "W′ balance" series in kJ, drawn like the other series, with the line at 0 marked.
2. Ride summary: "Lowest W′ balance {min} kJ of {w′} kJ".

### Acceptance tests (known values)

- `WPrimeBalance_ShouldDropByTheWorkAboveCp_WhenRidingAboveCp`: CP 250, W′ 20,000, 60 s at 350 W → balance 14,000 J after 60 s.
- `WPrimeBalance_ShouldRecoverTowardsWPrime_WhenRidingBelowCp`: from 14,000 J, 1 s at 150 W → 14,000 + 6,000 × 100 / 20,000 = 14,030 J.
- `WPrimeBalance_ShouldNeverExceedWPrime_WhenRidingEasyFromTheStart`
- `WPrimeBalance_ShouldCarryOverAPause_WhenTheRideIsPaused`
- `WPrimeBalance_ShouldBeNull_WhenTheRiderHasNoFit`
- `CoachRide_ShouldHideWPrimeBalance_WhenPowerIsHidden` and `…_WhenThereIsNoAnalyticsGrant`

---

## Story 7: aerobic decoupling and efficiency factor

**As an endurance rider**, I want to know whether my heart rate drifted against my power on long steady rides, and whether my efficiency improves over months, **so that** I see my base building.

Depends on: Story 2.

### Definitions (Friel)

On one ride with both power and heart rate:

1. Use moving samples only (pauses excluded, as for moving time), resampled to 1 s.
2. Keep a second when heart rate is between 60 and 220 bpm **and** power is between 50 and 2,500 W. Coasting (descents, traffic) and spikes are left out, so a hilly ride does not show drift that is only freewheeling. (Same filter as Domestique's `_is_valid_decoupling_sample`.)
3. Drop the first **15 minutes** of kept seconds (warm-up; Domestique's `DECOUPLING_WARMUP_TRIM_S`).
4. Require at least **40 minutes** of kept seconds after the drop; otherwise both values are null.
5. **Efficiency factor (EF)** = normalized power of the kept seconds ÷ mean heart rate of the kept seconds, 2 decimals.
6. **Decoupling** = split the kept seconds into two halves by count; `EF₁` and `EF₂` per half (normalized power ÷ mean heart rate of that half); decoupling % = `(EF₁ − EF₂) / EF₁ × 100`, 1 decimal. Positive means heart rate drifted up.
7. **Steady**: the ride's variability index (normalized power ÷ average power over the kept seconds) is ≤ 1.10. Only steady rides get a decoupling value; EF is stored for every qualifying ride, plus a `steady` flag.

### Server

1. Computed **at read** in `RideMetrics` and stored on `rides.rides`: `efficiency_factor double precision null`, `decoupling_pct double precision null`, `steady boolean null`. Migration adds the columns. **Raise `RideParserVersion.Current` by one** so stored rides are read again.
2. `RideResponse` gains `EfficiencyFactor`, `DecouplingPct`, `Steady`.
3. `TrainingResponse` (`Features/Analytics/GetTraining.cs`) gains `Efficiency: [{ weekStart, efficiencyFactor, rides }]`: for each week of the range (the rider's first day of the week), the mean EF of **steady** rides, omitting weeks without any.
4. Coaches: the three ride fields are hidden when the ride's effective privacy hides **power or heart rate**, and in `WithoutTrainingLoad()`. The weekly `Efficiency` series in the coach's training view leaves out rides whose effective privacy hides power or heart rate.

### App

1. Ride detail stats: "Efficiency factor {ef}" and, for steady rides, "Decoupling {d} %" with a word: below 5 % "Steady heart rate", 5–10 % "Some drift", above 10 % "Large drift". `SourceNote`: "From steady pedalling after a 15-minute warm-up".
2. Progress: a card "Aerobic efficiency" with the weekly series as a line, and "Higher is better: more power for the same heart rate." Empty state: "Needs steady rides of about an hour with power and heart rate."

### Acceptance tests (known values)

- `Decoupling_ShouldBeFourPointEight_WhenHeartRateRisesFrom140To147`: an 85-minute ride, 15 minutes of warm-up at 150 W and 120 bpm, then 70 minutes at a constant 200 W with heart rate 140 for the first 35 minutes and 147 for the last 35. EF₁ = 200 / 140 = 1.4286, EF₂ = 200 / 147 = 1.3605, decoupling = 4.8 %; EF = 200 / 143.5 = 1.39; `Steady = true`.
- `Decoupling_ShouldBeNull_WhenLessThan40MinutesRemainAfterWarmUp` (54 minutes of pedalling in total)
- `Decoupling_ShouldBeNull_WhenTheRideIsNotSteady` (VI 1.2), with EF still set and `Steady = false`
- `EfficiencyFactor_ShouldIgnorePauses_WhenTheRideStopped`
- `Decoupling_ShouldIgnoreCoasting_WhenPowerIsBelow50W`: the 85-minute ride above with 10 minutes at 0 W and 130 bpm inserted between the two 35-minute parts gives the same 4.8 %.
- `Training_ShouldAverageEfficiencyOfSteadyRidesPerWeek_WhenThereAreSeveral`
- `CoachRide_ShouldHideDecoupling_WhenHeartRateIsHidden` and `…_WhenPowerIsHidden`
- `RideReparse_ShouldFillEfficiency_WhenAnOlderRideIsReadAgain`

---

## Story 8: intensity distribution

**As a rider**, I want to see how my riding splits into easy, moderate and hard, **so that** I know whether I ride too much in the middle.

Depends on: nothing.

### Definitions (Seiler's three zones; Treff et al. 2019)

For each ready ride in the range, on read, from the **current** profile (zones are always computed on read):

- **With power and an FTP**, from the power stream and the existing power zones (`TrainingLoad.PowerBounds`): easy = Z1 + Z2 (below 75 % FTP), moderate = Z3 + Z4 (75 % to below 105 %), hard = Z5 + Z6 + Z7 (105 % and above).
- **Otherwise, with heart rate and a max heart rate**, from the existing heart-rate zones (`TrainingLoad.HeartRateBounds`): easy = Z1 + Z2 + Z3 (below 80 % of max), moderate = Z4 (80 % to below 90 %), hard = Z5 (90 % and above).
- A ride with neither contributes nothing.

Percentages are of the summed easy + moderate + hard seconds, rounded to **1 decimal** before anything below uses them.

**Polarisation index** (Treff 2019, the form intervals.icu shows and Domestique's `treff_polarization_index`): `PI = log10((easy% × hard%) / moderate%)` with percentages 0–100, 2 decimals. Null when moderate% < 0.1 or hard% = 0. This is the value returned and shown.

**Two-pole index**, used only by rule 1 and never returned (Domestique's additive `polarization_index`): `log10((easy% + hard%) / moderate%)`. Null when moderate% < 0.1.

**Label**: Domestique's `classify_distribution` cascade, first match wins. A rule whose index is null does not match.

1. `polarised`: two-pole index > 2.00 **and** easy > hard > moderate (Treff's precondition)
2. `polarised`: PI > 2.00 **and** hard ≥ 20 **and** moderate < hard
3. `hiit`: hard > 40 **and** easy < 20
4. `threshold`: moderate ≥ 30 **and** hard ≤ 15 **and** easy ≤ 50
5. `pyramidal`: moderate ≥ 35 **and** moderate > hard + 10
6. `base`: easy ≥ 70
7. `pyramidal`: moderate ≥ 20 **and** moderate > hard **and** 40 ≤ easy < 70
8. `mixed`: anything else

Why not "PI > 2 means polarised" alone: a week of 80 % easy, 5 % moderate and 15 % hard has PI 2.38 but is mostly base riding with some efforts; rules 1 and 2 need a real hard pole.

### Server

1. `TrainingResponse` gains a flat `Intensity` object: `{ easyS, moderateS, hardS, easyPct, moderatePct, hardPct, polarisationIndex, label, rides }` and `IntensityWeeks: [{ weekStart, easyS, moderateS, hardS }]`. Null when no ride contributes.
2. The query reads **only** the time, power and heart-rate arrays of the rides in range (a projection on `rides.ride_streams`), never positions.
3. Coaches: in the coach's training view, a ride whose effective privacy hides power falls back to heart rate; if heart rate is hidden too, it contributes nothing.

### App

Progress: a card "Easy, moderate, hard": one stacked bar for the range with the three percentages, the label in words ("Polarised: mostly easy, a real share of hard, little in between", "Pyramidal: most easy, less moderate, least hard", "Threshold-heavy: a lot of moderate riding", "High-intensity heavy: a lot of hard riding", "Base: almost all easy riding", "Mixed"), and small weekly stacked bars. A `SourceNote`: "From power where you have it, otherwise heart rate."

### Acceptance tests (known values)

Known values (easy / moderate / hard → PI, label); one test per row, for example `IntensityLabel_ShouldBePolarised_When58Easy11Moderate31Hard`. The rows come from Domestique's tests, which were checked against intervals.icu's labels.

| Easy | Moderate | Hard | PI | Label | Rule |
|---|---|---|---|---|---|
| 58.0 | 10.7 | 31.3 | 2.23 | `polarised` | 2 |
| 80.0 | 5.0 | 15.0 | 2.38 | `base` | 6 (rules 1 and 2 fail: two-pole index 1.28, hard < 20) |
| 99.9 | 0.1 | 0.0 | null | `base` | 6 (rule 1 fails: hard is not above moderate) |
| 15.0 | 49.2 | 35.8 | 1.04 | `pyramidal` | 5 |
| 58.3 | 27.6 | 14.1 | 1.47 | `pyramidal` | 7 |
| 30.0 | 60.0 | 10.0 | 0.70 | `threshold` | 4 |
| 10.0 | 30.0 | 60.0 | 1.30 | `hiit` | 3 |
| 50.0 | 25.0 | 25.0 | 1.70 | `mixed` | 8 |
| 70.0 | 20.0 | 10.0 | 1.54 | `base` | 6 |

- `Intensity_ShouldHaveNoIndex_WhenThereIsNoHardTime`
- `Intensity_ShouldUseHeartRate_WhenTheRideHasNoPower`
- `Intensity_ShouldSkipTheRide_WhenItHasNeitherSignal`
- `CoachTraining_ShouldFallBackToHeartRate_WhenPowerIsHidden` and `…_ShouldNotBeVisible_WhenRequestComesFromAnotherClub`

---

## Story 9: personal power records

**As a rider**, I want to be told when a ride beat my best power for a duration, **so that** progress feels like progress.

Depends on: nothing.

### Rules

1. Durations considered: every `PowerBests.Durations` value **except 1 s** (5 s to 60 min).
2. A ride sets an **all-time record** for a duration when its best for that duration is **strictly greater** than every earlier ride's best for that duration (earlier = ready, not duplicate, start time before this ride's).
3. It sets a **90-day record** when strictly greater than every earlier ride in the 90 days before its start, and it is not already an all-time record.
4. Records are computed **on read** from `rides.ride_power_bests`; nothing new is stored.
5. A rider's first ride with power sets no records (there is nothing to beat).

### Server

1. `RideResponse` gains `PowerRecords: [{ durationS, watts, kind }]` with `kind` = `all_time` or `90_days`, ordered by duration. Owner always; coaches only with the **analytics** grant and when the ride's effective privacy does not hide power (add to `PrivacyRules.ForViewer` and `WithoutTrainingLoad()`).
2. Notification: new type `power_record`, created once when a ride becomes `ready` for the first time with at least one **all-time** record, referring to the ride, subject the longest record as `"{duration}: {watts} W"` (`5 s`, `1 min`, `20 min`…). Not created for quiet rides, for rides whose local date is more than 30 days before today, or on a re-read.

### App

1. Ride detail: chips under the summary, "Best 5 min ever: 312 W" and "Best 20 min in 90 days: 268 W".
2. The notification opens the ride.

### Acceptance tests

- `PowerRecords_ShouldMarkAllTime_WhenTheRideBeatsEveryEarlierRide`
- `PowerRecords_ShouldNotMark_WhenTheRideOnlyEqualsTheBest`
- `PowerRecords_ShouldMarkNinetyDays_WhenOnlyOlderRidesWereBetter`
- `PowerRecords_ShouldIgnoreLaterRides_WhenAskedAboutAnOlderRide`
- `PowerRecords_ShouldBeEmpty_WhenItIsTheFirstPowerRide`
- `PowerRecords_ShouldIgnoreOneSecond_WhenItIsTheOnlyRecord`
- `PowerRecordNotification_ShouldBeCreated_WhenAnAllTimeRecordIsSet` / `…_ShouldNotBeCreated_WhenTheRideIsQuiet` / `…_WhenTheRideIsOlderThan30Days`
- `CoachRide_ShouldHidePowerRecords_WhenPowerIsHidden` and `…_ShouldNotBeVisible_WhenRequestComesFromAnotherClub`

---

## When all nine are done

1. `site/status/index.html`, "Training and goals": add one line per story, in the site's plain style, for example "Critical power, W′ and peak power from your best efforts", "W′ balance on every ride with power", "Aerobic decoupling and efficiency factor on steady rides", "Easy, moderate and hard time, with the polarisation index", "Personal power records", "FTP history, a reminder when it is out of date, and a suggestion when a ride shows a higher FTP".
2. `README.md`, "What it does today": one bullet summarising the above.
3. Demo: make sure `Features/Demo/demo-seed.sql` gives the demo rider enough power rides for Stories 5, 7, 8 and 9 to show something (at least 2-, 5-, 10- and 20-minute efforts, two steady rides over 50 minutes with heart rate). Adjust the seed if not, and extend `DemoTests`.
4. Delete this file in the last commit; the code and the status page are the record.
