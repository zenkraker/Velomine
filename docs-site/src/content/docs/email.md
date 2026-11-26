---
title: Email
description: Set up SMTP so Velomine can send password resets and notifications.
---

Email is off until `VELOMINE__SMTP__HOST` and `VELOMINE__SMTP__FROM` are both set. The settings are environment variables only: the password is never stored in the database or shown in the app.

| Variable | Default | What it does |
|----------|---------|--------------|
| `VELOMINE__SMTP__HOST` | | The SMTP server. |
| `VELOMINE__SMTP__FROM` | | The sender: a bare address, or a name and address in quotes, for example `"Velomine <velomine@club.example>"`. |
| `VELOMINE__SMTP__PORT` | `587` | The SMTP port. |
| `VELOMINE__SMTP__SECURITY` | `starttls` | `starttls` (port 587), `ssl` (port 465) or `none` (a local relay only). |
| `VELOMINE__SMTP__USER` | | The login, if the server needs one. |
| `VELOMINE__SMTP__PASSWORD` | | Its password. |

Put them in `.env` and restart the stack. In the app, *Admin, Settings* shows the setup read-only, with **Send a test email**.

## What needs email

- **Password reset.** Without email, the reset page says it is not available, and an admin can make a one-time reset link instead.
- **Admin notifications.** When new accounts wait for approval, admins are notified in the app and also by email.
- **Address confirmation, on the hosted service only.** With `VELOMINE__ACCOUNTS__CLOUD` on, a new member confirms their address from an email link. A self-hosted server never sends it.
- **The site's forms.** `VELOMINE__FEEDBACK__ADDRESS` is where the anonymous feedback form and the early-access list are emailed. Leave it empty and the forms answer that they are unavailable. Nothing is stored.
