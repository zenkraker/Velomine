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
}
