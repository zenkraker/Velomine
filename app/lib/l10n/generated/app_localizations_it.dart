// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get navRides => 'Uscite';

  @override
  String get navRecord => 'Registra';

  @override
  String get navProgress => 'Progressi';

  @override
  String get navBikes => 'Bici';

  @override
  String get navAdmin => 'Admin';

  @override
  String get notifications => 'Notifiche';

  @override
  String notificationsUnread(int count) {
    return 'Notifiche, $count non lette';
  }

  @override
  String get signOut => 'Esci';

  @override
  String themeTooltip(String name) {
    return 'Tema: $name';
  }

  @override
  String get themeSystem => 'Segui il dispositivo';

  @override
  String get themeLight => 'Giorno';

  @override
  String get themeDark => 'Notte';

  @override
  String languageTooltip(String name) {
    return 'Lingua: $name';
  }

  @override
  String get languageSystem => 'Segui il dispositivo';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get name => 'Nome';

  @override
  String get signIn => 'Accedi';

  @override
  String get change => 'Cambia';

  @override
  String get tryAgain => 'Riprova';

  @override
  String serverLabel(String url) {
    return 'Server: $url';
  }

  @override
  String continueWith(String provider) {
    return 'Continua con $provider';
  }

  @override
  String get createAccount => 'Crea un account';

  @override
  String get createAccountAction => 'Crea account';

  @override
  String get haveAccount => 'Ho già un account';

  @override
  String get backToSignIn => 'Torna all\'accesso';

  @override
  String get passwordHint =>
      'Almeno 10 caratteri, con una maiuscola, una minuscola e un numero.';

  @override
  String get registeredReady => 'Il tuo account è pronto. Ora puoi accedere.';

  @override
  String get registeredPending =>
      'Il tuo account è stato creato. Un amministratore deve approvarlo prima che tu possa accedere.';

  @override
  String get authWrongPassword => 'L\'email o la password non sono corretti.';

  @override
  String get authNotApproved =>
      'Il tuo account è in attesa di approvazione da parte di un amministratore.';

  @override
  String get authLockedOut =>
      'Troppi tentativi errati. Riprova tra qualche minuto.';

  @override
  String get authSignUpClosed =>
      'Le registrazioni sono chiuse su questo server.';

  @override
  String get authWeakPassword =>
      'La password deve avere almeno 10 caratteri, con una maiuscola, una minuscola e un numero.';

  @override
  String get authEmailTaken => 'Esiste già un account con questa email.';

  @override
  String get authUnavailable => 'Impossibile raggiungere il server. Riprova.';

  @override
  String get ssoEmailNotVerified =>
      'Il tuo provider di accesso non ha verificato il tuo indirizzo email.';

  @override
  String get ssoNoAccount =>
      'Non esiste ancora un account per te qui. Chiedi a un amministratore.';

  @override
  String get ssoLockedOut =>
      'Questo account è bloccato. Riprova tra qualche minuto.';

  @override
  String get ssoNoEmail =>
      'Il tuo provider di accesso non ha condiviso un indirizzo email.';

  @override
  String get ssoFailed => 'L\'accesso singolo non ha funzionato. Riprova.';

  @override
  String get ssoGeneric => 'accesso singolo';

  @override
  String get signingIn => 'Accesso in corso…';

  @override
  String get setupTitle => 'Quale server usa il tuo club?';

  @override
  String get setupServerAddress => 'Indirizzo del server';

  @override
  String get setupServerHint => 'https://velomine.club.example';

  @override
  String get setupInsecure =>
      'Questo indirizzo non è cifrato. Usalo solo su una rete di cui ti fidi, oppure chiedi all\'amministratore un indirizzo https.';

  @override
  String get setupChecking => 'Verifica…';

  @override
  String get setupConnect => 'Connetti';

  @override
  String get setupHelp =>
      'Chiedi all\'amministratore del club l\'indirizzo. Di solito è simile a https://velomine.il-tuo-club.example.';

  @override
  String get setupInvalidAddress =>
      'Inserisci un indirizzo che inizi con http:// o https://, per esempio https://velomine.club.example.';

  @override
  String get setupUnreachable =>
      'Impossibile raggiungere un server Velomine a quell\'indirizzo. Controlla l\'indirizzo e che il telefono sia sulla stessa rete del server.';

  @override
  String get setupSaveFailed => 'Impossibile salvare l\'indirizzo. Riprova.';

  @override
  String get failureRejected =>
      'Il server non ha accettato la richiesta. Controlla i valori.';

  @override
  String get failureMissing => 'Non esiste più.';

  @override
  String get failureConflict => 'Non è consentito.';

  @override
  String get failureMail =>
      'Il server di posta non l\'ha accettato. Controlla le impostazioni email.';

  @override
  String get failureWrongConfirmation =>
      'Non corrisponde. Non è stato eliminato nulla.';

  @override
  String get failureLastAdmin =>
      'Sei l\'unico amministratore. Nomina prima qualcun altro.';

  @override
  String get failureUnreachable =>
      'Impossibile raggiungere il server. Riprova.';

  @override
  String failureFailed(String action, int code) {
    return 'Impossibile $action ($code). Riprova.';
  }

  @override
  String get actionGeneral => 'farlo';

  @override
  String get actionLoadRides => 'caricare le tue uscite';

  @override
  String get actionUploadRide => 'caricare questo file';

  @override
  String get actionLoadRide => 'caricare questa uscita';

  @override
  String get actionChangeRideBike => 'cambiare la bici';

  @override
  String get actionDeleteRide => 'eliminare l\'uscita';

  @override
  String get actionLoadBikes => 'caricare le tue bici';

  @override
  String get actionAddBike => 'aggiungere la bici';

  @override
  String get actionLoadBike => 'caricare questa bici';

  @override
  String get actionSaveBike => 'salvare la bici';

  @override
  String get actionSetDefaultBike => 'impostare la predefinita';

  @override
  String get actionDeleteBike => 'eliminare la bici';

  @override
  String get actionAddPart => 'aggiungere il componente';

  @override
  String get actionSavePart => 'salvare il componente';

  @override
  String get actionRemovePart => 'rimuovere il componente';

  @override
  String get actionLoadProgress => 'caricare i tuoi progressi';

  @override
  String get actionAddGoal => 'aggiungere l\'obiettivo';

  @override
  String get actionChangeGoal => 'modificare l\'obiettivo';

  @override
  String get actionDeleteGoal => 'eliminare l\'obiettivo';

  @override
  String get actionLoadAdmin => 'caricare le pagine admin';

  @override
  String get actionReloadAccounts => 'ricaricare gli account';

  @override
  String get actionApproveAccount => 'approvare l\'account';

  @override
  String get actionChangeRoles => 'cambiare i ruoli';

  @override
  String get actionLockAccount => 'bloccare l\'account';

  @override
  String get actionUnlockAccount => 'sbloccare l\'account';

  @override
  String get actionDeleteAccount => 'eliminare l\'account';

  @override
  String get actionSendTestEmail => 'inviare l\'email di prova';

  @override
  String get actionSaveSettings => 'salvare le impostazioni';

  @override
  String get actionLoadProfile => 'caricare il tuo profilo';

  @override
  String get actionPrepareData => 'preparare i tuoi dati';

  @override
  String get actionSaveProfile => 'salvare il tuo profilo';

  @override
  String get actionLoadNotifications => 'caricare le tue notifiche';

  @override
  String get actionMarkRead => 'segnarla come letta';

  @override
  String get actionMarkAllRead => 'segnarle come lette';

  @override
  String notificationRideReady(String subject) {
    return 'La tua uscita $subject è pronta.';
  }

  @override
  String notificationRideFailed(String subject) {
    return 'Impossibile leggere $subject.';
  }

  @override
  String notificationRideDuplicate(String subject) {
    return '$subject era già stata caricata, quindi è nascosta.';
  }

  @override
  String notificationSignupWaiting(String subject) {
    return '$subject si è iscritto e attende l\'approvazione.';
  }

  @override
  String notificationPartSoon(String subject) {
    return '$subject è quasi usurato.';
  }

  @override
  String notificationPartWorn(String subject) {
    return '$subject è usurato. È ora di sostituirlo.';
  }

  @override
  String get rideErrorCorrupt => 'Il file è danneggiato o incompleto.';

  @override
  String get rideErrorInvalid => 'Questo non è un file di un\'uscita.';

  @override
  String get rideErrorUnsupported =>
      'Sono supportati solo i file FIT, GPX e TCX.';

  @override
  String get rideErrorNotCycling => 'Questa non è un\'attività di ciclismo.';

  @override
  String get rideErrorNoTimestamps => 'Il file non ha indicatori di tempo.';

  @override
  String get rideErrorNoRecords => 'Il file non contiene dati utilizzabili.';

  @override
  String get rideErrorTooLarge => 'Il file è troppo grande.';

  @override
  String get rideErrorUnknown =>
      'Il server non è riuscito a leggere questo file.';

  @override
  String get uploadRide => 'Carica uscita';

  @override
  String get uploading => 'Caricamento…';

  @override
  String get noRides => 'Nessuna uscita. Carica un file FIT, GPX o TCX.';

  @override
  String get loadMore => 'Carica altre';

  @override
  String get readingFile => 'Lettura del file…';

  @override
  String metresUp(int metres) {
    return '$metres m di dislivello';
  }

  @override
  String get delete => 'Elimina';

  @override
  String get deleteRideTitle => 'Eliminare questa uscita?';

  @override
  String get deleteRideBody =>
      'L\'uscita, i suoi grafici e il file caricato vengono rimossi. Non si può annullare.';

  @override
  String get keepIt => 'Mantienila';

  @override
  String get rideNotFound => 'Questa uscita non esiste, oppure non è tua.';

  @override
  String get couldNotLoadRide => 'Impossibile caricare questa uscita.';

  @override
  String get trainingHint =>
      'Imposta frequenza cardiaca massima e FTP nel profilo per vedere zone e carico di allenamento.';

  @override
  String get heartRateZones => 'Zone di frequenza cardiaca';

  @override
  String get powerZones => 'Zone di potenza';

  @override
  String get momentHint =>
      'Passa sopra un grafico, oppure tocca e trascina, per vedere i valori lungo l\'uscita.';

  @override
  String momentAt(String time, String distance) {
    return 'Alle $time$distance';
  }

  @override
  String get statDistance => 'Distanza';

  @override
  String get statMovingTime => 'Tempo in movimento';

  @override
  String get statElapsedTime => 'Tempo trascorso';

  @override
  String get statClimbing => 'Salita';

  @override
  String get statDescending => 'Discesa';

  @override
  String get statAverageSpeed => 'Velocità media';

  @override
  String get statTopSpeed => 'Velocità massima';

  @override
  String get statAveragePower => 'Potenza media';

  @override
  String get statNormalizedPower => 'Potenza normalizzata';

  @override
  String get statMaxPower => 'Potenza massima';

  @override
  String get statIntensity => 'Intensità';

  @override
  String get statTss => 'TSS';

  @override
  String get statTrimp => 'TRIMP';

  @override
  String get statAverageHeartRate => 'Frequenza cardiaca media';

  @override
  String get statMaxHeartRate => 'Frequenza cardiaca massima';

  @override
  String get statAverageCadence => 'Cadenza media';

  @override
  String get speedFromGps => 'La velocità è calcolata dalle posizioni GPS.';

  @override
  String get loadHint =>
      'TSS usa il tuo FTP; TRIMP è il tempo nelle zone di frequenza cardiaca. Impostali entrambi nel profilo per vederli.';

  @override
  String zoneSemantics(int zone, String range, String duration) {
    return 'Zona $zone, $range, $duration';
  }

  @override
  String zoneRange(int from, int to, String unit) {
    return '$from–$to $unit';
  }

  @override
  String zoneRangeOpen(int from, String unit) {
    return '≥ $from $unit';
  }

  @override
  String get bike => 'Bici';

  @override
  String get noBike => 'Nessuna bici';

  @override
  String get mapOfRoute => 'Mappa del percorso';

  @override
  String get seriesElevation => 'Altitudine';

  @override
  String get seriesSpeed => 'Velocità';

  @override
  String get seriesPower => 'Potenza';

  @override
  String get seriesHeartRate => 'Frequenza cardiaca';

  @override
  String get seriesCadence => 'Cadenza';

  @override
  String chartSemantics(String name, String low, String average, String high) {
    return 'Grafico $name: minimo $low, media $average, massimo $high';
  }

  @override
  String chartAverageMax(String average, String max) {
    return 'media $average · max $max';
  }

  @override
  String get addBike => 'Aggiungi bici';

  @override
  String get noBikes =>
      'Nessuna bici. Aggiungine una per tenere traccia dei chilometri e dell\'usura dei componenti. Le nuove uscite ricevono la bici predefinita.';

  @override
  String get defaultBike => 'Predefinita';

  @override
  String get archived => 'Archiviata';

  @override
  String bikeRides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uscite',
      one: '1 uscita',
      zero: 'Nessuna uscita',
    );
    return '$_temp0';
  }

  @override
  String get deleteBikeTitle => 'Eliminare questa bici?';

  @override
  String get deleteBikeBody =>
      'La bici e i suoi componenti vengono rimossi. Le uscite restano, ma non indicheranno più quale bici hai usato. Per conservare la storia, archivia la bici.';

  @override
  String removePartTitle(String name) {
    return 'Rimuovere $name dalla lista?';
  }

  @override
  String get removePartBody =>
      'La sua storia viene eliminata. Per conservarla, usa Sostituisci: ritira il componente ma mantiene l\'usura.';

  @override
  String get remove => 'Rimuovi';

  @override
  String get bikeNotFound => 'Questa bici non esiste, oppure non è tua.';

  @override
  String wheelLabel(int mm) {
    return 'ruota $mm mm';
  }

  @override
  String get statRides => 'Uscite';

  @override
  String get edit => 'Modifica';

  @override
  String get makeDefault => 'Imposta predefinita';

  @override
  String get archive => 'Archivia';

  @override
  String get restore => 'Ripristina';

  @override
  String get parts => 'Componenti';

  @override
  String get addPartAction => 'Aggiungi componente';

  @override
  String get noParts =>
      'Nessun componente. Aggiungi catena, copertoni o pastiglie dei freni per vedere quanto sono usurati.';

  @override
  String get replacedParts => 'Componenti sostituiti';

  @override
  String get wearReplace => 'Sostituiscilo';

  @override
  String get wearSoon => 'Si sta usurando';

  @override
  String get wearReplaced => 'Sostituito';

  @override
  String get wearGood => 'Buono';

  @override
  String wearDistance(String used, String expected) {
    return '$used di $expected km';
  }

  @override
  String wearHours(String used, String expected) {
    return '$used di $expected h';
  }

  @override
  String wearMonths(String used, int expected) {
    return '$used di $expected mesi';
  }

  @override
  String wearNoLimit(String distance, String hours) {
    return '$distance · $hours h, nessun limite';
  }

  @override
  String wearPercent(int percent) {
    return '$percent% usurato';
  }

  @override
  String installedOn(String date) {
    return 'Installato il $date';
  }

  @override
  String installedAndRemoved(String installed, String removed) {
    return 'Installato il $installed · rimosso il $removed';
  }

  @override
  String get replace => 'Sostituisci';

  @override
  String get addBikeTitle => 'Aggiungi una bici';

  @override
  String get editBikeTitle => 'Modifica bici';

  @override
  String get kind => 'Tipo';

  @override
  String get brand => 'Marca';

  @override
  String get model => 'Modello';

  @override
  String get wheelCircumference => 'Circonferenza ruota (mm)';

  @override
  String get wheelHelper =>
      'Valori tipici qui sotto; misura un giro della tua ruota per il numero esatto.';

  @override
  String get initialDistance => 'Distanza prima di Velomine (km)';

  @override
  String get initialHelper =>
      'Per una bici che hai già usato. Lascia vuoto per una nuova.';

  @override
  String get purchaseDate => 'Data di acquisto (facoltativa)';

  @override
  String boughtOn(String date) {
    return 'Acquistata il $date';
  }

  @override
  String get errorBikeName => 'Dai un nome alla bici.';

  @override
  String get errorWheelRange => 'La circonferenza ruota è tra 1000 e 2600 mm.';

  @override
  String get errorInitialDistance =>
      'La distanza prima di Velomine deve essere 0 o più.';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String replacePartTitle(String name) {
    return 'Sostituisci $name';
  }

  @override
  String get editPartTitle => 'Modifica componente';

  @override
  String get addPartTitle => 'Aggiungi un componente';

  @override
  String get partLabel => 'Componente';

  @override
  String get stillOnBike => 'Ancora sulla bici';

  @override
  String removedOn(String date) {
    return 'Rimosso il $date';
  }

  @override
  String get putBackOnBike => 'Rimettilo sulla bici';

  @override
  String get partLimitsHelp =>
      'Sostituiscilo quando raggiunge il primo di questi limiti. I valori tipici sono solo un punto di partenza; lascia un campo vuoto per nessun limite.';

  @override
  String get hours => 'ore';

  @override
  String get months => 'mesi';

  @override
  String get errorChoosePart => 'Scegli che tipo di componente è.';

  @override
  String get errorLimits =>
      'I limiti devono essere numeri maggiori di 0, oppure vuoti.';

  @override
  String get errorRemovedBeforeInstalled =>
      'Non può essere rimosso prima di essere installato.';

  @override
  String get bikeKindRoad => 'Strada';

  @override
  String get bikeKindGravel => 'Gravel';

  @override
  String get bikeKindMountain => 'Mountain bike';

  @override
  String get bikeKindEbike => 'E-bike';

  @override
  String get bikeKindTimeTrial => 'Cronometro';

  @override
  String get bikeKindTrack => 'Pista';

  @override
  String get bikeKindCity => 'Città';

  @override
  String get bikeKindOther => 'Altro';

  @override
  String get periodWeeks => 'Settimane';

  @override
  String get periodMonths => 'Mesi';

  @override
  String get periodYears => 'Anni';

  @override
  String get thisWeek => 'Questa settimana';

  @override
  String get thisMonth => 'Questo mese';

  @override
  String get thisYear => 'Quest\'anno';

  @override
  String get periodWordWeek => 'settimana';

  @override
  String get periodWordMonth => 'mese';

  @override
  String get periodWordYear => 'anno';

  @override
  String periodTotals(int count, String duration, int elevation) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uscite',
      one: '1 uscita',
      zero: 'Nessuna uscita',
    );
    return '$_temp0 · $duration · $elevation m di dislivello';
  }

  @override
  String get goals => 'Obiettivi';

  @override
  String get addGoal => 'Aggiungi obiettivo';

  @override
  String get noGoals =>
      'Nessun obiettivo. Imposta un traguardo per ogni settimana, mese o anno: distanza, dislivello, tempo in bici o numero di uscite.';

  @override
  String get goalWeekly => 'settimanale';

  @override
  String get goalMonthly => 'mensile';

  @override
  String get goalYearly => 'annuale';

  @override
  String get goalMetricDistance => 'Distanza';

  @override
  String get goalMetricElevation => 'Dislivello';

  @override
  String get goalMetricTime => 'Tempo in bici';

  @override
  String get goalMetricRides => 'Uscite';

  @override
  String get goalUnitRides => 'uscite';

  @override
  String goalRideCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uscite',
      one: '1 uscita',
      zero: 'Nessuna uscita',
    );
    return '$_temp0';
  }

  @override
  String get goalChange => 'Modifica obiettivo';

  @override
  String get goalAdd => 'Aggiungi obiettivo';

  @override
  String get goalEvery => 'Ogni';

  @override
  String get goalEveryWeek => 'settimana';

  @override
  String get goalEveryMonth => 'mese';

  @override
  String get goalEveryYear => 'anno';

  @override
  String get goalCount => 'Conteggio';

  @override
  String get goalTarget => 'Obiettivo';

  @override
  String get errorGoalTarget => 'Inserisci un obiettivo maggiore di 0.';

  @override
  String goalTitle(String period, String metric) {
    return '$metric $period';
  }

  @override
  String get goalReached => 'Raggiunto';

  @override
  String get goalChangeTarget => 'Modifica obiettivo';

  @override
  String get goalDelete => 'Elimina obiettivo';

  @override
  String goalSemantics(String metric) {
    return 'Obiettivo: $metric';
  }

  @override
  String goalProgress(String current, String target, int percent) {
    return '$current di $target · $percent %';
  }

  @override
  String totalsSemantics(String period, String distance) {
    return 'Distanza per $period. Questo periodo: $distance.';
  }

  @override
  String get trainingLoad => 'Carico di allenamento';

  @override
  String get range30Days => '30 g';

  @override
  String get range90Days => '90 g';

  @override
  String get rangeOneYear => '1 a';

  @override
  String get trainingLoadHint =>
      'Imposta FTP (e frequenza cardiaca massima) nel profilo, poi carica un\'uscita per vedere il carico di allenamento.';

  @override
  String get fitnessFatigueForm => 'Fitness, fatica e forma';

  @override
  String get fitness => 'Fitness';

  @override
  String get fatigue => 'Fatica';

  @override
  String get form => 'Forma';

  @override
  String fitnessSemantics(int fitness, int fatigue, int form) {
    return 'Fitness $fitness, fatica $fatigue, forma $form.';
  }

  @override
  String get dailyLoad => 'Carico giornaliero (TSS)';

  @override
  String dailyLoadSemantics(int days) {
    return 'Training stress score giornaliero negli ultimi $days giorni.';
  }

  @override
  String get trainingLoadHelp =>
      'La fitness media gli ultimi 42 giorni di carico, la fatica gli ultimi 7. La forma è fitness meno fatica.';

  @override
  String get adminAccounts => 'Account';

  @override
  String get adminSettings => 'Impostazioni';

  @override
  String get adminOverview => 'Panoramica';

  @override
  String deleteUserTitle(String name) {
    return 'Eliminare $name?';
  }

  @override
  String deleteUserBody(String email) {
    return 'L\'account di $email viene eliminato per sempre: uscite, bici, obiettivi e file delle uscite. Non si può annullare.';
  }

  @override
  String get waitingForApproval => 'In attesa di approvazione';

  @override
  String get nonePending => 'Nessun account in attesa di approvazione.';

  @override
  String get you => 'Tu';

  @override
  String get locked => 'Bloccato';

  @override
  String get roleMember => 'Membro';

  @override
  String get roleCoach => 'Allenatore';

  @override
  String get roleAdmin => 'Amministratore';

  @override
  String get approve => 'Approva';

  @override
  String actionsFor(String name) {
    return 'Azioni per $name';
  }

  @override
  String get changeRoles => 'Cambia ruoli';

  @override
  String get unlockAccount => 'Sblocca account';

  @override
  String get lockAccount => 'Blocca account';

  @override
  String get deleteAccountAction => 'Elimina account';

  @override
  String rolesFor(String name) {
    return 'Ruoli di $name';
  }

  @override
  String get everyAccountMember => 'Ogni account è un membro.';

  @override
  String get saved => 'Salvato.';

  @override
  String get signUp => 'Registrazione';

  @override
  String get peopleCanCreate => 'Le persone possono creare account';

  @override
  String get newAccountsApproval =>
      'I nuovi account devono essere approvati da un amministratore';

  @override
  String get mapBackground => 'Sfondo mappa';

  @override
  String get tileAddress => 'Indirizzo dei riquadri';

  @override
  String get tileHelper =>
      'Vuoto disegna solo il percorso e non contatta nessun server di mappe. Leggi prima le regole d\'uso del fornitore.';

  @override
  String get creditShown => 'Credito mostrato sulla mappa';

  @override
  String get envVariables => 'Impostato con variabili d\'ambiente';

  @override
  String get secretsHelp =>
      'Contengono password e segreti, quindi non vengono mai salvati nel database né modificati da qui. Modifica l\'ambiente del server e riavvialo.';

  @override
  String get sendTestEmail => 'Inviami un\'email di prova';

  @override
  String get testEmailSent => 'Email di prova inviata al tuo indirizzo.';

  @override
  String get emailSmtp => 'Email (SMTP)';

  @override
  String smtpDetail(String host, int port, String security, String from) {
    return '$host:$port · $security · da $from';
  }

  @override
  String get smtpNotConfigured =>
      'Non impostato. Imposta Velomine__Smtp__Host e Velomine__Smtp__From.';

  @override
  String get singleSignOn => 'Accesso singolo';

  @override
  String ssoDetail(String name, String authority) {
    return '$name · $authority';
  }

  @override
  String get ssoNotConfigured =>
      'Non impostato. Imposta Velomine__Sso__Authority, ClientId e ClientSecret.';

  @override
  String statusOn(String title) {
    return '$title: attivo';
  }

  @override
  String statusOff(String title) {
    return '$title: disattivo';
  }

  @override
  String get noOverview => 'Nessuna panoramica.';

  @override
  String get noSettings => 'Nessuna impostazione.';

  @override
  String get rideFilesOnDisk => 'File delle uscite su disco';

  @override
  String get serverVersion => 'Versione del server';
}
