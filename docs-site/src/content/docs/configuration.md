---
title: Configuration
description: The settings that decide who can sign up and how.
---

Every setting is an environment variable. Names are upper case, with `__` for a nested setting (`VELOMINE__SMTP__HOST`). Put them in `.env`; the commented file `.env.example` lists all of them with their defaults.

| Variable | Default | What it does |
|----------|---------|--------------|
| `VELOMINE__ACCOUNTS__SIGNUPENABLED` | `true` | Whether new people can create an account. |
| `VELOMINE__ACCOUNTS__REQUIREADMINAPPROVAL` | `false` | On, new accounts wait for an admin, who is notified in the app and by email. Ignored on the cloud service. |
| `VELOMINE__ACCOUNTS__CLOUD` | `false` | The hosted service. On, a new member confirms their own address from an email link (needs SMTP) and never waits for an admin. Off (self-hosted), no verification email is sent. |
| `VELOMINE__ACCOUNTS__CLUBCREATIONENABLED` | `false` | Lets a rider without a club start one. Off, only the operator creates clubs. |

An admin can change the first, second and fourth in the app (*Admin, Settings*); a value saved there wins over the environment.
