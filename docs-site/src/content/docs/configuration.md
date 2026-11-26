---
title: Configuration
description: Every setting is an environment variable. The ones that matter first, and what your server talks to.
---

Every setting is an environment variable. Names are upper case, with `__` for a nested setting (`VELOMINE__SMTP__HOST` is the server's `Velomine:Smtp:Host`). Put them in `.env` next to `docker-compose.yml`; every variable in it reaches the server. The commented file [`.env.example`](https://github.com/zenkraker/Velomine/blob/main/.env.example) lists every setting with its default and what it does.

## Accounts

| Variable | Default | What it does |
|----------|---------|--------------|
| `VELOMINE__ACCOUNTS__SIGNUPENABLED` | `true` | Whether new people can create an account. |
| `VELOMINE__ACCOUNTS__REQUIREADMINAPPROVAL` | `false` | On, new accounts wait for an admin, who is notified in the app and by email. Ignored on the cloud service. |
| `VELOMINE__ACCOUNTS__CLOUD` | `false` | The hosted service. On, a new member confirms their own address from an email link (needs SMTP) and never waits for an admin. Off (self-hosted), no verification email is sent. |
| `VELOMINE__ACCOUNTS__CLUBCREATIONENABLED` | `false` | Lets a rider without a club start one. Off, only the operator creates clubs. |

An admin can change the first, second and fourth in the app (*Admin, Settings*); a value saved there wins over the environment.

## What your server talks to

Nothing is sent to the Velomine project by default.

| What | Default | Setting |
|------|---------|---------|
| Map tiles, loaded by each member's browser or phone | OpenStreetMap | `VELOMINE__MAP__TILEURL` |
| Error reports, traces and logs | Off | `VELOMINE__TELEMETRY__*` and the standard `OTEL_EXPORTER_OTLP_*` |
| Email (password reset, notifications) | Off | `VELOMINE__SMTP__*`, see [Email](/docs/email/) |
| Shared parts catalogue: fetch a list, send back new parts | Off; the server keeps its own bundled list | `VELOMINE__CATALOGUE__*` |
| Anonymous feedback form and early-access list on the public site | Off | `VELOMINE__FEEDBACK__ADDRESS` (needs email); `VELOMINE__FEEDBACK__SITEURL` when the site is on another host |
| Single sign-on | Off | `VELOMINE__SSO__*` |

Telemetry never carries ride or health data, names, email or IP addresses, and each destination is optional. Traces, metrics and logs leave only over OTLP, to any OpenTelemetry backend; error reports go to the DSN of any compatible error-tracking service.

## Single sign-on

Any OpenID Connect provider works. It is on when `VELOMINE__SSO__AUTHORITY` is set. In the provider, register `https://<your host>/signin-oidc` for the web client and `com.velomine.app:/sso-callback` for the phone. `VELOMINE__SSO__CLIENTID` (and `CLIENTSECRET`, if the provider needs one) is for the web client; `VELOMINE__SSO__APPCLIENTID` is the phone's public client, with no secret. Like email, these are environment only.
