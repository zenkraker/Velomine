---
title: Allenamento e bici
description: Forma e fatica, i numeri di potenza, l'allenamento automatico e l'usura della bici.
---

## Progress

**Progress** si apre con una scheda del ciclista: FTP e W/kg, potenza critica, W′ e picco di potenza, i tuoi migliori da 5 secondi a 20 minuti (ognuno apre la sua uscita), frequenza cardiaca massima e di soglia, l'andamento dell'efficienza delle ultime otto settimane, gli ultimi 90 giorni, forma e fitness di oggi e il prossimo evento. Ogni numero dice da dove viene: scritto da te, misurato in un'uscita o stimato.

Sotto ci sono i totali settimanali e mensili, il carico di allenamento, fitness e fatica, la curva di potenza e un punteggio giornaliero di prontezza. Lo storico dell'FTP mostra da dove viene ogni valore, ti ricorda quando è vecchio e ne suggerisce uno più alto quando un'uscita lo mostra. Le formule sono nei [modelli di allenamento](https://github.com/zenkraker/Velomine/blob/main/docs/training-models.md).

Senza misuratore di potenza, una fascia cardio basta da sola a costruire il grafico della forma. Le zone di frequenza cardiaca partono dalla tua soglia, e entrambi i set di zone si possono regolare a mano. Velomine ti avvisa quando ogni giorno è stato duro più o meno uguale, o la settimana è stata molto più pesante del solito.

Gli **Events** sono una data, una distanza e un dislivello: i giorni che mancano, e l'uscita che si è rivelata essere quella.

## Allenamento automatico (sperimentale)

Attivalo in *Profile, Riding*. Velomine pianifica la tua settimana dalle tue uscite, dopo tre domande:

1. **Il tuo obiettivo.** Pedalare con più regolarità, essere più in forma, essere più veloce, prepararsi a un evento in una data, o restare in forma con meno tempo. Uno è suggerito, con il suo motivo.
2. **Quando pedali.** I tuoi giorni liberi, le ore a settimana (da 1 a 30) e un giorno per l'uscita lunga.
3. **La tua frequenza cardiaca.** Un massimo che scrivi tu, oppure "I don't know": viene stimato dall'età e imparato dalle uscite.

Poi **Training** mostra la sessione di oggi con i suoi obiettivi in watt, frequenza cardiaca e sensazione, e le sessioni della settimana con il loro stato: pianificata, fatta con un punteggio, facile al posto di, spostata, saltata o mancata. Due giorni duri a settimana restano separati da un'uscita lunga nel tuo giorno, ogni tanto arriva una settimana più leggera, e il carico cresce solo dopo una settimana completata. Un'uscita spunta la sessione che era e la valuta rispetto al piano. Puoi **rendere facile oggi**, spostare una sessione o saltarla indicando un motivo.

È nuovo e ancora in cambiamento: dicci cosa non ti convince. Se hai una malattia cardiaca o non ti alleni da molto tempo, chiedi prima al medico.

Spegnerlo elimina il piano di questa settimana e delle prossime; le sessioni passate restano. L'operatore di un server può disattivare del tutto la funzione con `VELOMINE__TRAINING__AUTOENABLED`.

## Bici e componenti

*Profile, My bikes* elenca le tue bici. Una bici contiene componenti raggruppati in trasmissione, ruote, freni e così via, ognuno con una barra di usura che passa ad avviso quando comincia a consumarsi e a pericolo quando è da cambiare, sempre con parole. Aggiungi promemoria di manutenzione, segnali come fatti e tieni un registro degli interventi. Una bici può essere quella predefinita per le nuove uscite, e archiviata quando non la usi più.
