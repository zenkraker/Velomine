---
title: Configurazione
description: Ogni impostazione è una variabile d'ambiente. Quelle importanti per prime, e con chi parla il tuo server.
---

Ogni impostazione è una variabile d'ambiente. I nomi sono in maiuscolo, con `__` per le impostazioni annidate (`VELOMINE__SMTP__HOST` è `Velomine:Smtp:Host` per il server). Mettile in `.env`, accanto a `docker-compose.yml`; ogni variabile lì dentro arriva al server. Il file commentato [`.env.example`](https://github.com/zenkraker/Velomine/blob/main/.env.example) elenca ogni impostazione con il valore predefinito e cosa fa.

## Account

| Variabile | Predefinito | Cosa fa |
|-----------|-------------|---------|
| `VELOMINE__ACCOUNTS__SIGNUPENABLED` | `true` | Se nuove persone possono creare un account. |
| `VELOMINE__ACCOUNTS__REQUIREADMINAPPROVAL` | `false` | Attivo, i nuovi account aspettano un admin, che riceve una notifica nell'app e per email. Ignorata sul servizio cloud. |
| `VELOMINE__ACCOUNTS__CLOUD` | `false` | Il servizio ospitato. Attivo, un nuovo membro conferma il proprio indirizzo da un link via email (serve SMTP) e non aspetta mai un admin. Spento (self-hosted), non viene inviata nessuna email di verifica. |
| `VELOMINE__ACCOUNTS__CLUBCREATIONENABLED` | `false` | Permette a chi non ha un club di crearne uno. Spento, solo l'operatore crea i club. |

Un admin può cambiare la prima, la seconda e la quarta nell'app (*Admin, Settings*); un valore salvato lì prevale sull'ambiente.

## Con chi parla il tuo server

Di norma non viene inviato nulla al progetto Velomine.

| Cosa | Predefinito | Impostazione |
|------|-------------|--------------|
| Tasselli della mappa, caricati dal browser o dal telefono di ogni membro | OpenStreetMap | `VELOMINE__MAP__TILEURL` |
| Segnalazioni di errori, tracce e log | Spento | `VELOMINE__TELEMETRY__*` e le standard `OTEL_EXPORTER_OTLP_*` |
| Email (reimpostazione password, notifiche) | Spenta | `VELOMINE__SMTP__*`, vedi [Email](/docs/it/email/) |
| Catalogo condiviso dei componenti: scarica una lista, rimanda i componenti nuovi | Spento; il server usa la lista che include | `VELOMINE__CATALOGUE__*` |
| Modulo anonimo di feedback e lista di accesso anticipato sul sito pubblico | Spenti | `VELOMINE__FEEDBACK__ADDRESS` (serve l'email); `VELOMINE__FEEDBACK__SITEURL` se il sito è su un altro host |
| Single sign-on | Spento | `VELOMINE__SSO__*` |

La telemetria non contiene mai dati di uscite o di salute, nomi, email o indirizzi IP, e ogni destinazione è facoltativa. Tracce, metriche e log escono solo via OTLP, verso qualsiasi backend OpenTelemetry; le segnalazioni di errori vanno al DSN di un qualsiasi servizio compatibile.

## Single sign-on

Va bene qualsiasi provider OpenID Connect. Si attiva quando `VELOMINE__SSO__AUTHORITY` è impostata. Nel provider registra `https://<il tuo host>/signin-oidc` per il client web e `com.velomine.app:/sso-callback` per il telefono. `VELOMINE__SSO__CLIENTID` (e `CLIENTSECRET`, se il provider lo richiede) è per il client web; `VELOMINE__SSO__APPCLIENTID` è il client pubblico del telefono, senza segreto. Come l'email, si impostano solo nell'ambiente.
