# Velomine v1: scope and architecture

Nov 1, 2026 · @Alex

## Decisions so far

Velomine is a self-hosted, cycling-only platform for clubs and teams. Rides are private by default, a coach can be given access, and wellbeing tracking focuses on how the rider feels. It is a clean-room rewrite: Endurain's ideas, not its AGPL code.

| Topic | Decision | What it means |
| --- | --- | --- |
| Sports | Cycling only | Road, gravel, MTB, e-bike, indoor, commute. Every screen and metric is bike-specific. |
| Users | Clubs and teams | Many accounts per server, admin role, invites with admin approval. SSO (OIDC) is built in and on by default from v1, alongside local accounts. |
| Social | Private + share links | Rides private by default. One ride can be shared by link. Privacy zones hide home and other saved places, and optionally the start and end of every ride. No feed or followers. |
| Clubs and coaches | Yes | Clubs include coaches. A club has members and coaches, but everything a member records stays private. The member decides what to share and with whom: the whole club or only a coach; rides, analytics or wellbeing. Every share can be revoked. |
| Health | Wellness + session feel, cycle tracking | Daily 1–5 check-in (fatigue, soreness, mood, stress, motivation), RPE and notes after each ride, menstrual phase as optional and highly protected context. |
| Body data | Weight in the profile (assumption) | Not chosen as a health area, but W/kg, VO2max estimate and calories need it. Kept as a single profile field, not a tracked series. |
| Name and brand | Velomine, direction D | Contour × Night Ride: Cloud Dancer, deep teal and iron oxide by day; asphalt and Volt while riding. |

**Dependency rule (all apps):** official libraries first. A community library is added only after a written evaluation and the owner's approval. The rule lives in the repository's `AGENTS.md`. Known cases that will need approval: Flutter has no official Bluetooth LE plugin, so the BLE library (for example universal\_ble) must go through the evaluation.

## Endurain features: keep, change or drop

Roughly half of Endurain carries over, mostly reshaped for cycling. The multi-sport, health-logging and social-feed parts are dropped. Based on Endurain v0.20.2 and its Flutter app v0.10.2.

| Endurain feature | Verdict | Velomine version |
| --- | --- | --- |
| Ingestion pipeline (parse, enrich, dedupe, save, emit event) | Keep | Same design in .NET: one upload endpoint, async jobs, `Idempotency-Key`, background subscribers. |
| FIT, GPX, TCX import | Change | FIT first. GPX reads every common extension, including `PowerInWatts` and `gpxtpx:speed`, both of which Endurain misses. |
| 47 activity types | Change | About 8 cycling types: road, gravel, MTB, e-bike, e-MTB, indoor, virtual, commute. |
| Streams (HR, power, cadence, speed, elevation, temperature, map) | Keep | Plus a speed source flag: wheel sensor or GPS. |
| HR zones and time in zone | Keep | Plus power zones. |
| Laps | Keep | — |
| Workout sets and steps, exercise titles | Drop | Gym and running concepts. |
| Activity media (photos) | Keep | Photos on a ride. |
| Thumbnails, reverse geocoding | Keep | — |
| Strava sync and bulk import | Change | Bulk import of a Strava export to migrate history. Ongoing sync is optional, given Strava's API limits. |
| Garmin Connect (unofficial login) | Change | Garmin's official personal key: activities as FIT files. |
| Gear and components (shoes, wetsuits, racquets…) | Change | Bikes only, with our own list of 35 bike part types (chain, tyres, pads, fork service…) and typical lifetimes as suggestions. Wear by distance, hours and months, computed from the rides; reminders come in v2. Wheel circumference per bike. |
| Default gear per activity type | Change | One default bike per member, copied onto a ride at import. A default per ride type waits until ride types exist. |
| Goals and summaries | Keep | Weekly, monthly, yearly totals, cycling only. Goals per week, month or year (distance, elevation, time or number of rides), in v1. |
| Followers, feed, follow requests | Drop | Replaced by share links, clubs and coaches. |
| Public activity pages | Change | Share link per ride, with optional expiry and privacy zones. |
| Per-stream privacy switches | Keep | Applied to share links and coach views. |
| Health: weight, steps, sleep, water, fasting, bowel log, targets | Drop | Replaced by wellness check-in, ride RPE and cycle tracking. Weight becomes a profile field. |
| Notifications | Keep | New types: component worn out, coach request, import failed. |
| Auth: local login, MFA, SSO (OIDC), sign-up approval, password reset, API keys, sessions | Keep | All needed for clubs. Add passkeys, on Endurain's roadmap. |
| Roles | Change | Admin, member, coach. |
| Profile export and import | Keep | Full export, including original files. |
| Server settings, custom map tiles, email | Keep | — |
| Multi-language UI | Keep | Start with English and Italian. |
| Mobile app: native background recorder, local-first save, upload queue | Keep | Same approach, rewritten. |
| Mobile app: BLE heart rate, power, cadence | Change | Also wheel speed from the speed sensor, which Endurain skips. |
| Mobile app: HealthKit and Health Connect workout import | Drop for now | Cycling rides come from the phone, a bike computer or connectors. |
| Mobile app: auto-pause, audio announcements | Keep | — |

## Velomine-only features

These are what make Velomine worth building instead of running Endurain. Each comes from a gap found in the analysis or a decision above.

| Feature | What it does | Why |
| --- | --- | --- |
| Wheel-sensor speed and distance | Uses CSC wheel revolutions and the bike's circumference; GPS only as a fallback | Accurate distance in the woods with single-band GPS. |
| Cycling analytics | NP, IF, TSS, FTP estimate, power curve, VO2max estimate, TRIMP, fitness/fatigue/form | Endurain stops at averages and normalized power. |
| Readiness view | Combines training load, wellness check-in and recent RPE into ride hard / ride easy / rest | The point of collecting wellbeing data. |
| Wellness check-in | Daily 1–5 scores in about 20 seconds; RPE and notes after each ride | Chosen health area. |
| Cycle tracking | Optional menstrual phase as context on charts; encrypted, never in share links, coach sees it only if granted separately | Chosen health area; most sensitive data on the server. |
| Clubs and coaches | Members join a club; the club has coaches. Nothing is visible by default: the member opts in per data type (rides, analytics, wellbeing, cycle tracking) and per audience (club or a coach). Revocable; every view logged | Clubs and coaches together, private by default. |
| Privacy zones | Like Strava's map visibility: hide up to 1 mile around saved addresses (home, work), and optionally hide the start and end of every ride wherever it is. Applied to share links and to what clubs and coaches see; the owner always sees the full track | Endurain can only hide the whole map. |
| Share links | One link per ride, optional expiry, respects privacy switches | Replaces public pages and the feed. |
| Component maintenance | Wear by km, hours or months, with notifications | Endurain shows a wear bar only. |
| Connectors | Garmin personal key, Wahoo cloud, watched Dropbox or Nextcloud folder | Automatic sync for bike computer owners (use case A). |
| Desktop and web upload | Drag and drop, plus a small USB tool for Bryton and others | Covers every bike computer. |

## Tech stack

Recommendation: .NET 10 for the server, and Flutter for everything a logged-in user touches, mobile and web, from one codebase. Share links and the landing page are plain HTML rendered by the server, because Flutter web cannot be crawled or previewed.

### Server: .NET 10

- **Runtime:** .NET 10 is the current LTS, released 2025-11-11 and supported until 2028-11-14 ([Microsoft support policy](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core)). .NET 11, due this month, is a short-term release: stay on 10.
- **API:** ASP.NET Core minimal APIs with an OpenAPI document, from which the Dart client is generated.
- **Data:** PostgreSQL with EF Core.
- **FIT parsing:** Garmin's official FIT C# SDK, on NuGet as `Garmin.FIT.Sdk` ([NuGet](https://nuget.org/packages/Garmin.FIT.Sdk/21.158.0)). It targets .NET Standard 2.0, so it runs on .NET 10.
- **Background work:** hosted services with a PostgreSQL-backed job table: ingestion, thumbnails, geocoding, connector polling, maintenance reminders.
- **Auth:** ASP.NET Core Identity with MFA, external OIDC login for SSO, scoped API keys, and passkeys, built into Identity since .NET 10 ([Microsoft docs](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/passkeys)).
- **Deploy:** one Docker image for amd64 and arm64, plus PostgreSQL.

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

**Decision: Flutter web** for the user, coach and admin web app. Velomine is self-hosted and everything behind login, so SEO does not matter, and one design system and API client for phone and web halves the UI work. The weaknesses are handled outside Flutter:

- **Share links:** small HTML pages rendered by the .NET server, with Open Graph tags so a shared ride previews properly in chats.
- **Landing page and docs:** static HTML.

**When to switch to Angular:** if the web app grows into heavy data tables, if accessibility audits become a requirement for clubs, or if a web developer joins who doesn't know Dart.

## Architecture

Every client talks to one .NET 10 server. The apps use the REST API, bike computer files go through the same ingestion pipeline, and share links are plain HTML pages the server renders.

&#91;embedded content: Velomine architecture · 4 clients, 1 server, 2 stores\]

Original FIT files are always kept, so any ride can be re-parsed when the parser improves.

## Release plan

v1 makes Velomine usable on its own: record with the phone or upload any FIT file, see rides, check in daily, share safely. v2 makes bike computers automatic and turns the data into coaching.

**v1: ride, record, share**

1. Server core: accounts, MFA, SSO with OIDC, roles (admin, member, coach), clubs with members and coaches, Docker image.
2. Ingestion: upload endpoint with async jobs and idempotency, FIT and GPX parsing including every sensor extension, deduplication.
3. Rides: map, stream charts, HR and power zones, laps, photos, ride types for cycling.
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
- [ ] **Licence for Velomine:** AGPL-3.0 (keeps forks open, like Endurain) or MIT (easier for others to reuse)?
- [ ] **Hosting:** self-host only, or also a hosted instance? "No paywall" needs a funding model for any hosted version.
- [ ] **Strava:** one-time import of an export only, or ongoing sync despite Strava's API limits?
- [ ] **Languages:** English and Italian first (assumption)?
