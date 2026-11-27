# 0001. Sessions are Identity's own

Status: accepted. Replaces the session rules that were in `docs/rules/api.md`.

## Why

Web sign-ins ended after about five minutes. Cause: Identity rebuilds the cookie's principal when the security stamp is
revalidated (`SecurityStampValidator` replaces it with `SignInManager.CreateUserPrincipalAsync`), and our own claims
(`vlm_session`, `vlm_session_gen`) were not in the rebuilt principal, so our row check rejected the cookie. The phone
never went through that validator, which is why only the web broke. Our rules had a second set of lifetimes, a table,
a validator replacement and a refresh rotation on top of the framework, and the framework's renewal fought them.

The decision is to use what Microsoft documents and defaults, and to add nothing of our own on top.

## What changed, against the Microsoft documentation

| Topic | We had | Microsoft's (Learn and the ASP.NET Core source) | Now |
|---|---|---|---|
| Security stamp revalidation | `ValidationInterval` 5 minutes, `ISecurityStampValidator` replaced by our subclass | Default 30 minutes; the hook for custom claims is `OnRefreshingPrincipal` | Default, no replacement |
| Revocation check | A database row looked up on every request | `ValidatePrincipal` runs on every request, so work in it costs every request | None; the stamp is the revocation |
| Extra claims at sign-in | Session id and generation added with `SignInWithClaimsAsync` | The validator regenerates the principal without them | None |
| Access token lifetime | 15 minutes | `BearerTokenExpiration`, 1 hour | 1 hour |
| Refresh token | Single-use, generation rotated in `user_sessions`, reuse revokes the session (RFC 9700) | `/refresh` checks the token, its expiry and the stamp; not single-use | Identity's behaviour, plus our approval and lockout checks |
| Refresh expiry | Slid with each refresh on the phone, fixed 14 days from sign-in on the web | `RefreshTokenExpiration`, 14 days from the token's creation | Identity's behaviour |
| Per-device list and revoke | `user_sessions`, list, revoke one, log out others | Not provided; Learn says `SignOutAsync` does not invalidate bearer tokens and the client discards them | Removed |
| Logout | Revoked the row, then signed out | `SignOutAsync` ends the cookie only | Same as Microsoft |
| Security changes | `UpdateSecurityStampAsync` and `RevokeAllAsync` | `UpdateSecurityStampAsync` | `UpdateSecurityStampAsync` |
| Two-factor change | Revoked the other devices, kept this one | `SetTwoFactorEnabledAsync` moves the stamp (checked by a test: the old refresh token is refused) | The stamp; this device is also signed out at its next check |
| Cleanup job | Daily `SessionCleanup` | None | Removed |
| Two-factor sign-in | Two calls: the password returned a signed challenge (`TwoFactorChallenges`), then `/login/two-factor` took the code | One call: Identity's `/login` takes `twoFactorCode` or `twoFactorRecoveryCode` with the password and runs `PasswordSignInAsync`, then `TwoFactorAuthenticatorSignInAsync` or `TwoFactorRecoveryCodeSignInAsync` | The same sequence in `Login`; `LoginTwoFactor` and `TwoFactorChallenges` are gone |
| Device label | Sent on every sign-in, shown in the session list | Not part of Identity | Removed from every request |
| Cookie lifetime and persistence | Not set | Framework defaults; `isPersistent` decides session or persistent cookie | Unchanged |

## Consequences

- A revoked account keeps working until the cookie's next stamp check (up to 30 minutes) or the access token's expiry
  (up to 1 hour). Locking an account still stops it at once from signing in and from refreshing.
- Members lose the "where am I signed in" list and "log out other devices". Changing the password remains the way to
  end every sign-in.
- `/api/v1` lost `GET /accounts/me/sessions`, `DELETE /accounts/me/sessions/{id}`,
  `POST /accounts/me/sessions/logout-others` and `POST /accounts/login/two-factor`, and `deviceLabel` left the
  requests. `POST /accounts/login` now answers `401 {"error":"two_factor_required"}` instead of `202` with a
  challenge when the account has a second factor, and takes `twoFactorCode` or `twoFactorRecoveryCode`. This breaks a
  released API version on purpose, with the owner's agreement, because no member uses the app yet.
- `accounts.user_sessions` is dropped by the `DropUserSessions` migration, in the same release that stops using it.
  The usual rule (never drop what the release just stopped using) was set aside by the owner for the same reason.
- A second-factor sign-in no longer offers "remember this device" (`rememberClient: false`); Identity's own /login
  would, for a persistent sign-in.
- The data export no longer contains `sessions.json`; the privacy page no longer lists devices and sessions.

## What stays our own, and why it is not Identity's `MapIdentityApi`

`MapIdentityApi` maps `/register`, `/login`, `/refresh`, `/confirmEmail`, `/forgotPassword`, `/resetPassword` and
`/manage/*`. Using it for `/login`, `/refresh` and `/register` is possible but costs more than it saves here:

- **Our rules for endpoints.** Endpoints are FastEndpoints with `Description(...)`, flat DTOs and short operation names,
  because the Dart client is generated from the OpenAPI document. Identity's minimal-API endpoints would not carry
  those names, and the client could not be regenerated or checked in this environment.
- **What the app reads.** The app tells wrong password, locked (423), not approved and unconfirmed email (403 with a
  code) apart. Identity answers all of them with a 401 problem.
- **`/register` cannot hold our product rules:** a display name, closed sign-up, admin approval and its notification,
  the cloud-only email confirmation, the solo trial and the demo lock. Identity's takes an email and a password.
- **`/login` and `/refresh` are now Identity's own sequence** wrapped in a FastEndpoints endpoint, with our approval and
  lockout checks added, so little of ours remains in them. They could move to `MapIdentityApi` later if the app moves
  to its request and response shapes.
