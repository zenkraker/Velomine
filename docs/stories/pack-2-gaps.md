# Pack 2 gaps: close what the audits found before Pack 2 Story 3

## Overview
Two audits on 19 Nov 2026 found Pack 2 Stories 1, 2 and 7 built on local `main` (commit `1c899dd`) with gaps against `docs/stories/pack-2.md`. This file closes them, so Pack 2 Story 3 starts from a state nobody doubts.

Original request (owner, 19 Nov): "we need to close the gaps and iron out the doubts before we continue with pack 2". The owner answered 16 questions, then 8 more after the architect's plan; the answers are under Decisions.

Who sees the data: nothing here shows member data to anyone but its owner. Heart-rate numbers, suggestions and the event/ride link stay owner-only, as in `pack-2.md`. Story 4 also closes a leak: a coach with the analytics grant receives owner-only fields today.

**Dev order: 3 → 5a → 4 → 5b → 6 → 7 → 8 → 9a → 9b.** One commit each, `just check` green before each commit. Stories 6 and 7 are adjacent because both edit `profile_screen.dart`. Pack 2 Story 3 ships straight after 9b.

## Stories

(DONE below means built, merged to `main` in PR #20 and checked by the architect against the code on 20 Nov 2026; delete this file once the owner confirms.)

### Story 1: Know where `main` stands (DONE)
**Result (19 Nov):** `just check` passed twice on `1c899dd` with uncommitted tooling changes: 993 server tests, 557 app tests, analyze clean, Android unit tests built, API client and `build_runner` output with no diff.

### Story 2: Settle the two Pack 1 doubts (DONE)
**Result (19 Nov):** Personal power records and `SourceNote` are fully present with their named tests and both `.arb` files. No change was needed. Three cosmetic differences were left as they are: the Progress FTP "test" note shows the day the FTP was set; the power-record chips sit above the map; the maximum heart-rate wording says "from your age".

### Story 3: A threshold effort must be a real 30-minute effort (DONE)
**Priority:** High
**Description:** As a rider, I want my threshold heart rate learned only from a steady 30-minute effort, so that a ride with a stop in it, or a ride that is too short, never sets a threshold that is too high.
**Acceptance criteria:**
- **Given** a ride whose best 30-minute window by mean heart rate has a pause inside it, **When** the ride becomes ready, **Then** that window is skipped and the next best valid window is used, or none. Test `ThresholdHeartRate_ShouldSkipTheWindow_WhenItHasAPause` (asserts an exact bpm).
- **Given** a window with heart rate present for less than 90 % of its seconds, **Then** the window is skipped. **Given** exactly 90 % (1,620 of 1,800 s) and no pause, **Then** it counts.
- **Given** a ride with fewer than 1,800 s of series (1,741 and 1,799 give none; 1,800 gives one), **Then** there is no threshold candidate.
- **Given** a ride sampled faster than once a second, **When** it is read, **Then** it is resampled to 1 Hz by time, so a window is 30 real minutes. The maximum rules are unchanged apart from that.
- A stop with the timer running (no pause event, heart rate present) still counts. The window is not compared with the ride's stored moving time.
- Detection still runs once per ride, never on a re-read, never for a duplicate.
- `RideParserVersion.Current` is **not** raised. The dev does not edit `RideMetrics`, zone seconds, TRIMP or moving time. If a stored metric must change, the version is raised in that commit and the PO is told.
**Dependencies:** None
**Size:** M

### Story 4: A ride can teach both numbers (DONE)
**Priority:** High
**Description:** As a rider, I want one ride to update both my maximum and my threshold when it earns both, so that my threshold does not lag behind a new maximum. As a rider, I also want my heart-rate notes hidden from my coach, because they are mine.
**Acceptance criteria:**
- **Given** a ride that sets a new maximum and holds a valid higher threshold effort, **Then** both are applied by the Pack 2 Story 2 rules (automatic, or a suggestion if the number was typed). The threshold is judged against the maximum in use after the first step; a maximum that was only suggested has not changed.
- `RideResponse` keeps `heartRateNote` (= max note, else threshold note) and gains `heartRateMaxNote` and `heartRateThresholdNote`.
- Ride detail shows up to two cards, in English and Italian. Progress is unchanged: it shows one card per open suggestion.
- A ride that changes both numbers sends two `heart_rate_measured` notifications.
- **Privacy:** `PrivacyRules.ForViewer` and `RideResponse.WithoutTrainingLoad` clear all three note fields and `FtpSuggestionId`. A coach with the analytics grant, and one without, get none of them.
- Tests: `HeartRateDetection_ShouldUpdateBoth_WhenARideRaisesTheMaxAndHoldsAThresholdEffort`, `HeartRateDetection_ShouldSuggestBoth_WhenBothNumbersWereTyped`, `HeartRateDetection_ShouldMeasureTheThreshold_WhenTheMaxWasOnlySuggested`, `HeartRateDetection_ShouldNotSetTheThreshold_WhenItIsNotBelowTheNewMax`, `HeartRateDetection_ShouldKeepTheLegacyNote_WhenBothHappen`, `CoachRide_ShouldNotCarryTheHeartRateNotes_WhenTheCoachViewsTheRide`, another member cannot see the notes, an app test with two cards.
**Dependencies:** Story 3 and Story 5a
**Size:** M

### Story 5a: One truth for the source and ride of a heart-rate number (DONE)
**Priority:** High
**Description:** As a rider, I want every screen to say where my heart-rate numbers came from, so that a measured number is never called "typed by you".
**Acceptance criteria:**
- `accounts.users` gains `max_heart_rate_source`, `threshold_heart_rate_source` (`manual` or `measured`) and `max_heart_rate_ride_id`, `threshold_heart_rate_ride_id` (FK to `rides.rides`, `ON DELETE SET NULL`). Checks: a source is set exactly when its bpm is set; a ride id only when the source is `measured`.
- **Backfill in the same migration, before the checks:** for each number, take the newest `heart_rate_history` row of that kind (`set_at desc, sequence desc`); copy its source and ride id only when its bpm equals the user's current number and its source is not `cleared` (ride id through a `LEFT JOIN rides.rides`). Everything else becomes `manual` with a null ride id. A migration test (pattern of `FtpHistoryTests.cs:207`) seeds a matching measured row, a measured row whose bpm no longer matches, a cleared row and a number with no history, and expects `measured` + ride, `manual`, `manual`, `manual`.
- `HeartRates.For(User, TimeProvider)` keeps its name and shape `(HeartRate? Max, HeartRate? Threshold)` and stays synchronous. Each `HeartRate(Bpm, Source, RideId)` carries the true source (`manual`, `measured`, `estimate`) and ride id. A bpm with a null source column counts as `manual`.
- `SetHeartRateValue.SetAsync` and `ClearAsync` write or null all three columns in the same save as the history row. `HeartRates.LatestAsync` and `GetProfile.ProfileWithSourcesAsync` are deleted; `ProfileOfAsync` is the only builder.
- Callers switched: `GetProfile`, `SetHeartRate` (both endpoints), `UpdateProfile`, `AcceptHeartRateSuggestion`, `StepMaxAsync`, `StepThresholdAsync`. This also fixes the bug where a measured threshold counts as typed, so a better ride only suggests.
- Every endpoint that returns the profile (including `setFtp` and accepting an FTP suggestion) shows `measured` and the ride id.
- Tests: `HeartRates_ShouldReturnMeasuredAndTheRide_WhenARideSetTheNumber`; `Profile_ShouldSayMeasured_WhenTheHeartRateCameFromARide` through `getProfile` and through `setFtp` or accepting an FTP suggestion; `HeartRateDetection_ShouldUseTheMeasuredThresholdAutomatically_WhenARideBeatsIt`; the newest history row and the columns agree after each kind of change; a deleted ride keeps `measured` with a null ride id; deleting a user with a measured number works; the export shows source and ride id.
- `AGENTS.md` *Ride processing → Zones* and `pack-2.md` Stories 1 and 2 describe the real shape.
**Dependencies:** None (runs after Story 3)
**Size:** M

### Story 5b: The profile save only sets (DONE)
**Priority:** High
**Description:** As a rider, I want saving my profile never to wipe a heart-rate number I did not touch.
**Acceptance criteria:**
- `UpdateProfile` only sets: a missing or null `MaxHeartRate` or `ThresholdHeartRate` never clears. Clearing goes through `DELETE /accounts/me/heart-rate/{kind}`. The DTO field names stay.
- One shared helper, "threshold below the maximum in use", serves `SetHeartRate`, `AcceptHeartRateSuggestion` and `UpdateProfile` and returns 400. When both numbers arrive together, the maximum is applied first.
- The dev runs `git show v0.1.27:src/Velomine.Server/Features/Accounts/UpdateProfile.cs`, says what a released app sends, and writes it in the commit message.
- A typed maximum below a set threshold is **not** refused (owner's decision). The dev checks how zones behave in that state and reports it to the PO.
- Tests: `UpdateProfile_ShouldKeepTheMax_WhenOnlyAThresholdIsSent`, `UpdateProfile_ShouldKeepTheThreshold_WhenOnlyTheMaxIsSent`, `UpdateProfile_ShouldRefuse_WhenTheThresholdIsNotBelowTheMax`.
**Dependencies:** Story 5a
**Size:** S

### Story 6: "Measured on your ride" opens the ride (DONE)
**Priority:** Medium
**Description:** As a rider, I want the source line of a measured heart rate to show my ride's date and open that ride.
**Acceptance criteria:**
- The line reads "Measured on your ride of {ride date}", with the ride's own local date (start time plus its stored offset), not the date the history row was written, and tapping it opens the ride (check the real route first).
- **Given** the ride was deleted (`measured` with a null ride id), **Then** the line shows no link and says "Measured on a ride you deleted" (`heartRateSourceMeasuredDeleted`, both `.arb` files).
- App tests: `ProfileScreen_ShouldOpenTheRide_WhenAMeasuredHeartRateIsTapped`, `ProfileScreen_ShouldShowNoLink_WhenTheMeasuringRideWasDeleted`.
**Dependencies:** Story 5a
**Size:** S

### Story 7: An estimated heart rate is never saved as typed (DONE)
**Priority:** High
**Description:** As a rider, I want an estimated number to stay an estimate unless I type my own.
**Acceptance criteria:**
- **Given** an estimated maximum or threshold, **Then** the field is empty and the estimate is its hint text.
- The decision lives in `ProfileViewModel.commitHeartRate(kind, typed)`: text equal to the set value → nothing; empty and no value set → nothing; empty and a value set → clear; a number typed → save as `manual`.
- Nothing is written to `heart_rate_history` for an untouched field.
- App tests: `ProfileScreen_ShouldNotSave_WhenAnEstimatedFieldIsLeftUntouched`, `ProfileScreen_ShouldSaveAsManual_WhenTheRiderTypesANumber`, `ProfileScreen_ShouldGoBackToTheEstimate_WhenATypedValueIsEmptied`. The two existing profile tests that assume the estimate is in the field are rewritten.
**Dependencies:** None (runs after Story 6)
**Size:** S

### Story 8: Two events on one day link to no ride (DONE)
**Priority:** Medium
**Description:** As a rider, I want events linked to rides in a way I can predict.
**Acceptance criteria:**
- The code already does this (`EventRideLink.AddAsync` returns when there is not exactly one unlinked event). Add `Event_ShouldNotLink_WhenTwoEventsShareTheDate`.
- `pack-2.md` Story 7 gets the rule in Rules and in server item 3 ("…and it is the only unlinked event of that date").
**Dependencies:** None
**Size:** S

### Story 9a: Linking an event's ride, server (DONE)
**Priority:** High
**Acceptance criteria:**
- `PUT /training/events/{id}/ride`: a ride whose local date (start time plus stored offset, `MemberClock.LocalDateOf`) differs from the event date answers 400 (documented with `ProducesProblem(400)`); another member's ride or event, or a ride that is not ready, stays 404.
- New `EventRideLink.ForEventAsync`, called from `AddEvent` and from `UpdateEvent` when the date changed. It links when exactly one ready ride of the member is on that local date, that ride is not already linked to another event, and the event is the only unlinked event of that date.
- When the date changes, a link to a ride that is not on the new date is dropped first, then `ForEventAsync` runs. Changing only the name never re-links an event the rider unlinked.
- Manual linking may still pick a ride that another event uses.
- No schema change, no new endpoint, nothing in `DemoLock.Refused`.
- Tests: `SetEventRide_ShouldRefuse_WhenTheRideIsOnAnotherDate`, `SetEventRide_ShouldAccept_WhenTheRideIsOnTheEventDayButAnotherUtcDay`, `Event_ShouldLinkTheRide_WhenAnEventIsAddedOnTheDayOfOneRide`, `Event_ShouldLinkTheRide_WhenTheDateIsChangedToTheDayOfOneRide`, `Event_ShouldNotLink_WhenTheNewEventIsNotTheOnlyUnlinkedOne`, `UpdateEvent_ShouldDropTheLink_WhenTheDateMovesAwayFromTheRide`, `UpdateEvent_ShouldNotRelink_WhenOnlyTheNameChanges`.
- Regenerate the API client. `pack-2.md` Story 7 gets the same-date check and the link-on-add-or-date-change rule.
**Dependencies:** Story 8
**Size:** M

### Story 9b: Linking an event's ride, app (DONE)
**Priority:** High
**Description:** As a rider, I want to pick the ride that was my event, or remove the link.
**Acceptance criteria:**
- `events_data.dart` gets `setRide(String id, String? rideId)` returning `Result<EventResponse?>` and `ridesOn(DateTime day)` (rides of that day with status `ready`). `EventsViewModel` gets `linkRide` and `unlinkRide`.
- The event card's `PageMenu` shows "Link a ride" when no ride is linked, or "Unlink" when one is. Neither is destructive, so neither is confirmed.
- "Link a ride" opens a `showSheet` with a `SheetFrame` picker of that day's rides, or an `EmptyState` when there are none. All strings are in both `.arb` files.
- App tests: one for picking, one for unlinking, at least one under the Italian locale.
**Dependencies:** Story 9a
**Size:** M

## Anchors (keep exactly)
- **JSON on `RideResponse`:** `heartRateNote` (unchanged), `heartRateMaxNote` (`max_measured`, `max_suggested` or null), `heartRateThresholdNote` (`threshold_measured`, `threshold_suggested` or null). Both new fields go last, as optional parameters. Storage: `rides.rides.heart_rate_threshold_note varchar(32) null`, backfilled from `heart_rate_note LIKE 'threshold%'`; ingestion writes `heart_rate_note = Max ?? Threshold`.
- **DB:** `accounts.users.max_heart_rate_source`, `max_heart_rate_ride_id`, `threshold_heart_rate_source`, `threshold_heart_rate_ride_id`.
- `HeartRates.For` keeps its name, parameters and `(HeartRate? Max, HeartRate? Threshold)` result; `ProfileResponse` field names are unchanged; the route and operation of `setEventRide` are unchanged.
- **Story 3 design:** a 1 Hz series by wall-clock second with zero-order hold; `HeartRateSeries(double?[] Values, bool[] Paused)` so a pause and a missing signal are separate; a 5-second median over the non-null neighbours, cut at the ends; samples with a time not after the previous one are dropped; windows of exactly 1,800 s every 60 s, valid when no second is paused and at least 1,620 values are non-null; the candidate is the rounded mean of the non-null values in the last 1,200 s; prefix sums, no quadratic scan. Before coding, check how many records `FitSession(seconds: 1800)` writes; fix the fixtures, not the rule.
- **Commands:** `just migration HeartRateSourceOnUser` (5a), `just migration RideHeartRateThresholdNote` (4); read the SQL, backfill before checks. `tools/generate-api-client.sh` after Stories 4 and 9a (5a and 5b: run it and confirm no diff). `just codegen` and l10n after Stories 6, 7, 9b. `just check` before every commit.

## Decisions
- 2026-11-19: Owner asked to close the audits' gaps and settle the doubts before Pack 2 continues.
- (Q1) Fix all gaps in Stories 1, 2 and 7 before Pack 2 Story 3.
- (Q2) Threshold window built exactly as Pack 2 Story 2 says: no pause, 90 % coverage, at least 30 minutes.
- (Q3) For Pack 2 Story 3: a typed, accepted or automatically measured threshold switches zones to the threshold model.
- (Q4) Coaches and share links see the same zones as the rider, under the existing grants.
- (Q5) For Pack 2 Story 3: heart rate below the bottom of the zones counts as easy in the zone chart and in the easy/moderate/hard split.
- (Q6) The zone-source note goes on the existing intensity card and the ride's heart-rate zones card; no new zone chart.
- (Q7) Source and ride id always right; the line opens the ride and shows the ride's date (Stories 5a and 6).
- (Q8) An estimated field stays empty with the estimate as hint (Story 7).
- (Q9) `HeartRates.For` keeps its shape and returns the true source and ride id (Story 5a).
- (Q10) A ride checks and can update both numbers (Story 4).
- (Q11) The "Your zones now use it" wording stays on the threshold card; Pack 2 Story 3 ships straight after these gaps.
- (Q12) Two events on one day link to no ride (Story 8).
- (Q13) A ride picker and "Unlink"; automatic link on add or date change (Stories 9a, 9b).
- (Q14) Only rides on the event's local date can be linked (Story 9a).
- (Q15) Pack 2 Stories 5 and 6 are two stories and two commits, with one parser-version bump in the second.
- (Q16) The 7 local commits and the untracked `.pi/` are not pushed for now.
- 2026-11-19 (plan Q1) Four source and ride-id columns on `accounts.users`, not an async history lookup.
- (plan Q2) The new-maximum card drops "Your zones now use it" when the rider's zones come from the threshold.
- (plan Q3) The easy/moderate/hard split maps per model: maximum model Z1–Z3 / Z4 / Z5 (unchanged); threshold model Z1–Z2 / Z3 / Z4–Z5. Written into Pack 2 Story 3.
- (plan Q4) Below-floor heart rate counts as easy in the zone chart and the split only. TRIMP stays as stored; no parser bump.
- (plan Q5) Story 9 rules accepted: a moved date drops a link that no longer fits; automatic linking skips a ride already linked to another event; manual linking may still pick such a ride.
- (plan Q6) A threshold window is 1,800 consecutive non-paused seconds, not compared with stored moving time.
- (plan Q7) `UpdateProfile` is set-only; clearing goes through `DELETE /accounts/me/heart-rate/{kind}`.
- (plan Q8) A typed maximum below a set threshold is not refused; the dev reports how zones behave then.
- Parser version: not raised in Stories 3 and 4 (detection runs only on a ride's first read and changes no stored metric). Only valid while `RideMetrics` is not edited.

## Plan
Written by the architect (reviewed by the Advisor on 19 Nov); the parts the dev needs are in Stories and Anchors above.

**Pack 2 Story 3 text must change before that story starts:**
1. Rule 2: a typed (`manual`), an accepted-suggestion or an automatically measured threshold (`measured`) switches zones to the threshold model; an estimated threshold keeps the maximum model.
2. Coaches and share links see the same zones and `HeartRateZoneModel` under the existing grants; this overrides the pack's owner-only rule 5 for zones. The source note for a non-owner must not say "your"; the heart-rate privacy switch hides it. Add `HeartRateZones_ShouldUseTheThresholdModel_WhenACoachViewsTheRide`.
3. Below-floor heart rate counts as easy (Z1, `From = 0`) in the ride's zone chart and the split; drop "time below it is not training time". TRIMP is unchanged.
4. Split mapping per model (see plan Q3).
5. The source note goes on the Progress intensity card and the ride's zones card; `IntensityResponse` gains the model and reference bpm; the note shows only when heart-rate rides were counted.
6. The maximum note drops "Your zones now use it" when the model is threshold; Story 3 ships straight after the gaps.
7. Dependencies: Stories 1–2 and the gaps Stories 3–5b. Add tests for the typed and the accepted threshold next to `HeartRateZones_ShouldUseTheThreshold_WhenItWasMeasured`.
