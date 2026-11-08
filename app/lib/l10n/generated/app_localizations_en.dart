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
  String get joinInvalid =>
      'That code is not right, or the club is not taking new members.';

  @override
  String get joinAlready => 'Your account is already in a club.';

  @override
  String get clubNoneTitle => 'You are not in a club yet';

  @override
  String get clubNoneBody => 'Join with the code from your club\'s owner.';

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
  String get errorWheelRange => 'The wheel circumference is 1000 to 2600 mm.';

  @override
  String get errorInitialDistance =>
      'Distance before Velomine must be 0 or more.';

  @override
  String get cancel => 'Cancel';

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
  String get mapBackground => 'Map background';

  @override
  String get tileAddress => 'Tile address';

  @override
  String get tileHelper =>
      'Empty draws the route alone and contacts no map server. Read the provider\'s usage rules first.';

  @override
  String get creditShown => 'Credit shown on the map';

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
      'Not set up. Set Velomine__Smtp__Host and Velomine__Smtp__From.';

  @override
  String get singleSignOn => 'Single sign-on';

  @override
  String ssoDetail(String name, String authority) {
    return '$name · $authority';
  }

  @override
  String get ssoNotConfigured =>
      'Not set up. Set Velomine__Sso__Authority, ClientId and ClientSecret.';

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
  String get maxHeartRate => 'Maximum heart rate';

  @override
  String get maxHeartRateHelper => 'Heart rate zones are worked out from it.';

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
  String get errorMaxHeartRate => 'Maximum heart rate is 100 to 240 bpm.';

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
}
