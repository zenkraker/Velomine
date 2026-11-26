---
title: Email
description: Configura SMTP perché Velomine possa inviare reimpostazioni della password e notifiche.
---

L'email è spenta finché `VELOMINE__SMTP__HOST` e `VELOMINE__SMTP__FROM` non sono entrambe impostate. Le impostazioni sono solo variabili d'ambiente: la password non viene mai salvata nel database né mostrata nell'app.

| Variabile | Predefinito | Cosa fa |
|-----------|-------------|---------|
| `VELOMINE__SMTP__HOST` | | Il server SMTP. |
| `VELOMINE__SMTP__FROM` | | Il mittente: un indirizzo semplice, oppure nome e indirizzo tra virgolette, per esempio `"Velomine <velomine@club.example>"`. |
| `VELOMINE__SMTP__PORT` | `587` | La porta SMTP. |
| `VELOMINE__SMTP__SECURITY` | `starttls` | `starttls` (porta 587), `ssl` (porta 465) o `none` (solo un relay locale). |
| `VELOMINE__SMTP__USER` | | L'utente, se il server lo richiede. |
| `VELOMINE__SMTP__PASSWORD` | | La sua password. |

Mettile in `.env` e riavvia lo stack. Nell'app, *Admin, Settings* mostra la configurazione in sola lettura, con **Send a test email**.

## Cosa richiede l'email

- **Reimpostazione della password.** Senza email, la pagina dice che non è disponibile, e un admin può creare un link di reimpostazione monouso.
- **Notifiche agli admin.** Quando i nuovi account aspettano approvazione, gli admin ricevono una notifica nell'app e anche per email.
- **Conferma dell'indirizzo, solo sul servizio ospitato.** Con `VELOMINE__ACCOUNTS__CLOUD` attivo, un nuovo membro conferma l'indirizzo da un link via email. Un server self-hosted non la invia mai.
- **I moduli del sito.** `VELOMINE__FEEDBACK__ADDRESS` è dove arrivano per email il modulo anonimo di feedback e la lista di accesso anticipato. Se è vuoto, i moduli rispondono che non sono disponibili. Non viene salvato nulla.
