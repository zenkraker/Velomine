# Training names

The words a rider reads in auto training: every session, goal and planner term. Used by `TrainingPage`, `SessionPage`, `TrainingSetupPage`, the Progress "Today" strip and the ride page's "Was this your …?" card. A name changes here first, then in `app_en.arb` and `app_it.arb`.

Plain names, chosen by the owner on 24 Nov, for a solo rider who wants to get fitter. The recipe and goal codes stay internal; the technical term
appears only as one line on the session page ("Coaches call this sweet spot"), and `docs/training-models.md` keeps it
next to the code.

| Code | Technical | English | Italian | Line under the name (English) | Line under the name (Italian) |
|---|---|---|---|---|---|
| R01 | Easy spin (recovery) | Easy spin | Giro defaticante | Legs moving, nothing more. You should be able to chat. | Gambe in movimento, niente di più. Devi riuscire a chiacchierare. |
| R02 | Endurance | Easy ride | Giro tranquillo | Steady and comfortable: the ride that builds everything else. | Costante e comodo: il giro su cui si costruisce tutto il resto. |
| R03 | Long ride | Long ride | Uscita lunga | Your longest ride of the week, at an easy pace. | Il tuo giro più lungo della settimana, a ritmo facile. |
| R04 | Tempo | Steady pace | Ritmo costante | A bit faster than easy: talking in short sentences. | Un po' più veloce del facile: parli a frasi brevi. |
| R05 | Sweet spot | Strong and steady | Forte e costante | Long efforts just below your limit. | Sforzi lunghi appena sotto il limite. |
| R06 | Threshold | At your limit | Al limite | Efforts at the pace you could hold for about an hour. | Sforzi al ritmo che riesci a tenere per circa un'ora. |
| R07 | Climbing repeats | Hill repeats | Ripetute in salita | The same climb, several times, strong. | La stessa salita, più volte, deciso. |
| R08 | VO2max 4–5 min | Hard efforts | Sforzi duri | 4–5 minutes very hard, with full recovery. | 4–5 minuti molto duri, con recupero completo. |
| R09 | 30/15 | On and off | Acceso e spento | 30 seconds hard, 15 easy, over and over. | 30 secondi duri, 15 facili, di nuovo e di nuovo. |
| R10 | Anaerobic capacity | All-out bursts | Scatti al massimo | Short, everything you have, long rest. | Corti, tutto quello che hai, riposo lungo. |
| R12 | Cadence | Quick legs | Gambe agili | Easy pace, fast pedalling. | Ritmo facile, pedalata veloce. |
| R14 | Easy start | First rides | Primi giri | Short and easy, to build the habit. | Corto e facile, per prendere l'abitudine. |
| R15 | Steady build | A little faster | Un po' più veloce | Mostly easy, with two short steady stretches. | Per lo più facile, con due brevi tratti costanti. |
| R16 | Long and easy (base) | Longer, still easy | Più lungo, sempre facile | A bit longer each week, never hard. | Un po' più lungo ogni settimana, mai duro. |
| R17 | Keep-it | Keep it going | Mantieni il ritmo | One short strong ride to keep what you've built. | Un giro corto e forte per tenere quello che hai costruito. |

| Goal code | English | Italian |
|---|---|---|
| aerobic | Ride more regularly | Pedalare con regolarità |
| fitter | Get fitter | Essere più in forma |
| faster | Get faster ("on climbs and on the flat") | Andare più forte |
| event | Get ready for a ride or race | Prepararsi a un evento |
| keep | Stay fit with less time | Restare in forma con meno tempo |

## Lines under a session's targets

The sentences a session shows when a target cannot be a number, or when a number needs explaining. Both languages live
here with the names, so a wording is approved in one place. `SessionPage.md` gives the first and the third;
`set_ftp` was written by the implementer and adopted by the owner on 24 Nov, because a rider who owns a power meter but
has set no FTP used to be told to buy one.

| Code | English | Italian |
|---|---|---|
| add_power_meter | Add a power meter for watt targets | Aggiungi un misuratore di potenza per gli obiettivi in watt |
| set_ftp | Set your FTP for watt targets | Imposta il tuo FTP per gli obiettivi in watt |
| heart_rate_lags | Heart rate lags here: go by watts and feel | Qui la frequenza cardiaca arriva in ritardo: segui watt e sensazioni |

Other words: a quality session is a **hard day** in every "why" line; the lighter week is an **easy week** ("Easy week:
your body gets stronger while it rests"); the gentle base block is never named, only "It gets more personal as your
rides come in"; feel is always shown with its words ("7 · hard, about an hour").

