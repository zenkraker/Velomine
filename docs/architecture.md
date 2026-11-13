# Velomine architecture

How Velomine is shaped: one application, one database, clubs and members, and how it is deployed. This document describes the system at a high level and records the decisions behind it. The code rules that implement it are in [`AGENTS.md`](../AGENTS.md), the product rules in [values](design/values.md), what works today on the [status page](../src/Velomine.Server/site/status/index.html), and inter-club ideas in [v2](design/v2.md).

It describes only what is decided. Features that are not built yet are on the status page, not here.

## 1. Goals and constraints

- **Simple to run.** One application image and one PostgreSQL database, for the cloud and for a self-hosted club alike. No microservices, brokers, caches or extra services; scale by running more instances behind a proxy.
- **Cycling only.** Every model, screen and metric is about bikes and rides.
- **Private by default.** Nothing a member records is visible to anyone else until the member shares it, and every share can be revoked.
- **Members own their data.** Full export (original files and JSON) and complete deletion, whether or not they belong to a club.
- **Small clubs.** A club has up to about 1,000 members; a cloud deployment serves many such clubs.
- **Official before community.** .NET, ASP.NET Core, EF Core and official libraries first (the rule is in `AGENTS.md`).

## 2. System context

```mermaid
flowchart LR
  M[Flutter phone app] --> HOST[Deployment host]
  B[Browser] --> HOST
  U[Bike computer files] --> HOST
  HOST --> WEBIMG

  subgraph WEBIMG["Web image: nginx"]
    WEBAPP[Flutter web app]
    SITE[Presentation site]
  end

  WEBIMG -->|/api, /health, /openapi| APP

  subgraph APP[".NET 10 application, server image"]
    API[REST API /api/v1]
    BG[Background services]
  end

  APP --> PG[(PostgreSQL<br/>one database)]
  APP --> FS[(File volume)]
  APP -.optional.-> EXT[SMTP, OIDC provider,<br/>map tiles, parts catalogue,<br/>error tracking]
```

PostgreSQL is storage only. The file volume holds the original ride files. Everything outside the box is optional and configured by the operator; OpenStreetMap tiles are the default map.

## 3. Clubs, members and isolation

**Decision: one database and one schema for both deployments.** The cloud runs one shared database with many clubs; a self-hosted club runs the same schema with one club. There is no tenant catalog, no database per club and no host-based tenant resolution, so there is one migration path and one code path.

- **The member is the owner, the club is a group.** An account exists on its own and may join one club. Rides, bikes, goals, wellbeing and the profile belong to the member and stay theirs if they leave or the club is deleted.
- **Club tables carry `club_id`.** Clubs, memberships, join requests and sharing grants are scoped by club, and every query on them is limited to the caller's clubs.
- **Membership shows the roster and nothing else.** A coach sees a member's rides, training, routes or wellbeing only through an active grant the member gave for that data type. Club admins administer the club; they do not read members' data.
- **Discovery is local and opt-in.** Clubs on the same deployment can opt into nearby discovery, and a rider asks to join; the owner approves. Discovery between deployments (cloud and self-hosted clubs) belongs to the inter-club layer in [v2](design/v2.md).

Trade-offs accepted: isolation depends on query filters, with tests proving one club cannot see another's data, instead of separate databases, and restoring a single club from a shared backup means restoring to a scratch database and copying that club's rows.

## 4. Deployment

- **Two Docker images, one origin** (amd64, non-root). The **server image** holds the .NET API and the background services, and no front-end. The **web image** is the official nginx image with the Flutter web build and the presentation site: it serves both and forwards `/api`, `/health` and `/openapi` to the server, so the browser sees one address and the cookie and single sign-on need no cross-origin setup. Both images share one version and are released together.
- **Cloud:** one deployment in the EU/EEA over a managed PostgreSQL database, behind TLS. **Self-host:** the same two images with PostgreSQL as a third container or an existing server, and one volume for files. Both run the same features; only the operator differs.
- **Volumes:** ride files on `/data/files`, the Data Protection key ring on `/data/keys`. Every instance mounts the same key ring, because it signs the session cookies and download links.
- **Background work runs on exactly one instance** (`VELOMINE__BACKGROUND__ENABLED`); migrations run on every instance under EF Core's migration lock.
- **Configuration** is environment variables, validated on start. Secrets come from the environment or a secret store, never the database.
- **Migrations** are backward-compatible for one release (expand, backfill, contract). A database rollback is a restore, not a downgrade.
- **Releases** use exact image versions, never `latest`, and can be rolled back to the previous version.
- **Backups:** the database (point-in-time recovery where the host offers it, plus a nightly `pg_dump -Fc`), the file volume and the Data Protection key ring. Deleted data leaves the backups within 90 days.
- **Supporter licence (self-host):** self-hosting is free. An optional supporter licence is paid once by a rider and once by a club, and never expires; the offline signed key names the holder, is validated with a public key and shows a badge the holder can hide. It unlocks no feature, has no seat count and never phones home; a server without one works exactly the same.
- **Hosted environments:** one VPS, set up by hand, runs `docker-compose.yml` with the `compose.demo.yaml` overlay: PostgreSQL, the server, the web image and Traefik. Traefik owns ports 80 and 443, gets and renews the Let's Encrypt certificates and forwards to the web container: `velomine.eu` serves only the presentation site and `demo.velomine.eu` only the app and the API, each redirecting the other's paths to the other name, and `/` on the demo opens the app. It reads these routes from `deploy/traefik/routes.yaml`, not from the Docker socket, so it has no power over the host's Docker. The server and PostgreSQL are not published. Settings and secrets live in a git-ignored `.env` on the host.
- **Only the demo runs for now.** dev, staging and prod are not defined until there are customers. Each will be its own compose project with its own `.env` and the same images; prod then answers at `app.velomine.eu`. `velomine.eu` and `www` are served by the demo until prod launches.
- **Releases:** CI builds and smoke-tests the server and web images per commit, together, and pushes them to GHCR with their build provenance. Every merge to `main` publishes the next patch version and a GitHub Release; a tag `vX.Y.Z` pushed by hand publishes that version, for a minor or major step. Deploying is manual: the operator sets that version for an environment on the host and runs `docker compose pull` and `up --wait`, which fails unless the pair answers `/health`; a rollback is the same with the previous version. GitHub holds no key to the hosts.
- No Kubernetes, no multi-cloud, no active-active.

## 5. Ride ingestion

Every ride arrives the same way, whether from the phone, the web upload or a file from a bike computer.

```mermaid
sequenceDiagram
  participant C as Client
  participant E as Upload endpoint
  participant Q as In-memory queue
  participant W as Ingestion service
  participant S as Database + files

  C->>E: POST /api/v1/rides/uploads (file, Idempotency-Key)
  E->>S: key already used? return that ride
  E->>S: save original file, ride row "processing"
  E->>Q: ride id
  E-->>C: 202 Accepted + ride id
  W->>Q: next ride id
  W->>S: hash, parse, apply privacy defaults and bike, dedupe
  W->>S: save ride, streams, metrics, laps, power bests, notify
  W->>S: status "ready" (or "failed" with a reason)
  C->>E: GET /api/v1/rides/{id} until ready
```

The original file is saved before `202` is returned, and on start the service re-queues every ride still processing, so a restart never loses a ride. Originals are kept forever, so rides can be read again when a parser improves.

## 6. Background work

Everything runs inside the application as hosted services; PostgreSQL holds data, not a job system.

- **Ingestion:** the queue above.
- **Timers:** email notifications (batched so a burst becomes one email), the parts catalogue sync, part contributions to the catalogue publisher, the sharing view log (three months) and ended sessions (a week). Each timer recomputes its work from the data, so a missed run is caught up next time.
- **Parts catalogue:** one list maintained by a publisher, mirrored every hour. Members never write to it. A part the list does not have waits in a table until the publisher answers, because losing it would mean asking the member to type it again. Only the part itself is sent: no member, bike, club or address.

Most numbers are computed when asked for (wear, totals, goals). Training load and power bests are stored per ride, because the dashboard and power curve sum them over long ranges.

## 7. Data ownership

```mermaid
erDiagram
  USER ||--o{ RIDE : records
  USER ||--o{ BIKE : owns
  BIKE ||--o{ COMPONENT : has
  BIKE ||--o{ RIDE : "ridden on"
  RIDE ||--o| STREAMS : has
  RIDE ||--o{ LAP : has
  RIDE ||--o{ POWER_BEST : has
  RIDE ||--o| RIDE_FEEL : "felt as"
  USER ||--o{ CHECK_IN : daily
  USER ||--o{ PRIVACY_ZONE : defines
  USER ||--o{ SESSION : "signed in on"
  CLUB ||--o{ MEMBERSHIP : has
  USER ||--o| MEMBERSHIP : "one club"
  CLUB ||--o{ SHARE_GRANT : scopes
  USER ||--o{ SHARE_GRANT : gives
```

- **Export** covers everything a member owns, with every original ride file byte for byte.
- **Account deletion** removes the account and everything it owns, then each ride file no other ride uses.
- **Club deletion** removes the club, its memberships and grants. Members keep their accounts and data.

## 8. Security model

- Access to member data is owner or an active grant for that data type and audience; checked on every endpoint that returns it.
- Everything a non-owner sees passes through one privacy function: privacy zones around saved places, start and end trimming, per-stream switches, and no position data without a route grant.
- Wellbeing is health data: explicit, versioned consent; notes never leave the owner.
- Every coach view of a member's data is logged, and the member can read the log.
- Sessions are listed and revocable per device; refresh tokens rotate and a reused one ends the session.
- Email verification: a confirmed address is required to sign in only when email is configured; without SMTP there is no gate and no verification email.
- Operational logs never contain member data. Member telemetry from the app is opt-in; server telemetry is anonymised and used only to fix bugs and performance problems.

## 9. Clients

- **One Flutter codebase** for Android, iOS and the web app. The web app is served by the web image at the same address as the API, so cookie sessions and single sign-on need no cross-origin setup.
- **The presentation site** is plain HTML in `site/`, served by the web image, with no JavaScript, no cookies, no analytics and no third-party scripts, because Flutter web cannot be crawled or previewed.
- **The phone records natively** (Kotlin, Swift) with the screen off, pairs standard Bluetooth LE sensors without vendor apps, saves each ride as a FIT file first and uploads it through an idempotent queue.
- **Design system:** a day theme (Cloud Dancer, deep teal, iron oxide) and a night-ride theme (asphalt, Volt) for recording.

## 10. Decisions

| Decision | Why |
|----------|-----|
| One database for cloud and self-host, clubs scoped by `club_id` | One code and migration path; a self-hosted club is the same system with one club. |
| A club plan: member limit and paid-until, set by the operator and later by a payment webhook | Admission is one checked step with the club row locked; a full or ended plan stops new members without taking anything from existing ones, and no price lives in the server. |
| A route belongs to the member who added it, with a nullable club share | Withdrawing, leaving the club or the club going away clears the share and keeps the route with its owner; it is in one club's library at a time. |
| A planned ride is club data, with a nullable creator | A coach or the owner plans it and every member sees it; it stays on the club's calendar when the planner's account goes. |
| A calendar feed address is verified by hash, never stored or logged | The database keeps only the SHA-256, so a dump cannot be replayed into a member's calendar; the address is shown once and replacing it stops the old one. |
| A member's sign-ups are in the account export | Saying "I'm in" is the member's own statement, so `club-rides.json` carries it even though the ride belongs to the club. |
| Vertical slices in one project, with FastEndpoints | Each use case is one file; no layers to keep in sync. |
| One PostgreSQL schema per feature area | Keeps a large database readable without splitting it. |
| Background work in the application; PostgreSQL is storage only | No extra service to run or monitor. |
| Dart API client generated from the OpenAPI document | The app cannot drift from the server's contract. |
| Flutter for every logged-in screen, web included; plain HTML for the public site | One language and design system for phone and web. Revisit if the web app grows heavy data tables, accessibility audits become a requirement, or a web developer without Dart joins. |
| Original ride files kept forever; FIT as the phone's format | Any ride can be read again when a parser improves. |
| Streams as one row per ride with an array per signal | A long ride is one row fetch. Revisit if queries must filter single samples across rides. |
| Wear, goals and totals computed on read; load and power bests stored | Always correct for the current profile, except the sums the dashboard needs fast. |
| Recurring maintenance jobs reuse the part-wear calculation | One set of interval rules for parts and service jobs; the reminder stores only its interval and last-done date, and the rest comes from the rides. |
| A solo plan: a 30-day trial date on the account, shown as a badge; it gates nothing | No feature sits behind a payment; the trial is billing state that never takes anything away, mirroring the club plan. Payment itself comes later. |
| A confirmed email is required to sign in only when email is configured | A self-hosted club with no SMTP must still create and sign in to accounts, so the gate is conditional; the admin's one-time reset link remains the no-email recovery path. SSO accounts are already verified. |
| Optional, offline, signed supporter licence | Funds the project without a paywall: no phone-home, no seats, never a feature or a block on member data. |
| Member telemetry opt-in; operational logs separate and anonymous | Health and location data never leave through diagnostics. |
| Vendor-neutral server telemetry: OTLP with the standard `OTEL_*` variables, errors through an error-tracking DSN | An operator picks any backend by changing settings, not code; the DSN protocol is spoken by open-source GlitchTip and Bugsink too. The app follows later: Flutter has no official OpenTelemetry SDK yet, so it keeps its crash-reporting SDK behind its `TelemetryRuntime` interface. |
| Two images, server and web, behind one origin | A Flutter build never blocks or slows a server image, and the server is API-only. One origin keeps the cookie and single sign-on simple. Costs a third container for self-hosters. |
| Another app's history comes from the member's own export, never that app's API | The bulk export is the data the member downloads themselves, needs no token or outside service, and keeps a self-hosted instance independent. A ride records its source and that app's activity id, so a later export skips what is already here. |
| Quiet bulk import: a `Bulk-Import` header and a token-bucket upload limit | A dropped bike computer folder sends many files at once; the member gets one summary instead of a notification per file, while the sustained rate stays capped. |
| `sharing.view_log.ride_id`, set null when the ride goes | "Who looked" is kept per ride, and deleting a ride must not delete the member's record that someone looked. |
| The presentation site ships in the web image, as plain HTML in `site/` | It is static front-end material; it stays plain HTML because Flutter web draws on a canvas, which is poor for search, link previews, first load and accessibility. |
| nginx inside the web image; Traefik in front of a public server, from a compose overlay | nginx serves the static files and forwards the API, the same for a self-hoster and on the demo. Traefik handles certificates and the public route in `compose.demo.yaml`, so the root compose stays free of hosting extras. It uses the file provider: the Docker socket would give it too much power over the host. |
| Compose overlays and pipelines in this repository; the host set up by hand, secrets outside Git | The demo runs the same root `docker-compose.yml` a self-hoster does, plus one overlay, so the stack is tested on every deploy. A provisioning tool cost more to maintain than one hand-managed VPS. GitHub holds no host secret. |
| Build once in CI; deploy by hand with `docker compose` | Every environment runs a version CI built and tested, never a rebuild. With no customers yet, a manual pull and `up --wait` is the simplest deploy with no deploy key, timer or script to maintain; automate it when deploys become frequent. |
| One VPS and one database instance for every environment; only the demo runs until there are customers | No cost for environments nobody uses yet. The others are written out and commented out, so turning one on is uncommenting, not designing. Commented-out code is not checked by CI or `tofu validate`: check it when turning it on. The public demo will live next to prod: revisit before prod holds a club's real data, when prod moves to its own VPS and an HA database. |
