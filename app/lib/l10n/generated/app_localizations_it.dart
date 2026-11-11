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
  String get navRecording => 'In corso';

  @override
  String get navRecordingPaused => 'In pausa';

  @override
  String get navProgress => 'Progressi';

  @override
  String get navBikes => 'Bici';

  @override
  String get navAdmin => 'Admin';

  @override
  String get accountMenu => 'Account';

  @override
  String get recordPermissionHelp =>
      'All\'avvio l\'app chiede la posizione e mostra una notifica mentre registra, anche a schermo spento.';

  @override
  String get rideNoData => 'Nessun dato';

  @override
  String get sessionsNavTitle => 'Sessioni';

  @override
  String get twoFactorNavTitle => 'Due fattori';

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
  String get language => 'Lingua';

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
  String get showPassword => 'Mostra password';

  @override
  String get hidePassword => 'Nascondi password';

  @override
  String get staySignedIn => 'Resta connesso';

  @override
  String get pressBackAgain => 'Premi di nuovo indietro per uscire';

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
  String get authWrongCode => 'Il codice non è corretto. Prova il successivo.';

  @override
  String get twoFactorTitle => 'Accesso a due fattori';

  @override
  String get twoFactorHelp =>
      'Inserisci il codice di 6 cifre della tua app di autenticazione, oppure uno dei codici di recupero.';

  @override
  String get twoFactorCode => 'Codice di 6 cifre';

  @override
  String get twoFactorVerify => 'Verifica';

  @override
  String get twoFactorUseAnother => 'Usa un altro account';

  @override
  String get twoFactorStateOn => 'L\'accesso a due fattori è attivo.';

  @override
  String get twoFactorStateOff => 'L\'accesso a due fattori è disattivato.';

  @override
  String get twoFactorIntro =>
      'Dopo la password inserisci un codice della tua app di autenticazione. È facoltativo e puoi disattivarlo quando vuoi.';

  @override
  String get twoFactorNoPassword =>
      'Questo account accede con l\'accesso singolo, che è già un secondo passaggio.';

  @override
  String get twoFactorStart => 'Configura un\'app di autenticazione';

  @override
  String get twoFactorKeyHelp =>
      'Digita questa chiave nella tua app di autenticazione, poi inserisci il codice che mostra.';

  @override
  String get twoFactorKey => 'Chiave';

  @override
  String get twoFactorPassword => 'La tua password';

  @override
  String get twoFactorCodeLabel => 'Codice dall\'app';

  @override
  String get twoFactorEnable => 'Attiva';

  @override
  String get twoFactorDisable => 'Disattiva';

  @override
  String get twoFactorRegenerate => 'Nuovi codici di recupero';

  @override
  String get twoFactorRecoveryTitle => 'Codici di recupero';

  @override
  String get twoFactorRecoveryHelp =>
      'Salvali in un posto sicuro. Ognuno funziona una volta, al posto del codice dell\'app.';

  @override
  String get twoFactorEnabled => 'L\'accesso a due fattori è attivo.';

  @override
  String get twoFactorDisabled => 'L\'accesso a due fattori è disattivato.';

  @override
  String get twoFactorCodeWrong =>
      'Il codice non è corretto. Controlla l\'ora del telefono e prova il successivo.';

  @override
  String get sessionsTitle => 'Dispositivi e sessioni';

  @override
  String get sessionsIntro =>
      'Dove hai effettuato l\'accesso adesso. Disconnettere un dispositivo richiede di nuovo la password lì.';

  @override
  String get sessionThisDevice => 'Questo dispositivo';

  @override
  String get sessionLastUsed => 'Ultimo uso';

  @override
  String get sessionSince => 'Accesso';

  @override
  String get sessionRevoke => 'Disconnetti';

  @override
  String get sessionLogoutOthers => 'Disconnetti gli altri dispositivi';

  @override
  String get sessionsEmpty => 'Nessun altro dispositivo è connesso.';

  @override
  String get sessionRevoked => 'Quel dispositivo è disconnesso.';

  @override
  String get sessionOthersRevoked =>
      'Tutti gli altri dispositivi sono disconnessi.';

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
  String get failureSessionEnded => 'La sessione è terminata. Accedi di nuovo.';

  @override
  String get failureForbidden => 'Il tuo account non può farlo.';

  @override
  String get failureTooMany => 'Troppi tentativi. Riprova tra poco.';

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
  String get actionLoadPrivacy => 'caricare le tue scelte di privacy';

  @override
  String get actionSavePrivacy => 'salvare le tue scelte di privacy';

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
  String get joinSkip => 'Continua senza club';

  @override
  String get joinInvalid =>
      'Il codice non è corretto, oppure il club non accetta nuovi membri.';

  @override
  String get joinAlready => 'Il tuo account è già in un club.';

  @override
  String get clubNoneTitle => 'Non sei ancora in un club';

  @override
  String get clubNoneBody =>
      'Velomine funziona anche da soli. Entra in un club quando vuoi uscire in gruppo e condividere con i suoi coach.';

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
  String get privacyTitle => 'Privacy delle uscite';

  @override
  String get privacyHelp =>
      'Cosa vedono gli altri quando condividi un\'uscita o quando il club può vederla. Tu vedi sempre tutto.';

  @override
  String get privacyOthersSee => 'Cosa vedono gli altri di ogni uscita';

  @override
  String get privacyHideHeartRate => 'Frequenza cardiaca';

  @override
  String get privacyHidePower => 'Potenza';

  @override
  String get privacyHideCadence => 'Cadenza';

  @override
  String get privacyHideSpeed => 'Velocità';

  @override
  String get privacyHideElevation => 'Dislivello';

  @override
  String get privacyHideTemperature => 'Temperatura';

  @override
  String get privacyTrimTitle => 'Nascondi inizio e fine';

  @override
  String get privacyTrimStart => 'Inizio';

  @override
  String get privacyTrimEnd => 'Fine';

  @override
  String get privacyTrimHelp =>
      'Metri nascosti all\'inizio e alla fine di ogni uscita. 0 tiene tutto.';

  @override
  String get privacyZonesTitle => 'Luoghi salvati';

  @override
  String get privacyZonesHelp =>
      'Ogni uscita nasconde fino a un miglio intorno a questi luoghi, e la linea del percorso si interrompe lì. Al massimo dieci luoghi.';

  @override
  String get privacyZonesEmpty => 'Nessun luogo salvato.';

  @override
  String get privacyAddZone => 'Aggiungi un luogo';

  @override
  String get privacyZoneName => 'Nome';

  @override
  String get privacyZoneRadius => 'Raggio (m)';

  @override
  String get privacyZoneRadiusHelp => 'Da 200 a 1609 metri.';

  @override
  String privacyZoneDelete(String name) {
    return 'Rimuovi $name';
  }

  @override
  String get privacyErrorRadius => 'Scegli un raggio da 200 a 1609 metri.';

  @override
  String get privacyErrorName => 'Dai un nome al luogo.';

  @override
  String get privacyErrorTrim => 'Scegli da 0 a 5000 metri per ogni estremo.';

  @override
  String get privacyRidePrivacy => 'Privacy delle uscite';

  @override
  String get privacyRidePrivacyHelp =>
      'Cosa vedono il tuo allenatore e i link condivisi.';

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
  String get bulkChooseFolder => 'Scegli una cartella';

  @override
  String get bulkChooseFiles => 'Scegli i file';

  @override
  String get bulkDropTitle => 'Rilascia per aggiungere le tue uscite';

  @override
  String get bulkDropHint =>
      'File o una cartella intera: vengono letti i file .fit, .gpx e .tcx, anche compressi (.gz).';

  @override
  String get bulkTitle => 'Aggiunta di uscite da file';

  @override
  String get bulkScanning => 'Sto guardando i file…';

  @override
  String bulkProgress(int done, int total) {
    return 'Lettura di $done su $total';
  }

  @override
  String get bulkCancel => 'Annulla';

  @override
  String get bulkStopping => 'Mi fermo…';

  @override
  String get bulkDone => 'Tutti i file sono stati letti';

  @override
  String get bulkStopped => 'Fermato prima della fine';

  @override
  String bulkAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uscite nuove',
      one: '1 uscita nuova',
      zero: 'Nessuna uscita nuova',
    );
    return '$_temp0';
  }

  @override
  String bulkAlreadyHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uscite erano già qui',
      one: '1 uscita era già qui',
    );
    return '$_temp0';
  }

  @override
  String bulkUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file non sono stati letti',
      one: '1 file non è stato letto',
    );
    return '$_temp0';
  }

  @override
  String bulkSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file saltati: non sono file di uscita',
      one: '1 file saltato: non è un file di uscita',
    );
    return '$_temp0';
  }

  @override
  String bulkNotRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file non sono stati letti',
      one: '1 file non è stato letto',
    );
    return '$_temp0';
  }

  @override
  String bulkAndMore(int count) {
    return 'e altri $count';
  }

  @override
  String get bulkClose => 'Chiudi';

  @override
  String get bulkSignedOut =>
      'Accedi prima, poi aggiungi di nuovo le tue uscite.';

  @override
  String get bulkNothing =>
      'Nessun file di uscita trovato. Velomine legge i file .fit, .gpx e .tcx, anche compressi (.gz).';

  @override
  String get bulkWaiting => 'Attendo un momento, il server è occupato…';

  @override
  String incomingAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uscite aggiunte. Verranno caricate in background.',
      one: '1 uscita aggiunta. Verrà caricata in background.',
    );
    return '$_temp0';
  }

  @override
  String incomingAlreadyHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uscite erano già qui.',
      one: '1 uscita era già qui.',
    );
    return '$_temp0';
  }

  @override
  String incomingRejectedOne(String name) {
    return '$name non è un file di uscita ed è stato saltato.';
  }

  @override
  String incomingRejectedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file non sono file di uscita e sono stati saltati.',
      one: '1 file non è un file di uscita ed è stato saltato.',
    );
    return '$_temp0';
  }

  @override
  String incomingSignedOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uscite sono state tenute. Accedi e verranno caricate.',
      one: '1 uscita è stata tenuta. Accedi e verrà caricata.',
    );
    return '$_temp0';
  }

  @override
  String get incomingOpen => 'Elenco uscite';

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
  String get rideActions => 'Azioni uscita';

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
  String get heartRateOnMap => 'Mostra la frequenza cardiaca sulla mappa';

  @override
  String mapHeartRateHint(int min, int max) {
    return 'Il colore del percorso indica la frequenza cardiaca da $min a $max bpm';
  }

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
  String get modelYear => 'Anno del modello';

  @override
  String get buildSpec => 'Allestimento o specifica';

  @override
  String get frameSize => 'Taglia telaio';

  @override
  String get modelYearHelper => 'Per esempio 2023. Facoltativo.';

  @override
  String get buildSpecHelper =>
      'Per esempio SL 7, Comp o il nome del gruppo. Facoltativo.';

  @override
  String get frameSizeHelper => '56, M o 17,5\".';

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
  String get errorModelYear =>
      'L\'anno del modello è tra 1900 e 2100, oppure vuoto.';

  @override
  String get errorWheelRange => 'La circonferenza ruota è tra 1000 e 2600 mm.';

  @override
  String get errorInitialDistance =>
      'La distanza prima di Velomine deve essere 0 o più.';

  @override
  String get cancel => 'Annulla';

  @override
  String get close => 'Chiudi';

  @override
  String get openFullMap => 'Apri la mappa intera';

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
  String get findPart => 'Cerca un componente conosciuto';

  @override
  String get findPartHint => 'Marca, modello o codice';

  @override
  String get mpn => 'Codice produttore (MPN)';

  @override
  String get gtin => 'Codice a barre (GTIN)';

  @override
  String get mpnHelper =>
      'Il codice stampato sul componente, per esempio CN-M8100. Facoltativo.';

  @override
  String get gtinHelper =>
      'Il numero sotto il codice a barre sulla confezione. Facoltativo.';

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
  String get errorGtin =>
      'Un GTIN ha 8, 12, 13 o 14 cifre e una cifra di controllo valida.';

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
  String get accountSearch => 'Cerca un account';

  @override
  String get clearSearch => 'Cancella la ricerca';

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
  String get resetTwoFactor => 'Reimposta l\'accesso a due fattori';

  @override
  String get resetTwoFactorBody =>
      'Il membro accede di nuovo con la password e configura da capo l\'app di autenticazione.';

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
      'Non impostato. Imposta VELOMINE__SMTP__HOST e VELOMINE__SMTP__FROM.';

  @override
  String get singleSignOn => 'Accesso singolo';

  @override
  String ssoDetail(String name, String authority) {
    return '$name · $authority';
  }

  @override
  String get ssoNotConfigured =>
      'Non impostato. Imposta VELOMINE__SSO__AUTHORITY, VELOMINE__SSO__CLIENTID e VELOMINE__SSO__CLIENTSECRET.';

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
  String get birthYear => 'Anno di nascita';

  @override
  String get birthYearHelper =>
      'La frequenza cardiaca massima si stima da qui con la formula di Tanaka (208 − 0,7 × età).';

  @override
  String estimatedMaxHeartRate(int bpm) {
    return 'Frequenza cardiaca massima stimata: $bpm bpm';
  }

  @override
  String get estimatedMaxHeartRateNone =>
      'Aggiungi il tuo anno di nascita per stimarla.';

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
  String get emailAccountNotifications => 'Email per account e club';

  @override
  String get emailAccountNotificationsHelp =>
      'Richieste di iscrizione e approvazioni, e nuove registrazioni in attesa.';

  @override
  String get emailTrainingNotifications => 'Email per uscite e componenti';

  @override
  String get emailTrainingNotificationsHelp =>
      'Uscite lette o non leggibili, e componenti usurati. Raggruppate in una sola email.';

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
  String get errorBirthYear =>
      'Inserisci un anno di nascita tra il 1900 e dieci anni fa.';

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
  String get wellbeingWithdrawConsent => 'Revoca il consenso';

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

  @override
  String get rideFilterAll => 'Tutte';

  @override
  String get rideTypeTitle => 'Dettagli uscita';

  @override
  String get rideTypeHelp => 'Che tipo di uscita era? Tutto è facoltativo.';

  @override
  String get rideTypeDiscipline => 'Superficie';

  @override
  String get rideTypeAssist => 'E-bike';

  @override
  String get rideTypeEnvironment => 'Dove';

  @override
  String get rideTypeCommute => 'Casa-lavoro';

  @override
  String get rideTypeNotSet => 'Imposta i dettagli';

  @override
  String get rideTypeEdit => 'Modifica i dettagli';

  @override
  String get rideTypeUnset => 'Non indicato';

  @override
  String get rideTypeNoAssist => 'Senza e-bike';

  @override
  String get rideTypeOutdoor => 'All\'aperto';

  @override
  String get rideTypeIndoor => 'Indoor';

  @override
  String get rideTypeVirtual => 'Virtuale';

  @override
  String get actionChangeRideType => 'cambiare i dettagli di questa uscita';

  @override
  String get yes => 'Sì';

  @override
  String get no => 'No';

  @override
  String get lapsTitle => 'Giri';

  @override
  String get lap => 'Giro';

  @override
  String get recorderRideType => 'Tipo di uscita';

  @override
  String get done => 'Fatto';

  @override
  String get recorderSettings => 'Impostazioni di registrazione';

  @override
  String get recorderEbike => 'E-bike';

  @override
  String get recorderEbikeHelp =>
      'Conta come assistita e preferisce la tua e-bike.';

  @override
  String get forgotPassword => 'Password dimenticata?';

  @override
  String get forgotPasswordTitle => 'Reimposta la password';

  @override
  String get forgotPasswordHelp =>
      'Inserisci l\'indirizzo email del tuo account. Se può essere reimpostata, ti invieremo un link.';

  @override
  String get forgotPasswordSent =>
      'Se esiste un account per quell\'indirizzo, abbiamo inviato un link per reimpostare la password. Controlla anche lo spam.';

  @override
  String get forgotPasswordUnavailable =>
      'Questo server non è configurato per inviare email. Chiedi a un amministratore del club di reimpostare la password.';

  @override
  String get forgotPasswordTooMany =>
      'Troppi tentativi. Riprova tra qualche minuto.';

  @override
  String get forgotPasswordFailed =>
      'Non è stato possibile avviare il ripristino. Riprova.';

  @override
  String get errorEnterEmail => 'Inserisci il tuo indirizzo email.';

  @override
  String get sendResetLink => 'Invia il link';

  @override
  String get resetPasswordTitle => 'Scegli una nuova password';

  @override
  String get resetPasswordHelp => 'Scegli una password di almeno 10 caratteri.';

  @override
  String get setNewPassword => 'Imposta la nuova password';

  @override
  String get newPassword => 'Nuova password';

  @override
  String get confirmPassword => 'Conferma password';

  @override
  String get passwordsDoNotMatch => 'Le due password non coincidono.';

  @override
  String get passwordTooShort => 'Usa almeno 10 caratteri.';

  @override
  String get resetPasswordInvalid =>
      'Questo link non è valido o è scaduto. Chiedine uno nuovo.';

  @override
  String get resetPasswordDone => 'Password cambiata. Accedi con quella nuova.';

  @override
  String get goToSignIn => 'Vai all\'accesso';

  @override
  String get changePassword => 'Cambia password';

  @override
  String get changePasswordTitle => 'Cambia password';

  @override
  String get currentPassword => 'Password attuale';

  @override
  String get passwordWrongCurrent => 'La password attuale non è corretta.';

  @override
  String get passwordNoPassword =>
      'Questo account accede con il single sign-on.';

  @override
  String get passwordChanged =>
      'Password cambiata. Accedi di nuovo su questo dispositivo.';

  @override
  String get passwordChangeFailed =>
      'Non è stato possibile cambiare la password. Riprova.';

  @override
  String get actionChangePassword => 'cambiare la password';

  @override
  String get actionResetPassword => 'reimpostare questa password';

  @override
  String get resetPasswordLink => 'Reimposta password';

  @override
  String resetPasswordLinkTitle(String name) {
    return 'Link di reimpostazione per $name';
  }

  @override
  String get resetPasswordLinkHelp =>
      'Invia questo link al membro. Funziona una volta e scade dopo 30 minuti.';

  @override
  String get copyLink => 'Copia link';

  @override
  String get linkCopied => 'Copiato';

  @override
  String get resetPasswordLinkFailed =>
      'Non è stato possibile creare il link. Riprova.';

  @override
  String get actionLoadNearbyClubs => 'trovare i club vicino a te';

  @override
  String get actionRequestJoinClub => 'chiedere di entrare nel club';

  @override
  String get actionCancelJoinRequest => 'annullare la richiesta';

  @override
  String get actionLoadJoinRequests => 'caricare le richieste di ingresso';

  @override
  String get actionApproveJoinRequest => 'approvare la richiesta';

  @override
  String get actionDeclineJoinRequest => 'rifiutare la richiesta';

  @override
  String get actionLoadSecurity => 'caricare le impostazioni di accesso';

  @override
  String get actionChangeSecurity => 'modificare le impostazioni di accesso';

  @override
  String get clubSeeNearby => 'Vedi i club vicino a te';

  @override
  String get clubLocation => 'Posizione del club';

  @override
  String get clubLocationHelp =>
      'Dove si ritrova il club. Serve solo a mostrarlo ai corridori vicini.';

  @override
  String get clubLocationNone => 'Nessuna posizione';

  @override
  String get clubLocationSet => 'Scegli sulla mappa';

  @override
  String get clubLocationChange => 'Cambia posizione';

  @override
  String get clubDiscoverable => 'Mostra questo club ai corridori vicini';

  @override
  String get clubDiscoverableHelp =>
      'I corridori senza club possono trovarlo per distanza e chiedere di entrare.';

  @override
  String get locationPickerTitle => 'Scegli un punto';

  @override
  String get locationPickerHelp =>
      'Sposta la mappa finché il segnaposto è sul posto.';

  @override
  String get locationPickerUse => 'Usa questo punto';

  @override
  String get locationPickerCurrent => 'Usa la mia posizione';

  @override
  String get locationCurrentUnavailable =>
      'Il dispositivo non ha condiviso la posizione.';

  @override
  String get locationMapFirst => 'Prima sposta la mappa sul posto.';

  @override
  String get nearbyTitle => 'Club vicino a te';

  @override
  String get nearbyIntro =>
      'Pedala al tuo ritmo. Entra in un club quando vuoi: puoi uscire quando vuoi e le tue uscite restano tue.';

  @override
  String get nearbyLocating => 'Sto cercando la tua posizione…';

  @override
  String get nearbyLocationHelp =>
      'La tua posizione serve solo a ordinare i club per distanza e non viene conservata sul server.';

  @override
  String get nearbyUseDevice => 'Usa la mia posizione';

  @override
  String get nearbySetHome => 'Imposta una posizione';

  @override
  String get nearbyHomeUsed => 'Uso la posizione salvata.';

  @override
  String nearbyRadius(int km) {
    return 'Entro $km km';
  }

  @override
  String nearbyEmpty(int km) {
    return 'Nessun club entro $km km. Pedala per conto tuo, oppure cerca più lontano.';
  }

  @override
  String nearbyDistance(int km) {
    return '~$km km';
  }

  @override
  String get nearbyAsk => 'Chiedi di entrare';

  @override
  String get nearbyRequested => 'Richiesto';

  @override
  String get nearbyCancel => 'Annulla richiesta';

  @override
  String nearbyRequestTitle(String club) {
    return 'Chiedi di entrare in $club';
  }

  @override
  String get nearbyRequestNote =>
      'Due parole per il proprietario (facoltative)';

  @override
  String get nearbyRequestSend => 'Invia richiesta';

  @override
  String get nearbyRequestSent =>
      'Richiesta inviata. Il proprietario deciderà quando può.';

  @override
  String nearbyPendingTitle(String club) {
    return 'In attesa di $club';
  }

  @override
  String get nearbyPendingBody =>
      'La tua richiesta è al proprietario del club.';

  @override
  String get nearbyWiden => 'Cerca più lontano';

  @override
  String nearbyReplaceTitle(String club) {
    return 'Annullare la richiesta a $club?';
  }

  @override
  String get nearbyReplaceBody =>
      'Puoi avere una sola richiesta aperta. Chiedendo a un altro club, questa viene annullata.';

  @override
  String get soloHintTitle => 'Pedala al tuo ritmo';

  @override
  String get soloHintBody =>
      'Ci sono club vicino a te, quando ne avrai voglia.';

  @override
  String get soloHintSee => 'Vedi i club';

  @override
  String get soloHintDismiss => 'Non ora';

  @override
  String get joinRequestsTitle => 'Richieste di ingresso';

  @override
  String get joinRequestsEmpty => 'Nessuno è in attesa di entrare.';

  @override
  String get joinRequestApprove => 'Approva';

  @override
  String get joinRequestDecline => 'Rifiuta';

  @override
  String joinRequestApproveTitle(String name) {
    return 'Far entrare $name?';
  }

  @override
  String get joinRequestApproveBody =>
      'Diventa un corridore. Le tue uscite restano tue; la condivisione resta una sua scelta.';

  @override
  String joinRequestDeclineTitle(String name) {
    return 'Rifiutare $name?';
  }

  @override
  String get joinRequestDeclineBody => 'Verrà avvisato, senza motivazione.';

  @override
  String notificationClubJoinRequest(String name) {
    return '$name ha chiesto di entrare nel tuo club.';
  }

  @override
  String notificationClubJoinApproved(String club) {
    return '$club ti ha accettato. Benvenuto!';
  }

  @override
  String notificationClubJoinDeclined(String club) {
    return '$club ha rifiutato la tua richiesta.';
  }

  @override
  String get actionLoadTemplates => 'caricare i tuoi modelli di allestimento';

  @override
  String get actionSaveTemplate => 'salvare il modello di allestimento';

  @override
  String get actionApplyTemplate => 'applicare il modello di allestimento';

  @override
  String get saveAsTemplate => 'Salva come modello di allestimento';

  @override
  String get applyTemplate => 'Applica un modello di allestimento';

  @override
  String get saveTemplateTitle =>
      'Salva i componenti di questa bici come modello';

  @override
  String get templateName => 'Nome del modello';

  @override
  String get templateNameHint => 'Per esempio: Gravel 2024';

  @override
  String templateParts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count componenti',
      one: '1 componente',
    );
    return '$_temp0';
  }

  @override
  String get noTemplates =>
      'Nessun modello di allestimento. Salva i componenti di una bici come modello per riutilizzarli.';

  @override
  String get applyTemplateTitle => 'Applica un modello di allestimento';

  @override
  String get templateApplied => 'Modello applicato.';

  @override
  String get errorTemplateName => 'Dai un nome al modello.';

  @override
  String get sharedCatalogue => 'Catalogo condiviso dei componenti';

  @override
  String get shareParts =>
      'Condividi i nuovi componenti con il catalogo condiviso';

  @override
  String get sharePartsHelp =>
      'I componenti non personalizzati che il catalogo condiviso non elenca vengono inviati all\'editore. I componenti personalizzati restano solo sulla tua bici.';

  @override
  String get catalogueNotConfigured =>
      'Questo server non ha un endpoint per i contributi, quindi non viene inviato nulla.';

  @override
  String catalogueVersion(int version, String date) {
    return 'Versione catalogo $version, ultimo controllo $date';
  }

  @override
  String get catalogueNeverSynced =>
      'Il catalogo condiviso non è ancora stato controllato.';

  @override
  String catalogueSynced(String date) {
    return 'Catalogo condiviso controllato il $date';
  }

  @override
  String get catalogueConflicts => 'Componenti diversi dal catalogo condiviso';

  @override
  String get keepMine => 'Tieni il mio';

  @override
  String get useShared => 'Usa il condiviso';

  @override
  String contributionCounts(int pending, int sent, int rejected, int failed) {
    return '$pending in attesa · $sent inviati · $rejected rifiutati · $failed falliti';
  }

  @override
  String get catalogueProblems =>
      'Componenti non accettati dal catalogo condiviso';

  @override
  String get contributionRejected => 'Rifiutato';

  @override
  String get contributionFailed => 'Abbandonato';

  @override
  String get custom => 'Componente personalizzato';

  @override
  String get customPart => 'Personalizzato';

  @override
  String get customHelper =>
      'Tieni questo componente fuori dal catalogo condiviso; non verrà inviato all\'editore.';

  @override
  String get privacy => 'Privacy';

  @override
  String get profileAthlete => 'Atleta';

  @override
  String get telemetryHelp =>
      'Aiuta a migliorare Velomine con segnalazioni anonime di errori e dati sulle prestazioni. Nessun dato che registri viene incluso.';

  @override
  String get crashReports => 'Segnalazioni di errori';

  @override
  String get crashReportsHelp =>
      'Stack trace e versione dell\'app, per correggere un bug.';

  @override
  String get usageData => 'Prestazioni e utilizzo';

  @override
  String get usageDataHelp =>
      'Schermate lente e funzioni usate, senza le tue uscite o dati di salute.';

  @override
  String get telemetryUnavailable => 'Questo server non raccoglie telemetria.';

  @override
  String get telemetrySaved => 'Salvato.';

  @override
  String get telemetryRestart => 'Riavvia l\'app per applicare questa scelta.';

  @override
  String powerCurveSummary(
    String p5s,
    String p1m,
    String p5m,
    String p20m,
    String ftp,
  ) {
    return 'Curva di potenza. Migliori 5 secondi $p5s watt, 1 minuto $p1m, 5 minuti $p5m, 20 minuti $p20m. FTP stimato $ftp watt.';
  }

  @override
  String routeMapSummary(String distance, String climb) {
    return 'Mappa del percorso. $distance, con $climb di dislivello.';
  }

  @override
  String routeMapDistanceSummary(String distance) {
    return 'Mappa del percorso. $distance.';
  }

  @override
  String get importFromStrava => 'Importa da Strava';

  @override
  String get importStarting => 'Avvio dell\'importazione…';

  @override
  String get importTitle => 'Importa da Strava';

  @override
  String get importRunning =>
      'Sto leggendo l\'archivio. Può richiedere qualche minuto.';

  @override
  String importProgress(int done, int total) {
    return '$done di $total attività lette';
  }

  @override
  String get importFinished => 'Importazione terminata';

  @override
  String importSummaryImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uscite importate',
      one: '1 uscita importata',
    );
    return '$_temp0';
  }

  @override
  String importSummaryDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uscite erano già qui',
      one: '1 uscita era già qui',
    );
    return '$_temp0';
  }

  @override
  String importSummaryFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file non sono stati letti',
      one: '1 file non è stato letto',
    );
    return '$_temp0';
  }

  @override
  String importSummarySkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attività saltate, non sono uscite o non hanno un file',
      one: '1 attività saltata, non è un\'uscita o non ha un file',
    );
    return '$_temp0';
  }

  @override
  String get importBackToRides => 'Torna alle uscite';

  @override
  String get importErrorNotStrava =>
      'Non è un\'esportazione di Strava: manca activities.csv.';

  @override
  String get importErrorMissing =>
      'L\'archivio non è più sul server. Scegli di nuovo il file.';

  @override
  String get importErrorUnknown => 'Non è stato possibile leggere l\'archivio.';

  @override
  String get actionImportRides => 'importare le tue uscite';

  @override
  String get actionLoadImport => 'controllare l\'importazione';

  @override
  String notificationRideImport(String subject) {
    return 'L\'importazione di $subject è terminata.';
  }

  @override
  String get loading => 'Caricamento';
}
