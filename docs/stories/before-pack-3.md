# Before Pack 3: close the last gaps auto training builds on

## Overview
The 22 Nov audit read `dev` at `64d95cc` against Packs 1 and 2. Both are built, with two small gaps left in Pack 1. Two more pieces are missing that auto training (Pack 3) will read: a sleep score in the morning check-in, and a FIT file the server writes itself. This story closes all four. Line numbers are from `64d95cc` and may drift slightly.

| Task | What the rider gets |
|------|---------------------|
| 1 | A test FTP on Progress says the day of the ride, not the day it was accepted |
| 2 | The FTP suggestion on a ride names the effort it came from |
| 3 | The morning check-in asks how well they slept |
| 4 | Any ride can be downloaded: its original file, and a FIT file for a ride read from GPX or TCX |

## How to work
- **Branch:** you are in the worktree `.dev/worktrees/before-pack-3` on `feat/before-pack-3` (from `origin/dev`). Commit this file first. Do not push; the owner opens the pull request into `dev`.
- **Order: 1 → 2 → 3 → 4.** One commit per task. After each task run only the tests it names (and the files you touched): `nix develop --command dotnet test --project tests/Velomine.Server.Tests -- --filter-class '<Namespace.Class>'` or `nix develop --command bash -c 'cd app && flutter test test/<file>'`. Run the full `nix develop --command just check` **once, after Task 4**, and fix anything it finds in a last commit.
- Follow `AGENTS.md`. Every test name is `Subject_ShouldDoSomething_WhenCondition`. Every new user-facing string goes in **both** `app/lib/l10n/app_en.arb` and `app_it.arb` (Italian says "giro/giri" for a ride), then `flutter gen-l10n`.
- **Do not add a dependency.** `Garmin.FIT.Sdk` is already there and can write FIT files (the tests do it in `tests/Velomine.Server.Tests/Rides/TestRideFiles.cs`).
- Do not edit `app/packages/velomine_api/` by hand; run `tools/generate-api-client.sh` in Tasks 2, 3 and 4, and commit the regenerated client with the task.
- **Do not raise `RideParserVersion.Current`:** nothing here changes how a file is read.
- Copy the setup of the existing test file each task names. Do not invent helpers when one exists.
- If anything here does not match the code, stop and report it instead of guessing.

## Tasks

### Task 1: A test FTP on Progress is dated by its ride
**Why:** Pack 1 Story 2 says a test FTP reads "From your ride on {ride date}". The profile does this (`ftpRideStart`, `app/lib/features/accounts/ftp_source_text.dart:42`), but Progress builds the note from the history row's `setAt` only: `ftpSourceNote` in `app/lib/features/progress/progress_screen.dart:40` and `_ftpNote` in `app/lib/features/progress/power_screen.dart:26`. A test FTP accepted three days after the ride reads the wrong day.
**Change (app only):**
1. `PowerState` (`progress_state.dart`): add `final DateTime? ftpRideDate;` (with `copyWith`). Doc comment: the day of the ride the current FTP came from, when it came from a ride; null otherwise or while unread.
2. `PowerCurveViewModel.load` (`progress_view_models.dart` ~line 115): after reading the history, when the newest entry has `source_ == 'test'` and a `rideId`, read that ride's start with the data source's existing ride-date lookup (the one `ftpRideDates` in `progress_data.dart:96` uses; check its name) and put it in the state. A failed lookup leaves it null.
3. Both note builders pass it: `ftpSourceText(l10n, newest.source_, newest.setAt, rideDate: rideDate)`. Merge the two near-identical builders into the one in `progress_screen.dart` (`ftpSourceNote`) and use it from `power_screen.dart` too; delete `_ftpNote` there.

**Tests** (in the existing Progress/FTP test files; find them with `rg -ln "ftpSource|From your ride" app/test`):
- `PowerScreen_ShouldDateATestFtpByItsRide_WhenItWasAcceptedLater`: history newest entry `source: test`, `setAt` 15 Nov, its ride started 12 Nov → the note reads "From your ride on 12 Nov 2026".
- `ProgressScreen_ShouldDateATestFtpByItsRide_WhenItWasAcceptedLater`: the same on the overview.

### Task 2: The ride's FTP suggestion names its effort
**Why:** Pack 1 Story 4 asks for "95 % of your best 20 minutes ({effort} W)". On the ride page the card gets no `effortWatts` (`app/lib/features/rides/detail/ride_detail_screen.dart:307`), so it reads "(– W)". The server has the number (`FtpSuggestion.EffortWatts`) but `RideResponse` does not carry it.
**Change:**
1. `src/Velomine.Server/Features/Rides/RideResponse.cs`: add `int? FtpSuggestionEffortW = null,` right after `FtpSuggestionId` (line ~53), covered by the same comment (owner only, copied by hand).
2. `RideResponse.WithoutTrainingLoad` (~line 134) and `PrivacyRules.ForViewer` (`Features/Privacy/Privacy.cs` ~line 120) clear it next to `FtpSuggestionW`.
3. `Features/Rides/GetRide.cs` (~line 51): `FtpSuggestionEffortW = suggestion?.EffortWatts,`. Check the query that loads `suggestion` selects the entity (or add the field to its projection).
4. `tools/generate-api-client.sh`.
5. App: `ride_detail_screen.dart` passes `effortWatts: ride.ftpSuggestionEffortW.value`. Update the doc comment in `app/lib/core/widgets/ftp_suggestion_card.dart:8` that says `effortWatts` is null on a ride.

**Tests:**
- Server, in `Analytics/FtpSuggestionTests.cs`: `GetRide_ShouldNameTheSuggestionsEffort_WhenTheRideSuggestsAnFtp` (equals the stored `EffortWatts`), and extend the existing coach/owner-only test (find it with `rg -n "FtpSuggestionW" tests`) so a coach gets null `FtpSuggestionEffortW` too.
- App, in the ride detail test file: `RideDetailScreen_ShouldShowTheEffortWatts_WhenTheRideSuggestsAnFtp` ("95 % of your best 20 minutes (263 W)" or the English text the key produces).

### Task 3: Sleep in the morning check-in
**Why:** Hooper's index is sleep, stress, fatigue and soreness; the check-in has no sleep. Auto training's "a tired morning makes today easy" will read it. Pack 3 is not built yet: this task only stores and shows sleep and feeds the existing readiness score.
**Scale:** 1 very poorly, 5 very well (higher is better, like mood).
**Change:**
1. `Features/Wellbeing/Wellbeing.cs` `DailyCheckIn`: add `public int? Sleep { get; set; }` with a `<summary>` "1 very poorly, 5 very well; null on a check-in saved before it was asked."
2. `WellbeingConfiguration.cs`: `t.HasCheckConstraint("ck_daily_check_ins_sleep", "sleep IS NULL OR sleep BETWEEN 1 AND 5");` next to the others.
3. Migration: `just migration CheckInSleep` (or `nix develop --command just migration CheckInSleep`). Read the generated file: it must only add the nullable column and the check. Never edit an older migration.
4. `SaveCheckIn.cs`: `public int? Sleep { get; set; }` in the request (**optional**, so an older app that does not send it still works; a released API is never broken). Validator: `RuleFor(x => x.Sleep).InclusiveBetween(1, 5).When(x => x.Sleep is not null);`. Save it; a check-in saved again without it keeps null.
5. `WellbeingResponses.cs` `CheckInResponse`: add `int? Sleep` and map it. Every endpoint that returns a check-in (owner and coach with the wellbeing grant) then carries it.
6. `Features/Analytics/GetReadiness.cs` (~line 71): the wellbeing average includes sleep when it is there: `(Mood + Motivation + Sleep + (6 − Fatigue) + (6 − Soreness) + (6 − Stress)) / 6.0`, otherwise the current five over 5.0. Keep the factor's name `wellbeing`.
7. `Features/Accounts/AccountExport.cs` (~line 249): add `c.Sleep` to the check-in projection.
8. Do **not** raise `WellbeingTerms.Version`: the consent text already covers "a short daily check-in".
9. `tools/generate-api-client.sh`.
10. App:
    - `app/lib/features/progress/wellbeing_card.dart`: a sleep slider first in the form (default 3), saved with the others; the summary row shows it with a short label; a check-in with null sleep shows no sleep value (not 0).
    - `wellbeing_screen.dart` and `coach/coach_athlete_screen.dart` (~line 164): show sleep next to the other scores when it is not null.
    - New keys, both files: `wellbeingSleep` en "Sleep" / it "Sonno"; `wellbeingShortSleep` (copy the style of `wellbeingShortMotivation`); the slider's end labels if the other sliders have them, en "Very poorly" / "Very well", it "Molto male" / "Molto bene".
11. Docs: `site/status/index.html` and `README.md` describe the check-in's questions if they list them (`rg -n -i "soreness|motivation" README.md site docs/architecture.md`); add sleep where they do.

**Tests** (in `Wellbeing/WellbeingTests.cs` and `Analytics/` readiness tests; copy their setup):
- `SaveCheckIn_ShouldStoreSleep_WhenItIsSent` and `SaveCheckIn_ShouldAcceptACheckIn_WhenSleepIsLeftOut` (older app).
- `SaveCheckIn_ShouldRefuseSleep_WhenItIsOutsideOneToFive` (400).
- `CheckInTable_ShouldRefuseSleepOutsideTheRange_WhenWrittenDirectly`: raw SQL, `PostgresException` with `ConstraintName == "ck_daily_check_ins_sleep"`.
- `Readiness_ShouldCountSleep_WhenTheCheckInHasIt`: same check-in with sleep 1 and sleep 5 gives a lower and a higher wellbeing factor, with the exact values from the formula.
- `CoachCheckIns_ShouldShowSleep_WhenWellbeingIsShared` and keep or extend the existing other-club isolation test for check-ins so it covers the new field.
- `AccountExport_ShouldIncludeSleep_WhenTheCheckInHasIt`. `MemberDataCoverageTests` must still pass.
- App: `WellbeingCard_ShouldSaveSleep_WhenTheRiderMovesTheSlider`, `WellbeingCard_ShouldShowNoSleep_WhenTheCheckInHasNone`.

### Task 4: Download a ride's file
**Why:** the original file of every ride is kept forever (`RideFileStore`), but a rider can get it back only inside the whole account export, and a ride read from GPX or TCX can never come back as FIT. Pack 3 will write FIT workouts; this task adds the server's FIT writing for activities first.
**How it works:** the same two-minute link as the export (`CreateExportLink` / `DownloadExport` in `Features/Accounts/`), so the phone can hand it to the system browser.
**Change (server):**
1. `Features/Accounts/UserToken.cs`: add `RideFileTokens : UserToken` (purpose `"velomine.ride-file"`, two minutes), registered where `ExportTokens` is (`rg -n "ExportTokens" src/Velomine.Server/Program.cs`). The token names the member; the download checks the ride is theirs.
2. `Features/Rides/CreateRideFileLink.cs`: `POST rides/{id}/file-link`, operation name `createRideFileLink`, request `{ format }` where `format` is `"original"` or `"fit"`. Answers `RideFileLinkResponse(string Path, DateTimeOffset ExpiresAt)` with path `/api/v1/rides/{id}/file/{token}?format={format}`. 404 when the ride is not the caller's, is a hidden duplicate, or has no stored file; 400 for another format, or `"fit"` on a ride that has no streams. Declare all of these in `Description(...)`.
3. `Features/Rides/DownloadRideFile.cs`: `GET rides/{id}/file/{token}`, `AllowAnonymous()`, query `format`. Read the token (401 when it is not valid), load the ride by id **and** that member (404 otherwise).
   - `original`: stream the stored file as received, with the ride's `FileName` and `application/octet-stream`. A multi-activity FIT is one file for several rides: return the whole file, as received.
   - `fit`: when the original is already FIT (`FileName` ends in `.fit` or `.fit.gz`, case-insensitive), return the original, decompressed when it is gzipped. Otherwise write one with `RideFitWriter` and name it after the original with `.fit` (`morning.gpx` → `morning.fit`).
4. `Features/Rides/RideFitWriter.cs`: `public static byte[] Write(Ride ride, RideStreams streams)`. Copy the message order of `TestRideFiles.Fit`: `FileIdMesg` (activity, manufacturer `Manufacturer.Development`), a timer start event, one `RecordMesg` per sample (timestamp = `ride.StartTime + Time[i]`; latitude/longitude in semicircles; altitude, speed, distance, heart rate, cadence, temperature, and **recorded** power only, never `EstimatedPower`), a timer stop event, then one `LapMesg`, one `SessionMesg` (sport cycling, start time, total elapsed and timer time, distance) and an `ActivityMesg` with the ride's local time offset. Null values are left unset. The owner gets every sample: this is their own file, not a viewer's copy.
5. `AGENTS.md`, API section, after the Export bullet: "A ride's file downloads the same way: `POST /rides/{id}/file-link` gives a two-minute link to the original as received, or to a FIT file the server writes for a ride read from GPX or TCX."
6. `tools/generate-api-client.sh`.

**Change (app):**
1. `rides` data source: `Future<Result<String?>> rideFileLink(String id, String format)` wrapping the generated call, like `exportLink` in `app/lib/features/profile/profile_data.dart:80`.
2. Ride detail ViewModel: a command returning the path; the view opens `'$serverUrl$path'` the same way the profile export does (`profile_screen.dart` `_export`, `widget.openLink`). Check how `serverUrl` and `openLink` reach the ride detail screen; follow the profile's wiring.
3. The ride page's `PageMenu` (`ride_detail_screen.dart` ~line 123): "Download original file" always; "Download as FIT" only when the file name does not end in `.fit` or `.fit.gz`. Before the divider (they are not destructive). Owner only: the coach's ride screen gets neither.
4. New keys, both files: `rideDownloadOriginal` en "Download original file" / it "Scarica il file originale"; `rideDownloadFit` en "Download as FIT" / it "Scarica come FIT".
5. `site/status/index.html`: one line under rides that the original file and a FIT copy can be downloaded.

**Tests** (server, new file `Rides/RideFileDownloadTests.cs`, setup copied from an existing upload test such as `Rides/EstimatedPowerTests.cs`):
- `DownloadRideFile_ShouldReturnTheOriginalAsReceived_WhenFormatIsOriginal`: upload a GPX; the downloaded bytes equal the uploaded bytes; the file name is the original's.
- `DownloadRideFile_ShouldWriteAFitThatReadsBack_WhenTheRideCameFromGpx`: upload a GPX with heart rate and altitude, download `fit`, parse it with the server's own FIT parser (the one ingestion uses): same number of samples, same start time, the same distance within 1 %, heart rate present.
- `DownloadRideFile_ShouldReturnTheOriginalFit_WhenTheRideIsAlreadyFit`.
- `RideFitWriter_ShouldLeaveOutEstimatedPower_WhenTheRideHasNoPowerMeter` (pure: streams with only `EstimatedPower` → no power field in any record).
- `CreateRideFileLink_ShouldAnswer404_WhenTheRideBelongsToSomeoneElse`.
- `DownloadRideFile_ShouldAnswer404_WhenTheTokenIsAnotherMembers`: member A's token on member B's ride.
- `DownloadRideFile_ShouldAnswer401_WhenTheTokenHasExpired` (advance the test clock past two minutes, as the export tests do).
- `CreateRideFileLink_ShouldAnswer400_WhenTheFormatIsUnknown`.

**App tests** (ride detail test file):
- `RideDetailScreen_ShouldOfferAFitDownload_WhenTheRideCameFromGpx`.
- `RideDetailScreen_ShouldOfferOnlyTheOriginal_WhenTheRideIsAlreadyFit`.
- `RideDetailScreen_ShouldOpenTheDownloadLink_WhenTheRiderChoosesIt` (the fake server returns a path; the opened address is the server URL plus that path).

## Done when
All four tasks are committed, the full `just check` passes once at the end, and the git status is clean. Report: the commits, the `just check` result (server and app test counts), anything that did not match this story and what you did about it.
