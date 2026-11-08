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

  @override
  String get failureRejected =>
      'The server did not accept that. Check the values.';

  @override
  String get failureMissing => 'It no longer exists.';

  @override
  String get failureConflict => 'That is not allowed.';

  @override
  String get failureMail =>
      'The mail server did not accept it. Check the email settings.';

  @override
  String get failureWrongConfirmation =>
      'That does not match. Nothing was deleted.';

  @override
  String get failureLastAdmin =>
      'You are the only admin. Make someone else an admin first.';

  @override
  String get failureUnreachable => 'Could not reach the server. Try again.';

  @override
  String failureFailed(String action, int code) {
    return 'Could not $action ($code). Try again.';
  }

  @override
  String get actionGeneral => 'do that';

  @override
  String get actionLoadRides => 'load your rides';

  @override
  String get actionUploadRide => 'upload this file';

  @override
  String get actionLoadRide => 'load this ride';

  @override
  String get actionChangeRideBike => 'change the bike';

  @override
  String get actionDeleteRide => 'delete the ride';

  @override
  String get actionLoadBikes => 'load your bikes';

  @override
  String get actionAddBike => 'add the bike';

  @override
  String get actionLoadBike => 'load this bike';

  @override
  String get actionSaveBike => 'save the bike';

  @override
  String get actionSetDefaultBike => 'set the default';

  @override
  String get actionDeleteBike => 'delete the bike';

  @override
  String get actionAddPart => 'add the part';

  @override
  String get actionSavePart => 'save the part';

  @override
  String get actionRemovePart => 'remove the part';

  @override
  String get actionLoadProgress => 'load your progress';

  @override
  String get actionAddGoal => 'add the goal';

  @override
  String get actionChangeGoal => 'change the goal';

  @override
  String get actionDeleteGoal => 'delete the goal';

  @override
  String get actionLoadAdmin => 'load the admin pages';

  @override
  String get actionReloadAccounts => 'reload the accounts';

  @override
  String get actionApproveAccount => 'approve the account';

  @override
  String get actionChangeRoles => 'change the roles';

  @override
  String get actionLockAccount => 'lock the account';

  @override
  String get actionUnlockAccount => 'unlock the account';

  @override
  String get actionDeleteAccount => 'delete the account';

  @override
  String get actionSendTestEmail => 'send the test email';

  @override
  String get actionSaveSettings => 'save the settings';

  @override
  String get actionLoadProfile => 'load your profile';

  @override
  String get actionPrepareData => 'prepare your data';

  @override
  String get actionSaveProfile => 'save your profile';

  @override
  String get actionLoadNotifications => 'load your notifications';

  @override
  String get actionMarkRead => 'mark it read';

  @override
  String get actionMarkAllRead => 'mark them read';

  @override
  String notificationRideReady(String subject) {
    return 'Your ride $subject is ready.';
  }

  @override
  String notificationRideFailed(String subject) {
    return '$subject could not be read.';
  }

  @override
  String notificationRideDuplicate(String subject) {
    return '$subject was already uploaded, so it is hidden.';
  }

  @override
  String notificationSignupWaiting(String subject) {
    return '$subject signed up and is waiting for approval.';
  }

  @override
  String notificationPartSoon(String subject) {
    return '$subject is nearly worn.';
  }

  @override
  String notificationPartWorn(String subject) {
    return '$subject is worn out. Time to replace it.';
  }

  @override
  String get rideErrorCorrupt => 'The file is damaged or incomplete.';

  @override
  String get rideErrorInvalid => 'This is not a ride file.';

  @override
  String get rideErrorUnsupported =>
      'Only FIT, GPX and TCX files are supported.';

  @override
  String get rideErrorNotCycling => 'This is not a cycling activity.';

  @override
  String get rideErrorNoTimestamps => 'The file has no timestamps.';

  @override
  String get rideErrorNoRecords => 'The file has no usable ride data.';

  @override
  String get rideErrorTooLarge => 'The file is too large.';

  @override
  String get rideErrorUnknown => 'The server could not read this file.';

  @override
  String get uploadRide => 'Upload ride';

  @override
  String get uploading => 'Uploading…';

  @override
  String get noRides => 'No rides yet. Upload a FIT, GPX or TCX file.';

  @override
  String get loadMore => 'Load more';

  @override
  String get readingFile => 'Reading the file…';

  @override
  String metresUp(int metres) {
    return '$metres m up';
  }

  @override
  String get delete => 'Delete';

  @override
  String get deleteRideTitle => 'Delete this ride?';

  @override
  String get deleteRideBody =>
      'The ride, its charts and the file you uploaded are removed. This cannot be undone.';

  @override
  String get keepIt => 'Keep it';

  @override
  String get rideNotFound => 'This ride does not exist, or it is not yours.';

  @override
  String get couldNotLoadRide => 'Could not load this ride.';

  @override
  String get trainingHint =>
      'Set your maximum heart rate and FTP in your profile to see zones and training load.';

  @override
  String get heartRateZones => 'Heart rate zones';

  @override
  String get powerZones => 'Power zones';

  @override
  String get momentHint =>
      'Move over a chart, or touch and drag, to see the values along the ride.';

  @override
  String momentAt(String time, String distance) {
    return 'At $time$distance';
  }

  @override
  String get statDistance => 'Distance';

  @override
  String get statMovingTime => 'Moving time';

  @override
  String get statElapsedTime => 'Elapsed time';

  @override
  String get statClimbing => 'Climbing';

  @override
  String get statDescending => 'Descending';

  @override
  String get statAverageSpeed => 'Average speed';

  @override
  String get statTopSpeed => 'Top speed';

  @override
  String get statAveragePower => 'Average power';

  @override
  String get statNormalizedPower => 'Normalized power';

  @override
  String get statMaxPower => 'Max power';

  @override
  String get statIntensity => 'Intensity';

  @override
  String get statTss => 'TSS';

  @override
  String get statTrimp => 'TRIMP';

  @override
  String get statAverageHeartRate => 'Average heart rate';

  @override
  String get statMaxHeartRate => 'Max heart rate';

  @override
  String get statAverageCadence => 'Average cadence';

  @override
  String get speedFromGps => 'Speed is worked out from GPS positions.';

  @override
  String get loadHint =>
      'TSS uses your FTP; TRIMP is time in heart-rate zones. Set both in your profile to see them.';

  @override
  String zoneSemantics(int zone, String range, String duration) {
    return 'Zone $zone, $range, $duration';
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
  String get bike => 'Bike';

  @override
  String get noBike => 'No bike';

  @override
  String get mapOfRoute => 'Map of the route';

  @override
  String get seriesElevation => 'Elevation';

  @override
  String get seriesSpeed => 'Speed';

  @override
  String get seriesPower => 'Power';

  @override
  String get seriesHeartRate => 'Heart rate';

  @override
  String get seriesCadence => 'Cadence';

  @override
  String chartSemantics(String name, String low, String average, String high) {
    return '$name chart: lowest $low, average $average, highest $high';
  }

  @override
  String chartAverageMax(String average, String max) {
    return 'avg $average · max $max';
  }
}
