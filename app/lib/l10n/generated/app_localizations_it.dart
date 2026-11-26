// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get navRides => 'Giri';

  @override
  String get navAllRides => 'Tutti i giri';

  @override
  String get navGoals => 'Obiettivi';

  @override
  String get navOverview => 'Panoramica';

  @override
  String get navClubRides => 'Giri del club';

  @override
  String get navSharing => 'Condivisioni';

  @override
  String get navTotals => 'Totali';

  @override
  String get navGoalsAndEvents => 'Obiettivi ed eventi';

  @override
  String get nextEvent => 'Prossimo evento';

  @override
  String get dayUnit => 'giorno';

  @override
  String get daysUnit => 'giorni';

  @override
  String get navGroupClub => 'Club';

  @override
  String get privacyCardTitle => 'I tuoi dati sono tuoi.';

  @override
  String get privacyCardBody => 'Privati finché non li condividi.';

  @override
  String get ridesSubtitle => 'I tuoi giri e le tue gare.';

  @override
  String get rideDetailTitle => 'Giro';

  @override
  String get startRide => 'Inizia giro';

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
  String get notifications => 'Notifiche';

  @override
  String notificationsUnread(int count) {
    return 'Notifiche, $count non lette';
  }

  @override
  String get sendFeedback => 'Invia un feedback';

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
  String get units => 'Unità';

  @override
  String get unitsMetric => 'Metriche (km, kg)';

  @override
  String get unitsImperial => 'Imperiali (miglia, lb)';

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
  String get signInHelp => 'Accedi per vedere i tuoi giri e la tua forma.';

  @override
  String get signInTitle => 'Bentornato';

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
  String get registerCaption => 'Nuovo account';

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
  String registeredCheckEmail(String email) {
    return 'Il tuo account è pronto. Apri il link che abbiamo inviato a $email per confermarlo, poi accedi.';
  }

  @override
  String get resendVerification => 'Invia di nuovo il link';

  @override
  String get resendVerificationSent => 'Inviato. Potrebbe volerci un minuto.';

  @override
  String get resendVerificationTooMany =>
      'Troppe richieste. Riprova tra qualche minuto.';

  @override
  String get resendVerificationUnavailable =>
      'Questo server non invia email, quindi non c\'è nulla da reinviare.';

  @override
  String get verifyEmailTitle => 'Conferma la tua email';

  @override
  String get verifyEmailWorking => 'Sto confermando il tuo indirizzo…';

  @override
  String get verifyEmailDone => 'La tua email è confermata. Ora puoi accedere.';

  @override
  String get verifyEmailInvalid =>
      'Questo link non è valido o è scaduto. Accedi per chiederne uno nuovo.';

  @override
  String get verifyEmailSendAgain => 'Invia un nuovo link';

  @override
  String get verifyEmailResent => 'Un nuovo link è in arrivo.';

  @override
  String soloTrialActive(int days) {
    return 'Prova solo · $days giorni rimasti';
  }

  @override
  String get soloTrialLastDay => 'Prova solo · ultimo giorno';

  @override
  String get soloTrialEnded => 'Prova solo · terminata';

  @override
  String get authEmailNotConfirmed =>
      'Conferma il tuo indirizzo email prima di accedere. Controlla la posta per il link.';

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
  String get twoFactorIntro =>
      'Dopo la password inserisci un codice della tua app di autenticazione. È facoltativo e puoi disattivarlo quando vuoi.';

  @override
  String get twoFactorNoPassword =>
      'Questo account accede con l\'accesso singolo, che è già un secondo passaggio.';

  @override
  String get twoFactorStartSetup => 'Inizia la configurazione';

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
  String get twoFactorSetupTitle => 'Configura un\'app di autenticazione';

  @override
  String get twoFactorEnabled => 'L\'accesso a due fattori è attivo.';

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
  String get sessionRevoke => 'Disconnetti';

  @override
  String get sessionLogoutOthers => 'Disconnetti gli altri dispositivi';

  @override
  String get sessionLogoutOthersBody =>
      'Disconnette ogni dispositivo tranne questo. Dovranno accedere di nuovo.';

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
  String get setupTitle => 'Quale server usa il tuo club?';

  @override
  String get setupCaption => 'Server';

  @override
  String get setupServerAddress => 'Indirizzo del server';

  @override
  String get setupServerHint => 'https://velomine.club.example';

  @override
  String get setupInsecure =>
      'Questo indirizzo non è cifrato. Usalo solo su una rete di cui ti fidi, oppure chiedi all\'amministratore un indirizzo https.';

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
  String get failureDemoLocked =>
      'Nella demo questo è disattivato, perché tutti condividono questi account.';

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
  String get actionLoadRides => 'caricare i tuoi giri';

  @override
  String get actionUploadRide => 'caricare questo file';

  @override
  String get actionLoadRide => 'caricare questo giro';

  @override
  String get actionChangeRideBike => 'cambiare la bici';

  @override
  String get actionDeleteRide => 'eliminare il giro';

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
  String get actionLoadCoachRide => 'caricare questo giro';

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
  String get clubNoneTitleShort => 'Il tuo club';

  @override
  String get clubNoneSubtitle => 'Esci da solo, oppure in un club.';

  @override
  String get clubNearbyBody => 'I club che pedalano vicino a te, per distanza.';

  @override
  String get clubJoinWithCode => 'Entra con un codice';

  @override
  String get clubJoinBody =>
      'Hai un codice dal proprietario di un club? Entra con quello.';

  @override
  String get clubStartBody =>
      'Avvia un club per le persone con cui pedali. Un mese per provarlo.';

  @override
  String get clubSubtitle =>
      'Il tuo club, i suoi giri e le persone che ne fanno parte.';

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
      'Puoi rientrare con un nuovo codice. I tuoi giri restano tuoi.';

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
  String get sharingTitle => 'Cosa condividi';

  @override
  String get sharingHelp =>
      'Esce dal tuo account solo ciò che attivi. Il club vede sempre il tuo nome e il tuo posto nella lista.';

  @override
  String get shareRides => 'Giri';

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
      'Attiva prima i giri; i percorsi aggiungono la mappa.';

  @override
  String get shareStatsConfirmTitle => 'Condividere con i tuoi allenatori?';

  @override
  String get shareStatsConfirmBody =>
      'I tuoi allenatori vedranno tutti i valori dei tuoi giri: potenza, frequenza cardiaca, velocità, cadenza, dislivello, temperatura e l\'allenamento che ne deriva. Possono solo guardare; i giri restano tuoi da modificare o eliminare. La mappa richiede Percorsi, e anche allora l\'inizio, la fine e i tuoi luoghi salvati restano nascosti.';

  @override
  String get shareWellbeingConfirmTitle =>
      'Condividere il tuo benessere con i tuoi allenatori?';

  @override
  String get shareWellbeingConfirmBody =>
      'I tuoi allenatori vedranno i punteggi del tuo check-in giornaliero e quanto è stato duro ogni giro. Sono dati sulla salute, per questo te lo chiediamo prima. Le tue note restano private e puoi smettere di condividere in qualsiasi momento.';

  @override
  String get shareConfirmAction => 'Condividi';

  @override
  String get privacyTitle => 'Privacy dei giri';

  @override
  String get privacyHelp =>
      'Cosa il tuo club e i tuoi allenatori non vedono mai dei tuoi percorsi. Tu vedi sempre tutto.';

  @override
  String get privacyTrimTitle => 'Nascondi inizio e fine';

  @override
  String get privacyTrimStart => 'Inizio';

  @override
  String get privacyTrimEnd => 'Fine';

  @override
  String get privacyTrimHelp =>
      'Metri nascosti all\'inizio e alla fine di ogni giro. 0 tiene tutto.';

  @override
  String get privacyZonesTitle => 'Luoghi salvati';

  @override
  String get privacyZonesHelp =>
      'Ogni giro nasconde fino a un miglio intorno a questi luoghi, e la linea del percorso si interrompe lì. Al massimo dieci luoghi.';

  @override
  String get privacyZonesEmpty => 'Nessun luogo salvato.';

  @override
  String get privacyAddZone => 'Aggiungi un luogo';

  @override
  String get privacyZoneName => 'Nome';

  @override
  String get privacyZoneRadius => 'Raggio';

  @override
  String get privacyZoneRadiusHelp =>
      'Da 200 a 1609 metri, cioè da 0,1 a 1,0 miglia.';

  @override
  String privacyZoneDelete(String name) {
    return 'Rimuovi $name';
  }

  @override
  String get privacyErrorRadius =>
      'Scegli un raggio da 200 a 1609 metri (da 0,1 a 1,0 miglia).';

  @override
  String get privacyErrorName => 'Dai un nome al luogo.';

  @override
  String get privacyErrorTrim =>
      'Scegli da 0 a 5000 metri per ogni estremo (da 0 a 3,1 miglia).';

  @override
  String get privacyRidePrivacy => 'Privacy dei giri';

  @override
  String get privacyRidePrivacyHelp =>
      'Cosa vedono il tuo allenatore e i link condivisi.';

  @override
  String get viewsTitle => 'Chi ha guardato';

  @override
  String get viewsEmpty => 'Nessuno ha ancora guardato.';

  @override
  String get athletesTitle => 'Atleti';

  @override
  String get coachViewAthletes => 'Vedi atleti';

  @override
  String get athletesSubtitle =>
      'I membri che condividono con te i giri o gli allenamenti.';

  @override
  String get athletesEmpty =>
      'Nessun atleta condivide ancora con te. I membri attivano la condivisione nella scheda Club.';

  @override
  String lastRideOn(String date) {
    return 'Ultimo giro $date';
  }

  @override
  String get days7 => '7 giorni';

  @override
  String get days42 => '42 giorni';

  @override
  String get sharesRides => 'Giri';

  @override
  String get sharesTraining => 'Allenamento';

  @override
  String get sharesRoutes => 'Percorsi';

  @override
  String get coachAthleteNotFound => 'Questo atleta non condivide con te.';

  @override
  String get coachRideNotFound => 'Questo giro non è condiviso con te.';

  @override
  String get coachReadOnly => 'Condivisa dall\'atleta, sola lettura.';

  @override
  String get coachNoRides => 'Nessun giro condiviso.';

  @override
  String get coachPlan => 'Piano';

  @override
  String coachPlanDone(int done, int total) {
    return '$done di $total fatte questa settimana';
  }

  @override
  String coachPlanPlannedRidden(String planned, String ridden) {
    return '$planned previsto · $ridden fatto';
  }

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
  String get adminClubInactive => 'Inattivo';

  @override
  String get adminClubPlanEnded => 'Piano terminato';

  @override
  String get adminClubActivate => 'Attiva club';

  @override
  String get adminClubDeactivate => 'Disattiva club';

  @override
  String get adminClubActiveHelp =>
      'Un club inattivo mantiene membri e giri, ma nessuno può iscriversi finché non lo riattivi.';

  @override
  String get adminPeopleAndRides => 'Persone e giri';

  @override
  String get adminServer => 'Server';

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
    return 'Il tuo giro $subject è pronto.';
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
  String get rideErrorInvalid => 'Questo non è un file di un giro.';

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
  String get uploadRide => 'Carica giro';

  @override
  String get uploading => 'Caricamento…';

  @override
  String get bulkChooseFolder => 'Scegli una cartella';

  @override
  String get bulkChooseFiles => 'Scegli i file';

  @override
  String get zwiftTitle => 'Da Zwift';

  @override
  String get zwiftHint =>
      'Zwift conserva ogni giro come file FIT in Documents/Zwift/Activities. Scegli quella cartella per portarli dentro tutti.';

  @override
  String get bulkDropTitle => 'Rilascia per aggiungere i tuoi giri';

  @override
  String get bulkDropHint =>
      'File o una cartella intera: vengono letti i file .fit, .gpx e .tcx, anche compressi (.gz).';

  @override
  String get bulkTitle => 'Aggiunta di giri da file';

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
      other: '$count giri nuovi',
      one: '1 giro nuovo',
      zero: 'Nessun giro nuovo',
    );
    return '$_temp0';
  }

  @override
  String bulkAlreadyHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giri erano già qui',
      one: '1 giro era già qui',
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
      other: '$count file saltati: non sono file di giro',
      one: '1 file saltato: non è un file di giro',
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
      'Accedi prima, poi aggiungi di nuovo i tuoi giri.';

  @override
  String get bulkNothing =>
      'Nessun file di giro trovato. Velomine legge i file .fit, .gpx e .tcx, anche compressi (.gz).';

  @override
  String get bulkWaiting => 'Attendo un momento, il server è occupato…';

  @override
  String incomingAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giri aggiunti. Verranno caricati in background.',
      one: '1 giro aggiunto. Verrà caricato in background.',
    );
    return '$_temp0';
  }

  @override
  String incomingAlreadyHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giri erano già qui.',
      one: '1 giro era già qui.',
    );
    return '$_temp0';
  }

  @override
  String incomingRejectedOne(String name) {
    return '$name non è un file di giro ed è stato saltato.';
  }

  @override
  String incomingRejectedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file non sono file di giro e sono stati saltati.',
      one: '1 file non è un file di giro ed è stato saltato.',
    );
    return '$_temp0';
  }

  @override
  String incomingSignedOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giri sono stati tenuti. Accedi e verranno caricati.',
      one: '1 giro è stato tenuto. Accedi e verrà caricato.',
    );
    return '$_temp0';
  }

  @override
  String get incomingOpen => 'Elenco giri';

  @override
  String get noRides => 'Nessun giro. Carica un file FIT, GPX o TCX.';

  @override
  String get loadMore => 'Carica altre';

  @override
  String get readingFile => 'Lettura del file…';

  @override
  String get delete => 'Elimina';

  @override
  String get deleteRideTitle => 'Eliminare questo giro?';

  @override
  String get deleteRideBody =>
      'Il giro, i suoi grafici e il file caricato vengono rimossi. Non si può annullare.';

  @override
  String get keepIt => 'Mantienila';

  @override
  String get rideNotFound => 'Questo giro non esiste, oppure non è tuo.';

  @override
  String get couldNotLoadRide => 'Impossibile caricare questo giro.';

  @override
  String get trainingHint =>
      'Imposta frequenza cardiaca massima e FTP nel profilo per vedere zone e carico di allenamento.';

  @override
  String get heartRateZones => 'Zone di frequenza cardiaca';

  @override
  String heartRateZonesFromThreshold(String bpm) {
    return 'Zone dalla tua frequenza cardiaca di soglia ($bpm bpm)';
  }

  @override
  String heartRateZonesFromMax(String bpm) {
    return 'Zone dalla tua frequenza cardiaca massima ($bpm bpm)';
  }

  @override
  String heartRateZonesFromMaxEstimated(String bpm) {
    return 'Zone dalla tua frequenza cardiaca massima ($bpm bpm, stimata)';
  }

  @override
  String get powerZones => 'Zone di potenza';

  @override
  String get zonesTitle => 'Zone';

  @override
  String get zonesEdit => 'Modifica';

  @override
  String get zonesEditTitle => 'Le tue zone';

  @override
  String get zonesEditHelp =>
      'Il limite superiore di ogni zona, in watt o battiti al minuto. Le zone sono una quota del tuo FTP e della tua frequenza cardiaca, quindi si spostano quando cambiano.';

  @override
  String zonesLimitLabel(int zone) {
    return 'Zona $zone fino a';
  }

  @override
  String get zonesInvalidLimit =>
      'Inserisci un numero intero maggiore di zero per ogni zona.';

  @override
  String get zonesNotRising =>
      'Il limite di ogni zona deve essere più alto del precedente.';

  @override
  String get zonesBackToAutomatic => 'Torna all\'automatico';

  @override
  String get zonesResetTitle => 'Usare le zone standard?';

  @override
  String get zonesResetBody =>
      'I tuoi limiti vengono rimossi da tutte le zone e tornano quelli standard.';

  @override
  String get zonesResetAction => 'Usa le zone standard';

  @override
  String get zonesCustom => 'Limiti tuoi';

  @override
  String get momentHint =>
      'Passa sopra un grafico, oppure tocca e trascina, per vedere i valori lungo il giro.';

  @override
  String momentAt(String time, String distance) {
    return 'Alle $time$distance';
  }

  @override
  String get rideNumbers => 'Numeri';

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
  String get statEffortScore => 'Punteggio di sforzo';

  @override
  String get effortFromPower => 'Dalla tua potenza';

  @override
  String get effortFromHeartRate => 'Dalla tua frequenza cardiaca';

  @override
  String get effortFromFeel => 'Da quanto è sembrata dura';

  @override
  String get effortFromEstimated => 'Dai watt stimati';

  @override
  String get statEfficiency => 'Fattore di efficienza';

  @override
  String get statDecoupling => 'Decoupling';

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
  String zoneName(String zone) {
    String _temp0 = intl.Intl.selectLogic(zone, {
      '1': 'Z1 Recupero',
      '2': 'Z2 Resistenza',
      '3': 'Z3 Tempo',
      '4': 'Z4 Soglia',
      '5': 'Z5 VO2max',
      '6': 'Z6 Anaerobico',
      '7': 'Z7 Neuromuscolare',
      'other': 'Zona',
    });
    return '$_temp0';
  }

  @override
  String get bike => 'Bici';

  @override
  String get noBike => 'Nessuna bici';

  @override
  String get mapOfRoute => 'Mappa del percorso';

  @override
  String get mapVirtualWorld =>
      'Mondo virtuale: la linea è disegnata senza mappa.';

  @override
  String get heartRateOnMap => 'Mostra la frequenza cardiaca sulla mappa';

  @override
  String mapHeartRateHint(int min, int max) {
    return 'Il colore del percorso indica la frequenza cardiaca da $min a $max bpm';
  }

  @override
  String mapHeartRateLegend(int min, int max) {
    return '$min–$max bpm';
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
  String get bikesSubtitle => 'Tutte le bici che usi e ciò che serve loro.';

  @override
  String get noBikes =>
      'Nessuna bici. Aggiungine una per tenere traccia dei chilometri e dell\'usura dei componenti. I nuovi giri ricevono la bici predefinita.';

  @override
  String get defaultBike => 'Predefinita';

  @override
  String get archived => 'Archiviata';

  @override
  String get deleteBikeTitle => 'Eliminare questa bici?';

  @override
  String get deleteBikeBody =>
      'La bici e i suoi componenti vengono rimossi. I giri restano, ma non indicheranno più quale bici hai usato. Per conservare la storia, archivia la bici.';

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
  String get metricPower => 'Potenza';

  @override
  String get statRides => 'Giri';

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
  String get totals => 'Totali';

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
    return '$used di $expected';
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
  String periodTotals(int count, String duration, String elevation) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giri',
      one: '1 giro',
      zero: 'Nessun giro',
    );
    return '$_temp0 · $duration · $elevation di dislivello';
  }

  @override
  String get goals => 'Obiettivi';

  @override
  String get addGoal => 'Aggiungi obiettivo';

  @override
  String get noGoals =>
      'Nessun obiettivo. Imposta un traguardo per ogni settimana, mese o anno: distanza, dislivello, tempo in bici o numero di giri.';

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
  String get goalMetricRides => 'Giri';

  @override
  String get goalUnitRides => 'giri';

  @override
  String goalRideCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giri',
      one: '1 giro',
      zero: 'Nessun giro',
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
  String get goalDeleteTitle => 'Eliminare questo obiettivo?';

  @override
  String get goalDeleteBody =>
      'L\'obiettivo e il suo traguardo vengono rimossi. I tuoi giri restano come sono.';

  @override
  String goalSemantics(String metric) {
    return 'Obiettivo: $metric';
  }

  @override
  String goalPercent(int percent) {
    return '$percent %';
  }

  @override
  String goalProgress(String current, String target, int percent) {
    return '$current di $target · $percent %';
  }

  @override
  String goalLeft(Object value) {
    return '$value per arrivare';
  }

  @override
  String goalReachedBy(Object value) {
    return 'Superato di $value';
  }

  @override
  String goalsSummary(num reached, num running) {
    String _temp0 = intl.Intl.pluralLogic(
      running,
      locale: localeName,
      other: '$running obiettivi in corso.',
      one: 'Un obiettivo in corso.',
      zero: 'Nessun obiettivo in corso.',
    );
    String _temp1 = intl.Intl.pluralLogic(
      reached,
      locale: localeName,
      other: '$reached raggiunti.',
      one: 'Uno raggiunto.',
      zero: '',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String chartAverage(String value) {
    return 'Media $value';
  }

  @override
  String totalsSemanticsMeasure(String measure, String period, String value) {
    return '$measure per $period. Questo periodo: $value.';
  }

  @override
  String get fitnessTrendRising => 'La tua forma sta salendo.';

  @override
  String get fitnessTrendFalling => 'La tua forma sta scendendo.';

  @override
  String formFitnessFatigue(int fitness, int fatigue) {
    return 'Forma $fitness, fatica $fatigue.';
  }

  @override
  String weekAgainstAverage(String trend, String average) {
    String _temp0 = intl.Intl.selectLogic(trend, {
      'above': 'Sopra la tua media di 12 settimane di $average.',
      'below': 'Sotto la tua media di 12 settimane di $average.',
      'other': 'In linea con la tua media di 12 settimane di $average.',
    });
    return '$_temp0';
  }

  @override
  String get noEventPlanned =>
      'Nessun evento in programma. Aggiungine uno per vedere i giorni che mancano.';

  @override
  String get totalsEmpty =>
      'Ancora nessun giro. Carica o registra un giro per vedere i tuoi totali.';

  @override
  String get progressSubtitle => 'La tua forma nel periodo che scegli.';

  @override
  String get progressFilterTitle => 'Filtra i progressi';

  @override
  String get totalsTitleWeekly => 'Distanza per settimana';

  @override
  String get totalsTitleMonthly => 'Distanza per mese';

  @override
  String get totalsTitleYearly => 'Distanza per anno';

  @override
  String get totalsShowEarlier => 'Mostra precedenti';

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
      'Imposta il tuo FTP o indossa una fascia cardiaca, poi carica un giro per vedere il carico di allenamento.';

  @override
  String get fitnessHeartRateLoad =>
      'Include giri valutati dalla frequenza cardiaca.';

  @override
  String get trimpHelp =>
      'Il TRIMP pesa ogni zona cardiaca da 1 a 5 (Edwards).';

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
  String get dailyLoadEmpty =>
      'Nessun carico di allenamento in questo periodo. I giri con potenza o frequenza cardiaca lo aumentano.';

  @override
  String get trainingLoadHelp =>
      'La fitness media gli ultimi 42 giorni di carico, la fatica gli ultimi 7. La forma è fitness meno fatica.';

  @override
  String get trainingMonotonous =>
      'Questa settimana ogni giorno è stato impegnativo uguale. Un giorno facile ti aiuta ad assimilare.';

  @override
  String get trainingHeavyWeek =>
      'Questa settimana è stata molto più pesante del solito.';

  @override
  String trainingStrain(String monotony, String strain) {
    return 'Monotonia $monotony · Strain $strain';
  }

  @override
  String get riderCardTitle => 'I tuoi numeri';

  @override
  String get riderCardWhole => 'Tutta la scheda';

  @override
  String get riderCardFtpPerKilo => 'FTP per chilo';

  @override
  String riderCardFtpAtWeight(int ftp, double weight) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return '$ftp W a $weightString kg';
  }

  @override
  String get riderCardPeak => 'Potenza di picco';

  @override
  String riderCardPeakNote(String duration) {
    return 'Il migliore $duration, ultimi 90 giorni';
  }

  @override
  String get riderCardPowerNote =>
      'Calcolata dai tuoi migliori sforzi degli ultimi 90 giorni.';

  @override
  String get riderCardBestsNote =>
      'I tuoi migliori sforzi degli ultimi 90 giorni. Tocca uno per aprire l\'uscita.';

  @override
  String get riderCardEfficiencyNote =>
      'La media delle tue uscite costanti, per settimana.';

  @override
  String get riderCardTotalsNote => 'Le tue uscite degli ultimi 90 giorni.';

  @override
  String get riderCardEffortNote => 'Dal tuo punteggio di sforzo.';

  @override
  String get riderCardEventNote => 'Dal tuo calendario.';

  @override
  String get accountSearch => 'Cerca un account';

  @override
  String get clearSearch => 'Cancella la ricerca';

  @override
  String get adminAccounts => 'Account';

  @override
  String get adminSettings => 'Impostazioni';

  @override
  String get authOr => 'oppure';

  @override
  String get adminOverview => 'Panoramica';

  @override
  String get adminOverviewSubtitle => 'Questo server in sintesi.';

  @override
  String get adminAccountsSubtitle => 'Gli account su questo server.';

  @override
  String get adminClubsSubtitle => 'I club su questo server.';

  @override
  String get adminSettingsSubtitle => 'Come funziona questo server.';

  @override
  String deleteUserTitle(String name) {
    return 'Eliminare $name?';
  }

  @override
  String deleteUserBody(String email) {
    return 'L\'account di $email viene eliminato per sempre: giri, bici, obiettivi e file dei giri. Non si può annullare.';
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
  String get noOverview => 'Nessuna panoramica.';

  @override
  String get noSettings => 'Nessuna impostazione.';

  @override
  String get rideFilesOnDisk => 'File dei giri su disco';

  @override
  String get serverVersion => 'Versione del server';

  @override
  String get rideReaderVersion => 'Versione del lettore dei giri';

  @override
  String get ridesToReread => 'Giri in attesa di essere riletti';

  @override
  String get ridesNotReread => 'Giri che non è stato possibile rileggere';

  @override
  String get profileTitle => 'Profilo';

  @override
  String get preferences => 'Preferenze';

  @override
  String get riding => 'In sella';

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
  String heartRateSourceManual(String date) {
    return 'Impostata da te il $date';
  }

  @override
  String heartRateSourceMeasured(String date) {
    return 'Misurata nel tuo giro del $date';
  }

  @override
  String get heartRateSourceMeasuredDeleted =>
      'Misurata in un giro che hai eliminato';

  @override
  String get maxHeartRateField => 'Frequenza cardiaca massima';

  @override
  String get thresholdHeartRateField => 'Frequenza cardiaca di soglia';

  @override
  String get heartRateLeaveEmpty => 'Lascia vuoto per stimarla.';

  @override
  String get thresholdHeartRateHelp =>
      'La frequenza cardiaca più alta che riesci a tenere per circa un\'ora.';

  @override
  String thresholdAboveMax(int max) {
    return 'Sopra la massima in uso ($max bpm). Le tue zone seguono ancora la massima.';
  }

  @override
  String get heartRateSourceMaxEstimate =>
      'Stimata dalla tua età (208 − 0,7 × età)';

  @override
  String get heartRateSourceThresholdEstimate =>
      'Stimata come 89 % della tua massima';

  @override
  String heartRateMaxMeasured(int bpm) {
    return 'Nuova frequenza cardiaca massima: $bpm bpm. Le tue zone ora la usano.';
  }

  @override
  String heartRateMaxMeasuredOnly(int bpm) {
    return 'Nuova frequenza cardiaca massima: $bpm bpm.';
  }

  @override
  String heartRateThresholdMeasured(int bpm) {
    return 'Nuova frequenza cardiaca di soglia: $bpm bpm. Le tue zone ora la usano.';
  }

  @override
  String heartRateSuggested(int bpm, int current) {
    return 'Questo giro ha raggiunto $bpm bpm, oltre i $current che hai impostato. Usare $bpm?';
  }

  @override
  String heartRateSuggestionUse(int bpm) {
    return 'Usa $bpm';
  }

  @override
  String heartRateSuggestionKeep(int current) {
    return 'Mantieni $current';
  }

  @override
  String get timeZone => 'Fuso orario';

  @override
  String get timeZoneHelper =>
      'Decide in quale giorno conta un giro quando il file non lo indica. Vuoto significa UTC.';

  @override
  String get firstDayOfWeek => 'La settimana inizia di';

  @override
  String get emailNotifications => 'Inviami le notifiche via email';

  @override
  String get emailAvailableHelp =>
      'Un giro letto, un componente usurato e così via.';

  @override
  String get emailUnavailableHelp =>
      'Questo server non è configurato per inviare email, quindi per ora non viene inviato nulla.';

  @override
  String get emailAccountNotifications => 'Email per account e club';

  @override
  String get emailAccountNotificationsHelp =>
      'Richieste di iscrizione e approvazioni, e nuove registrazioni in attesa.';

  @override
  String get emailTrainingNotifications => 'Email per giri e componenti';

  @override
  String get emailTrainingNotificationsHelp =>
      'Giri letti o non leggibili, e componenti usurati. Raggruppati in una sola email.';

  @override
  String get yourData => 'I tuoi dati';

  @override
  String get yourDataHelp =>
      'Sono tuoi. Scarica tutto ciò che Velomine conserva su di te: i tuoi dati, le bici, gli obiettivi e i giri, con ogni file esattamente come l\'hai caricato.';

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
  String get errorWeight =>
      'Inserisci un peso accettato dal server: da 20 a 300 kg (da 44 a 661 lb).';

  @override
  String get errorBirthYear =>
      'Inserisci un anno di nascita tra il 1900 e dieci anni fa.';

  @override
  String get errorHeartRate =>
      'Inserisci una massima tra 120 e 230 bpm o una soglia tra 90 e 220 bpm, sotto la tua massima.';

  @override
  String get deleteAccountTitle => 'Eliminare il tuo account?';

  @override
  String get deleteAccountBody =>
      'Elimina per sempre il tuo account e tutto ciò che contiene: giri e file, bici, obiettivi e notifiche. Scarica prima i tuoi dati se vuoi conservarli. Non si può annullare.';

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
  String get notificationsSubtitle =>
      'Ciò che il server ti ha detto, dal più recente.';

  @override
  String get notificationGroupRides => 'Giri';

  @override
  String get notificationGroupUnread => 'Non lette';

  @override
  String get notificationGroupClub => 'Club';

  @override
  String get notificationGroupBikes => 'Bici';

  @override
  String get notificationGroupAccount => 'Account';

  @override
  String get markAllRead => 'Segna tutte come lette';

  @override
  String get noNotifications =>
      'Ancora nulla. Qui vedrai quando un giro è stato letto o un componente della bici è quasi usurato.';

  @override
  String get unread => 'Non letta';

  @override
  String get recordRide => 'Registra un giro';

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
      'Nessuna abbinata. Facoltativa: la frequenza cardiaca viene salvata con il giro.';

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
  String get sensorConnectsOnStart => 'Si connette quando inizi un giro';

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
  String get noLocalRides => 'Nessun giro registrato su questo telefono.';

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
      'La registrazione si è fermata inaspettatamente. Completa per conservare il giro.';

  @override
  String get finish => 'Completa';

  @override
  String get retry => 'Riprova';

  @override
  String get upload => 'Carica';

  @override
  String get deleteFromPhone => 'Elimina questo giro dal telefono';

  @override
  String get deleteLocalRideTitle => 'Eliminare questo giro dal telefono?';

  @override
  String get deleteLocalRideBodyUploaded =>
      'Il giro è già sul server. Viene rimossa solo la copia su questo telefono.';

  @override
  String get deleteLocalRideBodyNotUploaded =>
      'Questo giro non è stato caricato. Se lo elimini dal telefono è perso per sempre.';

  @override
  String get pairStrapTitle => 'Abbina una fascia cardio';

  @override
  String get pairStrapHelp =>
      'Indossa la fascia perché si attivi, poi sceglila qui sotto. Verrà ricordata per i prossimi giri.';

  @override
  String get searchingStraps => 'Ricerca delle fasce…';

  @override
  String get noStraps =>
      'Nessuna fascia trovata. Controlla che la fascia sia indossata e il Bluetooth acceso.';

  @override
  String get searchAgain => 'Cerca di nuovo';

  @override
  String sensorSignalStrength(int rssi) {
    return '$rssi dBm';
  }

  @override
  String get recorderPermission =>
      'Consenti la posizione precisa, e le notifiche se richieste, così il giro può continuare a registrare.';

  @override
  String get recorderGpsOff =>
      'Attiva la posizione (GPS) per registrare un giro.';

  @override
  String get recorderLocationFailed =>
      'Il telefono non è riuscito ad avviare gli aggiornamenti di posizione.';

  @override
  String get recorderUnsupported =>
      'La registrazione è disponibile solo sul telefono.';

  @override
  String get recorderTooShort => 'Il giro era troppo breve per essere salvato.';

  @override
  String get recorderFitFailed => 'Non è stato possibile salvare il giro.';

  @override
  String get recorderStillRecording => 'Ferma il giro prima di completarlo.';

  @override
  String get recorderRideNotFound => 'Quel giro non è più su questo telefono.';

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
      'Il server ha impiegato troppo tempo a leggere il giro.';

  @override
  String get uploadServerFailed =>
      'Il server non è riuscito a leggere questo giro.';

  @override
  String uploadHttpRefused(String code) {
    return 'Il server ha rifiutato il caricamento ($code).';
  }

  @override
  String get uploadFailedGeneric => 'Caricamento non riuscito. Riprova.';

  @override
  String get readiness => 'Prontezza';

  @override
  String get readinessHard => 'Pronto per un giro duro';

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
  String get readinessNoData => 'Registra un giro per vedere la prontezza.';

  @override
  String get readinessLoadOnly =>
      'Aggiungi il check-in giornaliero per includere come ti senti.';

  @override
  String readinessWhyScore(Object score) {
    return 'Perché $score';
  }

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
  String get readinessFactorRpe => 'RPE ultimo giro';

  @override
  String get wellbeing => 'Benessere';

  @override
  String get wellbeingConsentTitle => 'Prima di iniziare';

  @override
  String get wellbeingConsentBody =>
      'Velomine conserva un breve check-in giornaliero e l\'RPE che aggiungi ai giri. Sono dati sulla salute: nessun altro li vede se non li condividi con i tuoi allenatori, e puoi esportarli o eliminarli in qualsiasi momento. Non sono consigli medici.';

  @override
  String get wellbeingConsentAction => 'Accetto';

  @override
  String get wellbeingWithdrawTitle => 'Revocare il consenso al benessere?';

  @override
  String get wellbeingWithdrawBody =>
      'Velomine smette di usare i tuoi check-in e le note sui giri, e i tuoi allenatori non li vedono più. Quello che hai salvato resta finché non lo elimini, e puoi acconsentire di nuovo quando vuoi.';

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
  String get wellbeingSleep => 'Sonno';

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
  String get wellbeingShortSleep => 'Son';

  @override
  String get wellbeingHistory14 => 'Ultimi 14 giorni';

  @override
  String get wellbeingCheckIn => 'Check-in';

  @override
  String get wellbeingHowYouFeel => 'Come ti senti';

  @override
  String get wellbeingNoToday =>
      'Nessun check-in oggi. La prontezza viene misurata solo sui tuoi giri.';

  @override
  String get wellbeingPrivate =>
      'Lo vedi solo tu. Prontezza e note non arrivano mai a un coach.';

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
      'Attiva il benessere in Progressi per aggiungere come è andato un giro.';

  @override
  String get shareWellbeing => 'Benessere';

  @override
  String get shareWellbeingHelper =>
      'Punteggi del check-in e RPE dei giri; le note restano private.';

  @override
  String get shareRidesHelper => 'I tuoi giri e l\'allenamento che ne deriva.';

  @override
  String get sharesWellbeing => 'Benessere';

  @override
  String get powerCurve => 'Curva di potenza';

  @override
  String get powerCurveEmpty =>
      'Registra giri con un misuratore di potenza per vedere la curva.';

  @override
  String get powerBestEfforts => 'Migliori sforzi';

  @override
  String powerCurveSentence(Object days) {
    return 'La tua migliore potenza per ogni durata negli ultimi $days giorni.';
  }

  @override
  String get bestEffortsDuration => 'Durata';

  @override
  String get bestEffortsPower => 'Potenza';

  @override
  String get bestEffortsWPerKg => 'W/kg';

  @override
  String get criticalPowerExplain =>
      'La potenza che riesci a tenere a lungo, e la riserva sopra di essa per gli scatti.';

  @override
  String get criticalPowerTitle => 'Potenza critica';

  @override
  String criticalPowerPeak(Object peak) {
    return 'Picco $peak W';
  }

  @override
  String ftpValue(Object watts) {
    return 'FTP $watts W';
  }

  @override
  String ftpEstimateToday(int watts, String method) {
    return 'Stima di oggi: $watts W, $method.';
  }

  @override
  String get ftpCurrent => 'FTP';

  @override
  String get ftpMethod20 => '95 % della tua migliore potenza sui 20 minuti';

  @override
  String get ftpMethod8 => '90 % della tua migliore potenza sugli 8 minuti';

  @override
  String ftpUse(int watts) {
    return 'Usa $watts W';
  }

  @override
  String ftpReminderStaleTitle(int weeks) {
    return 'Il tuo FTP ha $weeks settimane';
  }

  @override
  String get ftpReminderStaleBody =>
      'Zone e TSS lo usano. Fai un test, oppure usa la stima se ti sembra giusta.';

  @override
  String get ftpReminderEstimateTitle =>
      'Puoi essere più forte di quanto dica il tuo FTP';

  @override
  String ftpReminderEstimateBody(String estimate, String ftp) {
    return 'I tuoi migliori sforzi suggeriscono $estimate W; il tuo FTP è $ftp W.';
  }

  @override
  String get ftpReminderMissingTitle => 'Imposta il tuo FTP';

  @override
  String ftpReminderMissingBody(String estimate) {
    return 'I tuoi migliori sforzi suggeriscono $estimate W.';
  }

  @override
  String get ftpReminderHow => 'Come fare il test';

  @override
  String get ftpReminderHowBody =>
      'Riscaldati per 15 minuti, con tre brevi sforzi intensi. Pedala 5 minuti forte, poi 10 minuti facile. Poi pedala 20 minuti il più forte che riesci a tenere in modo costante. Velomine noterà lo sforzo e ti suggerirà il nuovo FTP (95 % dei 20 minuti).';

  @override
  String get ftpReminderNotNow => 'Non ora';

  @override
  String ftpSourceManual(String date) {
    return 'Impostato da te il $date';
  }

  @override
  String ftpSourceEstimate(String date) {
    return 'Dalla tua stima, adottata il $date';
  }

  @override
  String ftpSourceTest(String date) {
    return 'Dal tuo giro del $date';
  }

  @override
  String ftpSourceEarlier(String date) {
    return 'Impostato prima del $date';
  }

  @override
  String get ftpHistory => 'Storia dell\'FTP';

  @override
  String get ftpHistoryEmpty =>
      'Il tuo FTP è stato impostato una sola volta, quindi non c\'è ancora niente da confrontare.';

  @override
  String get ftpYouTypedIt => 'L\'hai scritto tu';

  @override
  String get ftpFromTheEstimate => 'Dalla stima';

  @override
  String get ftpFromYourRide => 'Dal tuo giro';

  @override
  String get ftpBeforeHistory => 'Prima che tenessimo la storia';

  @override
  String ftpSuggestionTitle(String watts) {
    return 'Questo giro suggerisce un FTP di $watts W';
  }

  @override
  String ftpSuggestionMethod20(String effort) {
    return '95 % dei tuoi migliori 20 minuti ($effort W)';
  }

  @override
  String ftpSuggestionMethod30(String effort) {
    return '97 % dei tuoi migliori 30 minuti ($effort W)';
  }

  @override
  String get ftpSuggestionMethod60 => 'I tuoi migliori 60 minuti';

  @override
  String ftpSuggestionUse(String watts) {
    return 'Usa $watts W';
  }

  @override
  String get ftpSuggestionDismiss => 'Ignora';

  @override
  String notificationFtpSuggested(String record) {
    return 'Un giro suggerisce un FTP di $record.';
  }

  @override
  String notificationHeartRateMaxMeasured(int bpm) {
    return 'La tua frequenza cardiaca massima ora è $bpm bpm, misurata in un giro.';
  }

  @override
  String notificationHeartRateThresholdMeasured(int bpm) {
    return 'La tua frequenza cardiaca di soglia ora è $bpm bpm, misurata in un giro.';
  }

  @override
  String notificationHeartRateMaxSuggested(int bpm) {
    return 'Un giro suggerisce una frequenza cardiaca massima di $bpm bpm.';
  }

  @override
  String notificationHeartRateThresholdSuggested(int bpm) {
    return 'Un giro suggerisce una frequenza cardiaca di soglia di $bpm bpm.';
  }

  @override
  String get vo2MaxEstimate => 'VO2max stimato';

  @override
  String get vo2MaxNeedsWeight => 'Imposta il peso per stimare il VO2max.';

  @override
  String get vo2MaxNeedsEffort =>
      'Serve uno sforzo di 5 minuti per stimare il VO2max.';

  @override
  String ftpEstimateSource20(String date) {
    return '95 % dei tuoi migliori 20 minuti, il $date';
  }

  @override
  String ftpEstimateSource8(String date) {
    return '90 % dei tuoi migliori 8 minuti, il $date';
  }

  @override
  String vo2MaxSource(String date) {
    return 'Dai tuoi migliori 5 minuti il $date e dal tuo peso';
  }

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
  String criticalPowerRow(String cp, String wPrime) {
    return 'Potenza critica $cp W · W′ $wPrime kJ';
  }

  @override
  String criticalPowerRowWithPeak(String cp, String wPrime, String peak) {
    return 'Potenza critica $cp W · W′ $wPrime kJ · Picco $peak W';
  }

  @override
  String criticalPowerSource(String durations) {
    return 'Calcolata dai tuoi migliori $durations in questo periodo';
  }

  @override
  String get criticalPowerUnavailable =>
      'Non ci sono abbastanza sforzi intensi da 2 a 20 minuti in questo periodo per calcolare la potenza critica.';

  @override
  String criticalPowerMinutes(int minutes) {
    return '$minutes minuti';
  }

  @override
  String criticalPowerSeconds(int seconds) {
    return '$seconds secondi';
  }

  @override
  String criticalPowerDurationList(String first, String last) {
    return '$first e $last';
  }

  @override
  String get rideFilterAll => 'Tutte';

  @override
  String get rideFilterTitle => 'Filtra i giri';

  @override
  String get rideFilterSearch => 'Cerca giri';

  @override
  String get rideFilterSearchHint => 'Cerca nei titoli e nelle descrizioni';

  @override
  String get rideFilterClearSearch => 'Cancella la ricerca';

  @override
  String get rideFilterDatesTooltip => 'Scegli le date';

  @override
  String get rideFilterRemoveDates => 'Togli il filtro delle date';

  @override
  String get rideFilterClear => 'Azzera i filtri';

  @override
  String get noRidesMatch => 'Nessun giro corrisponde.';

  @override
  String rideDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String rideDefaultTitle(String period, String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'commute': 'Tragitto casa-lavoro',
      'virtual': 'Giro virtuale',
      'indoor': 'Giro indoor',
      'road': 'Giro su strada',
      'gravel': 'Giro gravel',
      'mountain': 'Giro in mountain bike',
      'track': 'Giro in pista',
      'ebike': 'Giro in e-bike',
      'other': 'Giro in bici',
    });
    String _temp1 = intl.Intl.selectLogic(period, {
      'morning': 'del mattino',
      'afternoon': 'del pomeriggio',
      'evening': 'della sera',
      'other': 'della notte',
    });
    return '$_temp0 $_temp1';
  }

  @override
  String get rideTextEdit => 'Modifica titolo e descrizione';

  @override
  String get rideDownloadOriginal => 'Scarica il file originale';

  @override
  String get rideDownloadFit => 'Scarica come FIT';

  @override
  String get rideTextSheetTitle => 'Dai un nome al giro';

  @override
  String get rideTextHelp =>
      'Parole tue. Gli allenatori con cui condividi i giri possono leggerle.';

  @override
  String get rideTextTitle => 'Titolo';

  @override
  String get rideTextTitleHelper =>
      'Lascia vuoto per un nome ricavato da orario e tipo di giro.';

  @override
  String get rideTextDescription => 'Descrizione';

  @override
  String get rideTextAdd => 'Aggiungi una descrizione';

  @override
  String get actionSaveRideDetails => 'salvare titolo e descrizione';

  @override
  String rideViewedBy(String name, String when) {
    return 'Visto da $name · $when';
  }

  @override
  String get rideViewsEmpty => 'Nessun altro ha guardato questo giro.';

  @override
  String get rideTypeTitle => 'Dettagli giro';

  @override
  String get rideTypeHelp => 'Che tipo di giro era? Tutto è facoltativo.';

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
  String get actionChangeRideType => 'cambiare i dettagli di questo giro';

  @override
  String get yes => 'Sì';

  @override
  String get no => 'No';

  @override
  String get lapsTitle => 'Giri';

  @override
  String get lap => 'Giro';

  @override
  String get recorderRideType => 'Tipo di giro';

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
  String get forgotPasswordCaption => 'Aiuto password';

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
  String get resetPasswordCaption => 'Nuova password';

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
  String get passwordChangeFailed =>
      'Non è stato possibile cambiare la password. Riprova.';

  @override
  String get actionChangePassword => 'cambiare la password';

  @override
  String get actionResetPassword => 'reimpostare questa password';

  @override
  String get actionResendVerification => 'inviare di nuovo il link';

  @override
  String get actionVerifyEmail => 'confermare questa email';

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
  String get clubLocationOnMap => 'Visibile sulla mappa';

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
      'Pedala al tuo ritmo. Entra in un club quando vuoi: puoi uscire quando vuoi e i tuoi giri restano tuoi.';

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
      'Diventa un corridore. I tuoi giri restano tuoi; la condivisione resta una sua scelta.';

  @override
  String joinRequestDeclineTitle(String name) {
    return 'Rifiutare $name?';
  }

  @override
  String get joinRequestDeclineBody => 'Verrà avvisato, senza motivazione.';

  @override
  String noteQuoted(String note) {
    return '«$note»';
  }

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
  String get sharePartsHelp =>
      'I componenti non personalizzati che il catalogo condiviso non elenca vengono inviati all\'editore. I componenti personalizzati restano solo sulla tua bici.';

  @override
  String get catalogueNotConfigured =>
      'Questo server non ha un endpoint per i contributi, quindi non viene inviato nulla.';

  @override
  String get catalogueNeverSynced =>
      'Il catalogo condiviso non è ancora stato controllato.';

  @override
  String catalogueSynced(String date) {
    return 'Catalogo condiviso controllato il $date';
  }

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
  String get telemetryTitle => 'Aiutaci a migliorare Velomine';

  @override
  String get crashReports => 'Segnalazioni di errori';

  @override
  String get crashReportsHelp =>
      'Stack trace e versione dell\'app, per correggere un bug.';

  @override
  String get usageData => 'Prestazioni e utilizzo';

  @override
  String get usageDataHelp =>
      'Schermate lente e funzioni usate, senza i tuoi giri o dati di salute.';

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
  String importProgressUnit(Object total) {
    return 'di $total attività lette';
  }

  @override
  String get importFinished => 'Importazione terminata';

  @override
  String importSummaryImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giri importati',
      one: '1 giro importato',
    );
    return '$_temp0';
  }

  @override
  String importSummaryDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giri erano già qui',
      one: '1 giro era già qui',
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
      other: '$count attività saltate, non sono giri o non hanno un file',
      one: '1 attività saltata, non è un giro o non ha un file',
    );
    return '$_temp0';
  }

  @override
  String get importBackToRides => 'Torna ai giri';

  @override
  String get importErrorNotStrava =>
      'Non è un\'esportazione di Strava: manca activities.csv.';

  @override
  String get importErrorMissing =>
      'L\'archivio non è più sul server. Scegli di nuovo il file.';

  @override
  String get importErrorUnknown => 'Non è stato possibile leggere l\'archivio.';

  @override
  String get actionImportRides => 'importare i tuoi giri';

  @override
  String get actionLoadImport => 'controllare l\'importazione';

  @override
  String notificationRideImport(String subject) {
    return 'L\'importazione di $subject è terminata.';
  }

  @override
  String get actionStartClub => 'avviare il club';

  @override
  String get actionSetClubPlan => 'salvare il piano del club';

  @override
  String get startClubButton => 'Avvia un club';

  @override
  String get startClubTitle => 'Avvia un club';

  @override
  String get startClubIntro =>
      'Avvia un club per le persone con cui pedali. Ne sarai il proprietario e potrai invitare gli altri con un codice. Hai un mese per provarlo.';

  @override
  String get startClubName => 'Nome del club';

  @override
  String get startClubNameCard => 'Nome';

  @override
  String get startClubNameRequired => 'Dai un nome al club.';

  @override
  String get startClubAction => 'Avvia il club';

  @override
  String get clubPlanTitle => 'Piano';

  @override
  String clubPlanMembers(int count, int limit) {
    return '$count iscritti su $limit';
  }

  @override
  String clubPlanPaidUntil(String date) {
    return 'Pagato fino al $date';
  }

  @override
  String get clubPlanFullNotice =>
      'Il club è al completo. Per accogliere altri iscritti, contattaci per passare a una fascia più ampia.';

  @override
  String clubPlanEndedNotice(String date) {
    return 'Il piano del club è scaduto il $date. Tutto continua a funzionare, ma nessuno può entrare finché non viene rinnovato. Contattaci per rinnovarlo.';
  }

  @override
  String get joinRequestsBlockedFull =>
      'Il club è al completo, quindi per ora non puoi accettare richieste. Contattaci per passare a una fascia più ampia.';

  @override
  String get joinRequestsBlockedEnded =>
      'Il piano del club è scaduto, quindi non puoi accettare richieste finché non viene rinnovato.';

  @override
  String notificationClubPlanEnding(String date) {
    return 'Il piano del tuo club scade il $date. Contattaci per rinnovarlo.';
  }

  @override
  String notificationClubPlanEnded(String date) {
    return 'Il piano del tuo club è scaduto dopo il $date. Gli iscritti non perdono nulla, ma nessuno può entrare finché non viene rinnovato.';
  }

  @override
  String get adminClubCreation => 'Chi non ha un club può avviarne uno';

  @override
  String get adminClubCreationHelp =>
      'Chi ha un account e non è in un club può avviarne uno. Parte con posto per 25 iscritti e un mese di prova.';

  @override
  String get adminClubEditPlan => 'Modifica il piano';

  @override
  String get adminClubLimit => 'Posti';

  @override
  String get adminClubLimitNone => 'Oltre 150 iscritti (nessun limite)';

  @override
  String adminClubLimitOption(int count) {
    return 'Fino a $count iscritti';
  }

  @override
  String get adminClubPaidUntil => 'Pagato fino al';

  @override
  String get adminClubNoDate => 'Nessuna scadenza';

  @override
  String get adminClubChooseDate => 'Scegli una data';

  @override
  String get loading => 'Caricamento';

  @override
  String get actionLoadServiceLog => 'caricare il registro degli interventi';

  @override
  String get actionSaveReminder => 'salvare il promemoria';

  @override
  String get actionRemoveReminder => 'eliminare il promemoria';

  @override
  String get actionCompleteReminder => 'segnare l\'intervento come fatto';

  @override
  String get actionSaveServiceEntry => 'salvare la voce';

  @override
  String get actionRemoveServiceEntry => 'eliminare la voce';

  @override
  String get service => 'Manutenzione';

  @override
  String get serviceRemindersIntro =>
      'I promemoria ti avvisano quando torna il momento di un intervento su questa bici, come lubrificare la catena o rabboccare il lattice. Scegline uno comune per iniziare.';

  @override
  String get serviceAddReminder => 'Aggiungi promemoria';

  @override
  String get serviceCommonJobs => 'Interventi comuni';

  @override
  String get reminderStatusOk => 'A posto';

  @override
  String get reminderStatusSoon => 'Presto da fare';

  @override
  String get reminderStatusDue => 'Da fare';

  @override
  String get reminderStatusPaused => 'In pausa';

  @override
  String reminderLastDone(String date) {
    return 'Ultimo intervento $date';
  }

  @override
  String get reminderDone => 'Fatto';

  @override
  String get reminderDoneSaved => 'Fatto. Lo trovi nel registro interventi.';

  @override
  String get reminderDoneBody =>
      'Il conteggio riparte dal giorno scelto e l\'intervento finisce nel registro.';

  @override
  String doneOnDate(String date) {
    return 'Fatto il $date';
  }

  @override
  String get reminderPause => 'Metti in pausa';

  @override
  String get reminderResume => 'Riprendi';

  @override
  String get reminderFormAddTitle => 'Aggiungi un promemoria';

  @override
  String get reminderFormEditTitle => 'Modifica promemoria';

  @override
  String get reminderName => 'Cosa c\'è da fare?';

  @override
  String get reminderIntervalHelp =>
      'Scatta al primo di questi limiti. Lascia vuoto quello che non ti serve.';

  @override
  String get reminderErrorName => 'Dai un nome all\'intervento.';

  @override
  String get reminderErrorInterval =>
      'Indica una distanza, delle ore o dei mesi.';

  @override
  String get reminderRemoveTitle => 'Eliminare questo promemoria?';

  @override
  String get reminderRemoveBody =>
      'Nel registro restano gli interventi già fatti.';

  @override
  String get jobChainLube => 'Lubrifica la catena';

  @override
  String get jobChainWearCheck => 'Controlla l\'usura della catena';

  @override
  String get jobSealantTopUp => 'Rabbocca il lattice tubeless';

  @override
  String get jobBrakeBleed => 'Spurga i freni';

  @override
  String get jobForkService => 'Revisione dei foderi della forcella';

  @override
  String get jobShockService => 'Revisione dell\'ammortizzatore posteriore';

  @override
  String get jobBoltCheck => 'Controlla la coppia di serraggio delle viti';

  @override
  String get jobShiftingBattery => 'Ricarica il cambio elettronico';

  @override
  String get serviceLog => 'Registro interventi';

  @override
  String get serviceLogIntro =>
      'Qui trovi tutto quello che è stato fatto a questa bici, con i chilometri che aveva allora.';

  @override
  String get serviceAddEntry => 'Aggiungi voce';

  @override
  String entryAtDistance(String distance) {
    return 'a $distance';
  }

  @override
  String get entryAtHome => 'A casa';

  @override
  String get entryFormAddTitle => 'Aggiungi al registro';

  @override
  String get entryFormEditTitle => 'Modifica voce';

  @override
  String get entryTitleField => 'Cosa è stato fatto?';

  @override
  String get entryNotes => 'Note';

  @override
  String get entryPlace => 'Dove';

  @override
  String get entryPlaceHelp =>
      'Il nome del negozio. Lascia vuoto se l\'hai fatto a casa.';

  @override
  String get entryCost => 'Costo';

  @override
  String get entryCurrency => 'Valuta';

  @override
  String get entryPart => 'Su quale componente?';

  @override
  String get entryNoPart => 'Nessun componente in particolare';

  @override
  String get entryReminder => 'Su quale promemoria?';

  @override
  String get entryNoReminder => 'Nessun promemoria in particolare';

  @override
  String get entryErrorTitle => 'Scrivi cosa è stato fatto.';

  @override
  String get entryErrorCost =>
      'Inserisci il costo come numero, con una valuta di tre lettere come EUR.';

  @override
  String get entryRemoveTitle => 'Eliminare questa voce?';

  @override
  String get entryRemoveBody =>
      'Viene tolta dal registro. Non si può annullare.';

  @override
  String get entryRemoveDoneBody =>
      'Viene tolta dal registro. Il promemoria continua a contare dal giorno in cui è stato fatto.';

  @override
  String get logFilterLabel => 'Mostra';

  @override
  String get logFilterAll => 'Tutto';

  @override
  String get logFilterEmpty =>
      'Ancora niente nel registro per questo componente.';

  @override
  String get logShowMore => 'Mostra altro';

  @override
  String logReplacedPart(String part) {
    return 'Sostituzione: $part';
  }

  @override
  String logReplacedPartWith(String part, String make) {
    return 'Sostituzione $part: $make';
  }

  @override
  String get bikeServiceDue => 'Manutenzione da fare';

  @override
  String get bikeServiceSoon => 'Manutenzione in arrivo';

  @override
  String notificationReminderSoon(String subject) {
    return 'Manutenzione in scadenza: $subject.';
  }

  @override
  String notificationReminderDue(String subject) {
    return 'Manutenzione da fare: $subject.';
  }

  @override
  String get actionLoadRoutes => 'caricare le rotte del club';

  @override
  String get actionLoadRoute => 'caricare questa rotta';

  @override
  String get actionAddRoute => 'aggiungere la rotta';

  @override
  String get actionSaveRoute => 'salvare la rotta';

  @override
  String get actionDeleteRoute => 'eliminare la rotta';

  @override
  String get actionLoadClubRides => 'caricare i giri del club';

  @override
  String get actionLoadClubRide => 'caricare questo giro del club';

  @override
  String get actionSaveClubRide => 'salvare il giro del club';

  @override
  String get actionCancelClubRide => 'annullare il giro del club';

  @override
  String get actionJoinClubRide => 'confermare la tua presenza';

  @override
  String get actionLeaveClubRide => 'ritirare la tua presenza';

  @override
  String get actionLoadCalendarFeed => 'caricare l\'indirizzo del calendario';

  @override
  String get actionSaveCalendarFeed => 'modificare l\'indirizzo del calendario';

  @override
  String get clubRidesTitle => 'Giri';

  @override
  String get clubRidesHelp => 'I prossimi giri del club e chi c\'è.';

  @override
  String get clubRidesSeeAll => 'Vedi tutti i giri';

  @override
  String get clubPlanRide => 'Programma un giro';

  @override
  String get clubRoutesTitle => 'Rotte';

  @override
  String get clubRoutesCaption => 'Rotte del club';

  @override
  String get clubRoutesHelp =>
      'Le linee condivise dal club, ognuna custodita da chi l\'ha aggiunta.';

  @override
  String get clubRoutesSeeAll => 'Vedi tutte le rotte';

  @override
  String get clubAddRoute => 'Aggiungi una rotta';

  @override
  String get clubRoutesEmpty =>
      'Ancora nessuna rotta. Aggiungine una dai tuoi giri o da un file GPX.';

  @override
  String get routesFilterAll => 'Tutti i fondi';

  @override
  String get routesSubtitle =>
      'Le tracce su cui esce il club, con distanza e dislivello.';

  @override
  String get routesEmptyCta => 'Aggiungi il primo percorso';

  @override
  String get clubRidesSubtitle =>
      'I prossimi giri del club e quelli appena passati.';

  @override
  String get routesSortNewest => 'Più recenti';

  @override
  String get routesSortShortest => 'Più corte';

  @override
  String get routesSortLongest => 'Più lunghe';

  @override
  String get routeSurfaceRoad => 'Asfalto';

  @override
  String get routeSurfaceGravel => 'Sterrato';

  @override
  String get routeSurfaceMountain => 'Montagna';

  @override
  String get routeSurfaceMixed => 'Misto';

  @override
  String routeAddedBy(String name) {
    return 'Aggiunta da $name';
  }

  @override
  String get routeNotSharedBody =>
      'Questa rotta è tua, ma non è nella libreria del club.';

  @override
  String get routeOpenGpx => 'Scarica il GPX';

  @override
  String get routeTheRoute => 'Il percorso';

  @override
  String get routeDescription => 'Descrizione';

  @override
  String get routeEdit => 'Modifica';

  @override
  String get routeWithdraw => 'Rimuovi dal club';

  @override
  String get routeWithdrawConfirmTitle => 'Rimuovere questa rotta dal club?';

  @override
  String get routeWithdrawConfirmBody =>
      'Resta tua e puoi condividerla di nuovo quando vuoi.';

  @override
  String get routeShare => 'Condividi di nuovo';

  @override
  String get routeDelete => 'Elimina definitivamente';

  @override
  String get routeDeleteConfirmTitle => 'Eliminare questa rotta?';

  @override
  String get routeDeleteConfirmBody =>
      'La linea sparisce per sempre. I giri del club che l\'avevano scelta mantengono i loro dettagli.';

  @override
  String get routeOwnerOnly => 'Solo chi ha aggiunto la rotta può modificarla.';

  @override
  String get addRouteTitle => 'Aggiungi una rotta';

  @override
  String get addRouteHelp =>
      'Una rotta è una linea sulla mappa con un nome. Niente di come l\'hai percorsa viene condiviso.';

  @override
  String get addRouteFromRide => 'Da uno dei miei giri';

  @override
  String get addRouteFromFile => 'Da un file GPX';

  @override
  String get addRouteChooseFile => 'Scegli un file GPX';

  @override
  String get addRouteNoRides =>
      'Non hai ancora giri con una mappa. Importa un giro e torna qui.';

  @override
  String get addRoutePreview => 'Questa è la linea che vedrà il club';

  @override
  String get addRoutePrivacyNote =>
      'Le tue zone privacy e il taglio di inizio e fine sono già applicati.';

  @override
  String get addRouteDetails => 'Nome e dettagli';

  @override
  String get addRouteName => 'Nome';

  @override
  String get addRouteDescription => 'Descrizione (facoltativa)';

  @override
  String get addRouteSurface => 'Fondo';

  @override
  String get addRouteSave => 'Aggiungi alla libreria del club';

  @override
  String get editRouteTitle => 'Modifica la rotta';

  @override
  String get ridesEmpty =>
      'Ancora nessun giro programmato. Un coach può programmare il prossimo.';

  @override
  String get ridesUpcoming => 'In arrivo';

  @override
  String get ridesPast => 'Appena fatte';

  @override
  String get rideCancelled => 'Annullata';

  @override
  String get rideFull => 'Completa';

  @override
  String get rideSignedUp => 'Ci sei';

  @override
  String rideCountIn(int count) {
    return '$count presenti';
  }

  @override
  String ridePlacesLeft(int count, int max) {
    return '$count posti liberi su $max';
  }

  @override
  String get ridePaceEasy => 'Facile';

  @override
  String get ridePaceSteady => 'Regolare';

  @override
  String get ridePaceFast => 'Veloce';

  @override
  String get rideNoDrop => 'Nessuno resta indietro';

  @override
  String ridePlannedBy(String name) {
    return 'Programmata da $name';
  }

  @override
  String get rideMeeting => 'Punto di ritrovo';

  @override
  String get rideRoute => 'Rotta';

  @override
  String get rideNotes => 'Note';

  @override
  String get rideWhoIsIn => 'Chi c\'è';

  @override
  String get rideNobodyIn => 'Ancora nessuno.';

  @override
  String get rideImIn => 'Ci sono';

  @override
  String get rideImOut => 'Non vengo più';

  @override
  String get rideEdit => 'Modifica il giro';

  @override
  String get rideCancel => 'Annulla il giro';

  @override
  String get rideCancelConfirmTitle => 'Annullare questo giro?';

  @override
  String get rideCancelConfirmBody =>
      'Chi è iscritto riceve una notifica. Il giro resta sul calendario, annullato.';

  @override
  String get rideCancelledReason => 'Questo giro è annullato.';

  @override
  String get rideFullReason => 'Questo giro è completo.';

  @override
  String get rideStartedReason => 'Questo giro è già iniziato.';

  @override
  String get planRideTitle => 'Programma un giro';

  @override
  String get editRideTitle => 'Modifica il giro';

  @override
  String get rideFormTitle => 'Titolo';

  @override
  String get rideFormMeetingName => 'Nome del punto di ritrovo';

  @override
  String get rideFormPickMeeting => 'Scegli il punto di ritrovo sulla mappa';

  @override
  String get rideFormRoute => 'Rotta (facoltativa)';

  @override
  String get rideFormNoRoute => 'Nessuna rotta';

  @override
  String get rideFormPace => 'Andatura';

  @override
  String get rideFormNoDrop => 'Nessuno resta indietro';

  @override
  String get rideFormNotes => 'Note (facoltative)';

  @override
  String get rideFormMaxRiders =>
      'Numero massimo di partecipanti (facoltativo)';

  @override
  String get rideFormDetails => 'Dettagli';

  @override
  String get rideFormSave => 'Salva il giro';

  @override
  String get rideFormNeedTitle => 'Dai un titolo al giro.';

  @override
  String get rideFormNeedMeeting => 'Dai un nome al punto di ritrovo.';

  @override
  String get rideFormNeedPoint => 'Scegli il punto di ritrovo sulla mappa.';

  @override
  String get rideFormFuture => 'Scegli una data e un\'ora future.';

  @override
  String get rideFormMaxRange =>
      'Il limite è un numero da 1 a 500, oppure lascialo vuoto.';

  @override
  String get calendarTitle => 'Abbonamento al calendario';

  @override
  String get calendarAddressTitle => 'Il tuo indirizzo';

  @override
  String get clubCalendarCaption => 'Calendario del club';

  @override
  String get calendarHelp =>
      'Abbona il calendario del telefono o del computer ai giri del club. L\'indirizzo è privato: chi lo ha vede i giri del club, mai chi partecipa.';

  @override
  String get calendarInactive => 'Nessun indirizzo del calendario.';

  @override
  String get calendarActive => 'Un indirizzo del calendario è attivo.';

  @override
  String get calendarCreate => 'Crea l\'indirizzo';

  @override
  String get calendarReplace => 'Sostituisci l\'indirizzo';

  @override
  String get calendarReplaceConfirmTitle =>
      'Sostituire l\'indirizzo del calendario?';

  @override
  String get calendarReplaceConfirmBody =>
      'Il vecchio indirizzo smette subito di funzionare e il calendario ha bisogno del nuovo.';

  @override
  String get calendarDelete => 'Ferma l\'indirizzo';

  @override
  String get calendarDeleteConfirmTitle =>
      'Fermare l\'indirizzo del calendario?';

  @override
  String get calendarDeleteConfirmBody =>
      'Il calendario smette di aggiornarsi. Puoi creare un nuovo indirizzo quando vuoi.';

  @override
  String get calendarCopy => 'Copia l\'indirizzo';

  @override
  String get calendarAddressCopied => 'Indirizzo copiato';

  @override
  String get calendarShownOnce =>
      'Copialo ora. Il server conserva solo un hash, quindi non può mostrarlo di nuovo; se lo perdi, sostituiscilo.';

  @override
  String notificationClubRidePlanned(String ride) {
    return '$ride: il club ha programmato un giro.';
  }

  @override
  String notificationClubRideChanged(String ride) {
    return '$ride: sono cambiati l\'orario o il punto di ritrovo.';
  }

  @override
  String notificationClubRideCancelled(String ride) {
    return '$ride: il giro è annullato.';
  }

  @override
  String notificationPowerRecord(String record) {
    return 'Record personale: $record.';
  }

  @override
  String powerRecordAllTime(String duration, int watts) {
    return 'Miglior $duration di sempre: $watts W';
  }

  @override
  String powerRecordNinetyDays(String duration, int watts) {
    return 'Miglior $duration negli ultimi 90 giorni: $watts W';
  }

  @override
  String recordDurationSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String recordDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get supporterSignInTitle => 'Sostenitore';

  @override
  String get supporterBecome => 'Diventa sostenitore';

  @override
  String get supporterKey => 'Chiave di licenza';

  @override
  String get supporterKeyHelp =>
      'Incolla la chiave che hai ricevuto. Viene verificata offline: nessuno vede chi sei.';

  @override
  String get supporterActivate => 'Attiva';

  @override
  String get supporterKeyInvalid =>
      'Questa chiave non è valida. Controlla di averla incollata tutta.';

  @override
  String get supporterAlreadyActivated =>
      'Hai già una licenza da sostenitore, oppure questa chiave è già stata attivata.';

  @override
  String get supporterClubOwnerOnly =>
      'Solo il titolare del club può attivare una licenza del club.';

  @override
  String get supporterUnavailable =>
      'Questo server non accetta licenze da sostenitore.';

  @override
  String get supporterActivated => 'Licenza attivata';

  @override
  String supporterThanksName(String name) {
    return 'Grazie, $name.';
  }

  @override
  String get supporterBody =>
      'Hai appena reso Velomine un po\' più libera. Non cambia nessuna funzione: tutto resta di tutti, e i tuoi dati restano tuoi.';

  @override
  String supporterSerialNumber(int serial, String date) {
    return 'Sostenitore n. $serial · $date';
  }

  @override
  String get supporterKeyVerified => 'Chiave verificata';

  @override
  String get supporterReplayLink => 'Rivedi il momento';

  @override
  String get supporterBadgeReplayHint =>
      'Ripete il momento della licenza. Tre tocchi rapidi.';

  @override
  String get supporterContinue => 'Continua';

  @override
  String get supporter => 'Sostenitore';

  @override
  String get supporterAppearsOnProfile => 'compare sul tuo profilo';

  @override
  String get supporterHideBadge => 'Nascondi badge sostenitore';

  @override
  String get supporterHideBadgeHelp =>
      'La licenza vale lo stesso. Il badge lo mostri o lo nascondi tu.';

  @override
  String get actionLoadSupporter => 'caricare la tua licenza sostenitore';

  @override
  String get actionActivateSupporter => 'attivare la licenza';

  @override
  String get actionSaveSupporter => 'salvare il badge sostenitore';

  @override
  String get moreActions => 'Altre azioni';

  @override
  String get myBikes => 'Le mie bici';

  @override
  String bikeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bici',
      one: '1 bici',
      zero: 'Nessuna bici',
    );
    return '$_temp0';
  }

  @override
  String get intensityTitle => 'Facile, moderato, intenso';

  @override
  String intensityShares(String easy, String moderate, String hard) {
    return '$easy % facile · $moderate % moderato · $hard % intenso';
  }

  @override
  String get intensitySource =>
      'Dalla potenza dove ce l\'hai, altrimenti dalla frequenza cardiaca.';

  @override
  String get intensityLabelPolarised =>
      'Polarizzato: quasi tutto facile, una quota vera di intenso, poco in mezzo';

  @override
  String get intensityLabelPyramidal =>
      'Piramidale: molto facile, meno moderato, poco intenso';

  @override
  String get intensityLabelThreshold =>
      'Molto soglia: molta bici a ritmo moderato';

  @override
  String get intensityLabelHiit => 'Molto intenso: molta bici a ritmo intenso';

  @override
  String get intensityLabelBase => 'Base: quasi tutta bici facile';

  @override
  String get intensityLabelMixed => 'Misto';

  @override
  String get seriesWPrimeBalance => 'Bilancio W′';

  @override
  String wPrimeLowest(String min, String wPrime) {
    return 'Bilancio W′ più basso: $min kJ su $wPrime kJ';
  }

  @override
  String efficiencyFactor(String ef) {
    return 'Fattore di efficienza $ef';
  }

  @override
  String decoupling(String pct, String word) {
    return 'Decoupling $pct % · $word';
  }

  @override
  String get decouplingSteady => 'Frequenza cardiaca stabile';

  @override
  String get decouplingDrift => 'Un po\' di deriva';

  @override
  String get decouplingLargeDrift => 'Deriva marcata';

  @override
  String get decouplingSource =>
      'Dal pedalare costante dopo 15 minuti di riscaldamento';

  @override
  String get efficiencyTitle => 'Efficienza aerobica';

  @override
  String get efficiencyHint =>
      'Più alto è meglio: più potenza con la stessa frequenza cardiaca.';

  @override
  String get efficiencyEmpty =>
      'Servono giri costanti di circa un\'ora con potenza e frequenza cardiaca.';

  @override
  String efficiencyWeekSemantics(String date, String ef, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giri',
      one: '1 giro',
    );
    return '$date: fattore di efficienza $ef su $_temp0';
  }

  @override
  String get eventsTitle => 'Eventi';

  @override
  String get noEvents =>
      'Nessun evento. Aggiungi la gara, la granfondo o il giro per cui ti stai allenando; il giro che era si collega da solo se quel giorno è l\'unico.';

  @override
  String get eventAdd => 'Aggiungi un evento';

  @override
  String get eventChange => 'Modifica l\'evento';

  @override
  String get eventName => 'Nome';

  @override
  String get eventKind => 'Tipo';

  @override
  String get eventKindRace => 'Gara';

  @override
  String get eventKindSportive => 'Granfondo';

  @override
  String get eventKindTour => 'Giro';

  @override
  String get eventKindOther => 'Altro';

  @override
  String get eventDistance => 'Distanza';

  @override
  String get eventClimbing => 'Dislivello';

  @override
  String get eventNotes => 'Note';

  @override
  String eventNext(String name, String when) {
    return 'Prossimo evento: $name tra $when';
  }

  @override
  String get eventToday => 'oggi';

  @override
  String eventInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String eventInWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks settimane',
      one: '1 settimana',
    );
    return '$_temp0';
  }

  @override
  String get eventsAll => 'Tutti gli eventi';

  @override
  String eventYourRide(String name) {
    return 'Il tuo evento: $name';
  }

  @override
  String get eventLinkRide => 'Collega un giro';

  @override
  String get eventUnlinkRide => 'Scollega';

  @override
  String get eventNoRidesThatDay => 'Nessun giro pronto in quel giorno.';

  @override
  String get eventDeleteTitle => 'Eliminare questo evento?';

  @override
  String eventDeleteBody(String name) {
    return '«$name» viene rimosso. Il giro che era resta.';
  }

  @override
  String get errorEventName => 'Dai un nome all\'evento.';

  @override
  String get actionAddEvent => 'aggiungere l\'evento';

  @override
  String get actionSaveEvent => 'salvare l\'evento';

  @override
  String get actionDeleteEvent => 'eliminare l\'evento';

  @override
  String get seriesEstimatedPower => 'Watt stimati';

  @override
  String get statEstimatedAveragePower => 'Potenza media stimata';

  @override
  String get estimatedPowerSource =>
      'Dalla tua velocità, dalla pendenza e dal tuo peso con la bici. Senza vento, quindi sul piano può sbagliare di molto.';

  @override
  String get bikeWeight => 'Peso (kg)';

  @override
  String get bikeWeightHelper =>
      'Serve a stimare i watt sulle uscite senza misuratore di potenza.';

  @override
  String get errorBikeWeight =>
      'Inserisci il peso della bici in chilogrammi: da 3 a 40.';

  @override
  String get profileWeightEstimateHint =>
      'Aggiungi il tuo peso per stimare i watt sulle uscite senza misuratore di potenza.';

  @override
  String get riderModeQuestion => 'Come vai in bici?';

  @override
  String get riderModeTitle => 'Come vado in bici';

  @override
  String get riderModeJustRiding => 'Solo per uscire';

  @override
  String get riderModeJustRidingBody =>
      'Esco per divertirmi, con la famiglia o con gli amici. Voglio i miei percorsi, la distanza e com\'è andata l\'uscita.';

  @override
  String get riderModeWithGoals => 'Con obiettivi';

  @override
  String get riderModeWithGoalsBody =>
      'Esco spesso e mi piace vedere i miei progressi: totali settimanali, obiettivi e quanto è stata dura l\'uscita, detto in parole semplici.';

  @override
  String get riderModeTraining => 'Allenamento';

  @override
  String get riderModeTrainingBody =>
      'Mi alleno o gareggio. Voglio potenza, carico di allenamento, forma e ogni numero.';

  @override
  String get riderModeLater => 'Decido dopo';

  @override
  String get riderModeElsewhere => 'Scelta su un altro dispositivo';

  @override
  String get moreDetailsAll => 'Mostra tutti i dettagli';

  @override
  String get showLess => 'Mostra meno';

  @override
  String get rideEffortEasy => 'per lo più facile';

  @override
  String get rideEffortSteady => 'costante';

  @override
  String get rideEffortHard => 'duro';

  @override
  String get navTraining => 'Allenamento';

  @override
  String get autoTrainingTitle => 'Allenamento automatico (sperimentale)';

  @override
  String get autoTrainingSentence =>
      'Velomine prepara la tua settimana dalle tue uscite. È una novità:';

  @override
  String get autoTrainingFeedback => 'dicci cosa non va';

  @override
  String get autoTrainingOffTitle => 'Disattivare l\'allenamento automatico?';

  @override
  String get autoTrainingOffBody =>
      'Il piano di questa settimana e delle prossime sparisce. Le sedute già fatte restano.';

  @override
  String get autoTrainingOffAction => 'Disattiva l\'allenamento automatico';

  @override
  String get trainingChangeSetup => 'Cambia impostazioni';

  @override
  String get trainingGoalCard => 'Il tuo obiettivo';

  @override
  String trainingPlanStarts(String day) {
    return 'Il tuo piano inizia $day.';
  }

  @override
  String trainingHoursLine(int hours) {
    return '$hours h a settimana';
  }

  @override
  String get trainingSetupTitle => 'Imposta l\'allenamento automatico';

  @override
  String get trainingGoalStep => '1 · Il tuo obiettivo';

  @override
  String get trainingRideStep => '2 · Quando pedali';

  @override
  String get trainingHeartStep => '3 · La tua frequenza cardiaca';

  @override
  String get goalAerobic => 'Pedalare con regolarità';

  @override
  String get goalFitter => 'Essere più in forma';

  @override
  String get goalFaster => 'Andare più forte';

  @override
  String get goalEvent => 'Prepararsi a un evento';

  @override
  String get goalKeep => 'Restare in forma con meno tempo';

  @override
  String get goalFasterLine => 'In salita e in pianura';

  @override
  String get goalSuggested => 'Suggerito';

  @override
  String get goalReasonNotEnoughRiding =>
      'Non abbiamo ancora visto abbastanza delle tue uscite: iniziamo facili e costanti.';

  @override
  String get goalReasonRegularRiding =>
      'La regolarità viene prima della velocità: un ritmo costante di uscite facili è il modo migliore per iniziare.';

  @override
  String get goalReasonEventSoon => 'Costruiamo in vista del tuo evento.';

  @override
  String get goalReasonAfterBreak => 'Bentornato: ripartiamo piano.';

  @override
  String get goalReasonPowerRides =>
      'Pedali con regolarità e con il misuratore, quindi puntiamo alla tua soglia.';

  @override
  String get goalReasonRegularRider =>
      'Pedali con regolarità. Costruiamo la base e un po\' di velocità.';

  @override
  String get goalLineAerobic =>
      'Un ritmo costante di uscite facili, prima di qualsiasi cosa più veloce.';

  @override
  String get goalLineFitter => 'La tua base, e un po\' di velocità in più.';

  @override
  String get goalLineEvent =>
      'Pianificato come essere più in forma, fino al giorno.';

  @override
  String get goalLineKeep =>
      'Un paio di uscite a settimana mantengono quello che hai.';

  @override
  String goalNextEvent(String name, String date) {
    return '$name · $date';
  }

  @override
  String get goalAddEvent => 'Aggiungi un evento';

  @override
  String get trainingDaysLabel => 'Giorni in cui puoi pedalare';

  @override
  String get trainingHoursLabel => 'Ore a settimana';

  @override
  String get trainingLongRideLabel => 'Uscita lunga il';

  @override
  String get trainingLongRidePicks => 'Sceglie Velomine';

  @override
  String trainingLongRidePicksDay(String day) {
    return 'Sceglie Velomine ($day)';
  }

  @override
  String get trainingHeartUnknown => 'Non lo so';

  @override
  String get trainingHeartUnknownHelp =>
      'Lo stimiamo dalla tua età e lo impariamo dalle tue uscite.';

  @override
  String get trainingMaxHeartRate => 'Frequenza cardiaca massima';

  @override
  String get trainingBirthYear => 'Anno di nascita';

  @override
  String get trainingHealthNote =>
      'Se hai un problema di cuore o non fai attività da molto tempo, parlane prima con un medico.';

  @override
  String get trainingStart => 'Inizia';

  @override
  String get errorTrainingDays =>
      'Scegli almeno un giorno in cui puoi pedalare.';

  @override
  String get errorTrainingHours => 'Inserisci le ore a settimana: da 1 a 30.';

  @override
  String get errorTrainingMaxHeartRate =>
      'Inserisci una frequenza cardiaca massima da 120 a 230.';

  @override
  String get errorTrainingBirthYear => 'Inserisci il tuo anno di nascita.';

  @override
  String get actionLoadTraining => 'caricare il tuo piano di allenamento';

  @override
  String get actionSaveTrainingPlan => 'salvare le tue impostazioni';

  @override
  String get actionTurnOffTraining => 'disattivare l\'allenamento automatico';

  @override
  String get actionMatchTrainingSession =>
      'rispondere alla domanda sulla seduta';

  @override
  String trainingTodayCaption(String day) {
    return 'Oggi · $day';
  }

  @override
  String get trainingToday => 'oggi';

  @override
  String trainingTodayStrip(String what) {
    return 'Oggi · $what';
  }

  @override
  String get trainingRestDay => 'Riposo';

  @override
  String get trainingRestDaySentence =>
      'Niente oggi. Il riposo fa parte del piano.';

  @override
  String get trainingThisWeek => 'Questa settimana';

  @override
  String get trainingNextWeek => 'La prossima settimana (anteprima)';

  @override
  String get trainingRest => 'Riposo';

  @override
  String trainingWeekLine(int done, int total, String kind) {
    return '$done di $total fatte. $kind';
  }

  @override
  String trainingWeekLineAll(int done, int total) {
    return '$done di $total fatte. La settimana è tutta qui.';
  }

  @override
  String get trainingWeekKindOnTrack => 'Bella rotta.';

  @override
  String get trainingWeekKindStarted => 'Un buon inizio di settimana.';

  @override
  String get trainingWeekKindNothing => 'Ancora niente fatto. C\'è tempo.';

  @override
  String get trainingStatePlanned => 'In programma';

  @override
  String get trainingStateDone => 'Fatto';

  @override
  String trainingStateDoneScore(int score) {
    return 'Fatta · $score';
  }

  @override
  String get trainingStateEasy => 'Facile invece';

  @override
  String get trainingStateMoved => 'Spostato';

  @override
  String get trainingStateSkipped => 'Saltato';

  @override
  String get trainingStateMissed => 'Mancato';

  @override
  String get trainingOpenSession => 'Apri la seduta';

  @override
  String get trainingSessionWhy => 'Perché questa seduta';

  @override
  String get trainingSessionTitle => 'La seduta';

  @override
  String trainingCoachesCall(String term) {
    return 'I tecnici la chiamano $term.';
  }

  @override
  String get trainingBlockWarmup => 'Riscaldamento';

  @override
  String get trainingBlockMain => 'Parte principale';

  @override
  String get trainingBlockRecovery => 'Facile in mezzo';

  @override
  String get trainingBlockCooldown => 'Defaticamento';

  @override
  String trainingFeel(String range) {
    return 'sensazione $range';
  }

  @override
  String get trainingFeelExplained =>
      'Sensazione 7: duro, potresti tenerlo per circa un\'ora.';

  @override
  String get trainingEstimated => 'stimata';

  @override
  String get trainingHeartEstimated =>
      'Frequenza cardiaca stimata dalla tua massima.';

  @override
  String get trainingSessionMissing =>
      'Questa seduta non è nel piano di questa settimana.';

  @override
  String trainingQuestionTitle(String day, String name) {
    return 'Era questa la tua seduta di $day: $name?';
  }

  @override
  String get trainingQuestionYesterday =>
      'Questa uscita somiglia alla seduta pianificata per ieri.';

  @override
  String get trainingQuestionTomorrow =>
      'Questa uscita somiglia alla seduta pianificata per domani.';

  @override
  String trainingLinkedTitle(String day, String name) {
    return 'Questa era la tua seduta di $day: $name.';
  }

  @override
  String get trainingNotThisSession => 'Non è questa la seduta';

  @override
  String get actionMakeTrainingEasy => 'rendere facile oggi';

  @override
  String get actionBackToTrainingPlan => 'rimettere la seduta';

  @override
  String get actionMoveTrainingSession => 'spostare la seduta';

  @override
  String get actionSkipTrainingSession => 'saltare la seduta';

  @override
  String get trainingMakeEasy => 'Rendi facile oggi';

  @override
  String get trainingBackToPlan => 'Torna al piano';

  @override
  String get trainingMoveSession => 'Sposta';

  @override
  String get trainingSkipSession => 'Salta';

  @override
  String trainingEasyLine(String reason) {
    return 'Oggi facile: $reason.';
  }

  @override
  String trainingEasyMoved(String day) {
    return 'Il giorno duro si sposta a $day.';
  }

  @override
  String get trainingEasySleptPoorly => 'hai dormito male';

  @override
  String get trainingEasyTired => 'ti senti stanco';

  @override
  String get trainingEasySore => 'hai i muscoli indolenziti';

  @override
  String get trainingEasyFormLow => 'la tua forma è bassa';

  @override
  String get trainingEasyAsked => 'hai chiesto un giorno più facile';

  @override
  String get trainingMoveTitle => 'Sposta questa seduta';

  @override
  String get trainingMoveHelp =>
      'Qualsiasi giorno che resta di questa settimana, che tu pedali quel giorno o no. Un giorno duro non può stare subito prima o dopo un altro giorno duro né l\'uscita lunga.';

  @override
  String get trainingMoveRefusedHard =>
      'Subito prima o dopo un altro giorno duro';

  @override
  String get trainingMoveRefusedLongRide =>
      'Subito prima o dopo l\'uscita lunga';

  @override
  String get trainingMoveRefusedSession => 'Quel giorno ha già una seduta';

  @override
  String get trainingMoveRefusedLoaded => 'Sarebbe un quarto giorno carico';

  @override
  String trainingMoveNearest(String day) {
    return 'Il giorno più vicino che va bene è $day';
  }

  @override
  String get trainingSkipTitle => 'Salta questa seduta';

  @override
  String get trainingSkipReasonLabel => 'Perché? (facoltativo)';

  @override
  String get trainingSkipReasonTired => 'Stanco';

  @override
  String get trainingSkipReasonIll => 'Malato o infortunato';

  @override
  String get trainingSkipReasonNoTime => 'Niente tempo';

  @override
  String get trainingSkipReasonOther => 'Altro';

  @override
  String get trainingSkipAction => 'Salta';

  @override
  String get trainingSkipRestOfWeek => 'Saltare il resto di questa settimana?';

  @override
  String get trainingSkipRestOfWeekBody =>
      'Vanno anche le sedute che restano di questa settimana, e nessuna si sposta a un altro giorno.';

  @override
  String notificationTrainingToday(String name) {
    return 'Oggi: $name.';
  }

  @override
  String notificationTrainingMoved(String name, String day) {
    return '$name si sposta a $day.';
  }

  @override
  String notificationTrainingSkipped(String name, String day) {
    return '$name di $day è saltata.';
  }

  @override
  String get sessionHowItWent => 'Com\'è andata';

  @override
  String get sessionOfHundred => 'su 100';

  @override
  String get sessionKindSpotOn => 'Perfetta. Seduta da manuale.';

  @override
  String get sessionKindOnPlan => 'Come previsto. Dovrebbe sentirsi così.';

  @override
  String get sessionKindClose =>
      'Bel lavoro: quasi tutto il piano, fatto bene.';

  @override
  String get sessionKindMost => 'Hai fatto la maggior parte. Conta.';

  @override
  String get sessionKindAny =>
      'Sulla carta non è la seduta, ma l\'uscita conta.';

  @override
  String sessionPlannedDone(String planned, String done) {
    return '$planned previsti · $done fatti';
  }

  @override
  String sessionMainSetWatts(String planned, String done) {
    return '$planned W previsti · $done W fatti';
  }

  @override
  String sessionMainSetBpm(String planned, String done) {
    return '$planned bpm previsti · $done bpm fatti';
  }

  @override
  String sessionMainSetPlannedOnly(String planned) {
    return '$planned previsti';
  }

  @override
  String get sessionOpenRide => 'Apri l\'uscita →';

  @override
  String get sessionTime => 'Tempo';

  @override
  String get sessionEffortScore => 'Punteggio di sforzo';

  @override
  String get sessionMainSet => 'Serie principale';

  @override
  String get relativeNow => 'ora';

  @override
  String relativeMinutes(int count) {
    return '$count min fa';
  }

  @override
  String relativeHours(int count) {
    return '$count h fa';
  }

  @override
  String get relativeYesterday => 'ieri';

  @override
  String get formStateBuilding => 'In costruzione';

  @override
  String get totalsTableWeekly => 'Settimana per settimana';

  @override
  String get totalsTableMonthly => 'Mese per mese';

  @override
  String get totalsTableYearly => 'Anno per anno';

  @override
  String get totalsColumnWeek => 'Settimana';

  @override
  String get totalsColumnMonth => 'Mese';

  @override
  String get totalsColumnYear => 'Anno';

  @override
  String wellbeingFeelSentence(String today, String usual) {
    return 'Oggi $today su 5; la tua media è $usual.';
  }

  @override
  String get wellbeingPrivateNotes =>
      'Solo tu vedi le tue note. I coach con cui condividi vedono i punteggi e lo sforzo dei giri, mai le note.';

  @override
  String get accountSearchHint => 'Nome o email';

  @override
  String get askedJustNow => 'richiesta poco fa';

  @override
  String askedHoursAgo(int count) {
    return 'richiesta $count h fa';
  }

  @override
  String askedDaysAgo(int count) {
    return 'richiesta $count g fa';
  }

  @override
  String get registerHelp => 'Pedala, segui la tua forma e tieni i tuoi dati.';

  @override
  String get passwordShow => 'Mostra';

  @override
  String get passwordHide => 'Nascondi';

  @override
  String get recordingScreenOff =>
      'La registrazione continua anche con lo schermo spento. Un banner sopra la navigazione ti riporta qui da ogni pagina.';

  @override
  String get addRouteSourceTitle => 'Da dove viene?';

  @override
  String get addRouteChosen => 'Scelto';

  @override
  String get wellbeingDay => 'Giorno';

  @override
  String get wellbeingRpeColumn => 'RPE';

  @override
  String get importReadingArchive => 'Lettura dell\'archivio';

  @override
  String clubMembersShowAll(int count) {
    return 'Mostra tutti ($count)';
  }

  @override
  String get clubMembersEmpty => 'Ancora nessun membro.';

  @override
  String get shareRoutesHelper =>
      'I tuoi percorsi, così un giro condiviso mostra la mappa.';

  @override
  String get clubStartUnavailable =>
      'La creazione dei club è disattivata su questo server.';

  @override
  String get twoFactorStateOff => 'L\'accesso a due fattori è disattivato.';

  @override
  String sessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dispositivi',
      one: '1 dispositivo',
    );
    return '$_temp0';
  }

  @override
  String privacyZoneRadiusLine(String distance) {
    return 'Raggio $distance';
  }

  @override
  String get intensityEasy => 'Facile';

  @override
  String get intensityModerate => 'Moderato';

  @override
  String get intensityHard => 'Intenso';
}
