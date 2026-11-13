# Server test suite: parallelization and audit — handoff

Branch `feat/parallel-tests`, worktree `/tmp/nix-shell.26e4ms/opencode/velomine-parallel`, based on
`origin/main` @ `8b6a57f`. Not pushed, no PR.

**Result: 712 tests, 0 failures, 1m25s** (was 697 tests in 5m08s). Five consecutive full runs green; a run
against an external `VELOMINE_TEST_POSTGRES` server also green, leaving no database behind; `dotnet format
--verify-no-changes` clean.

If you have uncommitted work in `tests/Velomine.Server.Tests/`, read **Where your work overlaps mine** at
the end before merging.

---

## Parallelism story

### Task 1 — baseline
Three runs of `dotnet test --solution Velomine.slnx` before any change: **5m08s / 5m07s / 5m06s** for 697
tests. Ten slowest classes (sum of their test durations):

| Class | Time |
|---|---|
| `Routes.RoutesTests` | 28.5 s |
| `Rides.RideIngestionTests` | 21.9 s |
| `Bikes.MaintenanceTests` | 17.6 s |
| `PasswordTests` | 13.3 s |
| `Rides.RideTitleTests` | 13.3 s |
| `Calendar.CalendarTests` | 12.3 s |
| `Rides.StravaImportTests` | 12.0 s |
| `Clubs.ClubPlanTests` | 11.3 s |
| `Analytics.AnalyticsTests` | 11.1 s |
| `Rides.RideReparseTests` | 9.6 s |

### Task 2 + 3 — assembly fixture, parallel use
The audit deletions (Stories 14/15) were applied **before** these, per the agreed ordering, so the class
count is 35 rather than 39 by the time storage changed.

| File | Change |
|---|---|
| `tests/Velomine.Server.Tests/PostgresFixture.cs` | **`PostgresCollection` class DELETED.** `[assembly: AssemblyFixture(typeof(PostgresFixture))]` and `[assembly: AssemblyFixture(typeof(DexFixture))]` added at the top of the file (assembly attributes must precede the namespace). `List<string> databases` → `ConcurrentBag<string>`. `.WithCommand("-c", "max_connections=500")` on the builder. `CreateDatabaseAsync` caps `MaxPoolSize = 5` **only** when `VELOMINE_TEST_POSTGRES` is set. `.WithTmpfsMount("/var/lib/postgresql/data")` on the builder (Task 5, kept). |
| every test class that carried `[Collection("postgres")]` | The attribute line is removed. Constructors unchanged — they already took `PostgresFixture` / `DexFixture`, which is how an assembly fixture arrives. |

Measured after Task 2 alone: **1m40s** (from 5m08s), but 21 failures from connection exhaustion, which the
`max_connections` and pool-cap changes fixed.

**Method note:** Task 2 and Task 3 landed in one commit (`02836db`) rather than two, because Task 2 on its
own does not pass — the connection limit is the first thing that breaks. The commit message covers both.

### Task 4 — shorter waits
| File | Change |
|---|---|
| `tests/Velomine.Server.Tests/TestApi.cs` | `UploadAndWaitAsync` polls every **20 ms** (500 × 20 ms = the same 10 s limit). New `WaitForReadAsync(client, id)` — the poll without the upload. New `WaitForNotificationAsync(client, type)` — waits for the notification the reader writes *after* it marks the ride ready. |
| `Rides/RideTitleTests.cs`, `Bikes/BikesTests.cs`, `Bikes/MaintenanceTests.cs`, `Rides/RideIngestionTests.cs`, `Rides/StravaImportTests.cs`, `Wellbeing/WellbeingTests.cs`, `Sharing/RideTextSharingTests.cs`, `Admin/EmailTests.cs`, `Routes/RoutesTestKit.cs` | **The private "upload and wait" copies are DELETED**; each is now a one-line delegation to `TestApi`. Signature changes: `Bikes/BikesTests.UploadRideAsync` and `MaintenanceTests.UploadAndWaitAsync` now return `Task<RideResponse>` / `Task` instead of carrying their own loop. |
| `Rides/RideReparseTests.cs` | `WaitWhileProcessingAsync` delegates to `TestApi.WaitForReadAsync`. The fixed `Task.Delay(1500)` in the queue test became a 300 ms settle (the assertion is "still running", not a wait for a result). |
| `PasswordTests.cs` | The fixed `Task.Delay(300)` became a poll on the token provider's clock. |

### Task 5 — tmpfs: **kept.** The data directory is in memory; clones of the migrated template are file copies.

### Task 6 — fewer servers
| File | Change |
|---|---|
| `tests/Velomine.Server.Tests/ProfileTests.cs` | Class now implements `IAsyncLifetime`; one `TestApi` started in `InitializeAsync` and shared by the 8-row invalid-profile theory (every row only sends a refused update). |
| `tests/Velomine.Server.Tests/ServerInfoTests.cs` | Class implements `IAsyncLifetime`; one default server shared by the front-end-path theory. |

No other theory shares a server: the rest write data or start with different settings.

### Task 7 — parallel *inside* a class: **NOT DONE (dropped).** `[assembly: Parallelization(Mode = ParallelMode.All)]`
is not set. It was the optional stretch goal, and with the audit work and the flake analysis still open at
the time it was the right thing to leave out. The suite is stable at class-level parallelism, which is
where the 3.6× came from.

---

## Audit stories

### Story 1 — privacy defaults copied at import: **verdict: the copy does NOT exist.**
No privacy, hide or trim field is stored on a ride: `Features/Rides/Ride.cs` has no privacy property, and
`RideIngestionService` never reads privacy settings. `PrivacyRules.LoadAsync` (Features/Privacy/Privacy.cs:96)
reads the member's **current** `PrivacySettings` on every non-owner view. Consequence, for the owner to
decide: **relaxing a privacy default today changes how older rides are shown to viewers** — the opposite of
what `AGENTS.md` promises. Not built, `AGENTS.md` unchanged. This is a real bug, reported, not fixed.

The second half of Story 1 is done: the default bike *is* copied onto a ride at import
(`target.BikeId ??= DefaultBike.For(...)` in `RideIngestionService`), and `Bikes/DefaultBikeTests.cs` plus
`UploadRide_ShouldUseTheBikeForItsDimensions_WhenTheMemberHasSeveral` already pin it, so no test was added.

### Story 2 — real contribution payload: **DONE.** `Bikes/ContributionsTests.cs`
`StubHandler` now records `LastBody`; the test pushes to the stub and asserts the part object's property
names are exactly `brand, gtin, key, model, mpn, type`. The old serialize-and-grep copy of the production
formatting is deleted.

### Story 3 — two-server "tenant" tests: **DONE.**
- `SessionsTests.cs` — rewritten as two members on **one** server: A revoking B's session gets 404 and B's
  refresh still works (`Sessions_ShouldBelongToTheirMember_WhenAnotherMemberTriesToRevokeThem`).
- **DELETED:** `PrivacyTests.cs` "token from another tenant", `Bikes/PartCatalogueTests.cs` "not visible",
  `Bikes/TemplateTests.cs` "not visible". `TelemetryTests.cs` "not cross tenants" became
  `Telemetry_ShouldBeEachMembersOwn_WhenTwoMembersShareTheServer`.
- Replacement second-member coverage: `Privacy_ShouldBeEachMembersOwn_WhenTwoMembersShareTheServer`,
  `PartCatalogue_ShouldBeSharedByEveryMember_WhenThePublisherListsThePart`,
  `Template_ShouldBeEachMembersOwn_WhenTwoMembersShareTheServer`.

### Story 4 — wrong-thing tests: **DONE.**
`StravaImportTests` sign-in now posts to `/api/v1/rides/imports` (and is additionally covered by the
endpoint walker). `RideReparseTests` batch test renamed to `Reparse_ShouldReadEveryRideAgain_WhenManyAreWaiting`
— its assert is "every ride re-read", not order or batch size, so it is named for what it proves; the
tautological `Assert.Equal(45, ids.Count)` is gone. `CatalogueTests` now runs a failing fetch then a good
one and asserts the second is applied.

### Story 5 — Tanaka clock: **DONE** (the only `src/` change).
`User.EstimateMaxHeartRate(int? birthYear, TimeProvider time)`; `MaxHeartRate` property and
`RideIngestionService` pass the clock. `ProfileTests` asserts the literal **183**. New
`MaxHeartRateTests.cs`: known values (1986→180, 1990→183, 2000→190, 1976→173), age clamp at 10 (2025→201)
and at 100 (1926→138), null without a birth year.

### Story 6 — password/upload limits: **PARTIAL — see the finding below.**
Two throttle tests in `DeploymentTests.cs`, both on an injected clock:
`PasswordResetThrottle_ShouldStartAFreshWindow_WhenTheWindowHasPassed` passes;
`PasswordResetThrottle_ShouldRefuseTheTwentyFirstAttempt_WhenTheWindowHasNotPassed` is **`[Fact(Skip=…)]`**.
The upload token-bucket refill test was **not added**.

**Finding (production bug, not fixed):** `PasswordResetThrottle.Allowed` (Features/Accounts/PasswordResetThrottle.cs:22-37)
writes the counter with `AbsoluteExpiration = counter.Start.Add(Window)` after incrementing. On the next
call that expiry is in the past (by milliseconds), MemoryCache treats the entry as expired, and the count
restarts — so **the limit never refuses anything**. Measured directly: 25 of 25 allowed in a window. Fixing
it is a `src/` change beyond Story 5's allowance, so it is reported here; the skipped test states the
intended rule and will go green when the cache expiry is removed or set relative to `now`.

### Story 7 — sessions and two-factor: **DONE** (`SessionRevocationTests.cs`, new).
Password change ends every session (both refresh tokens refused); the admin two-factor reset ends every
session of that account; enabling two-factor signs the other devices out; disabling it with a wrong password
is refused (and login still asks for a code); a revoked cookie stops working. SSO bypassing the code and the
wrong-2FA-code-counts-toward-lockout case were **not** added — see the checklist at the end.

### Story 8 — privacy function for viewers: **DONE** (`Privacy/PrivacyRulesTests.cs`, new, 10 tests).
End trim; a zone mid-ride; a zone over the whole line; every stream switch; positions hidden without the
routes grant; IF/TSS/zone null when power hidden; TRIMP/HR zones null when heart rate hidden; speed/cadence/
climb; title and description kept; laps redacted like the summary; nothing changed when everything is shared.

### Story 9 — club isolation: **DONE** (`Clubs/ClubCrossClubTests.cs`, new, plus calendar).
Another club's owner cannot decline its join request (404) or change a real member's role (404, role
unchanged); a member of another club gets 404/403 on the athlete summary, rides, ride, streams, laps,
power curve and wellbeing. Calendar: `Calendar/CalendarFeedSecrecyTests.cs` asserts the feed carries none of
another club's rides, and that only the SHA-256 is stored (32 bytes, equal to
`CalendarFeedTokens.Hash(secret)`, secret absent from every column) and the address is shown once.

### Story 10 — export, deletion, background flag: **DONE.**
`MemberDataCoverageTests.cs` (new) walks the EF model for every entity with a `Guid UserId` (excluding
Identity's own link tables, which the framework cascades) and fails if the table is not in the map — so a new
member table cannot be added without joining the export and the deletion. It asserts each export file is
present and each listed table holds the rows the test wrote; a second test deletes the account and asserts the
tables are empty. `DeploymentTests.BackgroundJobs_ShouldNotRun_WhenBackgroundIsDisabled` now asserts that of
Velomine's own hosted services, **only `DatabaseMigrator`** is registered (the framework's telemetry, key and
health services are filtered out by assembly).

### Story 11 — ride formulas: **PARTIAL.**
`Rides/RideFormulaTests.cs` (new): power-zone boundaries at 55/75/90/105/120/150 % with 0 W excluded, zone
watt ranges, heart-rate boundaries with the 50 % floor (under it lands in no zone), TRIMP with known weights,
TSS/IF at FTP, pause threshold at a 10 s cadence, normalized power, elevation descent/spike/climb. The Sharing
test now asserts **599 zone-seconds in heart-rate zone 4 and power zone 3** for a known ride.
**Not covered:** zone seconds follow the *current* profile while TSS stays at first-read (no test); duplicate
windows (±60 s, 200 m, 2 %, two minutes); fitness/fatigue/form; a known readiness score. The duplicates live
in `RideMatchTests` and were left alone as "leave alone".

### Story 12 — Strava import and reparse: **PARTIAL.**
`Rides/StravaImportArchiveTests.cs` (new): archive deleted when finished; photos and other files ignored; a
ride records `Source = "strava"` and its activity id; an entry name that climbs out of the archive is not
read and the import still completes. **Not added:** reparse keeping the first read's max heart rate, and
reparse keeping the member's title and description (both are asserted indirectly by
`RideReparseTests.Reparse_ShouldRefreshDerivedNumbersAndKeepWhatTheMemberDecided_...`).

### Story 13 — catalogue, contributions, consent: **PARTIAL — and a contradiction.**
`Bikes/CatalogueLifecycleTests.cs` (new): a changed name is applied; a retired part comes back **once**; a
backed-off contribution is not pushed again before its next attempt. **Not added:** a new wellbeing consent
version asks again.

**Contradiction to resolve:** Story 13 wants "a retired part comes back when re-listed" but Story 14 tells
me to delete `ContributionsTests.cs:112` (`CatalogueContributions_ShouldNotQueue_WhenThePublisherAlreadyListsThePart`)
on the grounds that `PartCatalogueTests.cs:107` covers it. I deleted it. I also deleted
`PartCatalogueTests.cs:124` (the GTIN match) on the grounds of `:93` + `PartIdentityTests.cs:16` — `:93`
covers the name match, and `PartIdentityTests` covers the key, but **the end-to-end GTIN→PartId link is no
longer asserted anywhere**; I judge `:124` the stronger of those two and would have kept it. Your call.

### Stories 14 and 15 — deletions and merges: **DONE.**
Deleted exactly the list in Story 14 plus the duplicated fetch-only catalogue test. Merged:
- **`SignInRequiredTests.cs` (new)** replaces all eight per-endpoint 401 tests: it reads `/openapi/v1.json`,
  takes every operation with a `security` requirement, skips a named allow-list (register, login, 2FA login,
  refresh, forgot, reset, export download, share view, calendar feed, route download), calls it unsigned and
  asserts 401 (or 415 for multipart, where the form reader answers first). **148 operations.**
- Route trim folded into `CreateRoute_ShouldKeepTheWholeLine_WhenThePrivacySettingsTrimNothing`.
- Email sender type folded into `EmailSettings_ShouldSendNothingAndAnnounceNothing_WhenSmtpIsMissing`.
- `SiteTests` reduced to the canonical-address theory (the site lint is not server behaviour — it belongs in
  `tools/`, which is not done here).
- Theory rows halved: service jobs (2 rows), map fallback (2), front-end paths (2), notification sentences
  (now 9 rows covering both the sentence and the kind), sites.
- `NotificationKindsTests` and `ClubPlanTests` constant tables removed.

### Story 16 — tighten: **DONE.** Seeded catalogue asserts **exactly 44**; route thinning uses the 5,000-point
maximum and asserts the result is under it; `SharingTests` asserts zone seconds (599 in zone 4 / zone 3);
`BikesTests` asserts named component types and their typical distances.

### Story 17 — helpers: **DONE in part.** One "upload and wait" (`TestApi`); `RoutesTestKit.Member` replaced by
the shared `TestMember`; the `_ = userId; _ = otherId;` and `_ = athleteEmail;` leftovers removed. **Not
done:** real-device FIT/GPX/TCX fixtures with pinned values, and a shared `CreateClubAsync` across all nine
copies (only `RoutesTestKit`'s and the duplicate `Member` were unified).

---

## Where your work overlaps mine

Files with a structural change — reconcile rather than re-apply:

1. `tests/Velomine.Server.Tests/PostgresFixture.cs` — **`PostgresCollection` no longer exists**; assembly
   fixtures instead. Any test class you added that carries `[Collection("postgres")]` must lose it and keep
   taking `PostgresFixture` in the constructor.
2. `tests/Velomine.Server.Tests/TestApi.cs` — `UploadAndWaitAsync` (20 ms poll), plus new
   `WaitForReadAsync` and `WaitForNotificationAsync`. Use these instead of any private loop.
3. `tests/Velomine.Server.Tests/SignInRequiredTests.cs` — new; if you added a "401 when not signed in"
   test, delete it and make sure your endpoint appears in the OpenAPI document.
4. `tests/Velomine.Server.Tests/MemberDataCoverageTests.cs` — new; a **new table with a member id fails it
   until it is in `ExportFiles` and in the exporters map**. This is deliberate.
5. Deleted test methods (Story 14) and the eight merged 401 tests — if you were editing one of them, it is
   gone; the behaviour is still covered as noted above.
6. `tests/Velomine.Server.Tests/Routes/RoutesTestKit.cs` — `Member` is now `TestMember`.
7. `src/Velomine.Server/Features/Accounts/User.cs` — `EstimateMaxHeartRate` takes a `TimeProvider`.

## Open items for the owner
- **Privacy copy-on-import is not implemented** (Story 1) — relaxing a default exposes older rides today.
- **`PasswordResetThrottle` never refuses** (Story 6) — its own cache expiry expires the counter.
- `PartCatalogueTests.cs:124` (GTIN → PartId end to end) was deleted on the plan's instruction; I would keep it.
