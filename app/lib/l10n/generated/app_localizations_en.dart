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
  String get navRecording => 'Recording';

  @override
  String get navRecordingPaused => 'Paused';

  @override
  String get navProgress => 'Progress';

  @override
  String get navBikes => 'Bikes';

  @override
  String get navAdmin => 'Admin';

  @override
  String get accountMenu => 'Account';

  @override
  String get recordPermissionHelp =>
      'Starting asks for your position and shows a notification while the ride records, even with the screen off.';

  @override
  String get rideNoData => 'No data';

  @override
  String get sessionsNavTitle => 'Sessions';

  @override
  String get twoFactorNavTitle => 'Two-factor';

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
  String get language => 'Language';

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
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get staySignedIn => 'Stay logged in';

  @override
  String get pressBackAgain => 'Press back again to exit';

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
  String get authWrongCode => 'That code did not work. Try the next one.';

  @override
  String get twoFactorTitle => 'Two-factor sign-in';

  @override
  String get twoFactorHelp =>
      'Enter the 6-digit code from your authenticator app, or one of your recovery codes.';

  @override
  String get twoFactorCode => '6-digit code';

  @override
  String get twoFactorVerify => 'Verify';

  @override
  String get twoFactorUseAnother => 'Use another account';

  @override
  String get twoFactorStateOn => 'Two-factor sign-in is on.';

  @override
  String get twoFactorStateOff => 'Two-factor sign-in is off.';

  @override
  String get twoFactorIntro =>
      'After your password, you enter a code from your authenticator app. It is optional, and you can turn it off again.';

  @override
  String get twoFactorNoPassword =>
      'This account signs in with single sign-on, so it already has a second step.';

  @override
  String get twoFactorStart => 'Set up an authenticator';

  @override
  String get twoFactorKeyHelp =>
      'Type this key into your authenticator app, then enter the code it shows.';

  @override
  String get twoFactorKey => 'Key';

  @override
  String get twoFactorPassword => 'Your password';

  @override
  String get twoFactorCodeLabel => 'Code from the app';

  @override
  String get twoFactorEnable => 'Turn on';

  @override
  String get twoFactorDisable => 'Turn off';

  @override
  String get twoFactorRegenerate => 'New recovery codes';

  @override
  String get twoFactorRecoveryTitle => 'Recovery codes';

  @override
  String get twoFactorRecoveryHelp =>
      'Save them somewhere safe. Each works once, in place of the app code.';

  @override
  String get twoFactorEnabled => 'Two-factor sign-in is on.';

  @override
  String get twoFactorDisabled => 'Two-factor sign-in is off.';

  @override
  String get twoFactorCodeWrong =>
      'That code did not work. Check the clock on your phone and try the next one.';

  @override
  String get sessionsTitle => 'Devices and sessions';

  @override
  String get sessionsIntro =>
      'Where you are signed in now. Signing a device out asks for the password again there.';

  @override
  String get sessionThisDevice => 'This device';

  @override
  String get sessionLastUsed => 'Last used';

  @override
  String get sessionSince => 'Signed in';

  @override
  String get sessionRevoke => 'Sign out';

  @override
  String get sessionLogoutOthers => 'Log out other devices';

  @override
  String get sessionsEmpty => 'No other devices are signed in.';

  @override
  String get sessionRevoked => 'That device is signed out.';

  @override
  String get sessionOthersRevoked => 'Every other device is signed out.';

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
  String get failureSessionEnded => 'Your session ended. Sign in again.';

  @override
  String get failureForbidden => 'Your account may not do that.';

  @override
  String get failureTooMany => 'Too many attempts. Try again shortly.';

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
  String get actionSaveWellbeing => 'save how you feel';

  @override
  String get actionSetFtp => 'set your FTP';

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
  String get actionLoadClub => 'load your club';

  @override
  String get actionJoinClub => 'join the club';

  @override
  String get actionLeaveClub => 'leave the club';

  @override
  String get actionRotateJoinCode => 'make a new join code';

  @override
  String get actionChangeClubRole => 'change the member\'s role';

  @override
  String get actionLoadAdminClubs => 'load the clubs';

  @override
  String get actionCreateClub => 'create the club';

  @override
  String get actionUpdateClub => 'change the club';

  @override
  String get actionSetClubOwner => 'name the owner';

  @override
  String get actionLoadSharing => 'load your sharing choices';

  @override
  String get actionSaveSharing => 'save your sharing choices';

  @override
  String get actionLoadPrivacy => 'load your privacy choices';

  @override
  String get actionSavePrivacy => 'save your privacy choices';

  @override
  String get actionLoadAthletes => 'load the athletes';

  @override
  String get actionLoadAthlete => 'load the athlete';

  @override
  String get actionLoadCoachRide => 'load this ride';

  @override
  String get navClub => 'Club';

  @override
  String get joinTitle => 'Join a club';

  @override
  String get joinIntro =>
      'Ask your club\'s owner for the join code, or open the link they shared.';

  @override
  String get joinCode => 'Join code';

  @override
  String get joinAction => 'Join';

  @override
  String get joinSkip => 'Continue without a club';

  @override
  String get joinInvalid =>
      'That code is not right, or the club is not taking new members.';

  @override
  String get joinAlready => 'Your account is already in a club.';

  @override
  String get clubNoneTitle => 'You are not in a club yet';

  @override
  String get clubNoneBody =>
      'Velomine works on your own too. Join a club when you want to ride with a group and share with its coaches.';

  @override
  String get clubInactive => 'This club is not active. Joining is closed.';

  @override
  String get clubOwner => 'Owner';

  @override
  String get clubCoach => 'Coach';

  @override
  String get clubMemberRole => 'Rider';

  @override
  String get clubMembers => 'Members';

  @override
  String get clubJoinCode => 'Join code';

  @override
  String get clubJoinCodeHelp =>
      'Share this code or the link with the people who should join.';

  @override
  String get clubNewCode => 'New code';

  @override
  String get clubNewCodeConfirm =>
      'The old code stops working at once. Continue?';

  @override
  String get clubLeave => 'Leave club';

  @override
  String get clubLeaveTitle => 'Leave this club?';

  @override
  String get clubLeaveBody =>
      'You can join again with a new code. Your rides stay yours.';

  @override
  String get clubOwnerCannotLeave =>
      'The owner cannot leave. Ask the server admin to name another owner first.';

  @override
  String get clubMakeCoach => 'Make coach';

  @override
  String get clubMakeMember => 'Make rider';

  @override
  String get clubCopy => 'Copy';

  @override
  String get clubCopied => 'Copied';

  @override
  String clubMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get sharingTitle => 'What you share';

  @override
  String get sharingHelp =>
      'Only what you turn on leaves your account. Your club always sees your name and place in the roster.';

  @override
  String get shareRides => 'Rides';

  @override
  String get shareAnalytics => 'Training';

  @override
  String get shareRoutes => 'Routes';

  @override
  String get audienceNone => 'Nobody';

  @override
  String get audienceCoaches => 'My coaches';

  @override
  String get routesNeedRides =>
      'Turn on rides first; routes add the map to them.';

  @override
  String get privacyTitle => 'Ride privacy';

  @override
  String get privacyHelp =>
      'What other people see when you share a ride or your club can see it. You always see everything.';

  @override
  String get privacyOthersSee => 'What others see of each ride';

  @override
  String get privacyHideHeartRate => 'Heart rate';

  @override
  String get privacyHidePower => 'Power';

  @override
  String get privacyHideCadence => 'Cadence';

  @override
  String get privacyHideSpeed => 'Speed';

  @override
  String get privacyHideElevation => 'Elevation';

  @override
  String get privacyHideTemperature => 'Temperature';

  @override
  String get privacyTrimTitle => 'Hide the start and end';

  @override
  String get privacyTrimStart => 'Start';

  @override
  String get privacyTrimEnd => 'End';

  @override
  String get privacyTrimHelp =>
      'Metres hidden at the start and end of every ride. 0 keeps everything.';

  @override
  String get privacyZonesTitle => 'Saved places';

  @override
  String get privacyZonesHelp =>
      'Every ride hides up to a mile around these places, and the route line breaks there. At most ten places.';

  @override
  String get privacyZonesEmpty => 'No saved places yet.';

  @override
  String get privacyAddZone => 'Add a place';

  @override
  String get privacyZoneName => 'Name';

  @override
  String get privacyZoneRadius => 'Radius (m)';

  @override
  String get privacyZoneRadiusHelp => '200 to 1609 metres.';

  @override
  String privacyZoneDelete(String name) {
    return 'Remove $name';
  }

  @override
  String get privacyErrorRadius => 'Choose a radius from 200 to 1609 metres.';

  @override
  String get privacyErrorName => 'Give the place a name.';

  @override
  String get privacyErrorTrim => 'Choose 0 to 5000 metres for each end.';

  @override
  String get privacyRidePrivacy => 'Ride privacy';

  @override
  String get privacyRidePrivacyHelp => 'What your coach and shared links see.';

  @override
  String get viewsTitle => 'Who looked';

  @override
  String get viewsEmpty => 'Nobody has looked yet.';

  @override
  String get viewSummary => 'Summary';

  @override
  String get viewTraining => 'Training';

  @override
  String get viewRide => 'Ride';

  @override
  String get viewRides => 'Ride list';

  @override
  String get viewRoute => 'Route';

  @override
  String get athletesTitle => 'Athletes';

  @override
  String get coachViewAthletes => 'View athletes';

  @override
  String get athletesEmpty =>
      'No athletes are sharing with you yet. Members turn sharing on in their Club tab.';

  @override
  String lastRideOn(String date) {
    return 'Last ride $date';
  }

  @override
  String get days7 => '7 days';

  @override
  String get days42 => '42 days';

  @override
  String get sharesRides => 'Rides';

  @override
  String get sharesTraining => 'Training';

  @override
  String get sharesRoutes => 'Routes';

  @override
  String get coachAthleteNotFound => 'This athlete is not sharing with you.';

  @override
  String get coachRideNotFound => 'This ride is not shared with you.';

  @override
  String get coachReadOnly => 'Shared by the athlete, read-only.';

  @override
  String get coachNoRides => 'No rides shared yet.';

  @override
  String get routeNotShared => 'The athlete has not shared the route.';

  @override
  String get adminClubs => 'Clubs';

  @override
  String get adminCreateClub => 'Create club';

  @override
  String get adminClubName => 'Club name';

  @override
  String get adminClubOwnerEmail => 'Owner\'s email';

  @override
  String get adminClubOwnerHelp =>
      'An existing account, which becomes the club\'s owner.';

  @override
  String get adminClubActive => 'Active';

  @override
  String get adminClubJoinCode => 'Join code';

  @override
  String get adminNoClubs => 'No clubs yet. Create the first one.';

  @override
  String get changeOwner => 'Change owner';

  @override
  String get chooseOwner => 'Choose the new owner';

  @override
  String get errorClubName => 'Give the club a name.';

  @override
  String get errorClubOwner => 'Enter the owner\'s email.';

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
  String get bulkChooseFolder => 'Choose a folder';

  @override
  String get bulkChooseFiles => 'Choose files';

  @override
  String get bulkDropTitle => 'Drop to add your rides';

  @override
  String get bulkDropHint =>
      'Files or a whole folder: .fit, .gpx and .tcx files are read, also zipped (.gz).';

  @override
  String get bulkTitle => 'Adding rides from files';

  @override
  String get bulkScanning => 'Looking through the files…';

  @override
  String bulkProgress(int done, int total) {
    return 'Reading $done of $total';
  }

  @override
  String get bulkCancel => 'Cancel';

  @override
  String get bulkStopping => 'Stopping…';

  @override
  String get bulkDone => 'All files read';

  @override
  String get bulkStopped => 'Stopped before the end';

  @override
  String bulkAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new rides',
      one: '1 new ride',
      zero: 'No new rides',
    );
    return '$_temp0';
  }

  @override
  String bulkAlreadyHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rides were already here',
      one: '1 ride was already here',
    );
    return '$_temp0';
  }

  @override
  String bulkUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files could not be read',
      one: '1 file could not be read',
    );
    return '$_temp0';
  }

  @override
  String bulkSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files skipped: not ride files',
      one: '1 file skipped: not a ride file',
    );
    return '$_temp0';
  }

  @override
  String bulkNotRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files were not read',
      one: '1 file was not read',
    );
    return '$_temp0';
  }

  @override
  String bulkAndMore(int count) {
    return 'and $count more';
  }

  @override
  String get bulkClose => 'Close';

  @override
  String get bulkSignedOut => 'Sign in first, then add your rides again.';

  @override
  String get bulkNothing =>
      'No ride files found. Velomine reads .fit, .gpx and .tcx files, also zipped (.gz).';

  @override
  String get bulkWaiting => 'Waiting a moment, the server is busy…';

  @override
  String incomingAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rides added. They will upload in the background.',
      one: '1 ride added. It will upload in the background.',
    );
    return '$_temp0';
  }

  @override
  String incomingAlreadyHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rides were already here.',
      one: '1 ride was already here.',
    );
    return '$_temp0';
  }

  @override
  String incomingRejectedOne(String name) {
    return '$name is not a ride file and was skipped.';
  }

  @override
  String incomingRejectedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files are not ride files and were skipped.',
      one: '1 file is not a ride file and was skipped.',
    );
    return '$_temp0';
  }

  @override
  String incomingSignedOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rides are kept. Sign in and they will upload.',
      one: '1 ride is kept. Sign in and it will upload.',
    );
    return '$_temp0';
  }

  @override
  String get incomingOpen => 'Ride list';

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
  String get rideActions => 'Ride actions';

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
  String get heartRateOnMap => 'Show heart rate on the map';

  @override
  String mapHeartRateHint(int min, int max) {
    return 'Route colour shows heart rate from $min to $max bpm';
  }

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

  @override
  String get addBike => 'Add bike';

  @override
  String get noBikes =>
      'No bikes yet. Add one to keep track of its distance and the wear on its parts. New rides are given your default bike.';

  @override
  String get defaultBike => 'Default';

  @override
  String get archived => 'Archived';

  @override
  String bikeRides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rides',
      one: '1 ride',
      zero: 'No rides',
    );
    return '$_temp0';
  }

  @override
  String get deleteBikeTitle => 'Delete this bike?';

  @override
  String get deleteBikeBody =>
      'The bike and its parts are removed. Your rides stay, but they will no longer say which bike you rode. To keep the history, archive the bike instead.';

  @override
  String removePartTitle(String name) {
    return 'Remove $name from the list?';
  }

  @override
  String get removePartBody =>
      'Its history is deleted. To keep it, use Replace, which retires the part but keeps its wear.';

  @override
  String get remove => 'Remove';

  @override
  String get bikeNotFound => 'This bike does not exist, or it is not yours.';

  @override
  String wheelLabel(int mm) {
    return 'wheel $mm mm';
  }

  @override
  String get statRides => 'Rides';

  @override
  String get edit => 'Edit';

  @override
  String get makeDefault => 'Make default';

  @override
  String get archive => 'Archive';

  @override
  String get restore => 'Restore';

  @override
  String get parts => 'Parts';

  @override
  String get addPartAction => 'Add part';

  @override
  String get noParts =>
      'No parts yet. Add the chain, tyres or brake pads to see how worn they are.';

  @override
  String get replacedParts => 'Replaced parts';

  @override
  String get wearReplace => 'Replace it';

  @override
  String get wearSoon => 'Getting worn';

  @override
  String get wearReplaced => 'Replaced';

  @override
  String get wearGood => 'Good';

  @override
  String wearDistance(String used, String expected) {
    return '$used of $expected km';
  }

  @override
  String wearHours(String used, String expected) {
    return '$used of $expected h';
  }

  @override
  String wearMonths(String used, int expected) {
    return '$used of $expected months';
  }

  @override
  String wearNoLimit(String distance, String hours) {
    return '$distance · $hours h, no limit set';
  }

  @override
  String wearPercent(int percent) {
    return '$percent% worn';
  }

  @override
  String installedOn(String date) {
    return 'Installed $date';
  }

  @override
  String installedAndRemoved(String installed, String removed) {
    return 'Installed $installed · removed $removed';
  }

  @override
  String get replace => 'Replace';

  @override
  String get addBikeTitle => 'Add a bike';

  @override
  String get editBikeTitle => 'Edit bike';

  @override
  String get kind => 'Kind';

  @override
  String get brand => 'Brand';

  @override
  String get model => 'Model';

  @override
  String get modelYear => 'Model year';

  @override
  String get buildSpec => 'Build or spec';

  @override
  String get frameSize => 'Frame size';

  @override
  String get modelYearHelper => 'Such as 2023. Optional.';

  @override
  String get buildSpecHelper =>
      'Such as SL 7, Comp or the groupset name. Optional.';

  @override
  String get frameSizeHelper => '56, M or 17.5\".';

  @override
  String get wheelCircumference => 'Wheel circumference (mm)';

  @override
  String get wheelHelper =>
      'Typical values below; measure one roll of your own wheel for the exact number.';

  @override
  String get initialDistance => 'Distance before Velomine (km)';

  @override
  String get initialHelper =>
      'For a bike you already rode. Leave empty for a new one.';

  @override
  String get purchaseDate => 'Purchase date (optional)';

  @override
  String boughtOn(String date) {
    return 'Bought $date';
  }

  @override
  String get errorBikeName => 'Give the bike a name.';

  @override
  String get errorModelYear => 'The model year is 1900 to 2100, or empty.';

  @override
  String get errorWheelRange => 'The wheel circumference is 1000 to 2600 mm.';

  @override
  String get errorInitialDistance =>
      'Distance before Velomine must be 0 or more.';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get openFullMap => 'Open the full map';

  @override
  String get save => 'Save';

  @override
  String replacePartTitle(String name) {
    return 'Replace $name';
  }

  @override
  String get editPartTitle => 'Edit part';

  @override
  String get addPartTitle => 'Add a part';

  @override
  String get partLabel => 'Part';

  @override
  String get findPart => 'Find a known part';

  @override
  String get findPartHint => 'Brand, model or part number';

  @override
  String get mpn => 'Part number (MPN)';

  @override
  String get gtin => 'Barcode (GTIN)';

  @override
  String get mpnHelper => 'The code on the part, such as CN-M8100. Optional.';

  @override
  String get gtinHelper => 'The number under the barcode on the box. Optional.';

  @override
  String get stillOnBike => 'Still on the bike';

  @override
  String removedOn(String date) {
    return 'Removed $date';
  }

  @override
  String get putBackOnBike => 'Put it back on the bike';

  @override
  String get partLimitsHelp =>
      'Replace it when it reaches the first of these limits. Typical values are only a starting point; leave a field empty for no limit.';

  @override
  String get hours => 'hours';

  @override
  String get months => 'months';

  @override
  String get errorChoosePart => 'Choose what kind of part it is.';

  @override
  String get errorLimits => 'Limits must be numbers above 0, or empty.';

  @override
  String get errorRemovedBeforeInstalled =>
      'It cannot be removed before it was installed.';

  @override
  String get errorGtin =>
      'A GTIN is 8, 12, 13 or 14 digits with a valid check digit.';

  @override
  String get bikeKindRoad => 'Road';

  @override
  String get bikeKindGravel => 'Gravel';

  @override
  String get bikeKindMountain => 'Mountain';

  @override
  String get bikeKindEbike => 'E-bike';

  @override
  String get bikeKindTimeTrial => 'Time trial';

  @override
  String get bikeKindTrack => 'Track';

  @override
  String get bikeKindCity => 'City';

  @override
  String get bikeKindOther => 'Other';

  @override
  String get partChain => 'Chain';

  @override
  String get partCassette => 'Cassette';

  @override
  String get partChainring => 'Chainring';

  @override
  String get partCrankset => 'Crankset';

  @override
  String get partBottomBracket => 'Bottom bracket';

  @override
  String get partFrontDerailleur => 'Front derailleur';

  @override
  String get partRearDerailleur => 'Rear derailleur';

  @override
  String get partDerailleurHanger => 'Derailleur hanger';

  @override
  String get partShifters => 'Shifters';

  @override
  String get partShiftCables => 'Shift cables';

  @override
  String get partPedals => 'Pedals';

  @override
  String get partFrontTire => 'Front tire';

  @override
  String get partRearTire => 'Rear tire';

  @override
  String get partTubelessSealant => 'Tubeless sealant';

  @override
  String get partInnerTubes => 'Inner tubes';

  @override
  String get partWheelset => 'Wheelset';

  @override
  String get partHubService => 'Hub service';

  @override
  String get partFrontBrakePads => 'Front brake pads';

  @override
  String get partRearBrakePads => 'Rear brake pads';

  @override
  String get partFrontRotor => 'Front rotor';

  @override
  String get partRearRotor => 'Rear rotor';

  @override
  String get partBrakeFluid => 'Brake fluid';

  @override
  String get partBrakeCables => 'Brake cables';

  @override
  String get partHandlebarTape => 'Handlebar tape or grips';

  @override
  String get partHandlebar => 'Handlebar';

  @override
  String get partStem => 'Stem';

  @override
  String get partHeadset => 'Headset';

  @override
  String get partSaddle => 'Saddle';

  @override
  String get partSeatpost => 'Seatpost';

  @override
  String get partForkService => 'Fork service';

  @override
  String get partShockService => 'Rear shock service';

  @override
  String get partDropperPostService => 'Dropper post service';

  @override
  String get partEBattery => 'E-bike battery';

  @override
  String get partEMotor => 'E-bike motor';

  @override
  String get partOther => 'Other part';

  @override
  String get partGroupDrivetrain => 'Drivetrain';

  @override
  String get partGroupWheels => 'Wheels';

  @override
  String get partGroupBrakes => 'Brakes';

  @override
  String get partGroupCockpit => 'Cockpit';

  @override
  String get partGroupSuspension => 'Suspension';

  @override
  String get partGroupElectric => 'Electric';

  @override
  String get partGroupOther => 'Other';

  @override
  String get periodWeeks => 'Weeks';

  @override
  String get periodMonths => 'Months';

  @override
  String get periodYears => 'Years';

  @override
  String get thisWeek => 'This week';

  @override
  String get thisMonth => 'This month';

  @override
  String get thisYear => 'This year';

  @override
  String get periodWordWeek => 'week';

  @override
  String get periodWordMonth => 'month';

  @override
  String get periodWordYear => 'year';

  @override
  String periodTotals(int count, String duration, int elevation) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rides',
      one: '1 ride',
      zero: 'No rides',
    );
    return '$_temp0 · $duration · $elevation m climbing';
  }

  @override
  String get goals => 'Goals';

  @override
  String get addGoal => 'Add goal';

  @override
  String get noGoals =>
      'No goals yet. Set a target for each week, month or year: distance, climbing, riding time or number of rides.';

  @override
  String get goalWeekly => 'Weekly';

  @override
  String get goalMonthly => 'Monthly';

  @override
  String get goalYearly => 'Yearly';

  @override
  String get goalMetricDistance => 'Distance';

  @override
  String get goalMetricElevation => 'Climbing';

  @override
  String get goalMetricTime => 'Riding time';

  @override
  String get goalMetricRides => 'Rides';

  @override
  String get goalUnitRides => 'rides';

  @override
  String goalRideCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rides',
      one: '1 ride',
      zero: 'No rides',
    );
    return '$_temp0';
  }

  @override
  String get goalChange => 'Change goal';

  @override
  String get goalAdd => 'Add goal';

  @override
  String get goalEvery => 'Every';

  @override
  String get goalEveryWeek => 'week';

  @override
  String get goalEveryMonth => 'month';

  @override
  String get goalEveryYear => 'year';

  @override
  String get goalCount => 'Count';

  @override
  String get goalTarget => 'Target';

  @override
  String get errorGoalTarget => 'Enter a target above 0.';

  @override
  String goalTitle(String period, String metric) {
    return '$period $metric';
  }

  @override
  String get goalReached => 'Reached';

  @override
  String get goalChangeTarget => 'Change target';

  @override
  String get goalDelete => 'Delete goal';

  @override
  String goalSemantics(String metric) {
    return '$metric goal';
  }

  @override
  String goalProgress(String current, String target, int percent) {
    return '$current of $target · $percent %';
  }

  @override
  String totalsSemantics(String period, String distance) {
    return 'Distance per $period. This $period: $distance.';
  }

  @override
  String get trainingLoad => 'Training load';

  @override
  String get range30Days => '30 d';

  @override
  String get range90Days => '90 d';

  @override
  String get rangeOneYear => '1 y';

  @override
  String get trainingLoadHint =>
      'Set your FTP (and maximum heart rate) in your profile, then upload a ride to see training load.';

  @override
  String get fitnessFatigueForm => 'Fitness, fatigue and form';

  @override
  String get fitness => 'Fitness';

  @override
  String get fatigue => 'Fatigue';

  @override
  String get form => 'Form';

  @override
  String fitnessSemantics(int fitness, int fatigue, int form) {
    return 'Fitness $fitness, fatigue $fatigue, form $form.';
  }

  @override
  String get dailyLoad => 'Daily load (TSS)';

  @override
  String dailyLoadSemantics(int days) {
    return 'Daily training stress score for the last $days days.';
  }

  @override
  String get trainingLoadHelp =>
      'Fitness averages the last 42 days of load, fatigue the last 7. Form is fitness minus fatigue.';

  @override
  String get accountSearch => 'Find an account';

  @override
  String get clearSearch => 'Clear the search';

  @override
  String get adminAccounts => 'Accounts';

  @override
  String get adminSettings => 'Settings';

  @override
  String get adminOverview => 'Overview';

  @override
  String deleteUserTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String deleteUserBody(String email) {
    return 'This deletes the account of $email for good: their rides, bikes, goals and the ride files. It cannot be undone.';
  }

  @override
  String get waitingForApproval => 'Waiting for approval';

  @override
  String get nonePending => 'No accounts are waiting for approval.';

  @override
  String get you => 'You';

  @override
  String get locked => 'Locked';

  @override
  String get roleMember => 'Member';

  @override
  String get roleCoach => 'Coach';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get approve => 'Approve';

  @override
  String actionsFor(String name) {
    return 'Actions for $name';
  }

  @override
  String get changeRoles => 'Change roles';

  @override
  String get unlockAccount => 'Unlock account';

  @override
  String get lockAccount => 'Lock account';

  @override
  String get deleteAccountAction => 'Delete account';

  @override
  String get resetTwoFactor => 'Reset two-factor sign-in';

  @override
  String get resetTwoFactorBody =>
      'The member signs in again with the password and sets up the authenticator app from scratch.';

  @override
  String rolesFor(String name) {
    return 'Roles for $name';
  }

  @override
  String get everyAccountMember => 'Every account is a member.';

  @override
  String get saved => 'Saved.';

  @override
  String get signUp => 'Sign-up';

  @override
  String get peopleCanCreate => 'People can create accounts';

  @override
  String get newAccountsApproval =>
      'New accounts need an admin to approve them';

  @override
  String get envVariables => 'Set with environment variables';

  @override
  String get secretsHelp =>
      'These hold passwords and secrets, so they are never stored in the database or changed from here. Edit the server\'s environment and restart it.';

  @override
  String get sendTestEmail => 'Send a test email to me';

  @override
  String get testEmailSent => 'Test email sent to your own address.';

  @override
  String get emailSmtp => 'Email (SMTP)';

  @override
  String smtpDetail(String host, int port, String security, String from) {
    return '$host:$port · $security · from $from';
  }

  @override
  String get smtpNotConfigured =>
      'Not set up. Set VELOMINE__SMTP__HOST and VELOMINE__SMTP__FROM.';

  @override
  String get singleSignOn => 'Single sign-on';

  @override
  String ssoDetail(String name, String authority) {
    return '$name · $authority';
  }

  @override
  String get ssoNotConfigured =>
      'Not set up. Set VELOMINE__SSO__AUTHORITY, VELOMINE__SSO__CLIENTID and VELOMINE__SSO__CLIENTSECRET.';

  @override
  String statusOn(String title) {
    return '$title: on';
  }

  @override
  String statusOff(String title) {
    return '$title: off';
  }

  @override
  String get noOverview => 'No overview.';

  @override
  String get noSettings => 'No settings.';

  @override
  String get rideFilesOnDisk => 'Ride files on disk';

  @override
  String get serverVersion => 'Server version';

  @override
  String get rideReaderVersion => 'Ride reader version';

  @override
  String get ridesToReread => 'Rides waiting to be read again';

  @override
  String get ridesNotReread => 'Rides that could not be read again';

  @override
  String get profileTitle => 'Profile';

  @override
  String get ftpHelper =>
      'Functional threshold power. Used for training load and power zones.';

  @override
  String get weight => 'Weight';

  @override
  String get birthYear => 'Year of birth';

  @override
  String get birthYearHelper =>
      'Maximum heart rate is estimated from it with the Tanaka formula (208 − 0.7 × age).';

  @override
  String estimatedMaxHeartRate(int bpm) {
    return 'Estimated maximum heart rate: $bpm bpm';
  }

  @override
  String get estimatedMaxHeartRateNone =>
      'Add your year of birth to estimate it.';

  @override
  String get timeZone => 'Time zone';

  @override
  String get timeZoneHelper =>
      'Decides which day a ride counts on when its file does not say. Empty means UTC.';

  @override
  String get firstDayOfWeek => 'Weeks start on';

  @override
  String get emailNotifications => 'Email me my notifications';

  @override
  String get emailAvailableHelp =>
      'A ride that was read, a part that is worn, and so on.';

  @override
  String get emailUnavailableHelp =>
      'This server is not set up to send email, so nothing is sent yet.';

  @override
  String get emailAccountNotifications => 'Account and club emails';

  @override
  String get emailAccountNotificationsHelp =>
      'Join requests and approvals, and sign-ups waiting for approval.';

  @override
  String get emailTrainingNotifications => 'Ride and gear emails';

  @override
  String get emailTrainingNotificationsHelp =>
      'Rides finishing or failing, and parts wearing out. Grouped into one email.';

  @override
  String get yourData => 'Your data';

  @override
  String get yourDataHelp =>
      'It is yours. Download everything Velomine keeps about you: your details, bikes, goals and rides, with every ride file exactly as you uploaded it.';

  @override
  String get downloadMyData => 'Download my data';

  @override
  String get exportStarted =>
      'Your download has started in your browser. The link works for two minutes.';

  @override
  String get deleteMyAccount => 'Delete my account';

  @override
  String get errorEnterName => 'Enter your name.';

  @override
  String get errorFtp => 'FTP is 30 to 1000 watts.';

  @override
  String get errorWeight => 'Weight is 20 to 300 kg.';

  @override
  String get errorBirthYear =>
      'Enter a year of birth between 1900 and ten years ago.';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'This deletes your account and everything in it for good: your rides and the ride files, bikes, goals and notifications. Download your data first if you want to keep it. It cannot be undone.';

  @override
  String get yourPassword => 'Your password';

  @override
  String get confirmEmail => 'Type your email address to confirm';

  @override
  String get deleteEverything => 'Delete everything';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotifications =>
      'Nothing yet. You will hear here when a ride has been read, or a part on your bike is nearly worn.';

  @override
  String get unread => 'Unread';

  @override
  String get recordRide => 'Record a ride';

  @override
  String get recordIntro =>
      'The phone keeps recording with the screen off. Your ride is saved on this phone first; uploads are added next.';

  @override
  String get starting => 'Starting…';

  @override
  String get startRecording => 'Start recording';

  @override
  String get pauseWhenStopped => 'Pause when stopped';

  @override
  String get pauseWhenStoppedHelp =>
      'After 3 seconds at 0.1 km/h or slower; resumes above it.';

  @override
  String get heartRateStrap => 'Heart-rate strap';

  @override
  String get nonePaired =>
      'None paired. Optional: heart rate is saved with the ride.';

  @override
  String get forget => 'Forget';

  @override
  String get pair => 'Pair';

  @override
  String get sensorConnected => 'Connected';

  @override
  String get sensorConnecting => 'Connecting…';

  @override
  String get bluetoothOffState => 'Bluetooth is off';

  @override
  String get sensorDeniedState => 'Nearby devices not allowed';

  @override
  String get sensorConnectsOnStart => 'Connects when you start a ride';

  @override
  String get autoPaused => 'Auto-paused';

  @override
  String get paused => 'Paused';

  @override
  String get recording => 'Recording';

  @override
  String get moving => 'Moving';

  @override
  String get gps => 'GPS';

  @override
  String get heartRate => 'Heart rate';

  @override
  String get resume => 'Resume';

  @override
  String get pause => 'Pause';

  @override
  String get stopAndSave => 'Stop and save';

  @override
  String get onThisPhone => 'On this phone';

  @override
  String get noLocalRides => 'No rides recorded on this phone yet.';

  @override
  String get uploaded => 'Uploaded';

  @override
  String get serverReading => 'Server is reading it…';

  @override
  String get waitingToUpload => 'Waiting to upload';

  @override
  String get uploadFailed => 'Upload failed';

  @override
  String get readyToUpload => 'Ready to upload';

  @override
  String get recordingOnPhone => 'Recording on this phone';

  @override
  String get interrupted => 'Interrupted';

  @override
  String get couldNotBeSaved => 'Could not be saved';

  @override
  String get interruptedHelp =>
      'The recording stopped unexpectedly. Finish it to keep the ride.';

  @override
  String get finish => 'Finish';

  @override
  String get retry => 'Retry';

  @override
  String get upload => 'Upload';

  @override
  String get deleteFromPhone => 'Delete this ride from the phone';

  @override
  String get pairStrapTitle => 'Pair a heart-rate strap';

  @override
  String get pairStrapHelp =>
      'Wear the strap so it wakes up, then pick it below. It is remembered for your next rides.';

  @override
  String get searchingStraps => 'Searching for straps…';

  @override
  String get noStraps =>
      'No straps found. Make sure the strap is worn and Bluetooth is on.';

  @override
  String get searchAgain => 'Search again';

  @override
  String get recorderPermission =>
      'Allow precise location, and notifications if asked, so the ride can keep recording.';

  @override
  String get recorderGpsOff => 'Turn on location (GPS) to record a ride.';

  @override
  String get recorderLocationFailed =>
      'The phone could not start location updates.';

  @override
  String get recorderUnsupported => 'Recording is only available on the phone.';

  @override
  String get recorderTooShort => 'The ride was too short to save.';

  @override
  String get recorderFitFailed => 'The ride could not be saved.';

  @override
  String get recorderStillRecording => 'Stop the ride before finishing it.';

  @override
  String get recorderRideNotFound => 'That ride is no longer on this phone.';

  @override
  String get recorderBluetoothOff =>
      'Turn on Bluetooth to use a heart-rate strap.';

  @override
  String get recorderBluetoothDenied =>
      'Allow nearby devices so the app can find your heart-rate strap.';

  @override
  String get recorderSensorNotFound => 'That strap is no longer nearby.';

  @override
  String get recorderFailed => 'The recorder could not do that. Try again.';

  @override
  String get recorderUnreadable => 'Could not read the recorder.';

  @override
  String get uploadNoFile => 'The FIT file is missing on this phone.';

  @override
  String get uploadOffline => 'Could not reach the server. Try again.';

  @override
  String get uploadSignIn => 'Sign in again to upload.';

  @override
  String get uploadTimeout => 'The server took too long to read the ride.';

  @override
  String get uploadServerFailed => 'The server could not read this ride.';

  @override
  String uploadHttpRefused(String code) {
    return 'The server refused the upload ($code).';
  }

  @override
  String get uploadFailedGeneric => 'Upload failed. Try again.';

  @override
  String get readiness => 'Readiness';

  @override
  String get readinessHard => 'Ready for a hard ride';

  @override
  String get readinessNormal => 'Train normally';

  @override
  String get readinessEasy => 'Take it easy';

  @override
  String get readinessRest => 'Rest today';

  @override
  String get readinessAdviceHard =>
      'Your form is good. A hard session fits today.';

  @override
  String get readinessAdviceNormal =>
      'A normal session is fine; keep the hardest intervals for a fresher day.';

  @override
  String get readinessAdviceEasy =>
      'Keep it easy: endurance pace, no hard efforts.';

  @override
  String get readinessAdviceRest =>
      'Rest or move very easily. You are carrying a lot of fatigue.';

  @override
  String get readinessNoData => 'Record a ride to see readiness.';

  @override
  String get readinessLoadOnly =>
      'Add a daily check-in to include how you feel.';

  @override
  String get readinessWhy => 'Why';

  @override
  String get readinessNotMedical => 'A training guide, not a medical measure.';

  @override
  String get readinessFactorForm => 'Form';

  @override
  String get readinessFactorRamp => '7-day ramp';

  @override
  String get readinessFactorRecentLoad => 'Last 2 days';

  @override
  String get readinessFactorWellbeing => 'How you feel';

  @override
  String get readinessFactorRpe => 'Last ride RPE';

  @override
  String get wellbeing => 'Wellbeing';

  @override
  String get wellbeingConsentTitle => 'Before you start';

  @override
  String get wellbeingConsentBody =>
      'Velomine stores a short daily check-in and the RPE you add to rides. It is health data: nobody else sees it unless you share it with your coaches, and you can export or delete it at any time. It is not medical advice.';

  @override
  String get wellbeingConsentAction => 'I agree';

  @override
  String get wellbeingWithdrawConsent => 'Withdraw consent';

  @override
  String get wellbeingToday => 'How do you feel today?';

  @override
  String get wellbeingSaved => 'Today\'s check-in';

  @override
  String get wellbeingEdit => 'Edit today';

  @override
  String get wellbeingSave => 'Save check-in';

  @override
  String get wellbeingFatigue => 'Fatigue';

  @override
  String get wellbeingSoreness => 'Soreness';

  @override
  String get wellbeingMood => 'Mood';

  @override
  String get wellbeingStress => 'Stress';

  @override
  String get wellbeingMotivation => 'Motivation';

  @override
  String get wellbeingShortFatigue => 'Fat';

  @override
  String get wellbeingShortSoreness => 'Sor';

  @override
  String get wellbeingShortMood => 'Mood';

  @override
  String get wellbeingShortStress => 'Str';

  @override
  String get wellbeingShortMotivation => 'Mot';

  @override
  String get wellbeingHistory => 'Last 30 days';

  @override
  String get wellbeingNoHistory => 'No check-ins yet.';

  @override
  String get wellbeingRpe => 'How hard was it?';

  @override
  String get wellbeingRpeHint => '1 easy, 10 maximal';

  @override
  String get wellbeingNotes => 'Notes (optional)';

  @override
  String get wellbeingRpeSave => 'Save';

  @override
  String wellbeingRpeSaved(int rpe) {
    return 'RPE $rpe/10';
  }

  @override
  String get wellbeingRpeDelete => 'Remove';

  @override
  String get wellbeingConsentNeeded =>
      'Set up wellbeing in Progress to add how a ride felt.';

  @override
  String get shareWellbeing => 'Wellbeing';

  @override
  String get shareWellbeingHelper =>
      'Check-in scores and ride RPE; notes stay private.';

  @override
  String get sharesWellbeing => 'Wellbeing';

  @override
  String get viewPowerCurve => 'Power curve';

  @override
  String get viewWellbeing => 'Wellbeing';

  @override
  String get powerCurve => 'Power curve';

  @override
  String get powerCurveEmpty =>
      'No power data in this range. Upload a ride with a power meter.';

  @override
  String get powerBestEfforts => 'Best efforts';

  @override
  String get ftpEstimate => 'Estimated FTP';

  @override
  String get ftpCurrent => 'Current FTP';

  @override
  String get ftpMethod20 => '95 % of your best 20-minute power';

  @override
  String get ftpMethod8 => '90 % of your best 8-minute power';

  @override
  String ftpUse(int watts) {
    return 'Use $watts W';
  }

  @override
  String get vo2MaxEstimate => 'VO2max estimate';

  @override
  String get vo2MaxFrom5Min => 'from your best 5-minute power and weight';

  @override
  String get vo2MaxNeedsWeight => 'Set your weight to estimate VO2max.';

  @override
  String get vo2MaxNeedsEffort =>
      'A 5-minute effort is needed to estimate VO2max.';

  @override
  String get coachWellbeing => 'Wellbeing';

  @override
  String get coachWellbeingEmpty =>
      'Wellbeing was shared, but there are no check-ins yet.';

  @override
  String get coachWellbeingNoNotes =>
      'Scores and RPE only. Notes stay private.';

  @override
  String get coachPowerCurve => 'Power curve';

  @override
  String get rideFilterAll => 'All';

  @override
  String get rideFilterSearch => 'Search rides';

  @override
  String get rideFilterSearchHint => 'Search titles and descriptions';

  @override
  String get rideFilterClearSearch => 'Clear search';

  @override
  String get rideFilterDatesTooltip => 'Choose dates';

  @override
  String get rideFilterRemoveDates => 'Remove the date filter';

  @override
  String get rideFilterClear => 'Clear filters';

  @override
  String get noRidesMatch => 'No rides match.';

  @override
  String rideDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String rideDefaultTitle(String period, String kind) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'morning': 'Morning',
      'afternoon': 'Afternoon',
      'evening': 'Evening',
      'other': 'Night',
    });
    String _temp1 = intl.Intl.selectLogic(kind, {
      'commute': 'commute',
      'virtual': 'virtual ride',
      'indoor': 'indoor ride',
      'road': 'road ride',
      'gravel': 'gravel ride',
      'mountain': 'mountain bike ride',
      'track': 'track ride',
      'ebike': 'e-bike ride',
      'other': 'ride',
    });
    return '$_temp0 $_temp1';
  }

  @override
  String get rideTextEdit => 'Edit title and description';

  @override
  String get rideTextSheetTitle => 'Name this ride';

  @override
  String get rideTextHelp =>
      'Your own words. Coaches you share rides with can read them.';

  @override
  String get rideTextTitle => 'Title';

  @override
  String get rideTextTitleHelper =>
      'Leave empty for a name made from the time and type of ride.';

  @override
  String get rideTextDescription => 'Description';

  @override
  String get rideTextAdd => 'Add a description';

  @override
  String get actionSaveRideDetails => 'save the title and description';

  @override
  String rideViewedBy(String name, String when) {
    return 'Seen by $name · $when';
  }

  @override
  String get rideViewsEmpty => 'Nobody else has looked at this ride.';

  @override
  String get rideTypeTitle => 'Ride details';

  @override
  String get rideTypeHelp =>
      'What kind of ride was it? Everything here is optional.';

  @override
  String get rideTypeDiscipline => 'Surface';

  @override
  String get rideTypeAssist => 'E-bike';

  @override
  String get rideTypeEnvironment => 'Where';

  @override
  String get rideTypeCommute => 'Commute';

  @override
  String get rideTypeNotSet => 'Set ride details';

  @override
  String get rideTypeEdit => 'Edit ride details';

  @override
  String get rideTypeUnset => 'Not set';

  @override
  String get rideTypeNoAssist => 'No e-bike';

  @override
  String get rideTypeOutdoor => 'Outdoor';

  @override
  String get rideTypeIndoor => 'Indoor';

  @override
  String get rideTypeVirtual => 'Virtual';

  @override
  String get actionChangeRideType => 'change this ride\'s details';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get lapsTitle => 'Laps';

  @override
  String get lap => 'Lap';

  @override
  String get recorderRideType => 'Ride type';

  @override
  String get done => 'Done';

  @override
  String get recorderSettings => 'Recording settings';

  @override
  String get recorderEbike => 'E-bike';

  @override
  String get recorderEbikeHelp => 'Counts as assisted and prefers your e-bike.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Reset your password';

  @override
  String get forgotPasswordHelp =>
      'Enter the email address of your account. If it can be reset, we will send a link.';

  @override
  String get forgotPasswordSent =>
      'If an account exists for that address, we sent a link to reset the password. Check your spam folder too.';

  @override
  String get forgotPasswordUnavailable =>
      'This server is not set up to send email. Ask your club admin to reset your password.';

  @override
  String get forgotPasswordTooMany =>
      'Too many attempts. Try again in a few minutes.';

  @override
  String get forgotPasswordFailed => 'Could not start the reset. Try again.';

  @override
  String get errorEnterEmail => 'Enter your email address.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get resetPasswordTitle => 'Choose a new password';

  @override
  String get resetPasswordHelp =>
      'Choose a password of at least 10 characters.';

  @override
  String get setNewPassword => 'Set new password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordsDoNotMatch => 'The two passwords are not the same.';

  @override
  String get passwordTooShort => 'Use at least 10 characters.';

  @override
  String get resetPasswordInvalid =>
      'This link is not valid or has expired. Ask for a new one.';

  @override
  String get resetPasswordDone =>
      'Your password is changed. Sign in with the new one.';

  @override
  String get goToSignIn => 'Go to sign in';

  @override
  String get changePassword => 'Change password';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get passwordWrongCurrent => 'The current password is not right.';

  @override
  String get passwordNoPassword => 'This account signs in with single sign-on.';

  @override
  String get passwordChanged =>
      'Your password is changed. Sign in again on this device.';

  @override
  String get passwordChangeFailed =>
      'Could not change the password. Try again.';

  @override
  String get actionChangePassword => 'change your password';

  @override
  String get actionResetPassword => 'reset this password';

  @override
  String get resetPasswordLink => 'Reset password';

  @override
  String resetPasswordLinkTitle(String name) {
    return 'Password reset link for $name';
  }

  @override
  String get resetPasswordLinkHelp =>
      'Send this link to the member. It works once and expires in 30 minutes.';

  @override
  String get copyLink => 'Copy link';

  @override
  String get linkCopied => 'Copied';

  @override
  String get resetPasswordLinkFailed =>
      'Could not make a reset link. Try again.';

  @override
  String get actionLoadNearbyClubs => 'find clubs near you';

  @override
  String get actionRequestJoinClub => 'ask to join the club';

  @override
  String get actionCancelJoinRequest => 'cancel your request';

  @override
  String get actionLoadJoinRequests => 'load the join requests';

  @override
  String get actionApproveJoinRequest => 'approve the request';

  @override
  String get actionDeclineJoinRequest => 'decline the request';

  @override
  String get actionLoadSecurity => 'load your sign-in settings';

  @override
  String get actionChangeSecurity => 'change your sign-in settings';

  @override
  String get clubSeeNearby => 'See clubs near you';

  @override
  String get clubLocation => 'Club location';

  @override
  String get clubLocationHelp =>
      'Where the club meets. Only used to show the club to riders nearby.';

  @override
  String get clubLocationNone => 'No location yet';

  @override
  String get clubLocationSet => 'Choose on the map';

  @override
  String get clubLocationChange => 'Change location';

  @override
  String get clubDiscoverable => 'Show this club to riders nearby';

  @override
  String get clubDiscoverableHelp =>
      'Riders without a club can find it by distance and ask to join.';

  @override
  String get locationPickerTitle => 'Pick a point';

  @override
  String get locationPickerHelp =>
      'Drag the map until the pin is on the place.';

  @override
  String get locationPickerUse => 'Use this point';

  @override
  String get locationPickerCurrent => 'Use my current location';

  @override
  String get locationCurrentUnavailable =>
      'Your device did not share its position.';

  @override
  String get locationMapFirst => 'Drag the map to the place first.';

  @override
  String get nearbyTitle => 'Clubs near you';

  @override
  String get nearbyIntro =>
      'Ride at your own pace. Join a club whenever you want; you can leave any time and your rides stay yours.';

  @override
  String get nearbyLocating => 'Finding your position…';

  @override
  String get nearbyLocationHelp =>
      'Your position is used only to sort clubs by distance and is not kept on the server.';

  @override
  String get nearbyUseDevice => 'Use my position';

  @override
  String get nearbySetHome => 'Set a location';

  @override
  String get nearbyHomeUsed => 'Using your saved location.';

  @override
  String nearbyRadius(int km) {
    return 'Within $km km';
  }

  @override
  String nearbyEmpty(int km) {
    return 'No clubs within $km km. Ride on your own for now, or look farther.';
  }

  @override
  String nearbyDistance(int km) {
    return '~$km km';
  }

  @override
  String get nearbyAsk => 'Ask to join';

  @override
  String get nearbyRequested => 'Requested';

  @override
  String get nearbyCancel => 'Cancel request';

  @override
  String nearbyRequestTitle(String club) {
    return 'Ask to join $club';
  }

  @override
  String get nearbyRequestNote => 'A word for the owner (optional)';

  @override
  String get nearbyRequestSend => 'Send request';

  @override
  String get nearbyRequestSent =>
      'Request sent. The owner decides when they can.';

  @override
  String nearbyPendingTitle(String club) {
    return 'Waiting for $club';
  }

  @override
  String get nearbyPendingBody => 'Your request is with the club\'s owner.';

  @override
  String get nearbyWiden => 'Look farther';

  @override
  String nearbyReplaceTitle(String club) {
    return 'Withdraw your request to $club?';
  }

  @override
  String get nearbyReplaceBody =>
      'You can have one open request. Asking another club withdraws this one.';

  @override
  String get soloHintTitle => 'Ride at your own pace';

  @override
  String get soloHintBody => 'There are clubs near you when you want one.';

  @override
  String get soloHintSee => 'See clubs';

  @override
  String get soloHintDismiss => 'Not now';

  @override
  String get joinRequestsTitle => 'Join requests';

  @override
  String get joinRequestsEmpty => 'No one is waiting to join.';

  @override
  String get joinRequestApprove => 'Approve';

  @override
  String get joinRequestDecline => 'Decline';

  @override
  String joinRequestApproveTitle(String name) {
    return 'Let $name in?';
  }

  @override
  String get joinRequestApproveBody =>
      'They become a rider. Your rides stay yours; sharing is still their choice.';

  @override
  String joinRequestDeclineTitle(String name) {
    return 'Decline $name?';
  }

  @override
  String get joinRequestDeclineBody => 'They are told, without a reason.';

  @override
  String notificationClubJoinRequest(String name) {
    return '$name asked to join your club.';
  }

  @override
  String notificationClubJoinApproved(String club) {
    return '$club accepted you. Welcome!';
  }

  @override
  String notificationClubJoinDeclined(String club) {
    return '$club declined your request.';
  }

  @override
  String get actionLoadTemplates => 'load your build templates';

  @override
  String get actionSaveTemplate => 'save the build template';

  @override
  String get actionApplyTemplate => 'apply the build template';

  @override
  String get saveAsTemplate => 'Save as build template';

  @override
  String get applyTemplate => 'Apply a build template';

  @override
  String get saveTemplateTitle => 'Save this bike\'s parts as a template';

  @override
  String get templateName => 'Template name';

  @override
  String get templateNameHint => 'For example: Gravel build, 2024';

  @override
  String templateParts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parts',
      one: '1 part',
    );
    return '$_temp0';
  }

  @override
  String get noTemplates =>
      'No build templates yet. Save a bike\'s parts as a template to reuse them.';

  @override
  String get applyTemplateTitle => 'Apply a build template';

  @override
  String get templateApplied => 'Build template applied.';

  @override
  String get errorTemplateName => 'Give the template a name.';

  @override
  String get sharedCatalogue => 'Shared parts catalogue';

  @override
  String get shareParts => 'Share new parts with the shared catalogue';

  @override
  String get sharePartsHelp =>
      'Non-custom parts that the shared catalogue does not list are sent to the publisher. Custom parts stay only on your bike.';

  @override
  String get catalogueNotConfigured =>
      'This server has no contribution endpoint configured, so nothing is sent.';

  @override
  String catalogueVersion(int version, String date) {
    return 'Catalogue version $version, last checked $date';
  }

  @override
  String get catalogueNeverSynced =>
      'The shared catalogue has not been checked yet.';

  @override
  String catalogueSynced(String date) {
    return 'Shared catalogue last checked $date';
  }

  @override
  String get catalogueConflicts =>
      'Parts that differ from the shared catalogue';

  @override
  String get keepMine => 'Keep mine';

  @override
  String get useShared => 'Use shared';

  @override
  String contributionCounts(int pending, int sent, int rejected, int failed) {
    return '$pending waiting · $sent sent · $rejected rejected · $failed failed';
  }

  @override
  String get catalogueProblems => 'Parts the shared catalogue did not take';

  @override
  String get contributionRejected => 'Rejected';

  @override
  String get contributionFailed => 'Gave up';

  @override
  String get custom => 'Custom part';

  @override
  String get customPart => 'Custom';

  @override
  String get customHelper =>
      'Keep this part out of the shared catalogue; it will not be sent to the publisher.';

  @override
  String get privacy => 'Privacy';

  @override
  String get profileAthlete => 'Athlete';

  @override
  String get telemetryHelp =>
      'Help improve Velomine with anonymous crash reports and performance data. Nothing you record is ever included.';

  @override
  String get crashReports => 'Crash reports';

  @override
  String get crashReportsHelp =>
      'Stack traces and app version, so a bug can be fixed.';

  @override
  String get usageData => 'Performance and usage data';

  @override
  String get usageDataHelp =>
      'Slow screens and which features are used, without your rides or health data.';

  @override
  String get telemetryUnavailable => 'This server does not collect telemetry.';

  @override
  String get telemetrySaved => 'Saved.';

  @override
  String get telemetryRestart => 'Restart the app to apply this choice.';

  @override
  String powerCurveSummary(
    String p5s,
    String p1m,
    String p5m,
    String p20m,
    String ftp,
  ) {
    return 'Power curve. Best 5 seconds $p5s watts, 1 minute $p1m, 5 minutes $p5m, 20 minutes $p20m. Estimated FTP $ftp watts.';
  }

  @override
  String routeMapSummary(String distance, String climb) {
    return 'Route map. $distance, with $climb of climbing.';
  }

  @override
  String routeMapDistanceSummary(String distance) {
    return 'Route map. $distance.';
  }

  @override
  String get importFromStrava => 'Import from Strava';

  @override
  String get importStarting => 'Starting import…';

  @override
  String get importTitle => 'Import from Strava';

  @override
  String get importRunning =>
      'Reading your archive. This can take a few minutes.';

  @override
  String importProgress(int done, int total) {
    return '$done of $total activities read';
  }

  @override
  String get importFinished => 'Import finished';

  @override
  String importSummaryImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rides imported',
      one: '1 ride imported',
    );
    return '$_temp0';
  }

  @override
  String importSummaryDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rides were already here',
      one: '1 ride was already here',
    );
    return '$_temp0';
  }

  @override
  String importSummaryFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files could not be read',
      one: '1 file could not be read',
    );
    return '$_temp0';
  }

  @override
  String importSummarySkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities skipped, not rides or without a file',
      one: '1 activity skipped, not a ride or without a file',
    );
    return '$_temp0';
  }

  @override
  String get importBackToRides => 'Back to rides';

  @override
  String get importErrorNotStrava =>
      'This is not a Strava export: it has no activities.csv.';

  @override
  String get importErrorMissing =>
      'The archive is no longer on the server. Choose it again.';

  @override
  String get importErrorUnknown => 'The archive could not be read.';

  @override
  String get actionImportRides => 'import your rides';

  @override
  String get actionLoadImport => 'check the import';

  @override
  String notificationRideImport(String subject) {
    return 'Your import of $subject has finished.';
  }

  @override
  String get actionStartClub => 'start the club';

  @override
  String get actionSetClubPlan => 'save the club\'s plan';

  @override
  String get startClubButton => 'Start a club';

  @override
  String get startClubTitle => 'Start a club';

  @override
  String get startClubIntro =>
      'Start a club for the people you ride with. You will be its owner and can invite people with a code. You get a month to try it.';

  @override
  String get startClubName => 'Club name';

  @override
  String get startClubNameRequired => 'Give the club a name.';

  @override
  String get startClubAction => 'Start the club';

  @override
  String get clubPlanTitle => 'Plan';

  @override
  String clubPlanMembers(int count, int limit) {
    return '$count of $limit members';
  }

  @override
  String clubPlanPaidUntil(String date) {
    return 'Paid until $date';
  }

  @override
  String get clubPlanFullNotice =>
      'The club is full. To take more members, get in touch to move up to a larger size.';

  @override
  String clubPlanEndedNotice(String date) {
    return 'The club\'s plan ended on $date. Everything keeps working, but new members cannot join until it is renewed. Get in touch to renew it.';
  }

  @override
  String get joinRequestsBlockedFull =>
      'The club is full, so requests cannot be approved yet. Get in touch to move up to a larger size.';

  @override
  String get joinRequestsBlockedEnded =>
      'The club\'s plan has ended, so requests cannot be approved until it is renewed.';

  @override
  String notificationClubPlanEnding(String date) {
    return 'Your club\'s plan ends on $date. Get in touch to renew it.';
  }

  @override
  String notificationClubPlanEnded(String date) {
    return 'Your club\'s plan ended after $date. Members keep everything, but new members cannot join until it is renewed.';
  }

  @override
  String get adminClubCreation => 'Riders can start clubs';

  @override
  String get adminClubCreationHelp =>
      'A signed-in rider without a club can start one. It begins with room for 25 members and a month to try it.';

  @override
  String get adminClubEditPlan => 'Edit plan';

  @override
  String get adminClubLimit => 'Room for';

  @override
  String get adminClubLimitNone => 'More than 150 members (no limit)';

  @override
  String adminClubLimitOption(int count) {
    return 'Up to $count members';
  }

  @override
  String get adminClubPaidUntil => 'Paid until';

  @override
  String get adminClubNoDate => 'No end date';

  @override
  String get adminClubChooseDate => 'Choose a date';

  @override
  String get loading => 'Loading';

  @override
  String get actionLoadServiceLog => 'load the service log';

  @override
  String get actionSaveReminder => 'save the reminder';

  @override
  String get actionRemoveReminder => 'delete the reminder';

  @override
  String get actionCompleteReminder => 'mark the job as done';

  @override
  String get actionSaveServiceEntry => 'save the entry';

  @override
  String get actionRemoveServiceEntry => 'delete the entry';

  @override
  String get service => 'Service';

  @override
  String get serviceRemindersIntro =>
      'Reminders tell you when a job on this bike comes round again, like lubing the chain or topping up sealant. Pick a common one to start.';

  @override
  String get serviceAddReminder => 'Add reminder';

  @override
  String get serviceCommonJobs => 'Common jobs';

  @override
  String get reminderStatusOk => 'Fine';

  @override
  String get reminderStatusSoon => 'Due soon';

  @override
  String get reminderStatusDue => 'Due';

  @override
  String get reminderStatusPaused => 'Paused';

  @override
  String reminderLastDone(String date) {
    return 'Last done $date';
  }

  @override
  String get reminderDone => 'Done';

  @override
  String get reminderDoneSaved => 'Done. It is in the service log.';

  @override
  String get reminderDoneBody =>
      'Counting starts again from the day you pick, and the job goes in the service log.';

  @override
  String doneOnDate(String date) {
    return 'Done on $date';
  }

  @override
  String get reminderPause => 'Pause';

  @override
  String get reminderResume => 'Resume';

  @override
  String get reminderFormAddTitle => 'Add a reminder';

  @override
  String get reminderFormEditTitle => 'Edit reminder';

  @override
  String get reminderName => 'What needs doing?';

  @override
  String get reminderIntervalHelp =>
      'It is due at the first of these. Leave empty what you do not need.';

  @override
  String get reminderErrorName => 'Give the job a name.';

  @override
  String get reminderErrorInterval => 'Set a distance, hours or months.';

  @override
  String get reminderRemoveTitle => 'Delete this reminder?';

  @override
  String get reminderRemoveBody =>
      'The service log keeps what you already did.';

  @override
  String get jobChainLube => 'Lube the chain';

  @override
  String get jobChainWearCheck => 'Check chain wear';

  @override
  String get jobSealantTopUp => 'Top up tyre sealant';

  @override
  String get jobBrakeBleed => 'Bleed the brakes';

  @override
  String get jobForkService => 'Service the fork lowers';

  @override
  String get jobShockService => 'Service the rear shock';

  @override
  String get jobBoltCheck => 'Check bolt torque';

  @override
  String get jobShiftingBattery => 'Charge the electronic shifting';

  @override
  String get serviceLog => 'Service log';

  @override
  String get serviceLogIntro =>
      'Everything done to this bike goes here, with the distance it had at the time.';

  @override
  String get serviceAddEntry => 'Add entry';

  @override
  String entryAtDistance(String distance) {
    return 'at $distance';
  }

  @override
  String get entryAtHome => 'At home';

  @override
  String get entryFormAddTitle => 'Add to the service log';

  @override
  String get entryFormEditTitle => 'Edit entry';

  @override
  String get entryTitleField => 'What was done?';

  @override
  String get entryNotes => 'Notes';

  @override
  String get entryPlace => 'Where';

  @override
  String get entryPlaceHelp =>
      'A shop\'s name. Leave empty if you did it at home.';

  @override
  String get entryCost => 'Cost';

  @override
  String get entryCurrency => 'Currency';

  @override
  String get entryPart => 'About which part?';

  @override
  String get entryNoPart => 'No particular part';

  @override
  String get entryReminder => 'About which reminder?';

  @override
  String get entryNoReminder => 'No particular reminder';

  @override
  String get entryErrorTitle => 'Say what was done.';

  @override
  String get entryErrorCost =>
      'Enter the cost as a number, with a three-letter currency like EUR.';

  @override
  String get entryRemoveTitle => 'Delete this entry?';

  @override
  String get entryRemoveBody =>
      'It is removed from the log. This cannot be undone.';

  @override
  String get entryRemoveDoneBody =>
      'It is removed from the log. The reminder keeps counting from the day it was done.';

  @override
  String get logFilterLabel => 'Show';

  @override
  String get logFilterAll => 'Everything';

  @override
  String get logFilterEmpty => 'Nothing in the log for this part yet.';

  @override
  String get logShowMore => 'Show more';

  @override
  String logReplacedPart(String part) {
    return 'Replaced $part';
  }

  @override
  String logReplacedPartWith(String part, String make) {
    return 'Replaced $part: $make';
  }

  @override
  String get bikeServiceDue => 'Service due';

  @override
  String get bikeServiceSoon => 'Service due soon';

  @override
  String notificationReminderSoon(String subject) {
    return 'Maintenance nearly due: $subject.';
  }

  @override
  String notificationReminderDue(String subject) {
    return 'Maintenance due: $subject.';
  }

  @override
  String get actionLoadRoutes => 'load the club\'s routes';

  @override
  String get actionLoadRoute => 'load this route';

  @override
  String get actionAddRoute => 'add the route';

  @override
  String get actionSaveRoute => 'save the route';

  @override
  String get actionDeleteRoute => 'delete the route';

  @override
  String get actionLoadClubRides => 'load the club\'s rides';

  @override
  String get actionLoadClubRide => 'load this club ride';

  @override
  String get actionSaveClubRide => 'save the club ride';

  @override
  String get actionCancelClubRide => 'cancel the club ride';

  @override
  String get actionJoinClubRide => 'say you are in';

  @override
  String get actionLeaveClubRide => 'take your name off';

  @override
  String get actionLoadCalendarFeed => 'load your calendar address';

  @override
  String get actionSaveCalendarFeed => 'change your calendar address';

  @override
  String get clubRidesTitle => 'Rides';

  @override
  String get clubRidesHelp => 'The club\'s next rides, and who is in.';

  @override
  String get clubRidesSeeAll => 'See all rides';

  @override
  String get clubPlanRide => 'Plan a ride';

  @override
  String get clubRoutesTitle => 'Routes';

  @override
  String get clubRoutesHelp =>
      'Lines the club shares, each one kept by the member who added it.';

  @override
  String get clubRoutesSeeAll => 'See all routes';

  @override
  String get clubAddRoute => 'Add a route';

  @override
  String get clubRoutesEmpty =>
      'No routes yet. Add one from one of your rides or from a GPX file.';

  @override
  String get routesFilterAll => 'All surfaces';

  @override
  String get routesSortNewest => 'Newest';

  @override
  String get routesSortShortest => 'Shortest';

  @override
  String get routesSortLongest => 'Longest';

  @override
  String get routeSurfaceRoad => 'Road';

  @override
  String get routeSurfaceGravel => 'Gravel';

  @override
  String get routeSurfaceMountain => 'Mountain';

  @override
  String get routeSurfaceMixed => 'Mixed';

  @override
  String routeAddedBy(String name) {
    return 'Added by $name';
  }

  @override
  String get routeNotSharedBody =>
      'This route is yours, but it is not in the club library.';

  @override
  String get routeOpenGpx => 'Download GPX';

  @override
  String get routeEdit => 'Edit';

  @override
  String get routeWithdraw => 'Remove from club';

  @override
  String get routeWithdrawConfirmTitle => 'Remove this route from the club?';

  @override
  String get routeWithdrawConfirmBody =>
      'It stays yours and you can share it again at any time.';

  @override
  String get routeShare => 'Share again';

  @override
  String get routeDelete => 'Delete for good';

  @override
  String get routeDeleteConfirmTitle => 'Delete this route?';

  @override
  String get routeDeleteConfirmBody =>
      'The line is gone for good. Club rides that planned it keep their own details.';

  @override
  String get routeOwnerOnly =>
      'Only the member who added this route can change it.';

  @override
  String get addRouteTitle => 'Add a route';

  @override
  String get addRouteHelp =>
      'A route is a line on the map with a name. Nothing about how you rode it is shared.';

  @override
  String get addRouteFromRide => 'From one of my rides';

  @override
  String get addRouteFromFile => 'From a GPX file';

  @override
  String get addRouteChooseFile => 'Choose a GPX file';

  @override
  String get addRouteNoRides =>
      'You have no rides with a map yet. Import a ride first, then come back.';

  @override
  String get addRoutePreview => 'This is the line the club will see';

  @override
  String get addRoutePrivacyNote =>
      'Your privacy zones and your start and end trimming are already applied.';

  @override
  String get addRouteDetails => 'Name and details';

  @override
  String get addRouteName => 'Name';

  @override
  String get addRouteDescription => 'Description (optional)';

  @override
  String get addRouteSurface => 'Surface';

  @override
  String get addRouteSave => 'Add to the club library';

  @override
  String get editRouteTitle => 'Edit the route';

  @override
  String get ridesEmpty =>
      'No rides planned yet. A coach can plan the club\'s next ride.';

  @override
  String get ridesUpcoming => 'Coming up';

  @override
  String get ridesPast => 'Just happened';

  @override
  String get rideCancelled => 'Cancelled';

  @override
  String get rideFull => 'Full';

  @override
  String get rideSignedUp => 'You are in';

  @override
  String rideCountIn(int count) {
    return '$count in';
  }

  @override
  String ridePlacesLeft(int count, int max) {
    return '$count of $max places left';
  }

  @override
  String get ridePaceEasy => 'Easy';

  @override
  String get ridePaceSteady => 'Steady';

  @override
  String get ridePaceFast => 'Fast';

  @override
  String get rideNoDrop => 'No-drop';

  @override
  String ridePlannedBy(String name) {
    return 'Planned by $name';
  }

  @override
  String get rideMeeting => 'Meeting point';

  @override
  String get rideRoute => 'Route';

  @override
  String get rideNotes => 'Notes';

  @override
  String get rideWhoIsIn => 'Who is in';

  @override
  String get rideNobodyIn => 'Nobody is in yet.';

  @override
  String get rideImIn => 'I\'m in';

  @override
  String get rideImOut => 'Take me out';

  @override
  String get rideEdit => 'Edit ride';

  @override
  String get rideCancel => 'Cancel ride';

  @override
  String get rideCancelConfirmTitle => 'Cancel this ride?';

  @override
  String get rideCancelConfirmBody =>
      'The riders who are in get a notification. The ride stays on the calendar, marked cancelled.';

  @override
  String get rideCancelledReason => 'This ride is cancelled.';

  @override
  String get rideFullReason => 'This ride is full.';

  @override
  String get rideStartedReason => 'This ride has already started.';

  @override
  String get planRideTitle => 'Plan a ride';

  @override
  String get editRideTitle => 'Edit the ride';

  @override
  String get rideFormTitle => 'Title';

  @override
  String get rideFormMeetingName => 'Meeting point name';

  @override
  String get rideFormPickMeeting => 'Pick the meeting point on the map';

  @override
  String get rideFormRoute => 'Route (optional)';

  @override
  String get rideFormNoRoute => 'No route';

  @override
  String get rideFormPace => 'Pace';

  @override
  String get rideFormNoDrop => 'No-drop';

  @override
  String get rideFormNotes => 'Notes (optional)';

  @override
  String get rideFormMaxRiders => 'Maximum riders (optional)';

  @override
  String get rideFormSave => 'Save the ride';

  @override
  String get rideFormNeedTitle => 'Give the ride a title.';

  @override
  String get rideFormNeedMeeting => 'Name the meeting point.';

  @override
  String get rideFormNeedPoint => 'Pick the meeting point on the map.';

  @override
  String get rideFormFuture => 'Choose a date and time in the future.';

  @override
  String get rideFormMaxRange =>
      'The limit is a number from 1 to 500, or leave it empty.';

  @override
  String get calendarTitle => 'Calendar subscription';

  @override
  String get calendarHelp =>
      'Subscribe the calendar on your phone or computer to the club\'s rides. The address is private: whoever has it sees the club\'s rides, never who is in.';

  @override
  String get calendarInactive => 'No calendar address yet.';

  @override
  String get calendarActive => 'A calendar address is active.';

  @override
  String get calendarCreate => 'Create the address';

  @override
  String get calendarReplace => 'Replace the address';

  @override
  String get calendarReplaceConfirmTitle => 'Replace the calendar address?';

  @override
  String get calendarReplaceConfirmBody =>
      'The old address stops working at once and your calendar needs the new one.';

  @override
  String get calendarDelete => 'Stop the address';

  @override
  String get calendarDeleteConfirmTitle => 'Stop the calendar address?';

  @override
  String get calendarDeleteConfirmBody =>
      'Your calendar stops updating. You can make a new address at any time.';

  @override
  String get calendarCopy => 'Copy the address';

  @override
  String get calendarAddressCopied => 'Address copied';

  @override
  String get calendarShownOnce =>
      'Copy it now. The server keeps only a hash, so it cannot show the address again; if you lose it, replace it.';

  @override
  String notificationClubRidePlanned(String ride) {
    return '$ride: the club planned a ride.';
  }

  @override
  String notificationClubRideChanged(String ride) {
    return '$ride: the time or the meeting point changed.';
  }

  @override
  String notificationClubRideCancelled(String ride) {
    return '$ride: the ride is cancelled.';
  }
}
