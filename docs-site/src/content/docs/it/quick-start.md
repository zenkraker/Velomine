---
title: Per iniziare
description: Avvia Velomine sul tuo computer in circa un minuto.
---

Servono [Docker](https://docs.docker.com/get-started/get-docker/) con Compose 2.24 o successivo (il comando deve essere `docker compose`, con lo spazio) e Git.

```sh
git clone https://github.com/zenkraker/Velomine.git
cd Velomine
VELOMINE_VERSION=0.1.22 docker compose up --no-build
```

Al posto di `0.1.22` usa l'ultima versione tra le [Releases](https://github.com/zenkraker/Velomine/releases/latest).

Apri **http://localhost:8080**, premi *Sign in* e accedi come `admin@velomine.local` con la password `Velomine-dev-1`.

:::caution
Questi valori sono pensati per provarlo sul tuo computer. Prima che altri possano raggiungerlo, segui [Self-hosting](/docs/it/self-hosting/).
:::

## L'app Android

L'APK è allegato a ogni [release](https://github.com/zenkraker/Velomine/releases/latest). Installalo e scrivi l'indirizzo del tuo server quando richiesto. Su iPhone la web app funziona nel browser.
