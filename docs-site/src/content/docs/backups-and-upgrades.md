---
title: Backups and upgrades
description: Back up a Velomine server, upgrade it and go back.
---

## Back up

Back up three things, **together**:

- the database: `docker compose exec postgres pg_dump -Fc -U velomine velomine > velomine.dump`
- the `velomine-files` volume: the uploaded ride files, kept as received.
- the `velomine-keys` volume. Without the keys, every member is signed out and old links stop working.

To restore, put the volumes back, start the stack, and load the dump into the empty database with `pg_restore`.

Each rider can also export everything from the app, original ride files included. That is their own copy, not a replacement for your backup.

## Upgrade

1. Set the new `VELOMINE_VERSION` in `.env`.
2. Run `docker compose pull && docker compose up -d --wait`.

Database changes are applied on start. The [Releases](https://github.com/zenkraker/Velomine/releases) page lists every version.

## Go back

Change `VELOMINE_VERSION` back and run the same command. Every database change stays compatible with the previous release, so going back **one** version is safe. Going back further is not promised: restore a backup taken before the upgrade instead.
