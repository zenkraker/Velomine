---
title: Backup e aggiornamenti
description: Fai il backup di un server Velomine, aggiornalo e torna indietro.
---

## Backup

Salva tre cose, **insieme**:

- il database: `docker compose exec postgres pg_dump -Fc -U velomine velomine > velomine.dump`
- il volume `velomine-files`: i file delle uscite caricati, conservati così come arrivati.
- il volume `velomine-keys`. Senza le chiavi, tutti i membri vengono disconnessi e i vecchi link smettono di funzionare.

Per ripristinare, rimetti i volumi, avvia lo stack e carica il dump nel database vuoto con `pg_restore`.

Ogni ciclista può anche esportare tutto dall'app, compresi i file originali delle uscite. È la sua copia personale, non sostituisce il tuo backup.

## Aggiornare

1. Imposta la nuova `VELOMINE_VERSION` in `.env`.
2. Esegui `docker compose pull && docker compose up -d --wait`.

Le modifiche al database vengono applicate all'avvio. La pagina [Releases](https://github.com/zenkraker/Velomine/releases) elenca ogni versione.

## Tornare indietro

Rimetti la `VELOMINE_VERSION` precedente ed esegui lo stesso comando. Ogni modifica al database resta compatibile con la release precedente, quindi tornare indietro di **una** versione è sicuro. Per andare più indietro non c'è garanzia: ripristina invece un backup fatto prima dell'aggiornamento.
