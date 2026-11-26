# Server and data rules

Binding rules for the server, clubs and isolation, data, ride processing and the shared parts catalogue. Moved verbatim from `AGENTS.md`, which keeps the short version and links here. Same authority: where this file and a skill disagree, this file wins.

## Server

- **Stack:** .NET 10 (LTS), ASP.NET Core, EF Core, PostgreSQL. One project, `src/Velomine.Server`.
- **Vertical slices.** Code lives in `Features/<Area>/`, one file per use case (request, response, validation, endpoint, logic). Slices use `VelomineDbContext` directly: no repositories, service layers or mediators. Code moves to a shared place only when a second slice needs it.
- **Endpoints use FastEndpoints**, one endpoint class per slice, validated by the endpoint's validator.
- **Server errors are HTTP.** Expected failures use status codes and ProblemDetails (`400`, `401`, `403`, `404`, `409`, `423`, `429`, `502`, and `503` for a feature the operator has not configured, such as email). Exceptions are for bugs only. Never wrap a response in a custom `Result` envelope: HTTP is the result, and the generated client depends on it.
- **One PostgreSQL schema per feature area.** A feature's tables live in its own schema; slices may read another area's tables when they need to.
- **The server image is API-only** (`Dockerfile`): the API, health, the OpenAPI document and background work. It never serves front-end files; the web image does, and reaches it as `server:8080`.
- **Background work runs in the server** as hosted services: a `Channel<T>` read by a `BackgroundService` for queues, `PeriodicTimer` for schedules. No message broker, no job framework, and no FastEndpoints job queues or messaging. A timed task recomputes what it needs from the data, so a missed run is caught up next time.
- **Background work on one instance.** Ingestion, email, catalogue sync and contributions run only where `VELOMINE__BACKGROUND__ENABLED` is `true`. Migrations run on every instance under EF Core's migration lock.
- **Demo mode** (`VELOMINE__DEMO__ENABLED`) answers 403 `demo_locked` to the actions in `DemoLock.Refused`, and remakes the demo accounts, club and data every night at 03:00 UTC from `Features/Demo/`. A new endpoint that would let one visitor lock out or remove another goes into `DemoLock.Refused` in the same change.
- **Migrate forward.** Migrations are additive and backward-compatible for one release: expand, backfill, contract. Never drop a column in the release that stops using it. Never edit an applied migration.
- **Configuration** is environment variables bound with `IOptions<T>` and validated on start. A self-hoster can run with environment variables only.
- **Don't reinvent the wheel.** Use what .NET, ASP.NET Core, EF Core and official Microsoft libraries provide: Identity, authentication, rate limiting, Data Protection, health checks, hosted services, `Channel<T>`, `TimeProvider`. Write it yourself only when nothing official fits.

## Clubs and isolation

- **One schema for both deployments.** Cloud runs one database with many clubs; self-host runs the same schema with one club. There is no tenant catalog, no per-club database and no host-based tenant resolution.
- **The member owns their data; the club does not.** Rides, bikes, goals, wellbeing and profile belong to a user, and a user may have no club. A club never reads member data through membership alone.
- **Club tables carry `club_id`.** Tables that describe a club (clubs, memberships, join requests, sharing grants) have a non-null `club_id`. A query on them is always limited to the clubs the caller belongs to or administers.
- **Access is owner or grant.** An endpoint that returns member data to anyone but the owner checks an active grant for that data type, audience and club. Club admins get no member data from their role.
- **Isolation is tested.** Every endpoint or job that touches club data has a test proving another club cannot see it, for example `ClubData_ShouldNotBeVisible_WhenRequestComesFromAnotherClub`.

## Data

- Instants are `timestamptz` in UTC; a ride also stores its local time zone offset. SI units internally; format only in the UI.
- Keys are `uuid`; a ride recorded on the phone keeps the phone's id. Table and column names are snake_case.
- Constraints live in the database: `NOT NULL`, foreign keys, unique and check constraints.
- Rides carry an EF Core concurrency token, so two edits never silently overwrite each other.
- Streams are one row per ride in `rides.ride_streams`, one PostgreSQL array column per signal, aligned by index; a missing signal is null.
- Best mean maximal power per duration is stored per ride in `rides.ride_power_bests`; the power curve never reads the stream arrays.
- Original ride files are kept as received, forever, so any ride can be read again when a parser improves.
- **A change to parsing or to a ride metric raises `RideParserVersion.Current` in the same change.** Each ride records the version it was read with; the server reads older rides again from their original file in the background, keeping the member's own edits and the FTP and maximum heart rate of the first read.
- Privacy defaults and the default bike are copied onto a ride at import, so changing a default never changes or exposes older rides.
- **Stored or computed on read:** *Stored or computed* in `docs/training-models.md` decides which ride numbers are written and which are recomputed on every request. A number that becomes stored follows the `RideParserVersion` rule above.
- A heart-rate number keeps how it was set (`manual` or `measured`) and the ride that measured it in its own column on the account, which that ride's deletion empties; `heart_rate_history` records every change. Both numbers come from `HeartRates.For` in `Features/Accounts/`, which reads those columns and needs no history lookup.
- **Export and deletion cover every table a member owns.** A new table that holds member data is added to the export and to the deletion cascade in the same change.
- A ride that came from another app records that app and the activity id, so the same activity is recognised when a later export lists it again.

## Ride processing

- FIT with `Garmin.FIT.Sdk`; GPX and TCX with the BCL XML APIs, reading every common extension (`gpxtpx:hr`, `cad`, `speed`, `atemp`, `PowerInWatts`). Gzipped files are accepted.
- Reading happens in the server, in the ingestion background service. The original file is kept as received and every number is derived from it, so a parser improvement costs a re-read and never the file.
- **Every training and physiology number follows `docs/training-models.md`.** It names each formula, constant and source, and where the code must match it. A change to a formula, a constant or a source updates that document and its test in the same change.
- Every formula has a test against known values.
- What a ride becomes — one ride per FIT activity, how a duplicate is recognised, what a Strava export yields, which source a speed has, the fallbacks for a rider without power — is `README.md`, *How rides are processed*. The code must match it.

## Shared parts catalogue

- The instance mirrors the publisher's complete list from `VELOMINE__CATALOGUE__URL` every hour: `{ "parts": [{ "type", "brand", "model", "mpn", "gtin" }] }`. It upserts every part, retires the ones left out, and computes each key itself with the same rules as member input. A failed fetch leaves the catalogue untouched. The bundled `parts-seed.json` has the same shape and only bootstraps an empty database.
- Members never write to the catalogue. A non-custom part the publisher does not list waits in the contributions table and is posted to `VELOMINE__CATALOGUE__CONTRIBUTEURL` with `Authorization: Bearer {ContributionKey}` as `{ "parts": [{ "key", "type", "brand", "model", "mpn", "gtin" }] }`. The answer `{ "accepted": [...], "rejected": [{ "key", "reason" }] }` moves each row to sent or rejected; a failed send backs off. The payload carries no member, bike, club or address. A custom part is never sent.
- The contribution key comes from configuration only.

