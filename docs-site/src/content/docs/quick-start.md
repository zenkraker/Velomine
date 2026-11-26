---
title: Quick start
description: Run Velomine on your own computer in about a minute.
---

You need [Docker](https://docs.docker.com/get-started/get-docker/) with Compose 2.24 or newer (the command must be `docker compose`, with a space) and Git.

```sh
git clone https://github.com/zenkraker/Velomine.git
cd Velomine
VELOMINE_VERSION=0.2.0 docker compose up --no-build
```

Use the newest version from [Releases](https://github.com/zenkraker/Velomine/releases/latest) in place of `0.2.0`.

Open **http://localhost:8080**, press *Sign in*, and sign in as `admin@velomine.local` with the password `Velomine-dev-1`.

:::caution
These defaults are for trying it on your own machine. Before anyone else can reach it, follow [Self-hosting](/docs/self-hosting/).
:::

## The Android app

The APK is attached to every [release](https://github.com/zenkraker/Velomine/releases/latest). Install it and type your server's address when it asks. On an iPhone, the web app works in the browser.
