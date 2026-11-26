---
title: Self-hosting
description: Avvia Velomine su un server per il tuo club.
---

Il self-hosting è gratuito, con tutte le funzioni e senza limite di membri. Tutto gira con Docker: il server, la web app e PostgreSQL.

1. Copia `.env.example` in `.env`, accanto a `docker-compose.yml`.
2. Imposta, **prima del primo avvio**:
   - `POSTGRES_PASSWORD`: il database conserva la prima password.
   - `VELOMINE__PUBLICURL`: l'indirizzo pubblico che i membri aprono, per esempio `https://club.example`. Compare nelle email di reimpostazione della password e nei calendari.
   - `VELOMINE__ADMIN__EMAIL` e `VELOMINE__ADMIN__PASSWORD`: il primo admin (almeno 10 caratteri, con una maiuscola, una minuscola e una cifra).
   - `VELOMINE_VERSION`: la release da usare. Mai `latest`.
3. Avvialo: `docker compose pull && docker compose up -d --wait`. `--wait` fallisce se il server e la web app non rispondono.
4. Metti il tuo HTTPS davanti alla porta 8080 (`VELOMINE_PORT` la cambia).

Per aggiornare o tornare indietro, cambia `VELOMINE_VERSION` e rilancia lo stesso comando.

## Nuovi membri

Di norma chi si iscrive parte subito. Per approvare ogni persona a mano, attiva `VELOMINE__ACCOUNTS__REQUIREADMINAPPROVAL` (o *Admin, Settings* nell'app). Gli admin ricevono una notifica nell'app, e per email se SMTP è configurato, e il nuovo account non può accedere finché un admin non lo accetta.

Un server self-hosted non invia mai una email di verifica a chi si iscrive.
