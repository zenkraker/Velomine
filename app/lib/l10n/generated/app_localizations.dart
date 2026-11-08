import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @navRides.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get navRides;

  /// No description provided for @navRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get navRecord;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @navBikes.
  ///
  /// In en, this message translates to:
  /// **'Bikes'**
  String get navBikes;

  /// No description provided for @navAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsUnread.
  ///
  /// In en, this message translates to:
  /// **'Notifications, {count} unread'**
  String notificationsUnread(int count);

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @themeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Theme: {name}'**
  String themeTooltip(String name);

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow this device'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get themeDark;

  /// No description provided for @languageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Language: {name}'**
  String languageTooltip(String name);

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow this device'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageItalian.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get languageItalian;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @serverLabel.
  ///
  /// In en, this message translates to:
  /// **'Server: {url}'**
  String serverLabel(String url);

  /// No description provided for @continueWith.
  ///
  /// In en, this message translates to:
  /// **'Continue with {provider}'**
  String continueWith(String provider);

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// No description provided for @createAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountAction;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get haveAccount;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters, with a capital letter, a small letter and a digit.'**
  String get passwordHint;

  /// No description provided for @registeredReady.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready. You can sign in now.'**
  String get registeredReady;

  /// No description provided for @registeredPending.
  ///
  /// In en, this message translates to:
  /// **'Your account was created. An admin has to approve it before you can sign in.'**
  String get registeredPending;

  /// No description provided for @authWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'The email or password is not right.'**
  String get authWrongPassword;

  /// No description provided for @authNotApproved.
  ///
  /// In en, this message translates to:
  /// **'Your account is waiting for an admin to approve it.'**
  String get authNotApproved;

  /// No description provided for @authLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong attempts. Try again in a few minutes.'**
  String get authLockedOut;

  /// No description provided for @authSignUpClosed.
  ///
  /// In en, this message translates to:
  /// **'Sign-up is closed on this server.'**
  String get authSignUpClosed;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'The password needs at least 10 characters with a capital letter, a small letter and a digit.'**
  String get authWeakPassword;

  /// No description provided for @authEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'There is already an account with this email.'**
  String get authEmailTaken;

  /// No description provided for @authUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Try again.'**
  String get authUnavailable;

  /// No description provided for @ssoEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Your sign-in provider has not verified your email address.'**
  String get ssoEmailNotVerified;

  /// No description provided for @ssoNoAccount.
  ///
  /// In en, this message translates to:
  /// **'There is no account for you here yet. Ask an admin.'**
  String get ssoNoAccount;

  /// No description provided for @ssoLockedOut.
  ///
  /// In en, this message translates to:
  /// **'This account is locked. Try again in a few minutes.'**
  String get ssoLockedOut;

  /// No description provided for @ssoNoEmail.
  ///
  /// In en, this message translates to:
  /// **'Your sign-in provider did not share an email address.'**
  String get ssoNoEmail;

  /// No description provided for @ssoFailed.
  ///
  /// In en, this message translates to:
  /// **'Single sign-on did not work. Try again.'**
  String get ssoFailed;

  /// No description provided for @ssoGeneric.
  ///
  /// In en, this message translates to:
  /// **'single sign-on'**
  String get ssoGeneric;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing you in…'**
  String get signingIn;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Which server does your club use?'**
  String get setupTitle;

  /// No description provided for @setupServerAddress.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get setupServerAddress;

  /// No description provided for @setupServerHint.
  ///
  /// In en, this message translates to:
  /// **'https://velomine.club.example'**
  String get setupServerHint;

  /// No description provided for @setupInsecure.
  ///
  /// In en, this message translates to:
  /// **'This address is not encrypted. Use it only on a network you trust, or ask your admin for an https address.'**
  String get setupInsecure;

  /// No description provided for @setupChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get setupChecking;

  /// No description provided for @setupConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get setupConnect;

  /// No description provided for @setupHelp.
  ///
  /// In en, this message translates to:
  /// **'Ask your club admin for the address. It usually looks like https://velomine.your-club.example.'**
  String get setupHelp;

  /// No description provided for @setupInvalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter an address that starts with http:// or https://, for example https://velomine.club.example.'**
  String get setupInvalidAddress;

  /// No description provided for @setupUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach a Velomine server at that address. Check the address, and that the phone is on the same network as the server.'**
  String get setupUnreachable;

  /// No description provided for @setupSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the address. Try again.'**
  String get setupSaveFailed;

  /// No description provided for @failureRejected.
  ///
  /// In en, this message translates to:
  /// **'The server did not accept that. Check the values.'**
  String get failureRejected;

  /// No description provided for @failureMissing.
  ///
  /// In en, this message translates to:
  /// **'It no longer exists.'**
  String get failureMissing;

  /// No description provided for @failureConflict.
  ///
  /// In en, this message translates to:
  /// **'That is not allowed.'**
  String get failureConflict;

  /// No description provided for @failureMail.
  ///
  /// In en, this message translates to:
  /// **'The mail server did not accept it. Check the email settings.'**
  String get failureMail;

  /// No description provided for @failureWrongConfirmation.
  ///
  /// In en, this message translates to:
  /// **'That does not match. Nothing was deleted.'**
  String get failureWrongConfirmation;

  /// No description provided for @failureLastAdmin.
  ///
  /// In en, this message translates to:
  /// **'You are the only admin. Make someone else an admin first.'**
  String get failureLastAdmin;

  /// No description provided for @failureUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Try again.'**
  String get failureUnreachable;

  /// No description provided for @failureFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not {action} ({code}). Try again.'**
  String failureFailed(String action, int code);

  /// No description provided for @actionGeneral.
  ///
  /// In en, this message translates to:
  /// **'do that'**
  String get actionGeneral;

  /// No description provided for @actionLoadRides.
  ///
  /// In en, this message translates to:
  /// **'load your rides'**
  String get actionLoadRides;

  /// No description provided for @actionUploadRide.
  ///
  /// In en, this message translates to:
  /// **'upload this file'**
  String get actionUploadRide;

  /// No description provided for @actionLoadRide.
  ///
  /// In en, this message translates to:
  /// **'load this ride'**
  String get actionLoadRide;

  /// No description provided for @actionChangeRideBike.
  ///
  /// In en, this message translates to:
  /// **'change the bike'**
  String get actionChangeRideBike;

  /// No description provided for @actionDeleteRide.
  ///
  /// In en, this message translates to:
  /// **'delete the ride'**
  String get actionDeleteRide;

  /// No description provided for @actionLoadBikes.
  ///
  /// In en, this message translates to:
  /// **'load your bikes'**
  String get actionLoadBikes;

  /// No description provided for @actionAddBike.
  ///
  /// In en, this message translates to:
  /// **'add the bike'**
  String get actionAddBike;

  /// No description provided for @actionLoadBike.
  ///
  /// In en, this message translates to:
  /// **'load this bike'**
  String get actionLoadBike;

  /// No description provided for @actionSaveBike.
  ///
  /// In en, this message translates to:
  /// **'save the bike'**
  String get actionSaveBike;

  /// No description provided for @actionSetDefaultBike.
  ///
  /// In en, this message translates to:
  /// **'set the default'**
  String get actionSetDefaultBike;

  /// No description provided for @actionDeleteBike.
  ///
  /// In en, this message translates to:
  /// **'delete the bike'**
  String get actionDeleteBike;

  /// No description provided for @actionAddPart.
  ///
  /// In en, this message translates to:
  /// **'add the part'**
  String get actionAddPart;

  /// No description provided for @actionSavePart.
  ///
  /// In en, this message translates to:
  /// **'save the part'**
  String get actionSavePart;

  /// No description provided for @actionRemovePart.
  ///
  /// In en, this message translates to:
  /// **'remove the part'**
  String get actionRemovePart;

  /// No description provided for @actionLoadProgress.
  ///
  /// In en, this message translates to:
  /// **'load your progress'**
  String get actionLoadProgress;

  /// No description provided for @actionAddGoal.
  ///
  /// In en, this message translates to:
  /// **'add the goal'**
  String get actionAddGoal;

  /// No description provided for @actionChangeGoal.
  ///
  /// In en, this message translates to:
  /// **'change the goal'**
  String get actionChangeGoal;

  /// No description provided for @actionDeleteGoal.
  ///
  /// In en, this message translates to:
  /// **'delete the goal'**
  String get actionDeleteGoal;

  /// No description provided for @actionLoadAdmin.
  ///
  /// In en, this message translates to:
  /// **'load the admin pages'**
  String get actionLoadAdmin;

  /// No description provided for @actionReloadAccounts.
  ///
  /// In en, this message translates to:
  /// **'reload the accounts'**
  String get actionReloadAccounts;

  /// No description provided for @actionApproveAccount.
  ///
  /// In en, this message translates to:
  /// **'approve the account'**
  String get actionApproveAccount;

  /// No description provided for @actionChangeRoles.
  ///
  /// In en, this message translates to:
  /// **'change the roles'**
  String get actionChangeRoles;

  /// No description provided for @actionLockAccount.
  ///
  /// In en, this message translates to:
  /// **'lock the account'**
  String get actionLockAccount;

  /// No description provided for @actionUnlockAccount.
  ///
  /// In en, this message translates to:
  /// **'unlock the account'**
  String get actionUnlockAccount;

  /// No description provided for @actionDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'delete the account'**
  String get actionDeleteAccount;

  /// No description provided for @actionSendTestEmail.
  ///
  /// In en, this message translates to:
  /// **'send the test email'**
  String get actionSendTestEmail;

  /// No description provided for @actionSaveSettings.
  ///
  /// In en, this message translates to:
  /// **'save the settings'**
  String get actionSaveSettings;

  /// No description provided for @actionLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'load your profile'**
  String get actionLoadProfile;

  /// No description provided for @actionPrepareData.
  ///
  /// In en, this message translates to:
  /// **'prepare your data'**
  String get actionPrepareData;

  /// No description provided for @actionSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'save your profile'**
  String get actionSaveProfile;

  /// No description provided for @actionLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'load your notifications'**
  String get actionLoadNotifications;

  /// No description provided for @actionMarkRead.
  ///
  /// In en, this message translates to:
  /// **'mark it read'**
  String get actionMarkRead;

  /// No description provided for @actionMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'mark them read'**
  String get actionMarkAllRead;

  /// No description provided for @notificationRideReady.
  ///
  /// In en, this message translates to:
  /// **'Your ride {subject} is ready.'**
  String notificationRideReady(String subject);

  /// No description provided for @notificationRideFailed.
  ///
  /// In en, this message translates to:
  /// **'{subject} could not be read.'**
  String notificationRideFailed(String subject);

  /// No description provided for @notificationRideDuplicate.
  ///
  /// In en, this message translates to:
  /// **'{subject} was already uploaded, so it is hidden.'**
  String notificationRideDuplicate(String subject);

  /// No description provided for @notificationSignupWaiting.
  ///
  /// In en, this message translates to:
  /// **'{subject} signed up and is waiting for approval.'**
  String notificationSignupWaiting(String subject);

  /// No description provided for @notificationPartSoon.
  ///
  /// In en, this message translates to:
  /// **'{subject} is nearly worn.'**
  String notificationPartSoon(String subject);

  /// No description provided for @notificationPartWorn.
  ///
  /// In en, this message translates to:
  /// **'{subject} is worn out. Time to replace it.'**
  String notificationPartWorn(String subject);

  /// No description provided for @rideErrorCorrupt.
  ///
  /// In en, this message translates to:
  /// **'The file is damaged or incomplete.'**
  String get rideErrorCorrupt;

  /// No description provided for @rideErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'This is not a ride file.'**
  String get rideErrorInvalid;

  /// No description provided for @rideErrorUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Only FIT, GPX and TCX files are supported.'**
  String get rideErrorUnsupported;

  /// No description provided for @rideErrorNotCycling.
  ///
  /// In en, this message translates to:
  /// **'This is not a cycling activity.'**
  String get rideErrorNotCycling;

  /// No description provided for @rideErrorNoTimestamps.
  ///
  /// In en, this message translates to:
  /// **'The file has no timestamps.'**
  String get rideErrorNoTimestamps;

  /// No description provided for @rideErrorNoRecords.
  ///
  /// In en, this message translates to:
  /// **'The file has no usable ride data.'**
  String get rideErrorNoRecords;

  /// No description provided for @rideErrorTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The file is too large.'**
  String get rideErrorTooLarge;

  /// No description provided for @rideErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'The server could not read this file.'**
  String get rideErrorUnknown;

  /// No description provided for @uploadRide.
  ///
  /// In en, this message translates to:
  /// **'Upload ride'**
  String get uploadRide;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploading;

  /// No description provided for @noRides.
  ///
  /// In en, this message translates to:
  /// **'No rides yet. Upload a FIT, GPX or TCX file.'**
  String get noRides;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @readingFile.
  ///
  /// In en, this message translates to:
  /// **'Reading the file…'**
  String get readingFile;

  /// No description provided for @metresUp.
  ///
  /// In en, this message translates to:
  /// **'{metres} m up'**
  String metresUp(int metres);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteRideTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this ride?'**
  String get deleteRideTitle;

  /// No description provided for @deleteRideBody.
  ///
  /// In en, this message translates to:
  /// **'The ride, its charts and the file you uploaded are removed. This cannot be undone.'**
  String get deleteRideBody;

  /// No description provided for @keepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get keepIt;

  /// No description provided for @rideNotFound.
  ///
  /// In en, this message translates to:
  /// **'This ride does not exist, or it is not yours.'**
  String get rideNotFound;

  /// No description provided for @couldNotLoadRide.
  ///
  /// In en, this message translates to:
  /// **'Could not load this ride.'**
  String get couldNotLoadRide;

  /// No description provided for @trainingHint.
  ///
  /// In en, this message translates to:
  /// **'Set your maximum heart rate and FTP in your profile to see zones and training load.'**
  String get trainingHint;

  /// No description provided for @heartRateZones.
  ///
  /// In en, this message translates to:
  /// **'Heart rate zones'**
  String get heartRateZones;

  /// No description provided for @powerZones.
  ///
  /// In en, this message translates to:
  /// **'Power zones'**
  String get powerZones;

  /// No description provided for @momentHint.
  ///
  /// In en, this message translates to:
  /// **'Move over a chart, or touch and drag, to see the values along the ride.'**
  String get momentHint;

  /// No description provided for @momentAt.
  ///
  /// In en, this message translates to:
  /// **'At {time}{distance}'**
  String momentAt(String time, String distance);

  /// No description provided for @statDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get statDistance;

  /// No description provided for @statMovingTime.
  ///
  /// In en, this message translates to:
  /// **'Moving time'**
  String get statMovingTime;

  /// No description provided for @statElapsedTime.
  ///
  /// In en, this message translates to:
  /// **'Elapsed time'**
  String get statElapsedTime;

  /// No description provided for @statClimbing.
  ///
  /// In en, this message translates to:
  /// **'Climbing'**
  String get statClimbing;

  /// No description provided for @statDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get statDescending;

  /// No description provided for @statAverageSpeed.
  ///
  /// In en, this message translates to:
  /// **'Average speed'**
  String get statAverageSpeed;

  /// No description provided for @statTopSpeed.
  ///
  /// In en, this message translates to:
  /// **'Top speed'**
  String get statTopSpeed;

  /// No description provided for @statAveragePower.
  ///
  /// In en, this message translates to:
  /// **'Average power'**
  String get statAveragePower;

  /// No description provided for @statNormalizedPower.
  ///
  /// In en, this message translates to:
  /// **'Normalized power'**
  String get statNormalizedPower;

  /// No description provided for @statMaxPower.
  ///
  /// In en, this message translates to:
  /// **'Max power'**
  String get statMaxPower;

  /// No description provided for @statIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get statIntensity;

  /// No description provided for @statTss.
  ///
  /// In en, this message translates to:
  /// **'TSS'**
  String get statTss;

  /// No description provided for @statTrimp.
  ///
  /// In en, this message translates to:
  /// **'TRIMP'**
  String get statTrimp;

  /// No description provided for @statAverageHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Average heart rate'**
  String get statAverageHeartRate;

  /// No description provided for @statMaxHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Max heart rate'**
  String get statMaxHeartRate;

  /// No description provided for @statAverageCadence.
  ///
  /// In en, this message translates to:
  /// **'Average cadence'**
  String get statAverageCadence;

  /// No description provided for @speedFromGps.
  ///
  /// In en, this message translates to:
  /// **'Speed is worked out from GPS positions.'**
  String get speedFromGps;

  /// No description provided for @loadHint.
  ///
  /// In en, this message translates to:
  /// **'TSS uses your FTP; TRIMP is time in heart-rate zones. Set both in your profile to see them.'**
  String get loadHint;

  /// No description provided for @zoneSemantics.
  ///
  /// In en, this message translates to:
  /// **'Zone {zone}, {range}, {duration}'**
  String zoneSemantics(int zone, String range, String duration);

  /// No description provided for @zoneRange.
  ///
  /// In en, this message translates to:
  /// **'{from}–{to} {unit}'**
  String zoneRange(int from, int to, String unit);

  /// No description provided for @zoneRangeOpen.
  ///
  /// In en, this message translates to:
  /// **'≥ {from} {unit}'**
  String zoneRangeOpen(int from, String unit);

  /// No description provided for @bike.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get bike;

  /// No description provided for @noBike.
  ///
  /// In en, this message translates to:
  /// **'No bike'**
  String get noBike;

  /// No description provided for @mapOfRoute.
  ///
  /// In en, this message translates to:
  /// **'Map of the route'**
  String get mapOfRoute;

  /// No description provided for @seriesElevation.
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get seriesElevation;

  /// No description provided for @seriesSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get seriesSpeed;

  /// No description provided for @seriesPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get seriesPower;

  /// No description provided for @seriesHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get seriesHeartRate;

  /// No description provided for @seriesCadence.
  ///
  /// In en, this message translates to:
  /// **'Cadence'**
  String get seriesCadence;

  /// No description provided for @chartSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name} chart: lowest {low}, average {average}, highest {high}'**
  String chartSemantics(String name, String low, String average, String high);

  /// No description provided for @chartAverageMax.
  ///
  /// In en, this message translates to:
  /// **'avg {average} · max {max}'**
  String chartAverageMax(String average, String max);

  /// No description provided for @addBike.
  ///
  /// In en, this message translates to:
  /// **'Add bike'**
  String get addBike;

  /// No description provided for @noBikes.
  ///
  /// In en, this message translates to:
  /// **'No bikes yet. Add one to keep track of its distance and the wear on its parts. New rides are given your default bike.'**
  String get noBikes;

  /// No description provided for @defaultBike.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultBike;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @bikeRides.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No rides} =1{1 ride} other{{count} rides}}'**
  String bikeRides(int count);

  /// No description provided for @deleteBikeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this bike?'**
  String get deleteBikeTitle;

  /// No description provided for @deleteBikeBody.
  ///
  /// In en, this message translates to:
  /// **'The bike and its parts are removed. Your rides stay, but they will no longer say which bike you rode. To keep the history, archive the bike instead.'**
  String get deleteBikeBody;

  /// No description provided for @removePartTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the list?'**
  String removePartTitle(String name);

  /// No description provided for @removePartBody.
  ///
  /// In en, this message translates to:
  /// **'Its history is deleted. To keep it, use Replace, which retires the part but keeps its wear.'**
  String get removePartBody;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @bikeNotFound.
  ///
  /// In en, this message translates to:
  /// **'This bike does not exist, or it is not yours.'**
  String get bikeNotFound;

  /// No description provided for @wheelLabel.
  ///
  /// In en, this message translates to:
  /// **'wheel {mm} mm'**
  String wheelLabel(int mm);

  /// No description provided for @statRides.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get statRides;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @makeDefault.
  ///
  /// In en, this message translates to:
  /// **'Make default'**
  String get makeDefault;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @parts.
  ///
  /// In en, this message translates to:
  /// **'Parts'**
  String get parts;

  /// No description provided for @addPartAction.
  ///
  /// In en, this message translates to:
  /// **'Add part'**
  String get addPartAction;

  /// No description provided for @noParts.
  ///
  /// In en, this message translates to:
  /// **'No parts yet. Add the chain, tyres or brake pads to see how worn they are.'**
  String get noParts;

  /// No description provided for @replacedParts.
  ///
  /// In en, this message translates to:
  /// **'Replaced parts'**
  String get replacedParts;

  /// No description provided for @wearReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace it'**
  String get wearReplace;

  /// No description provided for @wearSoon.
  ///
  /// In en, this message translates to:
  /// **'Getting worn'**
  String get wearSoon;

  /// No description provided for @wearReplaced.
  ///
  /// In en, this message translates to:
  /// **'Replaced'**
  String get wearReplaced;

  /// No description provided for @wearGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get wearGood;

  /// No description provided for @wearDistance.
  ///
  /// In en, this message translates to:
  /// **'{used} of {expected} km'**
  String wearDistance(String used, String expected);

  /// No description provided for @wearHours.
  ///
  /// In en, this message translates to:
  /// **'{used} of {expected} h'**
  String wearHours(String used, String expected);

  /// No description provided for @wearMonths.
  ///
  /// In en, this message translates to:
  /// **'{used} of {expected} months'**
  String wearMonths(String used, int expected);

  /// No description provided for @wearNoLimit.
  ///
  /// In en, this message translates to:
  /// **'{distance} · {hours} h, no limit set'**
  String wearNoLimit(String distance, String hours);

  /// No description provided for @wearPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% worn'**
  String wearPercent(int percent);

  /// No description provided for @installedOn.
  ///
  /// In en, this message translates to:
  /// **'Installed {date}'**
  String installedOn(String date);

  /// No description provided for @installedAndRemoved.
  ///
  /// In en, this message translates to:
  /// **'Installed {installed} · removed {removed}'**
  String installedAndRemoved(String installed, String removed);

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @addBikeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a bike'**
  String get addBikeTitle;

  /// No description provided for @editBikeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit bike'**
  String get editBikeTitle;

  /// No description provided for @kind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get kind;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @wheelCircumference.
  ///
  /// In en, this message translates to:
  /// **'Wheel circumference (mm)'**
  String get wheelCircumference;

  /// No description provided for @wheelHelper.
  ///
  /// In en, this message translates to:
  /// **'Typical values below; measure one roll of your own wheel for the exact number.'**
  String get wheelHelper;

  /// No description provided for @initialDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance before Velomine (km)'**
  String get initialDistance;

  /// No description provided for @initialHelper.
  ///
  /// In en, this message translates to:
  /// **'For a bike you already rode. Leave empty for a new one.'**
  String get initialHelper;

  /// No description provided for @purchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase date (optional)'**
  String get purchaseDate;

  /// No description provided for @boughtOn.
  ///
  /// In en, this message translates to:
  /// **'Bought {date}'**
  String boughtOn(String date);

  /// No description provided for @errorBikeName.
  ///
  /// In en, this message translates to:
  /// **'Give the bike a name.'**
  String get errorBikeName;

  /// No description provided for @errorWheelRange.
  ///
  /// In en, this message translates to:
  /// **'The wheel circumference is 1000 to 2600 mm.'**
  String get errorWheelRange;

  /// No description provided for @errorInitialDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance before Velomine must be 0 or more.'**
  String get errorInitialDistance;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @replacePartTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace {name}'**
  String replacePartTitle(String name);

  /// No description provided for @editPartTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit part'**
  String get editPartTitle;

  /// No description provided for @addPartTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a part'**
  String get addPartTitle;

  /// No description provided for @partLabel.
  ///
  /// In en, this message translates to:
  /// **'Part'**
  String get partLabel;

  /// No description provided for @stillOnBike.
  ///
  /// In en, this message translates to:
  /// **'Still on the bike'**
  String get stillOnBike;

  /// No description provided for @removedOn.
  ///
  /// In en, this message translates to:
  /// **'Removed {date}'**
  String removedOn(String date);

  /// No description provided for @putBackOnBike.
  ///
  /// In en, this message translates to:
  /// **'Put it back on the bike'**
  String get putBackOnBike;

  /// No description provided for @partLimitsHelp.
  ///
  /// In en, this message translates to:
  /// **'Replace it when it reaches the first of these limits. Typical values are only a starting point; leave a field empty for no limit.'**
  String get partLimitsHelp;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// No description provided for @errorChoosePart.
  ///
  /// In en, this message translates to:
  /// **'Choose what kind of part it is.'**
  String get errorChoosePart;

  /// No description provided for @errorLimits.
  ///
  /// In en, this message translates to:
  /// **'Limits must be numbers above 0, or empty.'**
  String get errorLimits;

  /// No description provided for @errorRemovedBeforeInstalled.
  ///
  /// In en, this message translates to:
  /// **'It cannot be removed before it was installed.'**
  String get errorRemovedBeforeInstalled;

  /// No description provided for @bikeKindRoad.
  ///
  /// In en, this message translates to:
  /// **'Road'**
  String get bikeKindRoad;

  /// No description provided for @bikeKindGravel.
  ///
  /// In en, this message translates to:
  /// **'Gravel'**
  String get bikeKindGravel;

  /// No description provided for @bikeKindMountain.
  ///
  /// In en, this message translates to:
  /// **'Mountain'**
  String get bikeKindMountain;

  /// No description provided for @bikeKindEbike.
  ///
  /// In en, this message translates to:
  /// **'E-bike'**
  String get bikeKindEbike;

  /// No description provided for @bikeKindTimeTrial.
  ///
  /// In en, this message translates to:
  /// **'Time trial'**
  String get bikeKindTimeTrial;

  /// No description provided for @bikeKindTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get bikeKindTrack;

  /// No description provided for @bikeKindCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get bikeKindCity;

  /// No description provided for @bikeKindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get bikeKindOther;

  /// No description provided for @periodWeeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get periodWeeks;

  /// No description provided for @periodMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get periodMonths;

  /// No description provided for @periodYears.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get periodYears;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get thisYear;

  /// No description provided for @periodWordWeek.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get periodWordWeek;

  /// No description provided for @periodWordMonth.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get periodWordMonth;

  /// No description provided for @periodWordYear.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get periodWordYear;

  /// No description provided for @periodTotals.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No rides} =1{1 ride} other{{count} rides}} · {duration} · {elevation} m climbing'**
  String periodTotals(int count, String duration, int elevation);

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @addGoal.
  ///
  /// In en, this message translates to:
  /// **'Add goal'**
  String get addGoal;

  /// No description provided for @noGoals.
  ///
  /// In en, this message translates to:
  /// **'No goals yet. Set a target for each week, month or year: distance, climbing, riding time or number of rides.'**
  String get noGoals;

  /// No description provided for @goalWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get goalWeekly;

  /// No description provided for @goalMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get goalMonthly;

  /// No description provided for @goalYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get goalYearly;

  /// No description provided for @goalMetricDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get goalMetricDistance;

  /// No description provided for @goalMetricElevation.
  ///
  /// In en, this message translates to:
  /// **'Climbing'**
  String get goalMetricElevation;

  /// No description provided for @goalMetricTime.
  ///
  /// In en, this message translates to:
  /// **'Riding time'**
  String get goalMetricTime;

  /// No description provided for @goalMetricRides.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get goalMetricRides;

  /// No description provided for @goalUnitRides.
  ///
  /// In en, this message translates to:
  /// **'rides'**
  String get goalUnitRides;

  /// No description provided for @goalRideCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No rides} =1{1 ride} other{{count} rides}}'**
  String goalRideCount(int count);

  /// No description provided for @goalChange.
  ///
  /// In en, this message translates to:
  /// **'Change goal'**
  String get goalChange;

  /// No description provided for @goalAdd.
  ///
  /// In en, this message translates to:
  /// **'Add goal'**
  String get goalAdd;

  /// No description provided for @goalEvery.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get goalEvery;

  /// No description provided for @goalEveryWeek.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get goalEveryWeek;

  /// No description provided for @goalEveryMonth.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get goalEveryMonth;

  /// No description provided for @goalEveryYear.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get goalEveryYear;

  /// No description provided for @goalCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get goalCount;

  /// No description provided for @goalTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get goalTarget;

  /// No description provided for @errorGoalTarget.
  ///
  /// In en, this message translates to:
  /// **'Enter a target above 0.'**
  String get errorGoalTarget;

  /// No description provided for @goalTitle.
  ///
  /// In en, this message translates to:
  /// **'{period} {metric}'**
  String goalTitle(String period, String metric);

  /// No description provided for @goalReached.
  ///
  /// In en, this message translates to:
  /// **'Reached'**
  String get goalReached;

  /// No description provided for @goalChangeTarget.
  ///
  /// In en, this message translates to:
  /// **'Change target'**
  String get goalChangeTarget;

  /// No description provided for @goalDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete goal'**
  String get goalDelete;

  /// No description provided for @goalSemantics.
  ///
  /// In en, this message translates to:
  /// **'{metric} goal'**
  String goalSemantics(String metric);

  /// No description provided for @goalProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} of {target} · {percent} %'**
  String goalProgress(String current, String target, int percent);

  /// No description provided for @totalsSemantics.
  ///
  /// In en, this message translates to:
  /// **'Distance per {period}. This {period}: {distance}.'**
  String totalsSemantics(String period, String distance);

  /// No description provided for @trainingLoad.
  ///
  /// In en, this message translates to:
  /// **'Training load'**
  String get trainingLoad;

  /// No description provided for @range30Days.
  ///
  /// In en, this message translates to:
  /// **'30 d'**
  String get range30Days;

  /// No description provided for @range90Days.
  ///
  /// In en, this message translates to:
  /// **'90 d'**
  String get range90Days;

  /// No description provided for @rangeOneYear.
  ///
  /// In en, this message translates to:
  /// **'1 y'**
  String get rangeOneYear;

  /// No description provided for @trainingLoadHint.
  ///
  /// In en, this message translates to:
  /// **'Set your FTP (and maximum heart rate) in your profile, then upload a ride to see training load.'**
  String get trainingLoadHint;

  /// No description provided for @fitnessFatigueForm.
  ///
  /// In en, this message translates to:
  /// **'Fitness, fatigue and form'**
  String get fitnessFatigueForm;

  /// No description provided for @fitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get fitness;

  /// No description provided for @fatigue.
  ///
  /// In en, this message translates to:
  /// **'Fatigue'**
  String get fatigue;

  /// No description provided for @form.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get form;

  /// No description provided for @fitnessSemantics.
  ///
  /// In en, this message translates to:
  /// **'Fitness {fitness}, fatigue {fatigue}, form {form}.'**
  String fitnessSemantics(int fitness, int fatigue, int form);

  /// No description provided for @dailyLoad.
  ///
  /// In en, this message translates to:
  /// **'Daily load (TSS)'**
  String get dailyLoad;

  /// No description provided for @dailyLoadSemantics.
  ///
  /// In en, this message translates to:
  /// **'Daily training stress score for the last {days} days.'**
  String dailyLoadSemantics(int days);

  /// No description provided for @trainingLoadHelp.
  ///
  /// In en, this message translates to:
  /// **'Fitness averages the last 42 days of load, fatigue the last 7. Form is fitness minus fatigue.'**
  String get trainingLoadHelp;

  /// No description provided for @adminAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get adminAccounts;

  /// No description provided for @adminSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get adminSettings;

  /// No description provided for @adminOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminOverview;

  /// No description provided for @deleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteUserTitle(String name);

  /// No description provided for @deleteUserBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the account of {email} for good: their rides, bikes, goals and the ride files. It cannot be undone.'**
  String deleteUserBody(String email);

  /// No description provided for @waitingForApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get waitingForApproval;

  /// No description provided for @nonePending.
  ///
  /// In en, this message translates to:
  /// **'No accounts are waiting for approval.'**
  String get nonePending;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// No description provided for @roleCoach.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get roleCoach;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @actionsFor.
  ///
  /// In en, this message translates to:
  /// **'Actions for {name}'**
  String actionsFor(String name);

  /// No description provided for @changeRoles.
  ///
  /// In en, this message translates to:
  /// **'Change roles'**
  String get changeRoles;

  /// No description provided for @unlockAccount.
  ///
  /// In en, this message translates to:
  /// **'Unlock account'**
  String get unlockAccount;

  /// No description provided for @lockAccount.
  ///
  /// In en, this message translates to:
  /// **'Lock account'**
  String get lockAccount;

  /// No description provided for @deleteAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountAction;

  /// No description provided for @rolesFor.
  ///
  /// In en, this message translates to:
  /// **'Roles for {name}'**
  String rolesFor(String name);

  /// No description provided for @everyAccountMember.
  ///
  /// In en, this message translates to:
  /// **'Every account is a member.'**
  String get everyAccountMember;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get saved;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign-up'**
  String get signUp;

  /// No description provided for @peopleCanCreate.
  ///
  /// In en, this message translates to:
  /// **'People can create accounts'**
  String get peopleCanCreate;

  /// No description provided for @newAccountsApproval.
  ///
  /// In en, this message translates to:
  /// **'New accounts need an admin to approve them'**
  String get newAccountsApproval;

  /// No description provided for @mapBackground.
  ///
  /// In en, this message translates to:
  /// **'Map background'**
  String get mapBackground;

  /// No description provided for @tileAddress.
  ///
  /// In en, this message translates to:
  /// **'Tile address'**
  String get tileAddress;

  /// No description provided for @tileHelper.
  ///
  /// In en, this message translates to:
  /// **'Empty draws the route alone and contacts no map server. Read the provider\'s usage rules first.'**
  String get tileHelper;

  /// No description provided for @creditShown.
  ///
  /// In en, this message translates to:
  /// **'Credit shown on the map'**
  String get creditShown;

  /// No description provided for @envVariables.
  ///
  /// In en, this message translates to:
  /// **'Set with environment variables'**
  String get envVariables;

  /// No description provided for @secretsHelp.
  ///
  /// In en, this message translates to:
  /// **'These hold passwords and secrets, so they are never stored in the database or changed from here. Edit the server\'s environment and restart it.'**
  String get secretsHelp;

  /// No description provided for @sendTestEmail.
  ///
  /// In en, this message translates to:
  /// **'Send a test email to me'**
  String get sendTestEmail;

  /// No description provided for @testEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Test email sent to your own address.'**
  String get testEmailSent;

  /// No description provided for @emailSmtp.
  ///
  /// In en, this message translates to:
  /// **'Email (SMTP)'**
  String get emailSmtp;

  /// No description provided for @smtpDetail.
  ///
  /// In en, this message translates to:
  /// **'{host}:{port} · {security} · from {from}'**
  String smtpDetail(String host, int port, String security, String from);

  /// No description provided for @smtpNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not set up. Set Velomine__Smtp__Host and Velomine__Smtp__From.'**
  String get smtpNotConfigured;

  /// No description provided for @singleSignOn.
  ///
  /// In en, this message translates to:
  /// **'Single sign-on'**
  String get singleSignOn;

  /// No description provided for @ssoDetail.
  ///
  /// In en, this message translates to:
  /// **'{name} · {authority}'**
  String ssoDetail(String name, String authority);

  /// No description provided for @ssoNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not set up. Set Velomine__Sso__Authority, ClientId and ClientSecret.'**
  String get ssoNotConfigured;

  /// No description provided for @statusOn.
  ///
  /// In en, this message translates to:
  /// **'{title}: on'**
  String statusOn(String title);

  /// No description provided for @statusOff.
  ///
  /// In en, this message translates to:
  /// **'{title}: off'**
  String statusOff(String title);

  /// No description provided for @noOverview.
  ///
  /// In en, this message translates to:
  /// **'No overview.'**
  String get noOverview;

  /// No description provided for @noSettings.
  ///
  /// In en, this message translates to:
  /// **'No settings.'**
  String get noSettings;

  /// No description provided for @rideFilesOnDisk.
  ///
  /// In en, this message translates to:
  /// **'Ride files on disk'**
  String get rideFilesOnDisk;

  /// No description provided for @serverVersion.
  ///
  /// In en, this message translates to:
  /// **'Server version'**
  String get serverVersion;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @ftpHelper.
  ///
  /// In en, this message translates to:
  /// **'Functional threshold power. Used for training load and power zones.'**
  String get ftpHelper;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @maxHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Maximum heart rate'**
  String get maxHeartRate;

  /// No description provided for @maxHeartRateHelper.
  ///
  /// In en, this message translates to:
  /// **'Heart rate zones are worked out from it.'**
  String get maxHeartRateHelper;

  /// No description provided for @timeZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get timeZone;

  /// No description provided for @timeZoneHelper.
  ///
  /// In en, this message translates to:
  /// **'Decides which day a ride counts on when its file does not say. Empty means UTC.'**
  String get timeZoneHelper;

  /// No description provided for @firstDayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Weeks start on'**
  String get firstDayOfWeek;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email me my notifications'**
  String get emailNotifications;

  /// No description provided for @emailAvailableHelp.
  ///
  /// In en, this message translates to:
  /// **'A ride that was read, a part that is worn, and so on.'**
  String get emailAvailableHelp;

  /// No description provided for @emailUnavailableHelp.
  ///
  /// In en, this message translates to:
  /// **'This server is not set up to send email, so nothing is sent yet.'**
  String get emailUnavailableHelp;

  /// No description provided for @yourData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get yourData;

  /// No description provided for @yourDataHelp.
  ///
  /// In en, this message translates to:
  /// **'It is yours. Download everything Velomine keeps about you: your details, bikes, goals and rides, with every ride file exactly as you uploaded it.'**
  String get yourDataHelp;

  /// No description provided for @downloadMyData.
  ///
  /// In en, this message translates to:
  /// **'Download my data'**
  String get downloadMyData;

  /// No description provided for @exportStarted.
  ///
  /// In en, this message translates to:
  /// **'Your download has started in your browser. The link works for two minutes.'**
  String get exportStarted;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteMyAccount;

  /// No description provided for @errorEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get errorEnterName;

  /// No description provided for @errorFtp.
  ///
  /// In en, this message translates to:
  /// **'FTP is 30 to 1000 watts.'**
  String get errorFtp;

  /// No description provided for @errorWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight is 20 to 300 kg.'**
  String get errorWeight;

  /// No description provided for @errorMaxHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Maximum heart rate is 100 to 240 bpm.'**
  String get errorMaxHeartRate;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes your account and everything in it for good: your rides and the ride files, bikes, goals and notifications. Download your data first if you want to keep it. It cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @yourPassword.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get yourPassword;

  /// No description provided for @confirmEmail.
  ///
  /// In en, this message translates to:
  /// **'Type your email address to confirm'**
  String get confirmEmail;

  /// No description provided for @deleteEverything.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get deleteEverything;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. You will hear here when a ride has been read, or a part on your bike is nearly worn.'**
  String get noNotifications;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
