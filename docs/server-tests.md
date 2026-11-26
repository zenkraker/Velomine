# The server test suite, and where its time goes

What runs, when it runs, what it cost, and what was done about it. Measured on a 16-core dev container with a warm
build.

**Read durations carefully.** A time printed during a full parallel run is how long a test waited, not how long it
worked: 138 classes fight over 16 cores, so a class that costs 29 seconds alone reports 176 in the run. Only a class
run alone gives an honest number.

## When anything runs

There are no git hooks. Nothing runs on save or on commit. Three gates:

| Trigger | What runs |
|---|---|
| `just check`, by hand before a commit | `just check-server`, then the Dart half (`build_runner`, `dart format`, `flutter analyze`, `flutter test`, the Android Kotlin tests) |
| A pull request opened or updated | `.github/workflows/ci.yml`, six jobs in parallel |
| A push to `main`, `dev` or a version tag | `release.yml` calls `ci.yml` first, then builds and smoke-tests the images |

`just check-server` is two commands:

```
dotnet format Velomine.slnx --verify-no-changes    ~32s   formatting only
dotnet test --solution Velomine.slnx               ~200s  everything else
```

## Result

| | before | now |
|---|---|---|
| tests | 1450 | 1408 |
| full `dotnet test`, build included | 459s | **about 162s** (162, 162, 163 on three runs) |
| `Demo` namespace | about 256s (60% of the run) | 54s when last measured, before the seed tests went |
| `DeploymentTests` | 75s alone | about 13s |
| `Bikes/MaintenanceTests` | 29s alone | 14s |

Every full run along the way passed, with `dotnet format` clean: 1435 tests at 249s, 1422 at 213s, 204s, 200s, then
1408 at 162s.

The five largest remaining classes, run alone (about 7s of each is the test process starting):

| class | alone before | alone now |
|---|---|---|
| `RoutesTests` | 52s | 40s |
| `TrainingTickTests` | 32s | 28s |
| `RideIngestionTests` | 31s | 21s |
| `TrainingAdaptTests` | 27s | 19s |
| `FtpSuggestionTests` | 27s | 21s |

### What was already tuned, and left alone

- One `postgres:17` container for the whole run, with the data directory in memory (`PostgresFixture`).
- Migrations run **once** into a template database; every test clones it.
- `TestHost.RemoveJobs` drops the hosted services that only repeat on a timer.
- `VELOMINE_TEST_POSTGRES` reuses an existing server when one is available.

What is left is the per-test cost: **0.7–1s for every test that starts a server** (`TestApi.StartAsync`: a fresh
`WebApplicationFactory`, a cloned database, a register and a login). Most of the work below was removing server starts
and resets that bought nothing.

## What was done

### `DeploymentTests`: 14 tests to 12

- **Deleted** `Uploads_ShouldAcceptThemAgain_WhenTheBucketHasRefilled`. It slept a real `Task.Delay(62s)` to wait out a
  refill period hardcoded at `src/Velomine.Server/Program.cs:168`, which re-tests Microsoft's `TokenBucketRateLimiter`.
  The 429 test beside it already proves our wiring. Only a typo in the one-minute period is no longer caught; a review
  sees it. It was the only real sleep in the suite.
- **Deleted** `BackgroundJobs_ShouldNotRepeatOnATimer`. It checked `TestHost`, the test fixture, by class-name
  substring, not the product. A hosted service that `TestHost` does not strip now shows up as flaky tests, not as one
  named failure.
- Kept: the Data Protection key ring reaches the disk, the 429s for login, register and upload, and the password reset
  throttle.

### `Demo/`: 48 tests to 22

The demo seed is an 872-line SQL script (`demo-seed.sql`) plus `DemoData`. A reset costs about **9 seconds** (it was
not profiled), and the old tests did 34 of them.

- **`DemoTests`** keeps what is about demo mode: the `DemoLock` route walk (the only check that a route in
  `DemoLock.Refused` really exists), email suppression, `ServerInfo`, the nightly `DemoResetService` clock and
  `LastBoundary`, "skip the rest of the week is refused", and one test that a reset undoes what a visitor did. That one
  merges the old "undo", "rider mode" and "keeps the admin" tests; no assertion was dropped. The lock and email tests
  no longer reset: the lock answers before an endpoint runs, so the server admin is enough.
- **`DemoTrainingTests`** is deleted. Apart from two checks that moved into `DemoTests`, it re-tested `Training/`
  behaviour through the demo.
- **Deleted** seven "the demo's charts aren't empty" tests (critical power fit, W' balance, decoupling, efficiency
  trend, intensity, power record, FTP history). Each re-checked an analytics feature that has its own test.
- **Added and then deleted** `SeededDemoTests`, which shared one reset across tests that asserted the seed's numbers
  and its Girona coordinates. It tested the seed script, not a feature.
- **Consequence:** the demo seed has no test. A broken seed shows in the public demo and nowhere else. A seed change
  that leaves a demo chart blank is not caught.
- Left alone: `DemoTrainingWeekTests`, pure unit tests with no server.

### `Bikes/MaintenanceTests`: 36 tests, 14s

Nothing was deleted. Reminders and the service log hang off `BikeId`, so the export, account-deletion and bike-delete
tests here are the only guard for those tables.

- **One server for the class** (`MaintenanceHost`, a class fixture), instead of 28.
- **One shared member** for the 19 tests that only touch their own bike. Each still makes its own bike, which is what
  isolates them. The other 9 make their own member, because they read something that belongs to the whole member (its
  notifications, its bike list, the export or the deletion) or need a second member to prove isolation.
- **A shared server needs `Velomine:RateLimits:AnonymousPerMinute` raised.** It is 60 a minute per IP and every test
  client has the same IP, so ten tests failed with 429 on the first shared run. Separate servers each had a fresh
  budget. Any other class moved to a shared host needs the same setting.

### `MemberDataCoverageTests`: deleted

It walked the EF model for every entity with a `UserId` and failed when one had no export file, and it checked the
deletion left no rows. Its deletion half proved nothing for most tables: it only created rows for some of them, and
its own comment says "A member with nothing in a table is fine", so a table it never filled passed as 0 equals 0.
The per-feature export and deletion tests (reminders, FTP suggestions, routes, and so on) stay.

**Consequence:** the rule in `AGENTS.md` ("a new table with member data goes into the export and the deletion cascade
in the same change", also `docs/rules/server.md`) is no longer enforced by any test. A table added later can be
missing from the export or the account deletion without anything failing. Those two documents still state the rule.

### The export-link flake: cause found and fixed

`FtpSuggestionTests.AccountExport_…` once got a 401 downloading its export link. The link is a two-minute
data-protection token. `ExportTokens.Issue` stamps its expiry from the injected clock, but the data-protection
`Unprotect` checks it against the real system clock. The class pinned the clock to `FixedTime(Now)`, with `Now` taken
once when the class started, so after about two minutes of wall clock (a long class under load) every new link was
already expired.

Reproduced with a temporary test (deleted afterwards): a clock frozen 3 minutes ago gives **401**, a clock that starts
at the real time and keeps moving (`OffsetTime(DateTimeOffset.UtcNow)`) gives **200**.

Fixed in `FtpSuggestionTests` and `HeartRateDetectionTests` (their export tests now start their server with
`OffsetTime(DateTimeOffset.UtcNow)`; every other test keeps its deterministic clock) and in `FtpHistoryTests` (its
`OffsetTime(Now)` took a start time captured at class start, which lags the same way). `ZoneBoundsTests` and
`HeartRatesTests` already used this fix. It is a test-design bug, not a server bug: production uses the real clock.

### Shared servers for five more classes

`FtpSuggestionTests`, `TrainingTickTests`, `TrainingAdaptTests`, `RideIngestionTests` and `RoutesTests` each got a class
fixture (`…Host`) that starts one server for the class, with `RequireAdminApproval` off and
`Velomine:RateLimits:AnonymousPerMinute` raised. Every test still makes its own member (or its own "world", in
`RoutesTests`). Tests that need something server-wide keep their own server:

- a database trigger on a shared table: `Tick` and `Adapt` (the "first save loses the session" and the three
  "the night replaced the session" tests)
- a clock of their own: `Adapt` (the 07:00, 06:59 and 07:30 sweeps, and the one that moves the clock), `Tick` (+2 days,
  +10 days), `RideIngestion` (a fixed date), and the export test in each class that has one
- a scan of the whole files directory: four tests in `RideIngestionTests`
- a restart, or an interceptor registered in DI: one test each in `RideIngestionTests`
- a database-wide count: three tests in `RoutesTests`

Twenty test runs of the five classes all passed, five each, and three full runs.

### Duplicates cut, after checking each pair

Overlaps came from agents that only grepped, so every pair was read again before anything was deleted. Several first
calls did not survive, which is why this list is shorter than the first one.

Deleted or merged (the unique assertion moved first):

- `RideIngestion`: the single-upload notification test (the notifications test is strictly stronger), the "running ride
  is not cycling" test (same code path as the failure theory, and the parser tests), the member list paging test (its
  bad-cursor 400 moved into `RideTitleTests`, whose test already covers the member list's own paging), and the "no
  laps" test (now a second upload inside the laps test).
- `TrainingTick`: the three sub-sport cases (one case left; no code path differs) and the sensorless 50/50 score test
  (its null-main-set assertion moved into the time-alone test).
- `TrainingAdapt`: the notification-content test (its inbox assertions moved into the poor-sleep check-in test).
- `Routes`: the owner-unshare test (its two assertions moved into the club-owner test) and one redundant GPX row.
- `FtpSuggestion`: the effort-on-the-ride test (one assertion added to the creation test) and the coach test, which
  asserted three fields the coach endpoint never fills, so it passed whether or not the redaction worked. The real
  guard, `PrivacyRulesTests.ForViewer_ShouldClearTheRidersOwnAnswers`, now sets those fields too. It passed, so
  `ForViewer` does clear them.

Kept on purpose, because each guards something no other test does: the one-hundred-on-time-alone score test and the
"not asked when too far from the plan" test (`Tick`), the beside-the-long-ride message (`Adapt`), the unknown-discipline
test (a separate validator from the list filter), the laps and streams hidden-from-non-owners tests (separate checks
in separate endpoints), the dimensions test (the parser test stops before the stored row), the three "no club gives 404"
route tests (three separate call sites), the line-thinning test, and the 20-minute-branch test (the only one that
fails if the unused 30-minute path comes back).

Left alone: the "reach one hundred" test in `TrainingTickTests`, which could become a theory with the 150 W test; it
would save no time and needs conditional asserts.

## What was not done

- **The reset itself.** About 9s per `DemoData.ResetAsync`; nobody knows where inside it. It matters for the nightly
  reset and for `just up`, not only for tests.
- **A shared "world" in `RoutesTests`.** Each test still builds 6 members, 2 clubs and about 14 anonymous calls, which is
  most of that class's 40s. Tests that change the club's route list would see each other; not tried.
- **Other classes.** The same shared-server treatment would apply to most of the remaining classes. They were not
  measured alone or checked for being safe to share.
- **The Dart and Kotlin half of `just check`** (`flutter test`, the Gradle unit tests), the web and APK build jobs, and
  CI wall time. None of it is measured here, and none of it is the server gate.
