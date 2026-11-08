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
  String get actionSaveWellbeing => 'salvare come ti senti';

  @override
  String get actionSetFtp => 'impostare il tuo FTP';

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
  String get actionLoadClub => 'caricare il tuo club';

  @override
  String get actionJoinClub => 'entrare nel club';

  @override
  String get actionLeaveClub => 'uscire dal club';

  @override
  String get actionRotateJoinCode => 'creare un nuovo codice di accesso';

  @override
  String get actionChangeClubRole => 'cambiare il ruolo del membro';

  @override
  String get actionLoadAdminClubs => 'caricare i club';

  @override
  String get actionCreateClub => 'creare il club';

  @override
  String get actionUpdateClub => 'modificare il club';

  @override
  String get actionSetClubOwner => 'nominare il proprietario';

  @override
  String get actionLoadSharing => 'caricare le tue scelte di condivisione';

  @override
  String get actionSaveSharing => 'salvare le tue scelte di condivisione';

  @override
  String get actionLoadAthletes => 'caricare gli atleti';

  @override
  String get actionLoadAthlete => 'caricare l\'atleta';

  @override
  String get actionLoadCoachRide => 'caricare questa uscita';

  @override
  String get navClub => 'Club';

  @override
  String get joinTitle => 'Entra in un club';

  @override
  String get joinIntro =>
      'Chiedi il codice di accesso al proprietario del club, oppure apri il link che ha condiviso.';

  @override
  String get joinCode => 'Codice di accesso';

  @override
  String get joinAction => 'Entra';

  @override
  String get joinInvalid =>
      'Il codice non è corretto, oppure il club non accetta nuovi membri.';

  @override
  String get joinAlready => 'Il tuo account è già in un club.';

  @override
  String get clubNoneTitle => 'Non sei ancora in un club';

  @override
  String get clubNoneBody => 'Entra con il codice del proprietario del club.';

  @override
  String get clubInactive =>
      'Questo club non è attivo. Le iscrizioni sono chiuse.';

  @override
  String get clubOwner => 'Proprietario';

  @override
  String get clubCoach => 'Allenatore';

  @override
  String get clubMemberRole => 'Corridore';

  @override
  String get clubMembers => 'Membri';

  @override
  String get clubJoinCode => 'Codice di accesso';

  @override
  String get clubJoinCodeHelp =>
      'Condividi questo codice o il link con chi deve entrare.';

  @override
  String get clubNewCode => 'Nuovo codice';

  @override
  String get clubNewCodeConfirm =>
      'Il vecchio codice smette subito di funzionare. Continuare?';

  @override
  String get clubLeave => 'Esci dal club';

  @override
  String get clubLeaveTitle => 'Uscire da questo club?';

  @override
  String get clubLeaveBody =>
      'Puoi rientrare con un nuovo codice. Le tue uscite restano tue.';

  @override
  String get clubOwnerCannotLeave =>
      'Il proprietario non può uscire. Chiedi all\'amministratore del server di nominare prima un altro proprietario.';

  @override
  String get clubMakeCoach => 'Rendi allenatore';

  @override
  String get clubMakeMember => 'Rendi corridore';

  @override
  String get clubCopy => 'Copia';

  @override
  String get clubCopied => 'Copiato';

  @override
  String clubMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membri',
      one: '1 membro',
    );
    return '$_temp0';
  }

  @override
  String get sharingTitle => 'Cosa condividi';

  @override
  String get sharingHelp =>
      'Esce dal tuo account solo ciò che attivi. Il club vede sempre il tuo nome e il tuo posto nella lista.';

  @override
  String get shareRides => 'Uscite';

  @override
  String get shareAnalytics => 'Allenamento';

  @override
  String get shareRoutes => 'Percorsi';

  @override
  String get audienceNone => 'Nessuno';

  @override
  String get audienceCoaches => 'I miei allenatori';

  @override
  String get routesNeedRides =>
      'Attiva prima le uscite; i percorsi aggiungono la mappa.';

  @override
  String get viewsTitle => 'Chi ha guardato';

  @override
  String get viewsEmpty => 'Nessuno ha ancora guardato.';

  @override
  String get viewSummary => 'Riepilogo';

  @override
  String get viewTraining => 'Allenamento';

  @override
  String get viewRide => 'Uscita';

  @override
  String get viewRides => 'Elenco uscite';

  @override
  String get viewRoute => 'Percorso';

  @override
  String get athletesTitle => 'Atleti';

  @override
  String get coachViewAthletes => 'Vedi atleti';

  @override
  String get athletesEmpty =>
      'Nessun atleta condivide ancora con te. I membri attivano la condivisione nella scheda Club.';

  @override
  String lastRideOn(String date) {
    return 'Ultima uscita $date';
  }

  @override
  String get days7 => '7 giorni';

  @override
  String get days42 => '42 giorni';

  @override
  String get sharesRides => 'Uscite';

  @override
  String get sharesTraining => 'Allenamento';

  @override
  String get sharesRoutes => 'Percorsi';

  @override
  String get coachAthleteNotFound => 'Questo atleta non condivide con te.';

  @override
  String get coachRideNotFound => 'Questa uscita non è condivisa con te.';

  @override
  String get coachReadOnly => 'Condivisa dall\'atleta, sola lettura.';

  @override
  String get coachNoRides => 'Nessuna uscita condivisa.';

  @override
  String get routeNotShared => 'L\'atleta non ha condiviso il percorso.';

  @override
  String get adminClubs => 'Club';

  @override
  String get adminCreateClub => 'Crea club';

  @override
  String get adminClubName => 'Nome del club';

  @override
  String get adminClubOwnerEmail => 'Email del proprietario';

  @override
  String get adminClubOwnerHelp =>
      'Un account esistente, che diventa proprietario del club.';

  @override
  String get adminClubActive => 'Attivo';

  @override
  String get adminClubJoinCode => 'Codice di accesso';

  @override
  String get adminNoClubs => 'Nessun club. Crea il primo.';

  @override
  String get changeOwner => 'Cambia proprietario';

  @override
  String get chooseOwner => 'Scegli il nuovo proprietario';

  @override
  String get errorClubName => 'Dai un nome al club.';

  @override
  String get errorClubOwner => 'Inserisci l\'email del proprietario.';

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
  String get partChain => 'Catena';

  @override
  String get partCassette => 'Cassetta';

  @override
  String get partChainring => 'Corona';

  @override
  String get partCrankset => 'Guarnitura';

  @override
  String get partBottomBracket => 'Movimento centrale';

  @override
  String get partFrontDerailleur => 'Deragliatore anteriore';

  @override
  String get partRearDerailleur => 'Deragliatore posteriore';

  @override
  String get partDerailleurHanger => 'Forcellino deragliatore';

  @override
  String get partShifters => 'Comandi del cambio';

  @override
  String get partShiftCables => 'Cavi del cambio';

  @override
  String get partPedals => 'Pedali';

  @override
  String get partFrontTire => 'Copertone anteriore';

  @override
  String get partRearTire => 'Copertone posteriore';

  @override
  String get partTubelessSealant => 'Liquido tubeless';

  @override
  String get partInnerTubes => 'Camere d\'aria';

  @override
  String get partWheelset => 'Ruote';

  @override
  String get partHubService => 'Manutenzione mozzi';

  @override
  String get partFrontBrakePads => 'Pastiglie freno anteriori';

  @override
  String get partRearBrakePads => 'Pastiglie freno posteriori';

  @override
  String get partFrontRotor => 'Disco freno anteriore';

  @override
  String get partRearRotor => 'Disco freno posteriore';

  @override
  String get partBrakeFluid => 'Olio freni';

  @override
  String get partBrakeCables => 'Cavi freno';

  @override
  String get partHandlebarTape => 'Nastro manubrio o manopole';

  @override
  String get partHandlebar => 'Manubrio';

  @override
  String get partStem => 'Attacco manubrio';

  @override
  String get partHeadset => 'Serie sterzo';

  @override
  String get partSaddle => 'Sella';

  @override
  String get partSeatpost => 'Reggisella';

  @override
  String get partForkService => 'Manutenzione forcella';

  @override
  String get partShockService => 'Manutenzione ammortizzatore';

  @override
  String get partDropperPostService => 'Manutenzione reggisella telescopico';

  @override
  String get partEBattery => 'Batteria e-bike';

  @override
  String get partEMotor => 'Motore e-bike';

  @override
  String get partOther => 'Altro componente';

  @override
  String get partGroupDrivetrain => 'Trasmissione';

  @override
  String get partGroupWheels => 'Ruote';

  @override
  String get partGroupBrakes => 'Freni';

  @override
  String get partGroupCockpit => 'Cockpit';

  @override
  String get partGroupSuspension => 'Sospensioni';

  @override
  String get partGroupElectric => 'Elettrico';

  @override
  String get partGroupOther => 'Altro';

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

  @override
  String get profileTitle => 'Profilo';

  @override
  String get ftpHelper =>
      'Soglia funzionale di potenza. Usata per il carico di allenamento e le zone di potenza.';

  @override
  String get weight => 'Peso';

  @override
  String get maxHeartRate => 'Frequenza cardiaca massima';

  @override
  String get maxHeartRateHelper =>
      'Le zone di frequenza cardiaca si calcolano da qui.';

  @override
  String get timeZone => 'Fuso orario';

  @override
  String get timeZoneHelper =>
      'Decide in quale giorno conta un\'uscita quando il file non lo indica. Vuoto significa UTC.';

  @override
  String get firstDayOfWeek => 'La settimana inizia di';

  @override
  String get emailNotifications => 'Inviami le notifiche via email';

  @override
  String get emailAvailableHelp =>
      'Un\'uscita letta, un componente usurato e così via.';

  @override
  String get emailUnavailableHelp =>
      'Questo server non è configurato per inviare email, quindi per ora non viene inviato nulla.';

  @override
  String get yourData => 'I tuoi dati';

  @override
  String get yourDataHelp =>
      'Sono tuoi. Scarica tutto ciò che Velomine conserva su di te: i tuoi dati, le bici, gli obiettivi e le uscite, con ogni file esattamente come l\'hai caricato.';

  @override
  String get downloadMyData => 'Scarica i miei dati';

  @override
  String get exportStarted =>
      'Il download è partito nel browser. Il link funziona per due minuti.';

  @override
  String get deleteMyAccount => 'Elimina il mio account';

  @override
  String get errorEnterName => 'Inserisci il tuo nome.';

  @override
  String get errorFtp => 'L\'FTP è tra 30 e 1000 watt.';

  @override
  String get errorWeight => 'Il peso è tra 20 e 300 kg.';

  @override
  String get errorMaxHeartRate =>
      'La frequenza cardiaca massima è tra 100 e 240 bpm.';

  @override
  String get deleteAccountTitle => 'Eliminare il tuo account?';

  @override
  String get deleteAccountBody =>
      'Elimina per sempre il tuo account e tutto ciò che contiene: uscite e file, bici, obiettivi e notifiche. Scarica prima i tuoi dati se vuoi conservarli. Non si può annullare.';

  @override
  String get yourPassword => 'La tua password';

  @override
  String get confirmEmail => 'Scrivi il tuo indirizzo email per confermare';

  @override
  String get deleteEverything => 'Elimina tutto';

  @override
  String get monday => 'Lunedì';

  @override
  String get tuesday => 'Martedì';

  @override
  String get wednesday => 'Mercoledì';

  @override
  String get thursday => 'Giovedì';

  @override
  String get friday => 'Venerdì';

  @override
  String get saturday => 'Sabato';

  @override
  String get sunday => 'Domenica';

  @override
  String get markAllRead => 'Segna tutte come lette';

  @override
  String get noNotifications =>
      'Ancora nulla. Qui vedrai quando un\'uscita è stata letta o un componente della bici è quasi usurato.';

  @override
  String get unread => 'Non letta';

  @override
  String get recordRide => 'Registra un\'uscita';

  @override
  String get recordIntro =>
      'Il telefono continua a registrare anche con lo schermo spento. L\'uscita viene salvata prima su questo telefono; poi si aggiunge il caricamento.';

  @override
  String get starting => 'Avvio…';

  @override
  String get startRecording => 'Inizia a registrare';

  @override
  String get pauseWhenStopped => 'Pausa quando ti fermi';

  @override
  String get pauseWhenStoppedHelp =>
      'Dopo 3 secondi a 0,1 km/h o meno; riprende sopra questa velocità.';

  @override
  String get heartRateStrap => 'Fascia cardio';

  @override
  String get nonePaired =>
      'Nessuna abbinata. Facoltativa: la frequenza cardiaca viene salvata con l\'uscita.';

  @override
  String get forget => 'Dimentica';

  @override
  String get pair => 'Abbina';

  @override
  String get sensorConnected => 'Connessa';

  @override
  String get sensorConnecting => 'Connessione…';

  @override
  String get bluetoothOffState => 'Il Bluetooth è spento';

  @override
  String get sensorDeniedState => 'Dispositivi nelle vicinanze non consentiti';

  @override
  String get sensorConnectsOnStart => 'Si connette quando inizi un\'uscita';

  @override
  String get autoPaused => 'In pausa automatica';

  @override
  String get paused => 'In pausa';

  @override
  String get recording => 'Registrazione';

  @override
  String get moving => 'In movimento';

  @override
  String get gps => 'GPS';

  @override
  String get heartRate => 'Frequenza cardiaca';

  @override
  String get resume => 'Riprendi';

  @override
  String get pause => 'Pausa';

  @override
  String get stopAndSave => 'Ferma e salva';

  @override
  String get onThisPhone => 'Su questo telefono';

  @override
  String get noLocalRides => 'Nessuna uscita registrata su questo telefono.';

  @override
  String get uploaded => 'Caricata';

  @override
  String get serverReading => 'Il server la sta leggendo…';

  @override
  String get waitingToUpload => 'In attesa di caricamento';

  @override
  String get uploadFailed => 'Caricamento non riuscito';

  @override
  String get readyToUpload => 'Pronta per il caricamento';

  @override
  String get recordingOnPhone => 'Registrazione su questo telefono';

  @override
  String get interrupted => 'Interrotta';

  @override
  String get couldNotBeSaved => 'Salvataggio non riuscito';

  @override
  String get interruptedHelp =>
      'La registrazione si è fermata inaspettatamente. Completa per conservare l\'uscita.';

  @override
  String get finish => 'Completa';

  @override
  String get retry => 'Riprova';

  @override
  String get upload => 'Carica';

  @override
  String get deleteFromPhone => 'Elimina questa uscita dal telefono';

  @override
  String get pairStrapTitle => 'Abbina una fascia cardio';

  @override
  String get pairStrapHelp =>
      'Indossa la fascia perché si attivi, poi sceglila qui sotto. Verrà ricordata per le prossime uscite.';

  @override
  String get searchingStraps => 'Ricerca delle fasce…';

  @override
  String get noStraps =>
      'Nessuna fascia trovata. Controlla che la fascia sia indossata e il Bluetooth acceso.';

  @override
  String get searchAgain => 'Cerca di nuovo';

  @override
  String get recorderPermission =>
      'Consenti la posizione precisa, e le notifiche se richieste, così l\'uscita può continuare a registrare.';

  @override
  String get recorderGpsOff =>
      'Attiva la posizione (GPS) per registrare un\'uscita.';

  @override
  String get recorderLocationFailed =>
      'Il telefono non è riuscito ad avviare gli aggiornamenti di posizione.';

  @override
  String get recorderUnsupported =>
      'La registrazione è disponibile solo sul telefono.';

  @override
  String get recorderTooShort =>
      'L\'uscita era troppo breve per essere salvata.';

  @override
  String get recorderFitFailed => 'Non è stato possibile salvare l\'uscita.';

  @override
  String get recorderStillRecording => 'Ferma l\'uscita prima di completarla.';

  @override
  String get recorderRideNotFound =>
      'Quell\'uscita non è più su questo telefono.';

  @override
  String get recorderBluetoothOff =>
      'Attiva il Bluetooth per usare una fascia cardio.';

  @override
  String get recorderBluetoothDenied =>
      'Consenti i dispositivi nelle vicinanze così l\'app può trovare la fascia cardio.';

  @override
  String get recorderSensorNotFound =>
      'Quella fascia non è più nelle vicinanze.';

  @override
  String get recorderFailed =>
      'Il registratore non è riuscito a farlo. Riprova.';

  @override
  String get recorderUnreadable => 'Impossibile leggere il registratore.';

  @override
  String get uploadNoFile => 'Il file FIT manca su questo telefono.';

  @override
  String get uploadOffline => 'Impossibile raggiungere il server. Riprova.';

  @override
  String get uploadSignIn => 'Accedi di nuovo per caricare.';

  @override
  String get uploadTimeout =>
      'Il server ha impiegato troppo tempo a leggere l\'uscita.';

  @override
  String get uploadServerFailed =>
      'Il server non è riuscito a leggere questa uscita.';

  @override
  String uploadHttpRefused(String code) {
    return 'Il server ha rifiutato il caricamento ($code).';
  }

  @override
  String get uploadFailedGeneric => 'Caricamento non riuscito. Riprova.';

  @override
  String get readiness => 'Prontezza';

  @override
  String get readinessHard => 'Pronto per un\'uscita dura';

  @override
  String get readinessNormal => 'Allenati normalmente';

  @override
  String get readinessEasy => 'Vai piano';

  @override
  String get readinessRest => 'Riposa oggi';

  @override
  String get readinessAdviceHard =>
      'La forma è buona. Oggi ci sta una seduta intensa.';

  @override
  String get readinessAdviceNormal =>
      'Una seduta normale va bene; lascia gli intervalli più duri a un giorno più fresco.';

  @override
  String get readinessAdviceEasy =>
      'Resta facile: ritmo di resistenza, nessuno sforzo intenso.';

  @override
  String get readinessAdviceRest =>
      'Riposa o muoviti molto piano. Hai molta fatica accumulata.';

  @override
  String get readinessNoData => 'Registra un\'uscita per vedere la prontezza.';

  @override
  String get readinessLoadOnly =>
      'Aggiungi il check-in giornaliero per includere come ti senti.';

  @override
  String get readinessWhy => 'Perché';

  @override
  String get readinessNotMedical =>
      'Una guida per l\'allenamento, non una misura medica.';

  @override
  String get readinessFactorForm => 'Forma';

  @override
  String get readinessFactorRamp => 'Crescita 7 giorni';

  @override
  String get readinessFactorRecentLoad => 'Ultimi 2 giorni';

  @override
  String get readinessFactorWellbeing => 'Come ti senti';

  @override
  String get readinessFactorRpe => 'RPE ultima uscita';

  @override
  String get wellbeing => 'Benessere';

  @override
  String get wellbeingConsentTitle => 'Prima di iniziare';

  @override
  String get wellbeingConsentBody =>
      'Velomine conserva un breve check-in giornaliero e l\'RPE che aggiungi alle uscite. Sono dati sulla salute: nessun altro li vede se non li condividi con i tuoi allenatori, e puoi esportarli o eliminarli in qualsiasi momento. Non sono consigli medici.';

  @override
  String get wellbeingConsentAction => 'Accetto';

  @override
  String get wellbeingToday => 'Come ti senti oggi?';

  @override
  String get wellbeingSaved => 'Check-in di oggi';

  @override
  String get wellbeingEdit => 'Modifica oggi';

  @override
  String get wellbeingSave => 'Salva check-in';

  @override
  String get wellbeingFatigue => 'Affaticamento';

  @override
  String get wellbeingSoreness => 'Indolenzimento';

  @override
  String get wellbeingMood => 'Umore';

  @override
  String get wellbeingStress => 'Stress';

  @override
  String get wellbeingMotivation => 'Motivazione';

  @override
  String get wellbeingShortFatigue => 'Aff';

  @override
  String get wellbeingShortSoreness => 'Ind';

  @override
  String get wellbeingShortMood => 'Umo';

  @override
  String get wellbeingShortStress => 'Str';

  @override
  String get wellbeingShortMotivation => 'Mot';

  @override
  String get wellbeingHistory => 'Ultimi 30 giorni';

  @override
  String get wellbeingNoHistory => 'Nessun check-in.';

  @override
  String get wellbeingRpe => 'Quanto è stata dura?';

  @override
  String get wellbeingRpeHint => '1 facile, 10 massimo';

  @override
  String get wellbeingNotes => 'Note (facoltative)';

  @override
  String get wellbeingRpeSave => 'Salva';

  @override
  String wellbeingRpeSaved(int rpe) {
    return 'RPE $rpe/10';
  }

  @override
  String get wellbeingRpeDelete => 'Rimuovi';

  @override
  String get wellbeingConsentNeeded =>
      'Attiva il benessere in Progressi per aggiungere come è andata un\'uscita.';

  @override
  String get shareWellbeing => 'Benessere';

  @override
  String get shareWellbeingHelper =>
      'Punteggi del check-in e RPE delle uscite; le note restano private.';

  @override
  String get sharesWellbeing => 'Benessere';

  @override
  String get viewPowerCurve => 'Curva di potenza';

  @override
  String get viewWellbeing => 'Benessere';

  @override
  String get powerCurve => 'Curva di potenza';

  @override
  String get powerCurveEmpty =>
      'Nessun dato di potenza in questo periodo. Carica un\'uscita con un misuratore di potenza.';

  @override
  String get powerBestEfforts => 'Migliori sforzi';

  @override
  String get ftpEstimate => 'FTP stimato';

  @override
  String get ftpCurrent => 'FTP attuale';

  @override
  String get ftpMethod20 => '95 % della tua migliore potenza sui 20 minuti';

  @override
  String get ftpMethod8 => '90 % della tua migliore potenza sugli 8 minuti';

  @override
  String ftpUse(int watts) {
    return 'Usa $watts W';
  }

  @override
  String get vo2MaxEstimate => 'VO2max stimato';

  @override
  String get vo2MaxFrom5Min => 'dalla migliore potenza sui 5 minuti e dal peso';

  @override
  String get vo2MaxNeedsWeight => 'Imposta il peso per stimare il VO2max.';

  @override
  String get vo2MaxNeedsEffort =>
      'Serve uno sforzo di 5 minuti per stimare il VO2max.';

  @override
  String get coachWellbeing => 'Benessere';

  @override
  String get coachWellbeingEmpty =>
      'Il benessere è condiviso, ma non ci sono ancora check-in.';

  @override
  String get coachWellbeingNoNotes =>
      'Solo punteggi e RPE. Le note restano private.';

  @override
  String get coachPowerCurve => 'Curva di potenza';
}
