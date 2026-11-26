---
title: Portare dentro le uscite
description: Carica file, importa un export di Strava o registra con l'app Android.
---

## Da file

Nella pagina **Rides**, *Upload ride* accetta file FIT, GPX e TCX, compressi con gzip o no. Sul web puoi anche trascinare file, o un'intera cartella, sulla pagina: la cartella di un ciclocomputer, o la cartella Activities di Zwift, entra come un unico lavoro con un solo rapporto, non un messaggio per file. Un file FIT che contiene più attività diventa un'uscita per attività.

Alla fine vedi dei conteggi: uscite nuove, uscite già presenti, file che non è stato possibile leggere (con nomi e motivi) e file saltati perché non sono file di uscite.

## Da Strava

Richiedi il tuo export a Strava, poi scegli *Import from Strava* nel menu `⋯` di **Rides** e seleziona lo ZIP. Il server lo legge, un'uscita per attività. Importando in seguito un export più recente, quello che c'è già viene saltato. Le attività che non sono ciclismo vengono saltate e contate, le foto e gli altri file ignorati, e l'archivio viene cancellato a fine importazione.

## Dall'app Android

L'app registra con lo schermo spento e si collega a una fascia cardio via Bluetooth LE standard, senza app del produttore e senza ANT+. Un sensore mancante non blocca mai un'uscita. L'APK è allegato a ogni [release](https://github.com/zenkraker/Velomine/releases/latest). Su iPhone usa la web app nel browser; il registratore iOS non è ancora pronto.

## Cosa fa Velomine con un'uscita

- **Duplicati.** La stessa uscita proveniente da un'altra app o da un altro dispositivo viene riconosciuta (stesso file, oppure partenza, durata e distanza quasi uguali) e tenuta nascosta. Un singolo caricamento te lo dice; un'importazione la conta. Se cancelli l'uscita tenuta, la copia nascosta viene letta di nuovo.
- **La velocità** viene dal dato di velocità del file quando la maggior parte dei campioni lo contiene, altrimenti dalle posizioni GPS. Ogni uscita registra quale.
- **Il file originale** è conservato così come ricevuto, per sempre. Quando la lettura di Velomine migliora, le tue uscite più vecchie vengono rilette dai loro file.
- **Niente misuratore di potenza?** Il punteggio di sforzo di ogni uscita viene dalla potenza, altrimenti dalla frequenza cardiaca, altrimenti da quanto è sembrata dura, altrimenti dai watt stimati da velocità e pendenza. I numeri stimati sono sempre indicati come stimati.

Le formule sono nei [modelli di allenamento](https://github.com/zenkraker/Velomine/blob/main/docs/training-models.md).
