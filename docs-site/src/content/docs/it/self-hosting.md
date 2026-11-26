---
title: Self-hosting
description: Avvia Velomine su un server per il tuo club.
---

Il self-hosting è gratuito, con tutte le funzioni e senza limite di membri. Tutto gira con Docker: il server, la web app e PostgreSQL. Un server self-hosted serve solo l'app; il sito di presentazione su velomine.eu è pubblicato a parte.

Un server usa lo stesso `docker-compose.yml` del tuo computer, con le immagini pubblicate dalla CI invece di una build, dietro HTTPS.

1. Clona il repository sul server, oppure copiaci `docker-compose.yml`.
2. Copia `.env.example` in `.env`, accanto a `docker-compose.yml`.
3. Imposta, **prima del primo avvio**:
   - `POSTGRES_PASSWORD`: il database conserva la prima password.
   - `VELOMINE__PUBLICURL`: l'indirizzo pubblico che i membri aprono, per esempio `https://club.example`. Compare nelle email di reimpostazione della password e nei calendari.
   - `VELOMINE__ADMIN__EMAIL` e `VELOMINE__ADMIN__PASSWORD`: il primo admin (almeno 10 caratteri, con una maiuscola, una minuscola e una cifra).
   - `VELOMINE_VERSION`: la release da usare. Mai `latest`.
4. Avvialo: `docker compose pull && docker compose up -d --wait`. `--wait` fallisce se il server e la web app non rispondono.
5. Metti il tuo HTTPS davanti alla porta del container web (`VELOMINE_PORT`, di norma 8080). Non esporre quella porta direttamente a Internet: è HTTP semplice.

I valori predefiniti sono solo per provarlo sul tuo computer. Imposta le password e l'indirizzo pubblico prima che altri possano raggiungerlo.

Per aggiornare, tornare indietro o fare un backup, vedi [Backup e aggiornamenti](/docs/it/backups-and-upgrades/). Per inviare email, vedi [Email](/docs/it/email/).

## Nuovi membri

Di norma chi si iscrive parte subito. Per approvare ogni persona a mano, attiva `VELOMINE__ACCOUNTS__REQUIREADMINAPPROVAL` (o *Admin, Settings* nell'app). Gli admin ricevono una notifica nell'app, e per email se SMTP è configurato, e il nuovo account non può accedere finché un admin non lo accetta.

Un server self-hosted non invia mai una email di verifica a chi si iscrive.

## Provarlo dal sorgente

Il [quick start](/docs/it/quick-start/) usa le immagini pubblicate. Qui invece si costruisce tutto dal sorgente con un solo comando: il server, la web app e PostgreSQL. Non servono .NET, Flutter né PostgreSQL installati.

| Cosa installare | Perché | Note |
|-----------------|--------|------|
| **Docker** con Compose 2.24 o successivo | Costruisce e avvia tutto | Windows e macOS: [Docker Desktop](https://www.docker.com/products/docker-desktop/) (su Windows con il backend WSL 2). Linux: Docker Engine più il plugin Compose. Il comando deve essere `docker compose` (con lo spazio). |
| **Git** | Per scaricare il codice | Una versione recente qualsiasi. |
| **Chrome, Edge o Firefox** | Per aprire la web app | Safari non è stato provato. |

```sh
git clone https://github.com/zenkraker/Velomine.git
cd Velomine
docker compose up --build
```

La prima volta servono circa 5-10 minuti; gli avvii successivi pochi secondi. È pronto quando il log mostra `Now listening on: http://0.0.0.0:8080`. Apri **http://localhost:8080** e accedi come `admin@velomine.local` con la password `Velomine-dev-1`.

Fermalo con Ctrl+C. `docker compose down` rimuove i container e conserva i dati; `docker compose down -v` cancella anche i dati (database, file caricati e chiavi), per ripartire da zero.

**Provare il single sign-on.** `compose.development.yaml` aggiunge Dex, un piccolo provider di accesso di prova:

```sh
docker compose -f docker-compose.yml -f compose.development.yaml up --build
```

Accedi con *Dex (local test)* come `rider@sso.test` / `password`. Serve anche la porta 5556, e Chrome, Edge o Firefox, che indirizzano `dex.localhost` alla tua macchina. Dex serve solo per provare; non usarlo mai su un server condiviso.

## Se qualcosa non va

| Problema | Cosa fare |
|----------|-----------|
| `port is already allocated` | Qualcos'altro usa la 8080 (o la 5556, con Dex). Fermalo, oppure imposta `VELOMINE_PORT`. |
| La build fallisce durante un download | Riavviala; conserva quello che ha già scaricato. Controlla la connessione o il proxy. |
| La pagina *Continue with Dex* non si trova | Usa Chrome, Edge o Firefox. Risolvono `dex.localhost` da soli; altri browser e alcuni strumenti no. |
| Il provider di accesso dice che l'indirizzo di ritorno è sbagliato | Hai cambiato `VELOMINE_PORT` senza modificare `deploy/dex/config.yaml`. |
| Vedi ancora la vecchia app dopo aver scaricato nuovo codice | Esegui di nuovo `docker compose up --build`. |
| Il container web non è healthy, o ogni pagina risponde 502 | Il server non è in esecuzione. `docker compose logs server` dice perché; `Could not create the admin: Passwords must ...` significa che `VELOMINE__ADMIN__PASSWORD` non rispetta le regole sopra. |
| Hai dimenticato la password dell'admin | L'impostazione vale solo finché non esiste un admin. Esegui `docker compose down -v` per ricominciare (cancella i dati). |
| Altro | `docker compose logs -f server` mostra il log del server; aggiungi `web`, `postgres` o `dex` per gli altri. |
