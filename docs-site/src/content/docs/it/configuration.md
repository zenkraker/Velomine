---
title: Configurazione
description: Le impostazioni che decidono chi può iscriversi e come.
---

Ogni impostazione è una variabile d'ambiente. I nomi sono in maiuscolo, con `__` per le impostazioni annidate (`VELOMINE__SMTP__HOST`). Mettile in `.env`; il file commentato `.env.example` le elenca tutte con i valori predefiniti.

| Variabile | Predefinito | Cosa fa |
|-----------|-------------|---------|
| `VELOMINE__ACCOUNTS__SIGNUPENABLED` | `true` | Se nuove persone possono creare un account. |
| `VELOMINE__ACCOUNTS__REQUIREADMINAPPROVAL` | `false` | Attivo, i nuovi account aspettano un admin, che riceve una notifica nell'app e per email. Ignorata sul servizio cloud. |
| `VELOMINE__ACCOUNTS__CLOUD` | `false` | Il servizio ospitato. Attivo, un nuovo membro conferma il proprio indirizzo da un link via email (serve SMTP) e non aspetta mai un admin. Spento (self-hosted), non viene inviata nessuna email di verifica. |
| `VELOMINE__ACCOUNTS__CLUBCREATIONENABLED` | `false` | Permette a chi non ha un club di crearne uno. Spento, solo l'operatore crea i club. |

Un admin può cambiare la prima, la seconda e la quarta nell'app (*Admin, Settings*); un valore salvato lì prevale sull'ambiente.
