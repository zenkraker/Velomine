# Endurain → Velomine: what can be ported

Comparison of the Endurain backend code with Velomine's [v1 scope](../design/v1-scope-and-architecture.md), [architecture](../architecture.md) and the [Endurain feature analysis](endurain-feature-analysis-v0.20.2.md).

**Clean-room:** "port" here always means *re-implement the idea in .NET/Flutter*. No Endurain code is copied, translated or adapted (AGPL-3.0).

## Method

- Source: `endurain-project/endurain` at commit `712b04d` (2026-10-27, v0.20.2), the same commit as the feature analysis. Cloned outside this repository.
- Structure from the code-graph AST extractor (graphify): 474 Python files under `backend/app` (tests and migrations excluded), 6,310 symbols, 16,515 edges. That is too large for a curated graph, so symbols were collapsed into a module-level graph (files, symbols and cross-module edges per module) to choose what to read.
- Then the models, routers and key services of each module were read by hand. Database columns and routes below come from the code, not from Endurain's docs.

## Module map

| Endurain module | Files | Symbols | Edges in from other modules | What it is |
|-----------------|------:|--------:|----------------------------:|------------|
| `core` | 33 | 585 | 1,454 | Config, DB, rate limit, SSRF guard, signed URLs, ETag, ProblemDetails, scheduler, mail, i18n |
| `activities` | 168 | 1,738 | 238 | 12 sub-modules: activity, file import, ingestion, streams, laps, sets, workout steps, media, thumbnail, geocoding, file storage, exercise titles |
| `auth` | 99 | 1,262 | 395 | Credentials, sessions with refresh-token rotation, MFA + backup codes, OIDC providers, API keys, password reset, sign-up tokens |
| `users` | 40 | 570 | 237 | Users, profile (export/import), privacy settings, default gear, goals, integrations |
| `health` | 43 | 439 | 67 | Weight, steps, sleep, water, fasting, bowel log, targets |
| `gears` | 13 | 147 | 50 | Gear and components |
| `strava` | 10 | 111 | 7 | Strava OAuth and import |
| `followers` | 12 | 110 | 8 | Follow requests |
| `server_settings` | 13 | 108 | 38 | Instance settings |
| `notifications` | 11 | 102 | 10 | In-app notifications |
| `garmin` | 9 | 88 | 9 | Garmin Connect (unofficial login) |
| `websocket` | 6 | 52 | 35 | Server → client push |

Almost everything depends on `core` and `auth`; feature modules barely depend on each other. In Velomine these map onto feature folders (vertical slices); the cross-cutting parts of `core` are mostly covered by ASP.NET Core itself.

## Feature by feature

Verdicts: **Port** (same idea), **Reshape** (port the idea, changed for cycling or for Velomine's architecture), **Built in** (.NET/ASP.NET Core already provides it), **Skip**.

### Rides and ingestion

| Endurain (where) | Verdict | Velomine version |
|------------------|---------|------------------|
| Activity model (`activities/activity/models.py`): distance, times, timezone, elevation gain/loss, speed, power avg/max/NP, HR, cadence, calories, city/town/country | Port | Same core fields on `Ride`, SI units. Add speed source (wheel/GPS) and IF/TSS. |
| `private_notes`, `workout_feeling`, `workout_rpe` on the activity | Port | Become the ride's RPE and notes in Wellbeing (v1). |
| `tracker_manufacturer`, `tracker_model` | Port | Useful to tell phone rides from bike computer rides and to debug parsers. |
| `version` column on activity | Port | Optimistic concurrency with an EF Core concurrency token (built in). |
| 47 activity types (`constants.py`) | Reshape | About 8 cycling types. |
| Ingestion job (`activity_ingestion/models.py`): `idempotency_key`, `request_fingerprint`, file counts, status, `error_code`, `activity_ids` | Reshape | Velomine keeps idempotency key and status on the ride row itself (no job table). For a bulk Strava-export import (v2), keep counts done/failed on one import row so the UI can show progress. |
| Event pipeline with subscribers + scheduled backfills (`events.py`, `subscribers.py`, `scheduled_jobs.py`) | Reshape | No events in Velomine: the ingestion `BackgroundService` runs parse → enrich → dedupe → save → thumbnail → geocode → metrics in one pass. |
| Per-row retry times `thumbnail_next_attempt_at`, `location_next_lookup_at` | Port | Matches Velomine's "state on the row" approach: if the geocoder or tile server is down, store the next attempt time on the ride and let a `PeriodicTimer` retry. No queue needed. |
| `dedup_key` + dedupe order (provider id, then file hash + start time), probable duplicate stored hidden + `DUPLICATE_ACTIVITY` notification | Port | As in the architecture doc. |
| FIT parsing (`fit_utils.py`, 880 lines), GPX (`gpx_utils.py`, 703), TCX | Reshape | FIT via `Garmin.FIT.Sdk`; GPX/TCX with BCL XML. **Bug confirmed in the code:** `gpx_utils.py` lowercases the tag (line 161) and then compares it with `"PowerInWatts"` (line 240), so that power is always lost. Velomine must test with a Garmin/Strava GPX containing `PowerInWatts`. |
| Streams: one row per stream type per activity with a JSON array `stream_waypoints` (`activity_streams/models.py`) | Port (input for ADR) | Evidence for the "one array column per stream" option in the architecture doc. Measure `jsonb` vs `real[]`/`bytea` before fixing the schema. |
| Laps (`activity_laps`), with many running-only fields (vertical oscillation, stance time, step length) | Reshape | Keep cycling lap fields only (times, distance, HR, power, NP, cadence, ascent, trigger). |
| Sets, workout steps, exercise titles | Skip | Gym and running concepts. |
| Media (`activity_media`): path, type, content hash | Port | Ride photos, content-addressed like originals. |
| Map thumbnail (`activity_thumbnail/render.py`): static WebP from OSM tiles + route polyline, served with a signed URL | Port | Render in the ingestion pass, serve through a signed URL (see Security). Respect the tile server's usage policy; use the configured tile server. |
| Reverse geocoding (`activity_geocoding`): Nominatim (default) or Photon, config `REVERSE_GEO_PROVIDER` | Port | Off by default (it is a third-party call); admin chooses Nominatim, Photon or their own instance. Respect Nominatim's 1 request/second policy. |
| Bulk import: ZIP upload and server folder (`POST /bulk-import`, `/bulk-import/folder`) | Reshape | v2: Strava export ZIP import. The server-folder import is the base for the v2 watched folder. |
| Summaries and stats (`summary_service.py`, `GET /users/{id}/stats`) | Port | Weekly, monthly and yearly totals, cycling only (v1). |
| Activity feed (`GET /feed`) | Skip | No feed. |

### Bikes

| Endurain (where) | Verdict | Velomine version |
|------------------|---------|------------------|
| Gear (`gears/gear/models.py`): brand, model, nickname, type, active, `initial_kms`, purchase value | Reshape | Bikes only. Add wheel circumference. Keep `initial_kms` (bikes bought used). |
| Components (`gear_components/models.py`): type, brand, model, purchase/retired date, active, `expected_kms`, value | Reshape | Add expected hours and months; reminders (v2). |
| Default gear per activity type: one column per type (`users_default_gear`, 15 columns) | Reshape | One row per (member, ride type) → bike. Avoids a column per type. |
| Strava/Garmin gear ids on gear | Port | Keep a provider id per bike for connector imports (v2). |

### Accounts and security

| Endurain (where) | Verdict | Velomine version |
|------------------|---------|------------------|
| Local login, password hashing, password reset tokens, sign-up tokens with email verification and admin approval | Built in | ASP.NET Core Identity: password hashing, reset and email-confirmation tokens. Admin approval is one flag + one endpoint. |
| MFA (TOTP) + backup codes | Built in | Identity authenticator keys and recovery codes. |
| OIDC providers stored in DB, with provider templates, account linking and link tokens (`auth/identity_providers`) | Reshape | ASP.NET Core OpenID Connect handler. v1 configures providers by environment variables; DB-managed providers and templates only if admins need them. Account linking via Identity external logins. |
| Sessions with device info, refresh-token rotation, token families and reuse detection, CSRF hash (`auth/sessions`) | Reshape | Web: Identity cookie + built-in antiforgery. Mobile: Identity bearer tokens with refresh. Keep the idea of a session list the member can revoke ("log out other devices"). |
| API keys with scopes, prefix + hash, expiry, last used, revoke (`auth/api_keys`) | Port | Scoped keys (`rides:upload`) for the USB tool and scripts. Store only a hash; show the prefix. |
| Signed capability URLs for images (`core/signing.py`): per-feature salt, optional max age | Port | Thumbnails and photos on share pages via signed, expiring URLs, using ASP.NET Core Data Protection (`ITimeLimitedDataProtector` with a purpose string per feature). |
| SSRF guard for outbound calls (`core/network.py`) | Port | Needed for admin-entered URLs (tile server, OIDC issuer, connectors): block private and loopback addresses unless the admin allows them. |
| Rate limiting (`core/rate_limit.py`, Redis) | Built in | ASP.NET Core rate limiter, in memory (one instance, no Redis). |
| ETag (`core/etag.py`), ProblemDetails (`core/problem_details.py`) | Built in | ASP.NET Core output caching/ETag and `ProblemDetails`. |
| WebSocket with single-use tickets (`websocket`) | Skip (v1) | Clients poll the ride status after upload. Revisit only for live tracking (later). |

### Profile, privacy, sharing

| Endurain (where) | Verdict | Velomine version |
|------------------|---------|------------------|
| Profile fields (`users/users/models.py`): birthdate, gender, height, max HR, units, language, first day of week, timezone, photo | Reshape | Keep birthdate, max HR, units, language, first day of week, timezone, photo. Add weight and FTP. Height/gender only if an analytic needs them. |
| Per-user privacy defaults and per-activity hide flags (start time, location, map, HR, power, cadence, elevation, speed, laps, gear) | Port | Per-stream switches, as planned. Drop pace and sets. Add privacy zones (Endurain has none). |
| Visibility (public, followers, private) + public activity page (`public_router.py`) | Reshape | Private by default; share links with optional expiry instead of public pages. |
| Followers, follow requests | Skip | Replaced by clubs and coaches. |
| Profile export/import as a ZIP with `data/*.json` and files (`users_profile/export_service.py`) | Port | Full export: original files + JSON per table. Import is useful for moving between Velomine servers. |
| Goals: interval × activity type × metric (calories, count, distance, elevation, duration) with results (`users_goals`) | Port | Not in our v1 list; small and useful for cyclists (distance or elevation per week/month/year). Candidate for v1. |

### Health, notifications, settings, integrations

| Endurain (where) | Verdict | Velomine version |
|------------------|---------|------------------|
| Weight series, steps, sleep, water, fasting, bowel log, targets (`health/*`) | Skip | Replaced by daily check-in, RPE and cycle tracking; weight is a profile field. |
| Notifications: types `NEW_ACTIVITY`, `DUPLICATE_ACTIVITY`, follower types, `GARMIN_TOKEN_EXPIRED`, `ADMIN_NEW_SIGN_UP_APPROVAL_REQUEST`; read/unread, mark all read | Reshape | Keep ride processed, duplicate, sign-up approval, connector token expired. Add component worn, coach request, import failed. |
| Server settings (`server_settings/models.py`): units, public links, sign-up on/approval/email verification, SSO on, local login on, SSO auto-redirect, tile server URL + attribution + API key, map background, password policy, login photo, currency | Reshape | Keep sign-up, SSO and local login switches, tile server URL/attribution/key, password policy (Identity options). Drop currency and login photo. |
| Strava: per-user OAuth client, activity and gear import | Reshape | v2 option; v1 only one-time import of a Strava export. |
| Garmin Connect (unofficial login with MFA) | Reshape | Garmin's official personal key (v2). |
| i18n (`core/i18n`), 30 languages | Reshape | English and Italian first, Flutter's built-in localisation. |

## Found in the code but not yet in Velomine's docs

Worth adding to the architecture when the relevant feature is built:

1. **Signed, expiring image URLs** for thumbnails and photos on share pages (Data Protection).
2. **SSRF guard** on every admin-configurable outbound URL.
3. **Next-attempt time on the ride row** for thumbnail and geocoding retries.
4. **Optimistic concurrency** (`version`) on rides.
5. **Device/session list** with "log out other devices".
6. **Goals** per period and metric.
7. **Import progress row** for bulk imports.
8. **Reverse geocoding off by default**, with a choice of provider.

## Not checked

- The Vue frontend and the Flutter app repo were not read; the feature analysis already covers the app.
- Scheduler internals, mail templates and the migration services were not read.
- Behaviour was read, not run; nothing was executed against a live Endurain.
