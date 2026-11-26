---
title: Self-hosting
description: Run Velomine on a server for your club.
---

Self-hosting is free, with every feature and no member limit. Everything runs with Docker: the server, the web app and PostgreSQL.

1. Copy `.env.example` to `.env` next to `docker-compose.yml`.
2. Set, **before the first start**:
   - `POSTGRES_PASSWORD`: the database keeps its first password afterwards.
   - `VELOMINE__PUBLICURL`: the public address members open, for example `https://club.example`. It appears in password reset emails and calendar feeds.
   - `VELOMINE__ADMIN__EMAIL` and `VELOMINE__ADMIN__PASSWORD`: the first admin (10 characters or more, with an upper-case letter, a lower-case letter and a digit).
   - `VELOMINE_VERSION`: the release to run. Never `latest`.
3. Start it: `docker compose pull && docker compose up -d --wait`. `--wait` fails unless the server and the web app answer.
4. Put your own HTTPS in front of port 8080 (`VELOMINE_PORT` changes it).

To upgrade or roll back, change `VELOMINE_VERSION` and run the same command again.

## New members

By default a new rider signs up and starts at once. To approve each one yourself, turn on `VELOMINE__ACCOUNTS__REQUIREADMINAPPROVAL` (or *Admin, Settings* in the app). Admins are then notified in the app, and by email when SMTP is set, and the new account cannot sign in until an admin accepts it.

A self-hosted server never sends a verification email to the person who signed up.
