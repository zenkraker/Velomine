# Velomine v1: scope and architecture

Nov 1, 2026 · @Alex

## Decisions so far

Velomine is a cycling-only training platform for clubs and teams. Cloud is the default: one shared deployment with a database per club. Self-hosted and on-premise are first-class options using the same image. Rides are private by default, a coach can be given access, and wellbeing tracking focuses on how the rider feels.

| Topic | Decision | What it means |
| --- | --- | --- |
| Sports | Cycling only | Road, gravel, MTB, e-bike, indoor, commute. Every screen and metric is bike-specific. |
| Users | Clubs and teams | Many accounts per club, one club per account in that database, club admin role, invites with admin approval. SSO (OIDC) is built in and on by default from v1, alongside local accounts. |
| Social | Private + share links | Rides private by default. One ride can be shared by link. Privacy zones hide home and other saved places, and optionally the start and end of every ride. No feed or followers. |
| Clubs and coaches | Optional | One club per database. A rider can use Velomine on their own; a club is opt-in. Clubs include coaches, but everything a member records stays private. The member decides what to share and with whom: the club's coaches; rides, analytics, routes or wellbeing. Whole-club reading needs a member-facing club view. Every share can be revoked. Cross-club discovery is an opt-in directory or federation feature, not a local query. |
| Health | Wellness + session feel, cycle tracking | Daily 1–5 check-in (fatigue, soreness, mood, stress, motivation), RPE and notes after each ride, menstrual phase as optional and highly protected context. |
| Body data | Weight in the profile (assumption) | Not chosen as a health area, but W/kg, VO2max estimate and calories need it. Kept as a single profile field, not a tracked series. |
| Name and brand | Velomine, direction D | Contour × Night Ride: Cloud Dancer, deep teal and iron oxide by day; asphalt and Volt while riding. |
| Hosting and price | Managed cloud or self-host | Cloud: one shared Velomine deployment with one database and role per club on a managed PostgreSQL cluster. Self-host: the same image as a single-tenant instance. A one-time activation fee, then a yearly fee per club; a self-hosted club pays a licence. Pricing is published before a club commits, and comparable clubs pay the same. No feature paywall; the data stays the member's. |

**Dependency rule (all apps):** official libraries first. A community library is added only after a written evaluation and the owner's approval. The rule lives in the repository's `AGENTS.md`. Known cases that will need approval: Flutter has no official Bluetooth LE plugin, so the BLE library (for example universal\_ble) must go through the evaluation.

## What v1 includes

Everything below is cycling-first, and every feature is shaped for clubs and teams. A rider without a club is a supported starting point, not a half-configured account: the same personal tools, with the club as an opt-in step.

| Area | v1 |
| --- | --- |
| Ingestion | One upload endpoint, async jobs, `Idempotency-Key` and a tenant-aware background worker: parse, enrich, dedupe, save, notify. |
| File formats | FIT first, then GPX and TCX. GPX reads every common extension, including `PowerInWatts` and `gpxtpx:speed`. |
| Ride types | Four independent dimensions: surface (road, gravel, mountain, track), e-bike (none or assisted), environment (outdoor, indoor, virtual) and a commute flag. The older eight labels (e-MTB, virtual, commute…) are derived from these, so an e-MTB is mountain + e-bike and a commute can also be training. |
| Streams | HR, power, cadence, speed, elevation, temperature and map, plus a speed source flag: wheel sensor or GPS. |
| Zones | HR zones and time in zone, plus power zones. |
| Laps | Yes. |
| Photos | Photos on a ride. |
| Thumbnails, reverse geocoding | Yes. |
| Strava | Bulk import of a Strava export to migrate history. Ongoing sync is optional, given Strava's API limits. |
| Garmin Connect | Garmin's official personal key: activities as FIT files. |
| Bikes and components | Bikes only, with our own list of 35 bike part types (chain, tyres, pads, fork service…) and typical lifetimes as suggestions. Wear by distance, hours and months, computed from the rides; reminders come in v2. Wheel circumference per bike. |
| Default bike | One default bike per member, copied onto a ride at import. A ride also takes a bike of the matching kind (e-bike, mountain, gravel, track, city); the single default is the fallback when that kind has no active bike. |
| Goals and summaries | Weekly, monthly and yearly totals, cycling only. Goals per week, month or year (distance, elevation, time or number of rides), in v1. |
| Share links | One link per ride, with optional expiry and privacy zones, instead of public pages and a feed. |
| Per-stream privacy | Applied to share links and coach views. |
| Notifications | Component worn out, coach request, import failed. |
| Auth | Local login, MFA, SSO (OIDC) per club host, sign-up approval, password reset, API keys and sessions, plus passkeys. |
| Roles | Club admin, member and coach. |
| Solo riders | Any account works without a club on that club's host: personal tools, rides and wellbeing, with the club as an opt-in step. Discovery and joining across clubs are part of the inter-club layer (v2). |
| Profile export and import | Full export, including original files. |
| Server | Per-club settings, email and single sign-on; platform defaults with per-club override. Maps are always on (OpenStreetMap by default, a private tile server when the operator sets one). |
| Languages | Multi-language UI, starting with English and Italian. The language is an account setting, so a choice on one device follows the member to every device. |
| Phone recorder | Native background recorder, local-first save and an upload queue. |
| Phone sensors | BLE heart rate, power and cadence, plus wheel speed from the speed sensor. |
| Phone extras | Auto-pause and audio announcements. |
| Phone health import | Not in v1: rides come from the phone, a bike computer or connectors. |

Out of scope: gym and running concepts, a social feed with followers, and health logging (steps, sleep, water, fasting, bowel log). Clubs and coaches replace followers, and the wellness check-in replaces health logging.

## Velomine-only features

These are Velomine's differentiators. Each comes from a decision above.

| Feature | What it does | Why |
| --- | --- | --- |
| Wheel-sensor speed and distance | Uses CSC wheel revolutions and the bike's circumference; GPS only as a fallback | Accurate distance in the woods with single-band GPS. |
| Cycling analytics | NP, IF, TSS, FTP estimate, power curve, VO2max estimate, TRIMP, fitness/fatigue/form | Turns recorded streams into training guidance. |
| Readiness view | Combines training load, wellness check-in and recent RPE into ride hard / ride easy / rest | The point of collecting wellbeing data. |
| Wellness check-in | Daily 1–5 scores in about 20 seconds; RPE and notes after each ride | Chosen health area. |
| Cycle tracking | Optional menstrual phase as context on charts; encrypted, never in share links, coach sees it only if granted separately | Chosen health area; most sensitive data on the server. |
| Clubs and coaches | A club has coaches and riders, and a rider may use Velomine without one. Nothing is visible by default: the member opts in per data type (rides, analytics, routes, wellbeing, cycle tracking) and per audience (the club's coaches today; whole-club reading later). Revocable; every view logged. Discovery and joining across clubs are part of the inter-club layer (v2). | Clubs and coaches together, private by default, solo riding included. |
| Privacy zones | Like Strava's map visibility: hide up to 1 mile around saved addresses (home, work), and optionally hide the start and end of every ride wherever it is. Applied to share links and to what clubs and coaches see; the owner always sees the full track | Keeps home and other saved places out of every shared view. |
| Share links | One link per ride, optional expiry, respects privacy switches | Replaces public pages and the feed. |
| Component maintenance | Wear by km, hours or months, with notifications | Warns before a part fails, not after. |
| Connectors | Garmin personal key, Wahoo cloud, watched Dropbox or Nextcloud folder | Automatic sync for bike computer owners (use case A). |
| Desktop and web upload | Drag and drop, plus a small USB tool for Bryton and others | Covers every bike computer. |

## Tech stack

Recommendation: .NET 10 for the server, and Flutter for everything a logged-in user touches, mobile and web, from one codebase. Share links and the landing page are plain HTML rendered by the server, because Flutter web cannot be crawled or previewed.

### Server: .NET 10

- **Runtime:** .NET 10 is the current LTS, released 2025-11-11 and supported until 2028-11-14 ([Microsoft support policy](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core)). .NET 11, due this month, is a short-term release: stay on 10.
- **API:** ASP.NET Core minimal APIs with an OpenAPI document, from which the Dart client is generated.
- **Data:** PostgreSQL with EF Core.
- **FIT parsing:** Garmin's official FIT C# SDK, on NuGet as `Garmin.FIT.Sdk` ([NuGet](https://nuget.org/packages/Garmin.FIT.Sdk/21.158.0)). It targets .NET Standard 2.0, so it runs on .NET 10.
- **Background work:** hosted services with an in-memory channel and timers: ingestion, thumbnails, geocoding, connector polling, maintenance reminders. Each unit of work resolves one tenant; nothing is queued in the database.
- **Auth:** ASP.NET Core Identity with MFA, external OIDC login for SSO, scoped API keys, and passkeys, built into Identity since .NET 10 ([Microsoft docs](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/passkeys)).
- **Deploy:** one Docker image (amd64; the Flutter web stage is Linux x64). Cloud runs one shared deployment over a managed PostgreSQL cluster with one database per club; self-host runs the same image single-tenant.

### Mobile apps: Flutter

As decided: Flutter UI, sensor pairing over Bluetooth LE, uploads, plus a native background recorder per platform (Kotlin, Swift).

### Web UI: Flutter web vs Angular 22

|  | Flutter web | Angular 22 |
| --- | --- | --- |
| Current version | Flutter 3.4x, Wasm build stable since 3.22 | Angular 22, released 2026-06-03 ([source](https://ecorpit.com/angular-development-company/)) |
| Code shared with the apps | Models, API client, design system, charts, maps | None: a second language and component set |
| Fit for logged-in screens (rides, analytics, club, admin) | Good: production-ready for logged-in apps and dashboards | Excellent |
| SEO and link previews | None: it paints to a canvas, and the HTML renderer was removed in 3.29 | Good, with server-side rendering |
| First load | Heavy: about 2.9 MB compressed for the official demo with Wasm, 4.2 MB without ([measurement](https://www.issoh.co.jp/tech/details/16727/)) | Light |
| Accessibility, text selection, browser feel | Weaker; improving | Native web |
| Team effort | One stack: Dart for app and web | Two stacks: Dart and TypeScript |

**Decision: Flutter web** for the user, coach and admin web app. Velomine runs as a managed cloud tenant or on the club's own server, and everything is behind login, so SEO does not matter, and one design system and API client for phone and web halves the UI work. The weaknesses are handled outside Flutter:

- **Share links:** small HTML pages rendered by the .NET server, with Open Graph tags so a shared ride previews properly in chats.
- **Landing page and docs:** static HTML.

**When to switch to Angular:** if the web app grows into heavy data tables, if accessibility audits become a requirement for clubs, or if a web developer joins who doesn't know Dart.

## Architecture

Every client talks to its club's host. Cloud serves all clubs from one shared .NET 10 deployment, with one database and role per club; self-host runs the same image for one club. The apps use the REST API, bike computer files go through the same ingestion pipeline, and share links are plain HTML pages the server renders.

&#91;embedded content: Velomine architecture · 4 clients, 1 shared app, one database per club\]

Original FIT files are always kept, so any ride can be re-parsed when the parser improves.

## Release plan

v1 makes Velomine usable on its own: record with the phone or upload any FIT file, see rides, check in daily, share safely. v2 makes bike computers automatic and turns the data into coaching.

**v1: ride, record, share**

1. Server core: tenancy (one shared deployment, one database per club), accounts, MFA, SSO with OIDC, roles (club admin, member, coach), clubs with members and coaches, Docker image.
2. Ingestion: upload endpoint with async jobs and idempotency, FIT and GPX parsing including every sensor extension, deduplication.
3. Rides: map, stream charts, HR and power zones, laps, photos, ride dimensions for cycling.
4. Bikes: bikes with wheel circumference, components with wear by km, hours or months.
5. Mobile app: native recorder, Bluetooth heart rate, speed/cadence (wheel and crank) and power, local-first save, upload queue, auto-pause, day and night themes.
6. Web app (Flutter web): rides, bikes, profile, club and admin screens, drag-and-drop upload.
7. Wellbeing: daily check-in, RPE and notes after each ride.
8. Sharing: share links rendered by the server, privacy zones (saved addresses up to 1 mile, plus optional start and end trimming), per-stream privacy switches.
9. Analytics, basic: NP, IF, TSS with a manual FTP, TRIMP, weekly and monthly totals, goals per week, month or year.

**v2: automatic and smart**

1. Connectors: Garmin personal key, Wahoo cloud, watched Dropbox or Nextcloud folder.
2. Desktop USB upload tool; Strava export import.
3. Sharing with club and coach: per data type, per audience, revocable, view log.
4. Analytics, advanced: power curve, FTP and VO2max estimates, fitness, fatigue and form, readiness view.
5. Cycle tracking, encrypted, with its own sharing permission.
6. Maintenance reminders as notifications.
7. Passkeys.

**Later**

- Android extras: USB import from a bike computer, Gadgetbridge hand-off for Garmin.
- Live tracking with an expiring link for solo rides.
- Opt-in club features: group rides, club leaderboards, self-hosted segments.
- FIT export of any ride.

## Open questions

- [ ] **Weight:** confirm it lives as a single profile field. W/kg, VO2max and calories need it.
- [ ] **Health data and the law:** wellness and cycle data are health data. A club running a server for its members holds health data about them, which in the EU is a special category under GDPR and needs explicit consent. Velomine should ship consent screens, export and deletion by design; check the legal side with someone qualified.
- [x] **Licence for Velomine:** AGPL-3.0 with a trademark policy. Clubs can inspect, self-host and fork; anyone running it as a service must publish their source, and nobody else may use the Velomine name.
- [x] **Strava:** one-time import of a user's export ZIP only. Ongoing sync is out of v1.
- [x] **Languages:** English and Italian first. The app ships both; the presentation site follows under `/it/`.
