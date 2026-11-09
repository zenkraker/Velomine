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
  String get frameSizeHelper =>
      'In the brand\'s own form: 56, M, S3, 17.5\". Optional.';

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
}
