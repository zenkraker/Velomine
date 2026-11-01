# Endurain feature analysis (v0.20.2) — input for Velomine

Nov 1, 2026 · @Alex

## Summary

Endurain v0.20.2 (released 2026-10-27) is a mature, multi-sport, self-hosted Strava alternative. It is general-purpose, not bike-centric, and since May 2026 it has been in a feature freeze focused on refactoring. The analysis below is from a clone of `endurain-project/endurain` at commit `712b04d` (2026-10-27), plus the mobile app repo `endurain-flutter` (last commit 2026-10-22).

- **Status:** the [feature freeze](https://docs.endurain.com/blog/2026/05/23/pausing-new-features-so-endurain-can-keep-growing/) started 2026-05-23. v0.20.0 (2026-10-21) shipped the first part of the refactor to an event-driven backend. The project moved from Codeberg back to GitHub in October 2026.
- **Size:** about 93,000 lines of Python in the backend, 336 backend test files, and about 79,000 lines of Vue/TypeScript in the frontend.
- **License:** AGPL-3.0. If Velomine copies or adapts any Endurain code, Velomine must also be AGPL-3.0 and publish its source, including for network users. A clean-room rewrite that only borrows ideas has no such obligation.
- **Trademark:** "Endurain" is a registered trademark of João Vitória Silva. Commercial use of the name or logo is not allowed without permission. Velomine must not use the name or logo in its branding.
- **Roadmap:** the remaining public wishlist is social only: passkeys, text posts, comments, reactions, events, challenges and federation through ActivityPub. Nothing on it is bike-specific.

## Architecture and stack

Endurain is a modular FastAPI monolith on PostgreSQL. Every activity source feeds one event-driven pipeline, introduced in v0.20.0.

- **Backend:** Python 3.13, FastAPI, SQLAlchemy 2, Alembic and the project's own [jasil](https://github.com/endurain-project/jasil) library for storage, events, durable jobs and geocoding. Eleven top-level modules: activities, auth, followers, garmin, gears, health, notifications, server\_settings, strava, users and websocket. Module boundaries are enforced with import-linter and architecture tests.
- **Frontend:** Vue 3, TypeScript, Vite, Tailwind CSS v4, shadcn-vue, TanStack Query and Pinia. The API client is generated from the backend's OpenAPI schema.
- **Mobile:** Flutter app for iOS and Android ([endurain-flutter](https://github.com/endurain-project/endurain-flutter)).
- **Deployment:** one Docker image for amd64 and arm64, plus PostgreSQL and optional Redis.

&#91;embedded content: Endurain architecture · 5 sources, 6 pipeline stages\]

Parsers know nothing about the database. Thumbnails, geocoding and notifications react to the `activity.created` event, and each has a scheduled backfill that repairs missed events.

## Activities and ingestion

Every activity enters through one pipeline, whatever its source: a single upload, a bulk import, or a Strava or Garmin sync. It is parsed into a canonical `ParsedFile`, enriched, deduplicated, saved, and announced with an `activity.created` event.

**Activity types.** There are 47 types (`activity/constants.py`). Nine count as cycling: Ride, Gravel ride, MTB ride, Virtual ride, Commuting ride, Indoor ride, Mixed surface ride, E-Bike ride and E-Mountain Bike ride.

**Import formats and what is read from them**

| Format | Library | Streams stored | Notes |
| --- | --- | --- | --- |
| .fit | fitdecode | HR, power, cadence, elevation, speed, pace, map, temperature | Also laps, sets, workout steps and RPE. This is the preferred format. |
| .gpx | gpxpy | HR, cadence, power, elevation, speed, pace, map | Speed is computed from positions. A `gpxtpx:speed` value from a wheel sensor is ignored. |
| .tcx | tcxreader | HR, cadence, power, elevation, speed, pace, map | Recording pauses have been excluded since v0.20.2. |
| .gz | — | as the inner file |  |

The eight stream types are defined in `activity_streams/constants.py`. Heart-rate zone percentages are computed at import time. Since v0.20.1 the import also smooths elevation and calculates a max speed that ignores single GPS glitches.

**Ways to import**

- **Upload API:** `POST /api/v1/activities/upload`. It accepts a JWT or an API key with the `activities:upload` scope, sent in the `X-API-Key` header. It is asynchronous: it returns `202` with a job id, and you poll `GET /api/v1/activities/ingestion-jobs/{job_id}`. An optional `Idempotency-Key` header makes retries safe.
- **Bulk import:** a ZIP upload (up to 500 MiB and 20,000 files), or files placed in a server folder and started from the UI. Strava export ZIPs and Nike Run Club exports (converted to .fit) are also supported. There is no folder that is watched and imported automatically.
- **Provider sync:** Strava and Garmin Connect, polled by scheduled jobs.
- **Deduplication order:** Strava activity id, then Garmin activity id plus start time, then the file's SHA-256 plus start time. A probable duplicate is stored hidden, and the user gets a notification.

**Activity detail in the UI:** map, metrics grid, a chart per stream, heart-rate zones with time in zone (new in v0.20.0), laps, workout sets, gear, a media gallery and privacy alerts. There are no segments, no leaderboards and no power analytics beyond averages and normalized power.

## Everything else it does

Beyond activities, Endurain covers integrations, a mobile recorder, gear wear, health logging, a small social layer, and strong authentication. The table lists what the code actually does today.

| Area | What exists (v0.20.2) | Limits seen in the code |
| --- | --- | --- |
| Strava | OAuth link with the user's own API client, hourly import of new activities, gear import (bikes, shoes) | Import only: nothing is pushed back to Strava. |
| Garmin Connect | Activities, gear and health (sleep, steps, weight, body composition), MFA login, China accounts | Uses an unofficial login and can break when Garmin changes it. A `GARMIN_TOKEN_EXPIRED` notification exists. |
| Mobile app ([endurain-flutter](https://github.com/endurain-project/endurain-flutter)) | GPS recording with auto-pause, outlier filter and audio announcements. BLE sensors: heart rate (0x180D), cycling speed/cadence (0x1816), power (0x1818), running speed/cadence (0x1814). Writes GPX with `gpxtpx:hr`/`cad`, an upload queue for offline use, health import from HealthKit or Health Connect | The CSC parser skips wheel revolutions, so a speed sensor gives cadence only. There is no wheel circumference setting. Distributed through TestFlight and a closed Google beta. |
| Gear | Bikes, shoes, wetsuits, racquets, skis, snowboards, windsurf. 44 bike component types (chain, cassette, tubeless sealant, brake pads and more), each with purchase date, price and expected km. A wear bar in the UI | Wear is measured by distance only, not time (sealant ages in months). No notification when a part is worn out. |
| Health | Weight, steps, sleep (with scoring), resting HR, water, fasting, bowel log, daily targets | Not bike-specific. |
| Goals and summary | User goals per sport, week/month/year summaries, per-type breakdowns | — |
| Social | Followers with follow requests, an activity feed, public, followers-only or private visibility, public activity pages | No comments, kudos, segments or clubs. These are on the roadmap. |
| Privacy | Default visibility, plus per-user switches to hide start time, location, map, HR, power, cadence, elevation, speed, pace, laps, sets and gear | No privacy zones: the map can only be hidden entirely, not trimmed around home. |
| Auth and accounts | Local login, TOTP MFA with backup codes, SSO through OIDC/SAML, sign-up with email verification and admin approval, password reset, scoped API keys, session management, profile export and import | Passkeys are not supported yet (on the roadmap). |
| Operations | Docker image for amd64 and arm64, PostgreSQL, optional Redis, durable background jobs, multi-user with admin and user roles, 30 UI languages, custom map tiles | — |

## Recent changes (v0.18 → v0.20.2)

Since May 2026 the changes have mostly been under the hood: the new architecture, data accuracy and security, not new user features. Each row is taken from the git history.

| Date | Release | Change |
| --- | --- | --- |
| 2026-10-27 | v0.20.2 | GPX/TCX imports drop recording pauses. FIT timezone comes from the local timestamp. Moving time is shown in the summary. Elevation is computed from a stream smoothed once. |
| 2026-10-21 | v0.20.1 | Max speed ignores single GPS glitches. GPS elevation is smoothed on import, matching the mobile app. Deleting an activity frees its upload idempotency key. |
| 2026-10-21 | v0.20.0 | **Breaking:** the backend was rebuilt on the JASIL platform library, as modules with event-driven ingestion. Uploads became async jobs at `/activities/upload`. Time in zone was added to the HR zones card. Apprise was replaced by durable email jobs. SSRF and X-Forwarded-For were hardened. |
| 2026-10-08 | v0.19.3 | The repository moved from Codeberg back to GitHub. |
| 2026-09-01 | v0.19.1 | Fixed zero-value GPX sensor streams, the configured tile server, the first day of the week, and the FIT sub-sport fallback. |
| 2026-07-22 | v0.19.0 | UI rebuilt with Tailwind v4 and shadcn-vue. Jump rope type. Garmin China accounts. Single-use WebSocket tickets. Anti-lockout when unlinking the last login method. The container runs as non-root. HR zones are computed at import. |
| 2026-05-14 | v0.18.0 | Activity laps and media modules. FIT temperature stream. PKCE for OAuth. Redis for rate limits and MFA. Step-up verification for API keys and MFA setup. Localized emails. Multi-arch Docker. SSRF protection. |

The official docs lag behind the code in at least one place: they still list `POST /activities/create/upload`, but the route in the code is `POST /api/v1/activities/upload`. A script written from the docs will call a route that does not exist.

## Mobile app (endurain-flutter v0.10.2)

The app is a solid, privacy-minded GPS recorder that saves the ride locally, then uploads a GPX to the server. It is not yet a cycling computer: one wheel sensor is ignored, there are only five activity types, and there is no navigation or offline map. The findings come from the [endurain-flutter](https://github.com/endurain-project/endurain-flutter) repo at v0.10.2+19 (2026-10-21), its README and its CHANGELOG.

**Size and stack:** about 29,600 lines of Dart and 170 test files. Native recorders are written in Kotlin (about 4,000 lines) and Swift (about 3,300 lines). It uses flutter\_map with OpenStreetMap tiles, geolocator, universal\_ble, health, sqflite and Sentry. License: AGPL-3.0, with a CLA for contributions.

| Area | What it does | Gaps for a cyclist |
| --- | --- | --- |
| Recording | Start, pause, resume and stop on the map. Configurable auto-pause and auto-resume. A native foreground service (Android) and CoreLocation (iOS) keep recording in the background and survive the app being reopened. GPS outlier filter, and max speed from a median window | Activity types are only Run, Ride, Walk, Hike and Other, so there is no Gravel or MTB. Live speed always comes from GPS. |
| Sensors (BLE) | One heart-rate monitor, one power meter and one cadence sensor at a time (CSC or running RSC). They reconnect automatically and are stamped on each GPX point | Wheel revolutions in CSC packets are skipped in both the Dart and the Kotlin code, so a speed sensor adds nothing. No wheel circumference. No ANT+. |
| Upload | The ride is always saved locally first (SQLite + GPX). A durable queue retries on resume or when the connection returns. An `Idempotency-Key` on every upload. Waits for the server's import job to finish (v0.10.0) | GPX only, no FIT. Sensor speed and temperature are not written. |
| History | Local history with a route preview and GPX share | Activities that are on the server are not shown. That is the app's own next roadmap item. |
| Map | Live position, heading, configurable tile server | No offline tiles, and no route import or turn-by-turn navigation. |
| Audio | On-device spoken announcements by distance or time, per activity type, with audio ducking | — |
| Health import | Picks route-carrying workouts from HealthKit or Health Connect, converts them to GPX, and sends them through the same upload queue | — |
| Auth and privacy | Server URL, PKCE login, SSO, MFA, an offline guest mode, secure storage. Local diagnostics | Optional, opt-in crash reports go to `diagnostics.endurain.com`, a service run by the project, not your own server. |
| Customization | 30 languages, dark and light themes, metric or imperial | I found no configurable data screens; the live stats are fixed. |

In short, the app's foundations are worth copying as ideas: a native background recorder, saving locally first, a durable upload queue and idempotent uploads. The bike-specific layer on top of them is what is missing.

## Gaps and bugs that matter for a bike-first app

Two bugs found in the code break a rider with a speed sensor and a power meter. The rest are missing features a cyclist would expect. I confirmed the code-level items by reading the source, not by running it.

| # | Finding | Evidence in the code | Effect for a cyclist |
| --- | --- | --- | --- |
| 1 | **Bug: GPX power in `PowerInWatts` is dropped.** The tag name is lowercased and then compared with `"PowerInWatts"`, which can never match. | `activity_file_import/gpx_utils.py`, `_extract_extension_data` (around line 240) | Power from Garmin, Strava and OpenTracks GPX exports is lost. Only the mobile app's own `<power>` tag is read. |
| 2 | **A wheel speed sensor is ignored end to end.** The mobile app's CSC parsers (Dart and Kotlin) skip wheel revolutions, and the GPX parser ignores `gpxtpx:speed`. | `cycling_speed_cadence_measurement_parser.dart`; `gpx_utils.py` computes speed from positions only | Distance and speed in the woods still come from GPS. The sensor bought for that purpose adds nothing. |
| 3 | The temperature stream is stored but not served by the per-type stream route, which stops at type 7. | `activity_streams/dependencies.py` (`le=STREAM_TYPE_MAP`) | Minor. The list route and the UI do show temperature; only \`GET /streams/8\` is rejected. |
| 4 | No privacy zones. | Privacy settings have `hide_activity_map` only | You cannot share a ride while hiding the first and last few hundred metres near home. |
| 5 | Component wear is measured by distance only, with no alerts. | `gear_components.expected_kms`; no notification type for wear | No reminder to replace the chain or refresh tubeless sealant (which goes off over months). |
| 6 | No automatic ingestion from a phone or folder, and no push to other services. | Bulk import is started manually; Strava is import-only | Endurain alone cannot reproduce the hands-off "stop the ride and it appears" flow of Wahoo Fitness and Strava. |
| 7 | No segments, climbs, power curve, FTP or training load. | Not in the modules; segments and challenges are on the roadmap | A cyclist's main analysis tools are missing. |
| 8 | No live tracking. | The WebSocket only pushes from server to client; there is no live-session API | No Beacon-style live location sharing for safety on solo gravel rides. |
| 9 | Docs and code disagree on the upload route. | `docs/integrate/api-keys.md` vs `activity_ingestion/router.py` | Integrations built from the docs fail. |
| 10 | One main maintainer, in a feature freeze. | Feature-freeze blog posts (May to October 2026) | Features arrive slowly. That is part of the case for building your own. |

## Takeaways for Velomine

Keep Endurain's ingestion design, and differentiate on what a cyclist feels: sensors, automatic sync, privacy zones and bike maintenance. Write the code clean-room unless you are willing to license Velomine under AGPL-3.0.

**Worth copying as ideas (not code)**

- One pipeline for every source: parse to a canonical model, then enrich, deduplicate, save and emit an event. Thumbnails, geocoding and notifications are subscribers, each with a scheduled backfill.
- An async upload route with job polling and an `Idempotency-Key` header. This is what makes automatic phone sync safe on flaky connections.
- Scoped API keys that can only upload, so the phone never holds a full-power token.
- Per-stream privacy switches, and storing the original file next to the parsed data.

**Where Velomine can be better from day one**

1. Correct sensor handling: wheel-sensor speed and distance preferred over GPS, wheel circumference per bike, and every common GPX extension (`gpxtpx:hr`, `cad`, `speed`, `atemp` and `PowerInWatts`).
2. Automatic sync: the phone app uploads as soon as the ride stops, plus a watched folder for files from OpenTracks or Nextcloud.
3. Privacy zones around home and work, applied before anything is shared.
4. Bike maintenance: wear by distance, hours or months per component, with reminders.
5. Cycling analysis: climbs, power curve and FTP, and self-hosted segments later.
6. Optional live tracking for solo rides, shared through an expiring link.
7. FIT export, so your data can leave as easily as it arrives.

## Velomine design: how rides get in

Every ride ends up as a FIT file sent to one Velomine upload endpoint. Use case B (the phone records) is fully under Velomine's control. Use case A (a bike computer records) depends on how each brand lets the file out.

&#91;embedded content: Velomine ingestion · 4 routes, 1 endpoint\]

### Use case B: the phone is the bike computer

The sensors connect directly to the Velomine app over standard Bluetooth profiles. No brand app or cloud is involved, on Android or iPhone.

| Sensor | Bluetooth profile | What the app gets |
| --- | --- | --- |
| Heart rate strap | Heart Rate (0x180D) | BPM, sometimes R-R intervals for HRV |
| Speed/cadence sensor | Cycling Speed and Cadence (0x1816) | Wheel and crank revolutions. The app turns them into speed, distance and cadence with the wheel circumference set per bike |
| Power meter | Cycling Power (0x1818) | Watts, often cadence |

**App stack:** Flutter for the UI, sensor pairing, history and uploads, using a Bluetooth LE library such as universal\_ble (the one Endurain uses). A native recorder per platform keeps GPS and sensors running with the screen off: a Kotlin foreground service on Android, Swift with location and Bluetooth background modes on iOS. That recorder is the hardest part of the app (Endurain needed about 4,000 lines of Kotlin and 3,300 of Swift).

**Recording rules:**

- Speed and distance come from the wheel sensor when one is paired, and from GPS otherwise.
- The ride is saved on the phone first, as FIT.
- A queue uploads it when there is signal, with an `Idempotency-Key` so a retry never creates a duplicate.

**Limits to accept:**

- Bluetooth only, no ANT+. iPhone has no ANT+, and Android support is patchy.
- The sensor must speak Bluetooth, which most recent ones do (some old Garmin sensors are ANT+ only).
- Some cheap sensors allow only one Bluetooth connection at a time, so they cannot be shared with a bike computer that also uses Bluetooth.
- Only standard data is available. Proprietary extras, such as data stored in a strap, need the brand's protocol.

**Derived metrics** are computed by Velomine, not by the sensors:

- With heart rate only: TRIMP load, fitness, fatigue and form, and zones.
- With a power meter, also: NP, IF, TSS, FTP and a VO2max estimate.
- With R-R intervals: HRV.

### Use case A: a bike computer records the ride

The sensors pair to the bike computer, so the only problem is getting its FIT file to Velomine. The Velomine app cannot talk to a bike computer over standard Bluetooth: file transfer uses each brand's private protocol.

| User has | Route into Velomine | User effort | Works on iPhone |
| --- | --- | --- | --- |
| Garmin | Server connector using Garmin's personal key (pull, own account, FIT files) | None | Yes, phone not involved |
| Wahoo | Server connector to the Wahoo cloud (needs Wahoo's app approval), or a watched Dropbox folder | None after setup | Yes, phone not involved |
| Bryton, iGPSPORT, others with no API | USB to a computer, then the web page or a desktop tool that uploads automatically | Plug in the cable | Yes, via the computer |
| Any device | Drag the FIT onto the web page, or share it to the Velomine app | Manual | Yes |

**Android-only extras:** reading FIT files from a bike computer plugged into the phone over USB, and a Gadgetbridge hand-off for supported Garmin Edges over Bluetooth.

**iPhone limits:** apps cannot read MTP devices, which is how newer Garmin Edges transfer files, and there is no ANT+ and no Gadgetbridge. iPhone users therefore rely on the server connectors or a computer.

### Build order

1. **Version 1:** upload endpoint, drag-and-drop web page, and the phone app for use case B. This already covers every bike computer, manually.
2. **Version 2:** Garmin and Wahoo connectors, which make use case A automatic for most bike computer owners.
3. **Later:** watched Dropbox or Nextcloud folder, desktop USB tool, Android USB and Gadgetbridge extras.
