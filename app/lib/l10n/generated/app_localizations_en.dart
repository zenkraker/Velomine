// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navRides => 'Rides';

  @override
  String get navRecord => 'Record';

  @override
  String get navProgress => 'Progress';

  @override
  String get navBikes => 'Bikes';

  @override
  String get navAdmin => 'Admin';

  @override
  String get notifications => 'Notifications';

  @override
  String notificationsUnread(int count) {
    return 'Notifications, $count unread';
  }

  @override
  String get signOut => 'Sign out';

  @override
  String themeTooltip(String name) {
    return 'Theme: $name';
  }

  @override
  String get themeSystem => 'Follow this device';

  @override
  String get themeLight => 'Day';

  @override
  String get themeDark => 'Night';

  @override
  String languageTooltip(String name) {
    return 'Language: $name';
  }

  @override
  String get languageSystem => 'Follow this device';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get name => 'Name';

  @override
  String get signIn => 'Sign in';

  @override
  String get change => 'Change';

  @override
  String get tryAgain => 'Try again';

  @override
  String serverLabel(String url) {
    return 'Server: $url';
  }

  @override
  String continueWith(String provider) {
    return 'Continue with $provider';
  }

  @override
  String get createAccount => 'Create an account';

  @override
  String get createAccountAction => 'Create account';

  @override
  String get haveAccount => 'I already have an account';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get passwordHint =>
      'At least 10 characters, with a capital letter, a small letter and a digit.';

  @override
  String get registeredReady => 'Your account is ready. You can sign in now.';

  @override
  String get registeredPending =>
      'Your account was created. An admin has to approve it before you can sign in.';

  @override
  String get authWrongPassword => 'The email or password is not right.';

  @override
  String get authNotApproved =>
      'Your account is waiting for an admin to approve it.';

  @override
  String get authLockedOut =>
      'Too many wrong attempts. Try again in a few minutes.';

  @override
  String get authSignUpClosed => 'Sign-up is closed on this server.';

  @override
  String get authWeakPassword =>
      'The password needs at least 10 characters with a capital letter, a small letter and a digit.';

  @override
  String get authEmailTaken => 'There is already an account with this email.';

  @override
  String get authUnavailable => 'Could not reach the server. Try again.';

  @override
  String get ssoEmailNotVerified =>
      'Your sign-in provider has not verified your email address.';

  @override
  String get ssoNoAccount =>
      'There is no account for you here yet. Ask an admin.';

  @override
  String get ssoLockedOut =>
      'This account is locked. Try again in a few minutes.';

  @override
  String get ssoNoEmail =>
      'Your sign-in provider did not share an email address.';

  @override
  String get ssoFailed => 'Single sign-on did not work. Try again.';

  @override
  String get ssoGeneric => 'single sign-on';

  @override
  String get signingIn => 'Signing you in…';

  @override
  String get setupTitle => 'Which server does your club use?';

  @override
  String get setupServerAddress => 'Server address';

  @override
  String get setupServerHint => 'https://velomine.club.example';

  @override
  String get setupInsecure =>
      'This address is not encrypted. Use it only on a network you trust, or ask your admin for an https address.';

  @override
  String get setupChecking => 'Checking…';

  @override
  String get setupConnect => 'Connect';

  @override
  String get setupHelp =>
      'Ask your club admin for the address. It usually looks like https://velomine.your-club.example.';

  @override
  String get setupInvalidAddress =>
      'Enter an address that starts with http:// or https://, for example https://velomine.club.example.';

  @override
  String get setupUnreachable =>
      'Could not reach a Velomine server at that address. Check the address, and that the phone is on the same network as the server.';

  @override
  String get setupSaveFailed => 'Could not save the address. Try again.';
}
