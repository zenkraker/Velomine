# API rules

Binding rules for the REST API, auth, sessions, uploads and export. Moved verbatim from `AGENTS.md`, which keeps the short version and links here.

## API

- REST under `/api/v1`, described by `FastEndpoints.OpenApi` as OpenAPI 3.0. DTOs stay flat: no `allOf`/`oneOf`, no inheritance, because the Dart generator does not support them.
- Every endpoint declares what it really accepts and returns (`Description(...)` in `Configure()`); operation names are short (`login`, `uploadRide`). The generated client is only as accurate as the document.
- After changing an endpoint, run `tools/generate-api-client.sh` and commit the regenerated client. Never edit `app/packages/velomine_api/` by hand; if a call is wrong, fix the endpoint's declaration.
- A released API version is never broken, because phones update late. Breaking changes go to `/api/v2`.
- **Uploads** go to `POST /api/v1/rides/uploads` and answer `202` with the ride id after the original file is saved; the client polls `GET /api/v1/rides/{id}`. The `Idempotency-Key` header (the phone sends its local ride id) makes a retry return the same ride. The optional `Bulk-Import: true` header marks one file of many: the ride is read and listed as usual, but the caller shows one summary and no notification is made for the file.
- **Streams** are served downsampled (`maxPoints`, default 1,500, up to 5,000).
- **Auth:** the Identity cookie for the web app, bearer tokens for the phone. The cookie is host-only.
- **Sessions:** every sign-in has a row in `accounts.user_sessions` (label and times, never an address) and carries its id. Access tokens last 15 minutes; cookies are revalidated against the row every 5 minutes. Refresh tokens are single-use: each refresh rotates a generation, and an older one revokes the session as stolen (RFC 9700). Password change or reset, role change, lock and a two-factor reset revoke every session.
- **Two-factor sign-in** uses Identity's authenticator provider with ten single-use recovery codes. Enrolling and disabling need the password. A wrong code counts toward the same lockout as a wrong password. Single sign-on bypasses the code.
- **Single sign-on, web:** Microsoft's OpenID Connect handler (code flow with PKCE); the account is found, linked by verified email, or created, then a normal cookie session starts.
- **Single sign-on, phone** (RFC 8252): a public client with PKCE through `flutter_appauth` and the redirect `com.velomine.app:/sso-callback`. The app posts the ID and access tokens to `POST /accounts/sso/token`; the server validates the ID token against the provider's discovery document and JWKS and is the trust boundary.
- **Password reset:** `forgot` always answers `202` when email is configured, so it never reveals who is registered; without email it answers `503` and an admin can make a one-time link. The link is built from `VELOMINE__PUBLICURL`, never the incoming Host header, and carries the token in the fragment.
- **Export** is a two-minute Data Protection token link (`POST /accounts/me/export-link`) that streams a ZIP built in a temporary file, so the phone can hand it to the system browser. Nothing secret goes in it.
- A ride's file downloads the same way: `POST /rides/{id}/file-link` gives a two-minute link to the original as received, or to a FIT file the server writes for a ride read from GPX or TCX.
- Rate limiting with the built-in ASP.NET Core limiter on login, upload and starting a club, plus an in-memory limit on the anonymous password endpoints. Uploads use a token bucket, so a whole folder can arrive at once while the sustained rate stays limited.

