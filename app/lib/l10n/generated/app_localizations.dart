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

  /// No description provided for @navGroupPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get navGroupPersonal;

  /// No description provided for @navGroupClub.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get navGroupClub;

  /// No description provided for @navNoClub.
  ///
  /// In en, this message translates to:
  /// **'No club'**
  String get navNoClub;

  /// No description provided for @eyebrowRides.
  ///
  /// In en, this message translates to:
  /// **'Your rides'**
  String get eyebrowRides;

  /// No description provided for @privacyCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data is yours.'**
  String get privacyCardTitle;

  /// No description provided for @privacyCardBody.
  ///
  /// In en, this message translates to:
  /// **'Private unless you share it.'**
  String get privacyCardBody;

  /// No description provided for @ridesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your rides and races.'**
  String get ridesSubtitle;

  /// No description provided for @ridesImportMenu.
  ///
  /// In en, this message translates to:
  /// **'Add rides'**
  String get ridesImportMenu;

  /// No description provided for @rideDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get rideDetailTitle;

  /// No description provided for @navRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get navRecord;

  /// No description provided for @navRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get navRecording;

  /// No description provided for @navRecordingPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get navRecordingPaused;

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

  /// No description provided for @accountMenu.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountMenu;

  /// No description provided for @recordPermissionHelp.
  ///
  /// In en, this message translates to:
  /// **'Starting asks for your position and shows a notification while the ride records, even with the screen off.'**
  String get recordPermissionHelp;

  /// No description provided for @rideNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get rideNoData;

  /// No description provided for @sessionsNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessionsNavTitle;

  /// No description provided for @twoFactorNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-factor'**
  String get twoFactorNavTitle;

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

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

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

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @unitsMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric (km, kg)'**
  String get unitsMetric;

  /// No description provided for @unitsImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial (miles, lb)'**
  String get unitsImperial;

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

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @staySignedIn.
  ///
  /// In en, this message translates to:
  /// **'Stay logged in'**
  String get staySignedIn;

  /// No description provided for @pressBackAgain.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackAgain;

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

  /// No description provided for @authWrongCode.
  ///
  /// In en, this message translates to:
  /// **'That code did not work. Try the next one.'**
  String get authWrongCode;

  /// No description provided for @twoFactorTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-factor sign-in'**
  String get twoFactorTitle;

  /// No description provided for @twoFactorHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your authenticator app, or one of your recovery codes.'**
  String get twoFactorHelp;

  /// No description provided for @twoFactorCode.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get twoFactorCode;

  /// No description provided for @twoFactorVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get twoFactorVerify;

  /// No description provided for @twoFactorUseAnother.
  ///
  /// In en, this message translates to:
  /// **'Use another account'**
  String get twoFactorUseAnother;

  /// No description provided for @twoFactorStateOn.
  ///
  /// In en, this message translates to:
  /// **'Two-factor sign-in is on.'**
  String get twoFactorStateOn;

  /// No description provided for @twoFactorStateOff.
  ///
  /// In en, this message translates to:
  /// **'Two-factor sign-in is off.'**
  String get twoFactorStateOff;

  /// No description provided for @twoFactorIntro.
  ///
  /// In en, this message translates to:
  /// **'After your password, you enter a code from your authenticator app. It is optional, and you can turn it off again.'**
  String get twoFactorIntro;

  /// No description provided for @twoFactorNoPassword.
  ///
  /// In en, this message translates to:
  /// **'This account signs in with single sign-on, so it already has a second step.'**
  String get twoFactorNoPassword;

  /// No description provided for @twoFactorStart.
  ///
  /// In en, this message translates to:
  /// **'Set up an authenticator'**
  String get twoFactorStart;

  /// No description provided for @twoFactorKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'Type this key into your authenticator app, then enter the code it shows.'**
  String get twoFactorKeyHelp;

  /// No description provided for @twoFactorKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get twoFactorKey;

  /// No description provided for @twoFactorPassword.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get twoFactorPassword;

  /// No description provided for @twoFactorCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code from the app'**
  String get twoFactorCodeLabel;

  /// No description provided for @twoFactorEnable.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get twoFactorEnable;

  /// No description provided for @twoFactorDisable.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get twoFactorDisable;

  /// No description provided for @twoFactorRegenerate.
  ///
  /// In en, this message translates to:
  /// **'New recovery codes'**
  String get twoFactorRegenerate;

  /// No description provided for @twoFactorRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery codes'**
  String get twoFactorRecoveryTitle;

  /// No description provided for @twoFactorRecoveryHelp.
  ///
  /// In en, this message translates to:
  /// **'Save them somewhere safe. Each works once, in place of the app code.'**
  String get twoFactorRecoveryHelp;

  /// No description provided for @twoFactorEnabled.
  ///
  /// In en, this message translates to:
  /// **'Two-factor sign-in is on.'**
  String get twoFactorEnabled;

  /// No description provided for @twoFactorDisabled.
  ///
  /// In en, this message translates to:
  /// **'Two-factor sign-in is off.'**
  String get twoFactorDisabled;

  /// No description provided for @twoFactorCodeWrong.
  ///
  /// In en, this message translates to:
  /// **'That code did not work. Check the clock on your phone and try the next one.'**
  String get twoFactorCodeWrong;

  /// No description provided for @sessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Devices and sessions'**
  String get sessionsTitle;

  /// No description provided for @sessionsIntro.
  ///
  /// In en, this message translates to:
  /// **'Where you are signed in now. Signing a device out asks for the password again there.'**
  String get sessionsIntro;

  /// No description provided for @sessionThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get sessionThisDevice;

  /// No description provided for @sessionLastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get sessionLastUsed;

  /// No description provided for @sessionSince.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get sessionSince;

  /// No description provided for @sessionRevoke.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get sessionRevoke;

  /// No description provided for @sessionLogoutOthers.
  ///
  /// In en, this message translates to:
  /// **'Log out other devices'**
  String get sessionLogoutOthers;

  /// No description provided for @sessionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No other devices are signed in.'**
  String get sessionsEmpty;

  /// No description provided for @sessionRevoked.
  ///
  /// In en, this message translates to:
  /// **'That device is signed out.'**
  String get sessionRevoked;

  /// No description provided for @sessionOthersRevoked.
  ///
  /// In en, this message translates to:
  /// **'Every other device is signed out.'**
  String get sessionOthersRevoked;

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

  /// No description provided for @failureSessionEnded.
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Sign in again.'**
  String get failureSessionEnded;

  /// No description provided for @failureForbidden.
  ///
  /// In en, this message translates to:
  /// **'Your account may not do that.'**
  String get failureForbidden;

  /// No description provided for @failureTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again shortly.'**
  String get failureTooMany;

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

  /// No description provided for @actionSaveWellbeing.
  ///
  /// In en, this message translates to:
  /// **'save how you feel'**
  String get actionSaveWellbeing;

  /// No description provided for @actionSetFtp.
  ///
  /// In en, this message translates to:
  /// **'set your FTP'**
  String get actionSetFtp;

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

  /// No description provided for @actionLoadClub.
  ///
  /// In en, this message translates to:
  /// **'load your club'**
  String get actionLoadClub;

  /// No description provided for @actionJoinClub.
  ///
  /// In en, this message translates to:
  /// **'join the club'**
  String get actionJoinClub;

  /// No description provided for @actionLeaveClub.
  ///
  /// In en, this message translates to:
  /// **'leave the club'**
  String get actionLeaveClub;

  /// No description provided for @actionRotateJoinCode.
  ///
  /// In en, this message translates to:
  /// **'make a new join code'**
  String get actionRotateJoinCode;

  /// No description provided for @actionChangeClubRole.
  ///
  /// In en, this message translates to:
  /// **'change the member\'s role'**
  String get actionChangeClubRole;

  /// No description provided for @actionLoadAdminClubs.
  ///
  /// In en, this message translates to:
  /// **'load the clubs'**
  String get actionLoadAdminClubs;

  /// No description provided for @actionCreateClub.
  ///
  /// In en, this message translates to:
  /// **'create the club'**
  String get actionCreateClub;

  /// No description provided for @actionUpdateClub.
  ///
  /// In en, this message translates to:
  /// **'change the club'**
  String get actionUpdateClub;

  /// No description provided for @actionSetClubOwner.
  ///
  /// In en, this message translates to:
  /// **'name the owner'**
  String get actionSetClubOwner;

  /// No description provided for @actionLoadSharing.
  ///
  /// In en, this message translates to:
  /// **'load your sharing choices'**
  String get actionLoadSharing;

  /// No description provided for @actionSaveSharing.
  ///
  /// In en, this message translates to:
  /// **'save your sharing choices'**
  String get actionSaveSharing;

  /// No description provided for @actionLoadPrivacy.
  ///
  /// In en, this message translates to:
  /// **'load your privacy choices'**
  String get actionLoadPrivacy;

  /// No description provided for @actionSavePrivacy.
  ///
  /// In en, this message translates to:
  /// **'save your privacy choices'**
  String get actionSavePrivacy;

  /// No description provided for @actionLoadAthletes.
  ///
  /// In en, this message translates to:
  /// **'load the athletes'**
  String get actionLoadAthletes;

  /// No description provided for @actionLoadAthlete.
  ///
  /// In en, this message translates to:
  /// **'load the athlete'**
  String get actionLoadAthlete;

  /// No description provided for @actionLoadCoachRide.
  ///
  /// In en, this message translates to:
  /// **'load this ride'**
  String get actionLoadCoachRide;

  /// No description provided for @navClub.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get navClub;

  /// No description provided for @joinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a club'**
  String get joinTitle;

  /// No description provided for @joinIntro.
  ///
  /// In en, this message translates to:
  /// **'Ask your club\'s owner for the join code, or open the link they shared.'**
  String get joinIntro;

  /// No description provided for @joinCode.
  ///
  /// In en, this message translates to:
  /// **'Join code'**
  String get joinCode;

  /// No description provided for @joinAction.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinAction;

  /// No description provided for @joinSkip.
  ///
  /// In en, this message translates to:
  /// **'Continue without a club'**
  String get joinSkip;

  /// No description provided for @joinInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code is not right, or the club is not taking new members.'**
  String get joinInvalid;

  /// No description provided for @joinAlready.
  ///
  /// In en, this message translates to:
  /// **'Your account is already in a club.'**
  String get joinAlready;

  /// No description provided for @clubNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You are not in a club yet'**
  String get clubNoneTitle;

  /// No description provided for @clubNoneBody.
  ///
  /// In en, this message translates to:
  /// **'Velomine works on your own too. Join a club when you want to ride with a group and share with its coaches.'**
  String get clubNoneBody;

  /// No description provided for @clubNoneTitleShort.
  ///
  /// In en, this message translates to:
  /// **'Your club'**
  String get clubNoneTitleShort;

  /// No description provided for @clubNoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ride on your own, or with a club.'**
  String get clubNoneSubtitle;

  /// No description provided for @eyebrowClub.
  ///
  /// In en, this message translates to:
  /// **'Your club'**
  String get eyebrowClub;

  /// No description provided for @clubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your club, its rides and the people in it.'**
  String get clubSubtitle;

  /// No description provided for @clubInactive.
  ///
  /// In en, this message translates to:
  /// **'This club is not active. Joining is closed.'**
  String get clubInactive;

  /// No description provided for @clubOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get clubOwner;

  /// No description provided for @clubCoach.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get clubCoach;

  /// No description provided for @clubMemberRole.
  ///
  /// In en, this message translates to:
  /// **'Rider'**
  String get clubMemberRole;

  /// No description provided for @clubMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get clubMembers;

  /// No description provided for @clubMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String clubMemberCount(int count);

  /// No description provided for @clubJoinCode.
  ///
  /// In en, this message translates to:
  /// **'Join code'**
  String get clubJoinCode;

  /// No description provided for @clubJoinCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Share this code or the link with the people who should join.'**
  String get clubJoinCodeHelp;

  /// No description provided for @clubNewCode.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get clubNewCode;

  /// No description provided for @clubNewCodeConfirm.
  ///
  /// In en, this message translates to:
  /// **'The old code stops working at once. Continue?'**
  String get clubNewCodeConfirm;

  /// No description provided for @clubLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave club'**
  String get clubLeave;

  /// No description provided for @clubLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this club?'**
  String get clubLeaveTitle;

  /// No description provided for @clubLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'You can join again with a new code. Your rides stay yours.'**
  String get clubLeaveBody;

  /// No description provided for @clubOwnerCannotLeave.
  ///
  /// In en, this message translates to:
  /// **'The owner cannot leave. Ask the server admin to name another owner first.'**
  String get clubOwnerCannotLeave;

  /// No description provided for @clubMakeCoach.
  ///
  /// In en, this message translates to:
  /// **'Make coach'**
  String get clubMakeCoach;

  /// No description provided for @clubMakeMember.
  ///
  /// In en, this message translates to:
  /// **'Make rider'**
  String get clubMakeMember;

  /// No description provided for @clubCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get clubCopy;

  /// No description provided for @clubCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get clubCopied;

  /// No description provided for @sharingTitle.
  ///
  /// In en, this message translates to:
  /// **'What you share'**
  String get sharingTitle;

  /// No description provided for @sharingHelp.
  ///
  /// In en, this message translates to:
  /// **'Only what you turn on leaves your account. Your club always sees your name and place in the roster.'**
  String get sharingHelp;

  /// No description provided for @shareRides.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get shareRides;

  /// No description provided for @shareAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get shareAnalytics;

  /// No description provided for @shareRoutes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get shareRoutes;

  /// No description provided for @audienceNone.
  ///
  /// In en, this message translates to:
  /// **'Nobody'**
  String get audienceNone;

  /// No description provided for @audienceCoaches.
  ///
  /// In en, this message translates to:
  /// **'My coaches'**
  String get audienceCoaches;

  /// No description provided for @routesNeedRides.
  ///
  /// In en, this message translates to:
  /// **'Turn on rides first; routes add the map to them.'**
  String get routesNeedRides;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ride privacy'**
  String get privacyTitle;

  /// No description provided for @privacyHelp.
  ///
  /// In en, this message translates to:
  /// **'What other people see when you share a ride or your club can see it. You always see everything.'**
  String get privacyHelp;

  /// No description provided for @privacyOthersSee.
  ///
  /// In en, this message translates to:
  /// **'What others see of each ride'**
  String get privacyOthersSee;

  /// No description provided for @privacyHideHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get privacyHideHeartRate;

  /// No description provided for @privacyHidePower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get privacyHidePower;

  /// No description provided for @privacyHideCadence.
  ///
  /// In en, this message translates to:
  /// **'Cadence'**
  String get privacyHideCadence;

  /// No description provided for @privacyHideSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get privacyHideSpeed;

  /// No description provided for @privacyHideElevation.
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get privacyHideElevation;

  /// No description provided for @privacyHideTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get privacyHideTemperature;

  /// No description provided for @privacyTrimTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide the start and end'**
  String get privacyTrimTitle;

  /// No description provided for @privacyTrimStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get privacyTrimStart;

  /// No description provided for @privacyTrimEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get privacyTrimEnd;

  /// No description provided for @privacyTrimHelp.
  ///
  /// In en, this message translates to:
  /// **'Metres hidden at the start and end of every ride. 0 keeps everything.'**
  String get privacyTrimHelp;

  /// No description provided for @privacyZonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get privacyZonesTitle;

  /// No description provided for @privacyZonesHelp.
  ///
  /// In en, this message translates to:
  /// **'Every ride hides up to a mile around these places, and the route line breaks there. At most ten places.'**
  String get privacyZonesHelp;

  /// No description provided for @privacyZonesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved places yet.'**
  String get privacyZonesEmpty;

  /// No description provided for @privacyAddZone.
  ///
  /// In en, this message translates to:
  /// **'Add a place'**
  String get privacyAddZone;

  /// No description provided for @privacyZoneName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get privacyZoneName;

  /// No description provided for @privacyZoneRadius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get privacyZoneRadius;

  /// No description provided for @privacyZoneRadiusHelp.
  ///
  /// In en, this message translates to:
  /// **'200 to 1609 metres, that is 0.1 to 1.0 miles.'**
  String get privacyZoneRadiusHelp;

  /// No description provided for @privacyZoneDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String privacyZoneDelete(String name);

  /// No description provided for @privacyErrorRadius.
  ///
  /// In en, this message translates to:
  /// **'Choose a radius from 200 to 1609 metres (0.1 to 1.0 miles).'**
  String get privacyErrorRadius;

  /// No description provided for @privacyErrorName.
  ///
  /// In en, this message translates to:
  /// **'Give the place a name.'**
  String get privacyErrorName;

  /// No description provided for @privacyErrorTrim.
  ///
  /// In en, this message translates to:
  /// **'Choose 0 to 5000 metres for each end (0 to 3.1 miles).'**
  String get privacyErrorTrim;

  /// No description provided for @privacyRidePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Ride privacy'**
  String get privacyRidePrivacy;

  /// No description provided for @privacyRidePrivacyHelp.
  ///
  /// In en, this message translates to:
  /// **'What your coach and shared links see.'**
  String get privacyRidePrivacyHelp;

  /// No description provided for @viewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Who looked'**
  String get viewsTitle;

  /// No description provided for @viewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nobody has looked yet.'**
  String get viewsEmpty;

  /// No description provided for @viewSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get viewSummary;

  /// No description provided for @viewTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get viewTraining;

  /// No description provided for @viewRide.
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get viewRide;

  /// No description provided for @viewRides.
  ///
  /// In en, this message translates to:
  /// **'Ride list'**
  String get viewRides;

  /// No description provided for @viewRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get viewRoute;

  /// No description provided for @athletesTitle.
  ///
  /// In en, this message translates to:
  /// **'Athletes'**
  String get athletesTitle;

  /// No description provided for @coachViewAthletes.
  ///
  /// In en, this message translates to:
  /// **'View athletes'**
  String get coachViewAthletes;

  /// No description provided for @athletesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No athletes are sharing with you yet. Members turn sharing on in their Club tab.'**
  String get athletesEmpty;

  /// No description provided for @lastRideOn.
  ///
  /// In en, this message translates to:
  /// **'Last ride {date}'**
  String lastRideOn(String date);

  /// No description provided for @days7.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get days7;

  /// No description provided for @days42.
  ///
  /// In en, this message translates to:
  /// **'42 days'**
  String get days42;

  /// No description provided for @sharesRides.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get sharesRides;

  /// No description provided for @sharesTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get sharesTraining;

  /// No description provided for @sharesRoutes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get sharesRoutes;

  /// No description provided for @coachAthleteNotFound.
  ///
  /// In en, this message translates to:
  /// **'This athlete is not sharing with you.'**
  String get coachAthleteNotFound;

  /// No description provided for @coachRideNotFound.
  ///
  /// In en, this message translates to:
  /// **'This ride is not shared with you.'**
  String get coachRideNotFound;

  /// No description provided for @coachReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Shared by the athlete, read-only.'**
  String get coachReadOnly;

  /// No description provided for @coachNoRides.
  ///
  /// In en, this message translates to:
  /// **'No rides shared yet.'**
  String get coachNoRides;

  /// No description provided for @routeNotShared.
  ///
  /// In en, this message translates to:
  /// **'The athlete has not shared the route.'**
  String get routeNotShared;

  /// No description provided for @adminClubs.
  ///
  /// In en, this message translates to:
  /// **'Clubs'**
  String get adminClubs;

  /// No description provided for @adminCreateClub.
  ///
  /// In en, this message translates to:
  /// **'Create club'**
  String get adminCreateClub;

  /// No description provided for @adminClubName.
  ///
  /// In en, this message translates to:
  /// **'Club name'**
  String get adminClubName;

  /// No description provided for @adminClubOwnerEmail.
  ///
  /// In en, this message translates to:
  /// **'Owner\'s email'**
  String get adminClubOwnerEmail;

  /// No description provided for @adminClubOwnerHelp.
  ///
  /// In en, this message translates to:
  /// **'An existing account, which becomes the club\'s owner.'**
  String get adminClubOwnerHelp;

  /// No description provided for @adminClubActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminClubActive;

  /// No description provided for @adminClubJoinCode.
  ///
  /// In en, this message translates to:
  /// **'Join code'**
  String get adminClubJoinCode;

  /// No description provided for @adminNoClubs.
  ///
  /// In en, this message translates to:
  /// **'No clubs yet. Create the first one.'**
  String get adminNoClubs;

  /// No description provided for @changeOwner.
  ///
  /// In en, this message translates to:
  /// **'Change owner'**
  String get changeOwner;

  /// No description provided for @chooseOwner.
  ///
  /// In en, this message translates to:
  /// **'Choose the new owner'**
  String get chooseOwner;

  /// No description provided for @errorClubName.
  ///
  /// In en, this message translates to:
  /// **'Give the club a name.'**
  String get errorClubName;

  /// No description provided for @errorClubOwner.
  ///
  /// In en, this message translates to:
  /// **'Enter the owner\'s email.'**
  String get errorClubOwner;

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

  /// No description provided for @bulkChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder'**
  String get bulkChooseFolder;

  /// No description provided for @bulkChooseFiles.
  ///
  /// In en, this message translates to:
  /// **'Choose files'**
  String get bulkChooseFiles;

  /// No description provided for @bulkDropTitle.
  ///
  /// In en, this message translates to:
  /// **'Drop to add your rides'**
  String get bulkDropTitle;

  /// No description provided for @bulkDropHint.
  ///
  /// In en, this message translates to:
  /// **'Files or a whole folder: .fit, .gpx and .tcx files are read, also zipped (.gz).'**
  String get bulkDropHint;

  /// No description provided for @bulkTitle.
  ///
  /// In en, this message translates to:
  /// **'Adding rides from files'**
  String get bulkTitle;

  /// No description provided for @bulkScanning.
  ///
  /// In en, this message translates to:
  /// **'Looking through the files…'**
  String get bulkScanning;

  /// No description provided for @bulkProgress.
  ///
  /// In en, this message translates to:
  /// **'Reading {done} of {total}'**
  String bulkProgress(int done, int total);

  /// No description provided for @bulkCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get bulkCancel;

  /// No description provided for @bulkStopping.
  ///
  /// In en, this message translates to:
  /// **'Stopping…'**
  String get bulkStopping;

  /// No description provided for @bulkDone.
  ///
  /// In en, this message translates to:
  /// **'All files read'**
  String get bulkDone;

  /// No description provided for @bulkStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped before the end'**
  String get bulkStopped;

  /// No description provided for @bulkAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No new rides} =1{1 new ride} other{{count} new rides}}'**
  String bulkAdded(int count);

  /// No description provided for @bulkAlreadyHere.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ride was already here} other{{count} rides were already here}}'**
  String bulkAlreadyHere(int count);

  /// No description provided for @bulkUnreadable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file could not be read} other{{count} files could not be read}}'**
  String bulkUnreadable(int count);

  /// No description provided for @bulkSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file skipped: not a ride file} other{{count} files skipped: not ride files}}'**
  String bulkSkipped(int count);

  /// No description provided for @bulkNotRead.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file was not read} other{{count} files were not read}}'**
  String bulkNotRead(int count);

  /// No description provided for @bulkAndMore.
  ///
  /// In en, this message translates to:
  /// **'and {count} more'**
  String bulkAndMore(int count);

  /// No description provided for @bulkClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get bulkClose;

  /// No description provided for @bulkSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Sign in first, then add your rides again.'**
  String get bulkSignedOut;

  /// No description provided for @bulkNothing.
  ///
  /// In en, this message translates to:
  /// **'No ride files found. Velomine reads .fit, .gpx and .tcx files, also zipped (.gz).'**
  String get bulkNothing;

  /// No description provided for @bulkWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting a moment, the server is busy…'**
  String get bulkWaiting;

  /// No description provided for @incomingAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ride added. It will upload in the background.} other{{count} rides added. They will upload in the background.}}'**
  String incomingAdded(int count);

  /// No description provided for @incomingAlreadyHere.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ride was already here.} other{{count} rides were already here.}}'**
  String incomingAlreadyHere(int count);

  /// No description provided for @incomingRejectedOne.
  ///
  /// In en, this message translates to:
  /// **'{name} is not a ride file and was skipped.'**
  String incomingRejectedOne(String name);

  /// No description provided for @incomingRejectedMany.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file is not a ride file and was skipped.} other{{count} files are not ride files and were skipped.}}'**
  String incomingRejectedMany(int count);

  /// No description provided for @incomingSignedOut.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ride is kept. Sign in and it will upload.} other{{count} rides are kept. Sign in and they will upload.}}'**
  String incomingSignedOut(int count);

  /// No description provided for @incomingOpen.
  ///
  /// In en, this message translates to:
  /// **'Ride list'**
  String get incomingOpen;

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

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rideActions.
  ///
  /// In en, this message translates to:
  /// **'Ride actions'**
  String get rideActions;

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

  /// No description provided for @heartRateOnMap.
  ///
  /// In en, this message translates to:
  /// **'Show heart rate on the map'**
  String get heartRateOnMap;

  /// No description provided for @mapHeartRateHint.
  ///
  /// In en, this message translates to:
  /// **'Route colour shows heart rate from {min} to {max} bpm'**
  String mapHeartRateHint(int min, int max);

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

  /// No description provided for @eyebrowBikes.
  ///
  /// In en, this message translates to:
  /// **'Your bikes'**
  String get eyebrowBikes;

  /// No description provided for @bikesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every bike you ride and what it needs.'**
  String get bikesSubtitle;

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

  /// No description provided for @metricTrainingLoad.
  ///
  /// In en, this message translates to:
  /// **'Training load'**
  String get metricTrainingLoad;

  /// No description provided for @metricPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get metricPower;

  /// No description provided for @metricThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'This {period}'**
  String metricThisPeriod(String period);

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
  /// **'{used} of {expected}'**
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

  /// No description provided for @modelYear.
  ///
  /// In en, this message translates to:
  /// **'Model year'**
  String get modelYear;

  /// No description provided for @buildSpec.
  ///
  /// In en, this message translates to:
  /// **'Build or spec'**
  String get buildSpec;

  /// No description provided for @frameSize.
  ///
  /// In en, this message translates to:
  /// **'Frame size'**
  String get frameSize;

  /// No description provided for @modelYearHelper.
  ///
  /// In en, this message translates to:
  /// **'Such as 2023. Optional.'**
  String get modelYearHelper;

  /// No description provided for @buildSpecHelper.
  ///
  /// In en, this message translates to:
  /// **'Such as SL 7, Comp or the groupset name. Optional.'**
  String get buildSpecHelper;

  /// No description provided for @frameSizeHelper.
  ///
  /// In en, this message translates to:
  /// **'56, M or 17.5\".'**
  String get frameSizeHelper;

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

  /// No description provided for @errorModelYear.
  ///
  /// In en, this message translates to:
  /// **'The model year is 1900 to 2100, or empty.'**
  String get errorModelYear;

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

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @openFullMap.
  ///
  /// In en, this message translates to:
  /// **'Open the full map'**
  String get openFullMap;

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

  /// No description provided for @findPart.
  ///
  /// In en, this message translates to:
  /// **'Find a known part'**
  String get findPart;

  /// No description provided for @findPartHint.
  ///
  /// In en, this message translates to:
  /// **'Brand, model or part number'**
  String get findPartHint;

  /// No description provided for @mpn.
  ///
  /// In en, this message translates to:
  /// **'Part number (MPN)'**
  String get mpn;

  /// No description provided for @gtin.
  ///
  /// In en, this message translates to:
  /// **'Barcode (GTIN)'**
  String get gtin;

  /// No description provided for @mpnHelper.
  ///
  /// In en, this message translates to:
  /// **'The code on the part, such as CN-M8100. Optional.'**
  String get mpnHelper;

  /// No description provided for @gtinHelper.
  ///
  /// In en, this message translates to:
  /// **'The number under the barcode on the box. Optional.'**
  String get gtinHelper;

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

  /// No description provided for @errorGtin.
  ///
  /// In en, this message translates to:
  /// **'A GTIN is 8, 12, 13 or 14 digits with a valid check digit.'**
  String get errorGtin;

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

  /// No description provided for @partChain.
  ///
  /// In en, this message translates to:
  /// **'Chain'**
  String get partChain;

  /// No description provided for @partCassette.
  ///
  /// In en, this message translates to:
  /// **'Cassette'**
  String get partCassette;

  /// No description provided for @partChainring.
  ///
  /// In en, this message translates to:
  /// **'Chainring'**
  String get partChainring;

  /// No description provided for @partCrankset.
  ///
  /// In en, this message translates to:
  /// **'Crankset'**
  String get partCrankset;

  /// No description provided for @partBottomBracket.
  ///
  /// In en, this message translates to:
  /// **'Bottom bracket'**
  String get partBottomBracket;

  /// No description provided for @partFrontDerailleur.
  ///
  /// In en, this message translates to:
  /// **'Front derailleur'**
  String get partFrontDerailleur;

  /// No description provided for @partRearDerailleur.
  ///
  /// In en, this message translates to:
  /// **'Rear derailleur'**
  String get partRearDerailleur;

  /// No description provided for @partDerailleurHanger.
  ///
  /// In en, this message translates to:
  /// **'Derailleur hanger'**
  String get partDerailleurHanger;

  /// No description provided for @partShifters.
  ///
  /// In en, this message translates to:
  /// **'Shifters'**
  String get partShifters;

  /// No description provided for @partShiftCables.
  ///
  /// In en, this message translates to:
  /// **'Shift cables'**
  String get partShiftCables;

  /// No description provided for @partPedals.
  ///
  /// In en, this message translates to:
  /// **'Pedals'**
  String get partPedals;

  /// No description provided for @partFrontTire.
  ///
  /// In en, this message translates to:
  /// **'Front tire'**
  String get partFrontTire;

  /// No description provided for @partRearTire.
  ///
  /// In en, this message translates to:
  /// **'Rear tire'**
  String get partRearTire;

  /// No description provided for @partTubelessSealant.
  ///
  /// In en, this message translates to:
  /// **'Tubeless sealant'**
  String get partTubelessSealant;

  /// No description provided for @partInnerTubes.
  ///
  /// In en, this message translates to:
  /// **'Inner tubes'**
  String get partInnerTubes;

  /// No description provided for @partWheelset.
  ///
  /// In en, this message translates to:
  /// **'Wheelset'**
  String get partWheelset;

  /// No description provided for @partHubService.
  ///
  /// In en, this message translates to:
  /// **'Hub service'**
  String get partHubService;

  /// No description provided for @partFrontBrakePads.
  ///
  /// In en, this message translates to:
  /// **'Front brake pads'**
  String get partFrontBrakePads;

  /// No description provided for @partRearBrakePads.
  ///
  /// In en, this message translates to:
  /// **'Rear brake pads'**
  String get partRearBrakePads;

  /// No description provided for @partFrontRotor.
  ///
  /// In en, this message translates to:
  /// **'Front rotor'**
  String get partFrontRotor;

  /// No description provided for @partRearRotor.
  ///
  /// In en, this message translates to:
  /// **'Rear rotor'**
  String get partRearRotor;

  /// No description provided for @partBrakeFluid.
  ///
  /// In en, this message translates to:
  /// **'Brake fluid'**
  String get partBrakeFluid;

  /// No description provided for @partBrakeCables.
  ///
  /// In en, this message translates to:
  /// **'Brake cables'**
  String get partBrakeCables;

  /// No description provided for @partHandlebarTape.
  ///
  /// In en, this message translates to:
  /// **'Handlebar tape or grips'**
  String get partHandlebarTape;

  /// No description provided for @partHandlebar.
  ///
  /// In en, this message translates to:
  /// **'Handlebar'**
  String get partHandlebar;

  /// No description provided for @partStem.
  ///
  /// In en, this message translates to:
  /// **'Stem'**
  String get partStem;

  /// No description provided for @partHeadset.
  ///
  /// In en, this message translates to:
  /// **'Headset'**
  String get partHeadset;

  /// No description provided for @partSaddle.
  ///
  /// In en, this message translates to:
  /// **'Saddle'**
  String get partSaddle;

  /// No description provided for @partSeatpost.
  ///
  /// In en, this message translates to:
  /// **'Seatpost'**
  String get partSeatpost;

  /// No description provided for @partForkService.
  ///
  /// In en, this message translates to:
  /// **'Fork service'**
  String get partForkService;

  /// No description provided for @partShockService.
  ///
  /// In en, this message translates to:
  /// **'Rear shock service'**
  String get partShockService;

  /// No description provided for @partDropperPostService.
  ///
  /// In en, this message translates to:
  /// **'Dropper post service'**
  String get partDropperPostService;

  /// No description provided for @partEBattery.
  ///
  /// In en, this message translates to:
  /// **'E-bike battery'**
  String get partEBattery;

  /// No description provided for @partEMotor.
  ///
  /// In en, this message translates to:
  /// **'E-bike motor'**
  String get partEMotor;

  /// No description provided for @partOther.
  ///
  /// In en, this message translates to:
  /// **'Other part'**
  String get partOther;

  /// No description provided for @partGroupDrivetrain.
  ///
  /// In en, this message translates to:
  /// **'Drivetrain'**
  String get partGroupDrivetrain;

  /// No description provided for @partGroupWheels.
  ///
  /// In en, this message translates to:
  /// **'Wheels'**
  String get partGroupWheels;

  /// No description provided for @partGroupBrakes.
  ///
  /// In en, this message translates to:
  /// **'Brakes'**
  String get partGroupBrakes;

  /// No description provided for @partGroupCockpit.
  ///
  /// In en, this message translates to:
  /// **'Cockpit'**
  String get partGroupCockpit;

  /// No description provided for @partGroupSuspension.
  ///
  /// In en, this message translates to:
  /// **'Suspension'**
  String get partGroupSuspension;

  /// No description provided for @partGroupElectric.
  ///
  /// In en, this message translates to:
  /// **'Electric'**
  String get partGroupElectric;

  /// No description provided for @partGroupOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get partGroupOther;

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
  /// **'{count, plural, =0{No rides} =1{1 ride} other{{count} rides}} · {duration} · {elevation} climbing'**
  String periodTotals(int count, String duration, String elevation);

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

  /// No description provided for @eyebrowProgress.
  ///
  /// In en, this message translates to:
  /// **'Your progress'**
  String get eyebrowProgress;

  /// No description provided for @progressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your form over the period you choose.'**
  String get progressSubtitle;

  /// No description provided for @progressFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter progress'**
  String get progressFilterTitle;

  /// No description provided for @totalsTitleWeekly.
  ///
  /// In en, this message translates to:
  /// **'Distance per week'**
  String get totalsTitleWeekly;

  /// No description provided for @totalsTitleMonthly.
  ///
  /// In en, this message translates to:
  /// **'Distance per month'**
  String get totalsTitleMonthly;

  /// No description provided for @totalsTitleYearly.
  ///
  /// In en, this message translates to:
  /// **'Distance per year'**
  String get totalsTitleYearly;

  /// No description provided for @totalsMore.
  ///
  /// In en, this message translates to:
  /// **'{count} older periods not listed'**
  String totalsMore(int count);

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

  /// No description provided for @accountSearch.
  ///
  /// In en, this message translates to:
  /// **'Find an account'**
  String get accountSearch;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear the search'**
  String get clearSearch;

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

  /// No description provided for @resetTwoFactor.
  ///
  /// In en, this message translates to:
  /// **'Reset two-factor sign-in'**
  String get resetTwoFactor;

  /// No description provided for @resetTwoFactorBody.
  ///
  /// In en, this message translates to:
  /// **'The member signs in again with the password and sets up the authenticator app from scratch.'**
  String get resetTwoFactorBody;

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
  /// **'Not set up. Set VELOMINE__SMTP__HOST and VELOMINE__SMTP__FROM.'**
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
  /// **'Not set up. Set VELOMINE__SSO__AUTHORITY, VELOMINE__SSO__CLIENTID and VELOMINE__SSO__CLIENTSECRET.'**
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

  /// No description provided for @rideReaderVersion.
  ///
  /// In en, this message translates to:
  /// **'Ride reader version'**
  String get rideReaderVersion;

  /// No description provided for @ridesToReread.
  ///
  /// In en, this message translates to:
  /// **'Rides waiting to be read again'**
  String get ridesToReread;

  /// No description provided for @ridesNotReread.
  ///
  /// In en, this message translates to:
  /// **'Rides that could not be read again'**
  String get ridesNotReread;

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

  /// No description provided for @birthYear.
  ///
  /// In en, this message translates to:
  /// **'Year of birth'**
  String get birthYear;

  /// No description provided for @birthYearHelper.
  ///
  /// In en, this message translates to:
  /// **'Maximum heart rate is estimated from it with the Tanaka formula (208 − 0.7 × age).'**
  String get birthYearHelper;

  /// No description provided for @estimatedMaxHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Estimated maximum heart rate: {bpm} bpm'**
  String estimatedMaxHeartRate(int bpm);

  /// No description provided for @estimatedMaxHeartRateNone.
  ///
  /// In en, this message translates to:
  /// **'Add your year of birth to estimate it.'**
  String get estimatedMaxHeartRateNone;

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

  /// No description provided for @emailAccountNotifications.
  ///
  /// In en, this message translates to:
  /// **'Account and club emails'**
  String get emailAccountNotifications;

  /// No description provided for @emailAccountNotificationsHelp.
  ///
  /// In en, this message translates to:
  /// **'Join requests and approvals, and sign-ups waiting for approval.'**
  String get emailAccountNotificationsHelp;

  /// No description provided for @emailTrainingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Ride and gear emails'**
  String get emailTrainingNotifications;

  /// No description provided for @emailTrainingNotificationsHelp.
  ///
  /// In en, this message translates to:
  /// **'Rides finishing or failing, and parts wearing out. Grouped into one email.'**
  String get emailTrainingNotificationsHelp;

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
  /// **'Enter a weight the server accepts: 20 to 300 kg (44 to 661 lb).'**
  String get errorWeight;

  /// No description provided for @errorBirthYear.
  ///
  /// In en, this message translates to:
  /// **'Enter a year of birth between 1900 and ten years ago.'**
  String get errorBirthYear;

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

  /// No description provided for @recordRide.
  ///
  /// In en, this message translates to:
  /// **'Record a ride'**
  String get recordRide;

  /// No description provided for @recordIntro.
  ///
  /// In en, this message translates to:
  /// **'The phone keeps recording with the screen off. Your ride is saved on this phone first; uploads are added next.'**
  String get recordIntro;

  /// No description provided for @starting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get starting;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get startRecording;

  /// No description provided for @pauseWhenStopped.
  ///
  /// In en, this message translates to:
  /// **'Pause when stopped'**
  String get pauseWhenStopped;

  /// No description provided for @pauseWhenStoppedHelp.
  ///
  /// In en, this message translates to:
  /// **'After 3 seconds at 0.1 km/h or slower; resumes above it.'**
  String get pauseWhenStoppedHelp;

  /// No description provided for @heartRateStrap.
  ///
  /// In en, this message translates to:
  /// **'Heart-rate strap'**
  String get heartRateStrap;

  /// No description provided for @nonePaired.
  ///
  /// In en, this message translates to:
  /// **'None paired. Optional: heart rate is saved with the ride.'**
  String get nonePaired;

  /// No description provided for @forget.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get forget;

  /// No description provided for @pair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get pair;

  /// No description provided for @sensorConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get sensorConnected;

  /// No description provided for @sensorConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get sensorConnecting;

  /// No description provided for @bluetoothOffState.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off'**
  String get bluetoothOffState;

  /// No description provided for @sensorDeniedState.
  ///
  /// In en, this message translates to:
  /// **'Nearby devices not allowed'**
  String get sensorDeniedState;

  /// No description provided for @sensorConnectsOnStart.
  ///
  /// In en, this message translates to:
  /// **'Connects when you start a ride'**
  String get sensorConnectsOnStart;

  /// No description provided for @autoPaused.
  ///
  /// In en, this message translates to:
  /// **'Auto-paused'**
  String get autoPaused;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recording;

  /// No description provided for @moving.
  ///
  /// In en, this message translates to:
  /// **'Moving'**
  String get moving;

  /// No description provided for @gps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get gps;

  /// No description provided for @heartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get heartRate;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @stopAndSave.
  ///
  /// In en, this message translates to:
  /// **'Stop and save'**
  String get stopAndSave;

  /// No description provided for @onThisPhone.
  ///
  /// In en, this message translates to:
  /// **'On this phone'**
  String get onThisPhone;

  /// No description provided for @noLocalRides.
  ///
  /// In en, this message translates to:
  /// **'No rides recorded on this phone yet.'**
  String get noLocalRides;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @serverReading.
  ///
  /// In en, this message translates to:
  /// **'Server is reading it…'**
  String get serverReading;

  /// No description provided for @waitingToUpload.
  ///
  /// In en, this message translates to:
  /// **'Waiting to upload'**
  String get waitingToUpload;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailed;

  /// No description provided for @readyToUpload.
  ///
  /// In en, this message translates to:
  /// **'Ready to upload'**
  String get readyToUpload;

  /// No description provided for @recordingOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Recording on this phone'**
  String get recordingOnPhone;

  /// No description provided for @interrupted.
  ///
  /// In en, this message translates to:
  /// **'Interrupted'**
  String get interrupted;

  /// No description provided for @couldNotBeSaved.
  ///
  /// In en, this message translates to:
  /// **'Could not be saved'**
  String get couldNotBeSaved;

  /// No description provided for @interruptedHelp.
  ///
  /// In en, this message translates to:
  /// **'The recording stopped unexpectedly. Finish it to keep the ride.'**
  String get interruptedHelp;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @deleteFromPhone.
  ///
  /// In en, this message translates to:
  /// **'Delete this ride from the phone'**
  String get deleteFromPhone;

  /// No description provided for @pairStrapTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair a heart-rate strap'**
  String get pairStrapTitle;

  /// No description provided for @pairStrapHelp.
  ///
  /// In en, this message translates to:
  /// **'Wear the strap so it wakes up, then pick it below. It is remembered for your next rides.'**
  String get pairStrapHelp;

  /// No description provided for @searchingStraps.
  ///
  /// In en, this message translates to:
  /// **'Searching for straps…'**
  String get searchingStraps;

  /// No description provided for @noStraps.
  ///
  /// In en, this message translates to:
  /// **'No straps found. Make sure the strap is worn and Bluetooth is on.'**
  String get noStraps;

  /// No description provided for @searchAgain.
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get searchAgain;

  /// No description provided for @recorderPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow precise location, and notifications if asked, so the ride can keep recording.'**
  String get recorderPermission;

  /// No description provided for @recorderGpsOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on location (GPS) to record a ride.'**
  String get recorderGpsOff;

  /// No description provided for @recorderLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'The phone could not start location updates.'**
  String get recorderLocationFailed;

  /// No description provided for @recorderUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Recording is only available on the phone.'**
  String get recorderUnsupported;

  /// No description provided for @recorderTooShort.
  ///
  /// In en, this message translates to:
  /// **'The ride was too short to save.'**
  String get recorderTooShort;

  /// No description provided for @recorderFitFailed.
  ///
  /// In en, this message translates to:
  /// **'The ride could not be saved.'**
  String get recorderFitFailed;

  /// No description provided for @recorderStillRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop the ride before finishing it.'**
  String get recorderStillRecording;

  /// No description provided for @recorderRideNotFound.
  ///
  /// In en, this message translates to:
  /// **'That ride is no longer on this phone.'**
  String get recorderRideNotFound;

  /// No description provided for @recorderBluetoothOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on Bluetooth to use a heart-rate strap.'**
  String get recorderBluetoothOff;

  /// No description provided for @recorderBluetoothDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow nearby devices so the app can find your heart-rate strap.'**
  String get recorderBluetoothDenied;

  /// No description provided for @recorderSensorNotFound.
  ///
  /// In en, this message translates to:
  /// **'That strap is no longer nearby.'**
  String get recorderSensorNotFound;

  /// No description provided for @recorderFailed.
  ///
  /// In en, this message translates to:
  /// **'The recorder could not do that. Try again.'**
  String get recorderFailed;

  /// No description provided for @recorderUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Could not read the recorder.'**
  String get recorderUnreadable;

  /// No description provided for @uploadNoFile.
  ///
  /// In en, this message translates to:
  /// **'The FIT file is missing on this phone.'**
  String get uploadNoFile;

  /// No description provided for @uploadOffline.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Try again.'**
  String get uploadOffline;

  /// No description provided for @uploadSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to upload.'**
  String get uploadSignIn;

  /// No description provided for @uploadTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to read the ride.'**
  String get uploadTimeout;

  /// No description provided for @uploadServerFailed.
  ///
  /// In en, this message translates to:
  /// **'The server could not read this ride.'**
  String get uploadServerFailed;

  /// No description provided for @uploadHttpRefused.
  ///
  /// In en, this message translates to:
  /// **'The server refused the upload ({code}).'**
  String uploadHttpRefused(String code);

  /// No description provided for @uploadFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Try again.'**
  String get uploadFailedGeneric;

  /// No description provided for @readiness.
  ///
  /// In en, this message translates to:
  /// **'Readiness'**
  String get readiness;

  /// No description provided for @readinessHard.
  ///
  /// In en, this message translates to:
  /// **'Ready for a hard ride'**
  String get readinessHard;

  /// No description provided for @readinessNormal.
  ///
  /// In en, this message translates to:
  /// **'Train normally'**
  String get readinessNormal;

  /// No description provided for @readinessEasy.
  ///
  /// In en, this message translates to:
  /// **'Take it easy'**
  String get readinessEasy;

  /// No description provided for @readinessRest.
  ///
  /// In en, this message translates to:
  /// **'Rest today'**
  String get readinessRest;

  /// No description provided for @readinessAdviceHard.
  ///
  /// In en, this message translates to:
  /// **'Your form is good. A hard session fits today.'**
  String get readinessAdviceHard;

  /// No description provided for @readinessAdviceNormal.
  ///
  /// In en, this message translates to:
  /// **'A normal session is fine; keep the hardest intervals for a fresher day.'**
  String get readinessAdviceNormal;

  /// No description provided for @readinessAdviceEasy.
  ///
  /// In en, this message translates to:
  /// **'Keep it easy: endurance pace, no hard efforts.'**
  String get readinessAdviceEasy;

  /// No description provided for @readinessAdviceRest.
  ///
  /// In en, this message translates to:
  /// **'Rest or move very easily. You are carrying a lot of fatigue.'**
  String get readinessAdviceRest;

  /// No description provided for @readinessNoData.
  ///
  /// In en, this message translates to:
  /// **'Record a ride to see readiness.'**
  String get readinessNoData;

  /// No description provided for @readinessLoadOnly.
  ///
  /// In en, this message translates to:
  /// **'Add a daily check-in to include how you feel.'**
  String get readinessLoadOnly;

  /// No description provided for @readinessWhy.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get readinessWhy;

  /// No description provided for @readinessNotMedical.
  ///
  /// In en, this message translates to:
  /// **'A training guide, not a medical measure.'**
  String get readinessNotMedical;

  /// No description provided for @readinessFactorForm.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get readinessFactorForm;

  /// No description provided for @readinessFactorRamp.
  ///
  /// In en, this message translates to:
  /// **'7-day ramp'**
  String get readinessFactorRamp;

  /// No description provided for @readinessFactorRecentLoad.
  ///
  /// In en, this message translates to:
  /// **'Last 2 days'**
  String get readinessFactorRecentLoad;

  /// No description provided for @readinessFactorWellbeing.
  ///
  /// In en, this message translates to:
  /// **'How you feel'**
  String get readinessFactorWellbeing;

  /// No description provided for @readinessFactorRpe.
  ///
  /// In en, this message translates to:
  /// **'Last ride RPE'**
  String get readinessFactorRpe;

  /// No description provided for @wellbeing.
  ///
  /// In en, this message translates to:
  /// **'Wellbeing'**
  String get wellbeing;

  /// No description provided for @wellbeingConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get wellbeingConsentTitle;

  /// No description provided for @wellbeingConsentBody.
  ///
  /// In en, this message translates to:
  /// **'Velomine stores a short daily check-in and the RPE you add to rides. It is health data: nobody else sees it unless you share it with your coaches, and you can export or delete it at any time. It is not medical advice.'**
  String get wellbeingConsentBody;

  /// No description provided for @wellbeingConsentAction.
  ///
  /// In en, this message translates to:
  /// **'I agree'**
  String get wellbeingConsentAction;

  /// No description provided for @wellbeingWithdrawConsent.
  ///
  /// In en, this message translates to:
  /// **'Withdraw consent'**
  String get wellbeingWithdrawConsent;

  /// No description provided for @wellbeingToday.
  ///
  /// In en, this message translates to:
  /// **'How do you feel today?'**
  String get wellbeingToday;

  /// No description provided for @wellbeingSaved.
  ///
  /// In en, this message translates to:
  /// **'Today\'s check-in'**
  String get wellbeingSaved;

  /// No description provided for @wellbeingEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit today'**
  String get wellbeingEdit;

  /// No description provided for @wellbeingSave.
  ///
  /// In en, this message translates to:
  /// **'Save check-in'**
  String get wellbeingSave;

  /// No description provided for @wellbeingFatigue.
  ///
  /// In en, this message translates to:
  /// **'Fatigue'**
  String get wellbeingFatigue;

  /// No description provided for @wellbeingSoreness.
  ///
  /// In en, this message translates to:
  /// **'Soreness'**
  String get wellbeingSoreness;

  /// No description provided for @wellbeingMood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get wellbeingMood;

  /// No description provided for @wellbeingStress.
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get wellbeingStress;

  /// No description provided for @wellbeingMotivation.
  ///
  /// In en, this message translates to:
  /// **'Motivation'**
  String get wellbeingMotivation;

  /// No description provided for @wellbeingShortFatigue.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get wellbeingShortFatigue;

  /// No description provided for @wellbeingShortSoreness.
  ///
  /// In en, this message translates to:
  /// **'Sor'**
  String get wellbeingShortSoreness;

  /// No description provided for @wellbeingShortMood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get wellbeingShortMood;

  /// No description provided for @wellbeingShortStress.
  ///
  /// In en, this message translates to:
  /// **'Str'**
  String get wellbeingShortStress;

  /// No description provided for @wellbeingShortMotivation.
  ///
  /// In en, this message translates to:
  /// **'Mot'**
  String get wellbeingShortMotivation;

  /// No description provided for @wellbeingHistory.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get wellbeingHistory;

  /// No description provided for @wellbeingNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No check-ins yet.'**
  String get wellbeingNoHistory;

  /// No description provided for @wellbeingRpe.
  ///
  /// In en, this message translates to:
  /// **'How hard was it?'**
  String get wellbeingRpe;

  /// No description provided for @wellbeingRpeHint.
  ///
  /// In en, this message translates to:
  /// **'1 easy, 10 maximal'**
  String get wellbeingRpeHint;

  /// No description provided for @wellbeingNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get wellbeingNotes;

  /// No description provided for @wellbeingRpeSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get wellbeingRpeSave;

  /// No description provided for @wellbeingRpeSaved.
  ///
  /// In en, this message translates to:
  /// **'RPE {rpe}/10'**
  String wellbeingRpeSaved(int rpe);

  /// No description provided for @wellbeingRpeDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get wellbeingRpeDelete;

  /// No description provided for @wellbeingConsentNeeded.
  ///
  /// In en, this message translates to:
  /// **'Set up wellbeing in Progress to add how a ride felt.'**
  String get wellbeingConsentNeeded;

  /// No description provided for @shareWellbeing.
  ///
  /// In en, this message translates to:
  /// **'Wellbeing'**
  String get shareWellbeing;

  /// No description provided for @shareWellbeingHelper.
  ///
  /// In en, this message translates to:
  /// **'Check-in scores and ride RPE; notes stay private.'**
  String get shareWellbeingHelper;

  /// No description provided for @sharesWellbeing.
  ///
  /// In en, this message translates to:
  /// **'Wellbeing'**
  String get sharesWellbeing;

  /// No description provided for @viewPowerCurve.
  ///
  /// In en, this message translates to:
  /// **'Power curve'**
  String get viewPowerCurve;

  /// No description provided for @viewWellbeing.
  ///
  /// In en, this message translates to:
  /// **'Wellbeing'**
  String get viewWellbeing;

  /// No description provided for @powerCurve.
  ///
  /// In en, this message translates to:
  /// **'Power curve'**
  String get powerCurve;

  /// No description provided for @powerCurveEmpty.
  ///
  /// In en, this message translates to:
  /// **'No power data in this range. Upload a ride with a power meter.'**
  String get powerCurveEmpty;

  /// No description provided for @powerBestEfforts.
  ///
  /// In en, this message translates to:
  /// **'Best efforts'**
  String get powerBestEfforts;

  /// No description provided for @ftpEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimated FTP'**
  String get ftpEstimate;

  /// No description provided for @ftpCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current FTP'**
  String get ftpCurrent;

  /// No description provided for @ftpMethod20.
  ///
  /// In en, this message translates to:
  /// **'95 % of your best 20-minute power'**
  String get ftpMethod20;

  /// No description provided for @ftpMethod8.
  ///
  /// In en, this message translates to:
  /// **'90 % of your best 8-minute power'**
  String get ftpMethod8;

  /// No description provided for @ftpUse.
  ///
  /// In en, this message translates to:
  /// **'Use {watts} W'**
  String ftpUse(int watts);

  /// No description provided for @vo2MaxEstimate.
  ///
  /// In en, this message translates to:
  /// **'VO2max estimate'**
  String get vo2MaxEstimate;

  /// No description provided for @vo2MaxFrom5Min.
  ///
  /// In en, this message translates to:
  /// **'from your best 5-minute power and weight'**
  String get vo2MaxFrom5Min;

  /// No description provided for @vo2MaxNeedsWeight.
  ///
  /// In en, this message translates to:
  /// **'Set your weight to estimate VO2max.'**
  String get vo2MaxNeedsWeight;

  /// No description provided for @vo2MaxNeedsEffort.
  ///
  /// In en, this message translates to:
  /// **'A 5-minute effort is needed to estimate VO2max.'**
  String get vo2MaxNeedsEffort;

  /// No description provided for @coachWellbeing.
  ///
  /// In en, this message translates to:
  /// **'Wellbeing'**
  String get coachWellbeing;

  /// No description provided for @coachWellbeingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Wellbeing was shared, but there are no check-ins yet.'**
  String get coachWellbeingEmpty;

  /// No description provided for @coachWellbeingNoNotes.
  ///
  /// In en, this message translates to:
  /// **'Scores and RPE only. Notes stay private.'**
  String get coachWellbeingNoNotes;

  /// No description provided for @coachPowerCurve.
  ///
  /// In en, this message translates to:
  /// **'Power curve'**
  String get coachPowerCurve;

  /// No description provided for @rideFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get rideFilterAll;

  /// No description provided for @rideFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter rides'**
  String get rideFilterTitle;

  /// No description provided for @rideFilterSearch.
  ///
  /// In en, this message translates to:
  /// **'Search rides'**
  String get rideFilterSearch;

  /// No description provided for @rideFilterSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search titles and descriptions'**
  String get rideFilterSearchHint;

  /// No description provided for @rideFilterClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get rideFilterClearSearch;

  /// No description provided for @rideFilterDatesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Choose dates'**
  String get rideFilterDatesTooltip;

  /// No description provided for @rideFilterRemoveDates.
  ///
  /// In en, this message translates to:
  /// **'Remove the date filter'**
  String get rideFilterRemoveDates;

  /// No description provided for @rideFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get rideFilterClear;

  /// No description provided for @noRidesMatch.
  ///
  /// In en, this message translates to:
  /// **'No rides match.'**
  String get noRidesMatch;

  /// No description provided for @rideDateRange.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String rideDateRange(String from, String to);

  /// No description provided for @rideDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'{period, select, morning{Morning} afternoon{Afternoon} evening{Evening} other{Night}} {kind, select, commute{commute} virtual{virtual ride} indoor{indoor ride} road{road ride} gravel{gravel ride} mountain{mountain bike ride} track{track ride} ebike{e-bike ride} other{ride}}'**
  String rideDefaultTitle(String period, String kind);

  /// No description provided for @rideTextEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit title and description'**
  String get rideTextEdit;

  /// No description provided for @rideTextSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Name this ride'**
  String get rideTextSheetTitle;

  /// No description provided for @rideTextHelp.
  ///
  /// In en, this message translates to:
  /// **'Your own words. Coaches you share rides with can read them.'**
  String get rideTextHelp;

  /// No description provided for @rideTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get rideTextTitle;

  /// No description provided for @rideTextTitleHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for a name made from the time and type of ride.'**
  String get rideTextTitleHelper;

  /// No description provided for @rideTextDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get rideTextDescription;

  /// No description provided for @rideTextAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a description'**
  String get rideTextAdd;

  /// No description provided for @actionSaveRideDetails.
  ///
  /// In en, this message translates to:
  /// **'save the title and description'**
  String get actionSaveRideDetails;

  /// No description provided for @rideViewedBy.
  ///
  /// In en, this message translates to:
  /// **'Seen by {name} · {when}'**
  String rideViewedBy(String name, String when);

  /// No description provided for @rideViewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nobody else has looked at this ride.'**
  String get rideViewsEmpty;

  /// No description provided for @rideTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Ride details'**
  String get rideTypeTitle;

  /// No description provided for @rideTypeHelp.
  ///
  /// In en, this message translates to:
  /// **'What kind of ride was it? Everything here is optional.'**
  String get rideTypeHelp;

  /// No description provided for @rideTypeDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get rideTypeDiscipline;

  /// No description provided for @rideTypeAssist.
  ///
  /// In en, this message translates to:
  /// **'E-bike'**
  String get rideTypeAssist;

  /// No description provided for @rideTypeEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get rideTypeEnvironment;

  /// No description provided for @rideTypeCommute.
  ///
  /// In en, this message translates to:
  /// **'Commute'**
  String get rideTypeCommute;

  /// No description provided for @rideTypeNotSet.
  ///
  /// In en, this message translates to:
  /// **'Set ride details'**
  String get rideTypeNotSet;

  /// No description provided for @rideTypeEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit ride details'**
  String get rideTypeEdit;

  /// No description provided for @rideTypeUnset.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get rideTypeUnset;

  /// No description provided for @rideTypeNoAssist.
  ///
  /// In en, this message translates to:
  /// **'No e-bike'**
  String get rideTypeNoAssist;

  /// No description provided for @rideTypeOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get rideTypeOutdoor;

  /// No description provided for @rideTypeIndoor.
  ///
  /// In en, this message translates to:
  /// **'Indoor'**
  String get rideTypeIndoor;

  /// No description provided for @rideTypeVirtual.
  ///
  /// In en, this message translates to:
  /// **'Virtual'**
  String get rideTypeVirtual;

  /// No description provided for @actionChangeRideType.
  ///
  /// In en, this message translates to:
  /// **'change this ride\'s details'**
  String get actionChangeRideType;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @lapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Laps'**
  String get lapsTitle;

  /// No description provided for @lap.
  ///
  /// In en, this message translates to:
  /// **'Lap'**
  String get lap;

  /// No description provided for @recorderRideType.
  ///
  /// In en, this message translates to:
  /// **'Ride type'**
  String get recorderRideType;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @recorderSettings.
  ///
  /// In en, this message translates to:
  /// **'Recording settings'**
  String get recorderSettings;

  /// No description provided for @recorderEbike.
  ///
  /// In en, this message translates to:
  /// **'E-bike'**
  String get recorderEbike;

  /// No description provided for @recorderEbikeHelp.
  ///
  /// In en, this message translates to:
  /// **'Counts as assisted and prefers your e-bike.'**
  String get recorderEbikeHelp;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter the email address of your account. If it can be reset, we will send a link.'**
  String get forgotPasswordHelp;

  /// No description provided for @forgotPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for that address, we sent a link to reset the password. Check your spam folder too.'**
  String get forgotPasswordSent;

  /// No description provided for @forgotPasswordUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This server is not set up to send email. Ask your club admin to reset your password.'**
  String get forgotPasswordUnavailable;

  /// No description provided for @forgotPasswordTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in a few minutes.'**
  String get forgotPasswordTooMany;

  /// No description provided for @forgotPasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the reset. Try again.'**
  String get forgotPasswordFailed;

  /// No description provided for @errorEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get errorEnterEmail;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose a password of at least 10 characters.'**
  String get resetPasswordHelp;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set new password'**
  String get setNewPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'The two passwords are not the same.'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 10 characters.'**
  String get passwordTooShort;

  /// No description provided for @resetPasswordInvalid.
  ///
  /// In en, this message translates to:
  /// **'This link is not valid or has expired. Ask for a new one.'**
  String get resetPasswordInvalid;

  /// No description provided for @resetPasswordDone.
  ///
  /// In en, this message translates to:
  /// **'Your password is changed. Sign in with the new one.'**
  String get resetPasswordDone;

  /// No description provided for @goToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Go to sign in'**
  String get goToSignIn;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @passwordWrongCurrent.
  ///
  /// In en, this message translates to:
  /// **'The current password is not right.'**
  String get passwordWrongCurrent;

  /// No description provided for @passwordNoPassword.
  ///
  /// In en, this message translates to:
  /// **'This account signs in with single sign-on.'**
  String get passwordNoPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Your password is changed. Sign in again on this device.'**
  String get passwordChanged;

  /// No description provided for @passwordChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change the password. Try again.'**
  String get passwordChangeFailed;

  /// No description provided for @actionChangePassword.
  ///
  /// In en, this message translates to:
  /// **'change your password'**
  String get actionChangePassword;

  /// No description provided for @actionResetPassword.
  ///
  /// In en, this message translates to:
  /// **'reset this password'**
  String get actionResetPassword;

  /// No description provided for @resetPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordLink;

  /// No description provided for @resetPasswordLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Password reset link for {name}'**
  String resetPasswordLinkTitle(String name);

  /// No description provided for @resetPasswordLinkHelp.
  ///
  /// In en, this message translates to:
  /// **'Send this link to the member. It works once and expires in 30 minutes.'**
  String get resetPasswordLinkHelp;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get linkCopied;

  /// No description provided for @resetPasswordLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not make a reset link. Try again.'**
  String get resetPasswordLinkFailed;

  /// No description provided for @actionLoadNearbyClubs.
  ///
  /// In en, this message translates to:
  /// **'find clubs near you'**
  String get actionLoadNearbyClubs;

  /// No description provided for @actionRequestJoinClub.
  ///
  /// In en, this message translates to:
  /// **'ask to join the club'**
  String get actionRequestJoinClub;

  /// No description provided for @actionCancelJoinRequest.
  ///
  /// In en, this message translates to:
  /// **'cancel your request'**
  String get actionCancelJoinRequest;

  /// No description provided for @actionLoadJoinRequests.
  ///
  /// In en, this message translates to:
  /// **'load the join requests'**
  String get actionLoadJoinRequests;

  /// No description provided for @actionApproveJoinRequest.
  ///
  /// In en, this message translates to:
  /// **'approve the request'**
  String get actionApproveJoinRequest;

  /// No description provided for @actionDeclineJoinRequest.
  ///
  /// In en, this message translates to:
  /// **'decline the request'**
  String get actionDeclineJoinRequest;

  /// No description provided for @actionLoadSecurity.
  ///
  /// In en, this message translates to:
  /// **'load your sign-in settings'**
  String get actionLoadSecurity;

  /// No description provided for @actionChangeSecurity.
  ///
  /// In en, this message translates to:
  /// **'change your sign-in settings'**
  String get actionChangeSecurity;

  /// No description provided for @clubSeeNearby.
  ///
  /// In en, this message translates to:
  /// **'See clubs near you'**
  String get clubSeeNearby;

  /// No description provided for @clubLocation.
  ///
  /// In en, this message translates to:
  /// **'Club location'**
  String get clubLocation;

  /// No description provided for @clubLocationHelp.
  ///
  /// In en, this message translates to:
  /// **'Where the club meets. Only used to show the club to riders nearby.'**
  String get clubLocationHelp;

  /// No description provided for @clubLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'Shown on the map'**
  String get clubLocationOnMap;

  /// No description provided for @clubLocationNone.
  ///
  /// In en, this message translates to:
  /// **'No location yet'**
  String get clubLocationNone;

  /// No description provided for @clubLocationSet.
  ///
  /// In en, this message translates to:
  /// **'Choose on the map'**
  String get clubLocationSet;

  /// No description provided for @clubLocationChange.
  ///
  /// In en, this message translates to:
  /// **'Change location'**
  String get clubLocationChange;

  /// No description provided for @clubDiscoverable.
  ///
  /// In en, this message translates to:
  /// **'Show this club to riders nearby'**
  String get clubDiscoverable;

  /// No description provided for @clubDiscoverableHelp.
  ///
  /// In en, this message translates to:
  /// **'Riders without a club can find it by distance and ask to join.'**
  String get clubDiscoverableHelp;

  /// No description provided for @locationPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a point'**
  String get locationPickerTitle;

  /// No description provided for @locationPickerHelp.
  ///
  /// In en, this message translates to:
  /// **'Drag the map until the pin is on the place.'**
  String get locationPickerHelp;

  /// No description provided for @locationPickerUse.
  ///
  /// In en, this message translates to:
  /// **'Use this point'**
  String get locationPickerUse;

  /// No description provided for @locationPickerCurrent.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get locationPickerCurrent;

  /// No description provided for @locationCurrentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your device did not share its position.'**
  String get locationCurrentUnavailable;

  /// No description provided for @locationMapFirst.
  ///
  /// In en, this message translates to:
  /// **'Drag the map to the place first.'**
  String get locationMapFirst;

  /// No description provided for @nearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Clubs near you'**
  String get nearbyTitle;

  /// No description provided for @nearbyIntro.
  ///
  /// In en, this message translates to:
  /// **'Ride at your own pace. Join a club whenever you want; you can leave any time and your rides stay yours.'**
  String get nearbyIntro;

  /// No description provided for @nearbyLocating.
  ///
  /// In en, this message translates to:
  /// **'Finding your position…'**
  String get nearbyLocating;

  /// No description provided for @nearbyLocationHelp.
  ///
  /// In en, this message translates to:
  /// **'Your position is used only to sort clubs by distance and is not kept on the server.'**
  String get nearbyLocationHelp;

  /// No description provided for @nearbyUseDevice.
  ///
  /// In en, this message translates to:
  /// **'Use my position'**
  String get nearbyUseDevice;

  /// No description provided for @nearbySetHome.
  ///
  /// In en, this message translates to:
  /// **'Set a location'**
  String get nearbySetHome;

  /// No description provided for @nearbyHomeUsed.
  ///
  /// In en, this message translates to:
  /// **'Using your saved location.'**
  String get nearbyHomeUsed;

  /// No description provided for @nearbyRadius.
  ///
  /// In en, this message translates to:
  /// **'Within {km} km'**
  String nearbyRadius(int km);

  /// No description provided for @nearbyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No clubs within {km} km. Ride on your own for now, or look farther.'**
  String nearbyEmpty(int km);

  /// No description provided for @nearbyDistance.
  ///
  /// In en, this message translates to:
  /// **'~{km} km'**
  String nearbyDistance(int km);

  /// No description provided for @nearbyAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask to join'**
  String get nearbyAsk;

  /// No description provided for @nearbyRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get nearbyRequested;

  /// No description provided for @nearbyCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get nearbyCancel;

  /// No description provided for @nearbyRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask to join {club}'**
  String nearbyRequestTitle(String club);

  /// No description provided for @nearbyRequestNote.
  ///
  /// In en, this message translates to:
  /// **'A word for the owner (optional)'**
  String get nearbyRequestNote;

  /// No description provided for @nearbyRequestSend.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get nearbyRequestSend;

  /// No description provided for @nearbyRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent. The owner decides when they can.'**
  String get nearbyRequestSent;

  /// No description provided for @nearbyPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {club}'**
  String nearbyPendingTitle(String club);

  /// No description provided for @nearbyPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your request is with the club\'s owner.'**
  String get nearbyPendingBody;

  /// No description provided for @nearbyWiden.
  ///
  /// In en, this message translates to:
  /// **'Look farther'**
  String get nearbyWiden;

  /// No description provided for @nearbyReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw your request to {club}?'**
  String nearbyReplaceTitle(String club);

  /// No description provided for @nearbyReplaceBody.
  ///
  /// In en, this message translates to:
  /// **'You can have one open request. Asking another club withdraws this one.'**
  String get nearbyReplaceBody;

  /// No description provided for @soloHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Ride at your own pace'**
  String get soloHintTitle;

  /// No description provided for @soloHintBody.
  ///
  /// In en, this message translates to:
  /// **'There are clubs near you when you want one.'**
  String get soloHintBody;

  /// No description provided for @soloHintSee.
  ///
  /// In en, this message translates to:
  /// **'See clubs'**
  String get soloHintSee;

  /// No description provided for @soloHintDismiss.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get soloHintDismiss;

  /// No description provided for @joinRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Join requests'**
  String get joinRequestsTitle;

  /// No description provided for @joinRequestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one is waiting to join.'**
  String get joinRequestsEmpty;

  /// No description provided for @joinRequestApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get joinRequestApprove;

  /// No description provided for @joinRequestDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get joinRequestDecline;

  /// No description provided for @joinRequestApproveTitle.
  ///
  /// In en, this message translates to:
  /// **'Let {name} in?'**
  String joinRequestApproveTitle(String name);

  /// No description provided for @joinRequestApproveBody.
  ///
  /// In en, this message translates to:
  /// **'They become a rider. Your rides stay yours; sharing is still their choice.'**
  String get joinRequestApproveBody;

  /// No description provided for @joinRequestDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline {name}?'**
  String joinRequestDeclineTitle(String name);

  /// No description provided for @joinRequestDeclineBody.
  ///
  /// In en, this message translates to:
  /// **'They are told, without a reason.'**
  String get joinRequestDeclineBody;

  /// No description provided for @notificationClubJoinRequest.
  ///
  /// In en, this message translates to:
  /// **'{name} asked to join your club.'**
  String notificationClubJoinRequest(String name);

  /// No description provided for @notificationClubJoinApproved.
  ///
  /// In en, this message translates to:
  /// **'{club} accepted you. Welcome!'**
  String notificationClubJoinApproved(String club);

  /// No description provided for @notificationClubJoinDeclined.
  ///
  /// In en, this message translates to:
  /// **'{club} declined your request.'**
  String notificationClubJoinDeclined(String club);

  /// No description provided for @actionLoadTemplates.
  ///
  /// In en, this message translates to:
  /// **'load your build templates'**
  String get actionLoadTemplates;

  /// No description provided for @actionSaveTemplate.
  ///
  /// In en, this message translates to:
  /// **'save the build template'**
  String get actionSaveTemplate;

  /// No description provided for @actionApplyTemplate.
  ///
  /// In en, this message translates to:
  /// **'apply the build template'**
  String get actionApplyTemplate;

  /// No description provided for @saveAsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Save as build template'**
  String get saveAsTemplate;

  /// No description provided for @applyTemplate.
  ///
  /// In en, this message translates to:
  /// **'Apply a build template'**
  String get applyTemplate;

  /// No description provided for @saveTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Save this bike\'s parts as a template'**
  String get saveTemplateTitle;

  /// No description provided for @templateName.
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get templateName;

  /// No description provided for @templateNameHint.
  ///
  /// In en, this message translates to:
  /// **'For example: Gravel build, 2024'**
  String get templateNameHint;

  /// No description provided for @templateParts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 part} other{{count} parts}}'**
  String templateParts(int count);

  /// No description provided for @noTemplates.
  ///
  /// In en, this message translates to:
  /// **'No build templates yet. Save a bike\'s parts as a template to reuse them.'**
  String get noTemplates;

  /// No description provided for @applyTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply a build template'**
  String get applyTemplateTitle;

  /// No description provided for @templateApplied.
  ///
  /// In en, this message translates to:
  /// **'Build template applied.'**
  String get templateApplied;

  /// No description provided for @errorTemplateName.
  ///
  /// In en, this message translates to:
  /// **'Give the template a name.'**
  String get errorTemplateName;

  /// No description provided for @sharedCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Shared parts catalogue'**
  String get sharedCatalogue;

  /// No description provided for @shareParts.
  ///
  /// In en, this message translates to:
  /// **'Share new parts with the shared catalogue'**
  String get shareParts;

  /// No description provided for @sharePartsHelp.
  ///
  /// In en, this message translates to:
  /// **'Non-custom parts that the shared catalogue does not list are sent to the publisher. Custom parts stay only on your bike.'**
  String get sharePartsHelp;

  /// No description provided for @catalogueNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'This server has no contribution endpoint configured, so nothing is sent.'**
  String get catalogueNotConfigured;

  /// No description provided for @catalogueVersion.
  ///
  /// In en, this message translates to:
  /// **'Catalogue version {version}, last checked {date}'**
  String catalogueVersion(int version, String date);

  /// No description provided for @catalogueNeverSynced.
  ///
  /// In en, this message translates to:
  /// **'The shared catalogue has not been checked yet.'**
  String get catalogueNeverSynced;

  /// No description provided for @catalogueSynced.
  ///
  /// In en, this message translates to:
  /// **'Shared catalogue last checked {date}'**
  String catalogueSynced(String date);

  /// No description provided for @catalogueConflicts.
  ///
  /// In en, this message translates to:
  /// **'Parts that differ from the shared catalogue'**
  String get catalogueConflicts;

  /// No description provided for @keepMine.
  ///
  /// In en, this message translates to:
  /// **'Keep mine'**
  String get keepMine;

  /// No description provided for @useShared.
  ///
  /// In en, this message translates to:
  /// **'Use shared'**
  String get useShared;

  /// No description provided for @contributionCounts.
  ///
  /// In en, this message translates to:
  /// **'{pending} waiting · {sent} sent · {rejected} rejected · {failed} failed'**
  String contributionCounts(int pending, int sent, int rejected, int failed);

  /// No description provided for @catalogueProblems.
  ///
  /// In en, this message translates to:
  /// **'Parts the shared catalogue did not take'**
  String get catalogueProblems;

  /// No description provided for @contributionRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get contributionRejected;

  /// No description provided for @contributionFailed.
  ///
  /// In en, this message translates to:
  /// **'Gave up'**
  String get contributionFailed;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom part'**
  String get custom;

  /// No description provided for @customPart.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customPart;

  /// No description provided for @customHelper.
  ///
  /// In en, this message translates to:
  /// **'Keep this part out of the shared catalogue; it will not be sent to the publisher.'**
  String get customHelper;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @profileAthlete.
  ///
  /// In en, this message translates to:
  /// **'Athlete'**
  String get profileAthlete;

  /// No description provided for @telemetryHelp.
  ///
  /// In en, this message translates to:
  /// **'Help improve Velomine with anonymous crash reports and performance data. Nothing you record is ever included.'**
  String get telemetryHelp;

  /// No description provided for @crashReports.
  ///
  /// In en, this message translates to:
  /// **'Crash reports'**
  String get crashReports;

  /// No description provided for @crashReportsHelp.
  ///
  /// In en, this message translates to:
  /// **'Stack traces and app version, so a bug can be fixed.'**
  String get crashReportsHelp;

  /// No description provided for @usageData.
  ///
  /// In en, this message translates to:
  /// **'Performance and usage data'**
  String get usageData;

  /// No description provided for @usageDataHelp.
  ///
  /// In en, this message translates to:
  /// **'Slow screens and which features are used, without your rides or health data.'**
  String get usageDataHelp;

  /// No description provided for @telemetryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This server does not collect telemetry.'**
  String get telemetryUnavailable;

  /// No description provided for @telemetrySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get telemetrySaved;

  /// No description provided for @telemetryRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart the app to apply this choice.'**
  String get telemetryRestart;

  /// No description provided for @powerCurveSummary.
  ///
  /// In en, this message translates to:
  /// **'Power curve. Best 5 seconds {p5s} watts, 1 minute {p1m}, 5 minutes {p5m}, 20 minutes {p20m}. Estimated FTP {ftp} watts.'**
  String powerCurveSummary(
    String p5s,
    String p1m,
    String p5m,
    String p20m,
    String ftp,
  );

  /// No description provided for @routeMapSummary.
  ///
  /// In en, this message translates to:
  /// **'Route map. {distance}, with {climb} of climbing.'**
  String routeMapSummary(String distance, String climb);

  /// No description provided for @routeMapDistanceSummary.
  ///
  /// In en, this message translates to:
  /// **'Route map. {distance}.'**
  String routeMapDistanceSummary(String distance);

  /// No description provided for @importFromStrava.
  ///
  /// In en, this message translates to:
  /// **'Import from Strava'**
  String get importFromStrava;

  /// No description provided for @importStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting import…'**
  String get importStarting;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from Strava'**
  String get importTitle;

  /// No description provided for @importRunning.
  ///
  /// In en, this message translates to:
  /// **'Reading your archive. This can take a few minutes.'**
  String get importRunning;

  /// No description provided for @importProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} activities read'**
  String importProgress(int done, int total);

  /// No description provided for @importFinished.
  ///
  /// In en, this message translates to:
  /// **'Import finished'**
  String get importFinished;

  /// No description provided for @importSummaryImported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ride imported} other{{count} rides imported}}'**
  String importSummaryImported(int count);

  /// No description provided for @importSummaryDuplicates.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ride was already here} other{{count} rides were already here}}'**
  String importSummaryDuplicates(int count);

  /// No description provided for @importSummaryFailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file could not be read} other{{count} files could not be read}}'**
  String importSummaryFailed(int count);

  /// No description provided for @importSummarySkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 activity skipped, not a ride or without a file} other{{count} activities skipped, not rides or without a file}}'**
  String importSummarySkipped(int count);

  /// No description provided for @importBackToRides.
  ///
  /// In en, this message translates to:
  /// **'Back to rides'**
  String get importBackToRides;

  /// No description provided for @importErrorNotStrava.
  ///
  /// In en, this message translates to:
  /// **'This is not a Strava export: it has no activities.csv.'**
  String get importErrorNotStrava;

  /// No description provided for @importErrorMissing.
  ///
  /// In en, this message translates to:
  /// **'The archive is no longer on the server. Choose it again.'**
  String get importErrorMissing;

  /// No description provided for @importErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'The archive could not be read.'**
  String get importErrorUnknown;

  /// No description provided for @actionImportRides.
  ///
  /// In en, this message translates to:
  /// **'import your rides'**
  String get actionImportRides;

  /// No description provided for @actionLoadImport.
  ///
  /// In en, this message translates to:
  /// **'check the import'**
  String get actionLoadImport;

  /// No description provided for @notificationRideImport.
  ///
  /// In en, this message translates to:
  /// **'Your import of {subject} has finished.'**
  String notificationRideImport(String subject);

  /// No description provided for @actionStartClub.
  ///
  /// In en, this message translates to:
  /// **'start the club'**
  String get actionStartClub;

  /// No description provided for @actionSetClubPlan.
  ///
  /// In en, this message translates to:
  /// **'save the club\'s plan'**
  String get actionSetClubPlan;

  /// No description provided for @startClubButton.
  ///
  /// In en, this message translates to:
  /// **'Start a club'**
  String get startClubButton;

  /// No description provided for @startClubTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a club'**
  String get startClubTitle;

  /// No description provided for @startClubIntro.
  ///
  /// In en, this message translates to:
  /// **'Start a club for the people you ride with. You will be its owner and can invite people with a code. You get a month to try it.'**
  String get startClubIntro;

  /// No description provided for @startClubName.
  ///
  /// In en, this message translates to:
  /// **'Club name'**
  String get startClubName;

  /// No description provided for @startClubNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give the club a name.'**
  String get startClubNameRequired;

  /// No description provided for @startClubAction.
  ///
  /// In en, this message translates to:
  /// **'Start the club'**
  String get startClubAction;

  /// No description provided for @clubPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get clubPlanTitle;

  /// No description provided for @clubPlanMembers.
  ///
  /// In en, this message translates to:
  /// **'{count} of {limit} members'**
  String clubPlanMembers(int count, int limit);

  /// No description provided for @clubPlanPaidUntil.
  ///
  /// In en, this message translates to:
  /// **'Paid until {date}'**
  String clubPlanPaidUntil(String date);

  /// No description provided for @clubPlanFullNotice.
  ///
  /// In en, this message translates to:
  /// **'The club is full. To take more members, get in touch to move up to a larger size.'**
  String get clubPlanFullNotice;

  /// No description provided for @clubPlanEndedNotice.
  ///
  /// In en, this message translates to:
  /// **'The club\'s plan ended on {date}. Everything keeps working, but new members cannot join until it is renewed. Get in touch to renew it.'**
  String clubPlanEndedNotice(String date);

  /// No description provided for @joinRequestsBlockedFull.
  ///
  /// In en, this message translates to:
  /// **'The club is full, so requests cannot be approved yet. Get in touch to move up to a larger size.'**
  String get joinRequestsBlockedFull;

  /// No description provided for @joinRequestsBlockedEnded.
  ///
  /// In en, this message translates to:
  /// **'The club\'s plan has ended, so requests cannot be approved until it is renewed.'**
  String get joinRequestsBlockedEnded;

  /// No description provided for @notificationClubPlanEnding.
  ///
  /// In en, this message translates to:
  /// **'Your club\'s plan ends on {date}. Get in touch to renew it.'**
  String notificationClubPlanEnding(String date);

  /// No description provided for @notificationClubPlanEnded.
  ///
  /// In en, this message translates to:
  /// **'Your club\'s plan ended after {date}. Members keep everything, but new members cannot join until it is renewed.'**
  String notificationClubPlanEnded(String date);

  /// No description provided for @adminClubCreation.
  ///
  /// In en, this message translates to:
  /// **'Riders can start clubs'**
  String get adminClubCreation;

  /// No description provided for @adminClubCreationHelp.
  ///
  /// In en, this message translates to:
  /// **'A signed-in rider without a club can start one. It begins with room for 25 members and a month to try it.'**
  String get adminClubCreationHelp;

  /// No description provided for @adminClubEditPlan.
  ///
  /// In en, this message translates to:
  /// **'Edit plan'**
  String get adminClubEditPlan;

  /// No description provided for @adminClubLimit.
  ///
  /// In en, this message translates to:
  /// **'Room for'**
  String get adminClubLimit;

  /// No description provided for @adminClubLimitNone.
  ///
  /// In en, this message translates to:
  /// **'More than 150 members (no limit)'**
  String get adminClubLimitNone;

  /// No description provided for @adminClubLimitOption.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} members'**
  String adminClubLimitOption(int count);

  /// No description provided for @adminClubPaidUntil.
  ///
  /// In en, this message translates to:
  /// **'Paid until'**
  String get adminClubPaidUntil;

  /// No description provided for @adminClubNoDate.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get adminClubNoDate;

  /// No description provided for @adminClubChooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get adminClubChooseDate;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @actionLoadServiceLog.
  ///
  /// In en, this message translates to:
  /// **'load the service log'**
  String get actionLoadServiceLog;

  /// No description provided for @actionSaveReminder.
  ///
  /// In en, this message translates to:
  /// **'save the reminder'**
  String get actionSaveReminder;

  /// No description provided for @actionRemoveReminder.
  ///
  /// In en, this message translates to:
  /// **'delete the reminder'**
  String get actionRemoveReminder;

  /// No description provided for @actionCompleteReminder.
  ///
  /// In en, this message translates to:
  /// **'mark the job as done'**
  String get actionCompleteReminder;

  /// No description provided for @actionSaveServiceEntry.
  ///
  /// In en, this message translates to:
  /// **'save the entry'**
  String get actionSaveServiceEntry;

  /// No description provided for @actionRemoveServiceEntry.
  ///
  /// In en, this message translates to:
  /// **'delete the entry'**
  String get actionRemoveServiceEntry;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @serviceRemindersIntro.
  ///
  /// In en, this message translates to:
  /// **'Reminders tell you when a job on this bike comes round again, like lubing the chain or topping up sealant. Pick a common one to start.'**
  String get serviceRemindersIntro;

  /// No description provided for @serviceAddReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get serviceAddReminder;

  /// No description provided for @serviceCommonJobs.
  ///
  /// In en, this message translates to:
  /// **'Common jobs'**
  String get serviceCommonJobs;

  /// No description provided for @reminderStatusOk.
  ///
  /// In en, this message translates to:
  /// **'Fine'**
  String get reminderStatusOk;

  /// No description provided for @reminderStatusSoon.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get reminderStatusSoon;

  /// No description provided for @reminderStatusDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get reminderStatusDue;

  /// No description provided for @reminderStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get reminderStatusPaused;

  /// No description provided for @reminderLastDone.
  ///
  /// In en, this message translates to:
  /// **'Last done {date}'**
  String reminderLastDone(String date);

  /// No description provided for @reminderDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get reminderDone;

  /// No description provided for @reminderDoneSaved.
  ///
  /// In en, this message translates to:
  /// **'Done. It is in the service log.'**
  String get reminderDoneSaved;

  /// No description provided for @reminderDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Counting starts again from the day you pick, and the job goes in the service log.'**
  String get reminderDoneBody;

  /// No description provided for @doneOnDate.
  ///
  /// In en, this message translates to:
  /// **'Done on {date}'**
  String doneOnDate(String date);

  /// No description provided for @reminderPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get reminderPause;

  /// No description provided for @reminderResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get reminderResume;

  /// No description provided for @reminderFormAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a reminder'**
  String get reminderFormAddTitle;

  /// No description provided for @reminderFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get reminderFormEditTitle;

  /// No description provided for @reminderName.
  ///
  /// In en, this message translates to:
  /// **'What needs doing?'**
  String get reminderName;

  /// No description provided for @reminderIntervalHelp.
  ///
  /// In en, this message translates to:
  /// **'It is due at the first of these. Leave empty what you do not need.'**
  String get reminderIntervalHelp;

  /// No description provided for @reminderErrorName.
  ///
  /// In en, this message translates to:
  /// **'Give the job a name.'**
  String get reminderErrorName;

  /// No description provided for @reminderErrorInterval.
  ///
  /// In en, this message translates to:
  /// **'Set a distance, hours or months.'**
  String get reminderErrorInterval;

  /// No description provided for @reminderRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this reminder?'**
  String get reminderRemoveTitle;

  /// No description provided for @reminderRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'The service log keeps what you already did.'**
  String get reminderRemoveBody;

  /// No description provided for @jobChainLube.
  ///
  /// In en, this message translates to:
  /// **'Lube the chain'**
  String get jobChainLube;

  /// No description provided for @jobChainWearCheck.
  ///
  /// In en, this message translates to:
  /// **'Check chain wear'**
  String get jobChainWearCheck;

  /// No description provided for @jobSealantTopUp.
  ///
  /// In en, this message translates to:
  /// **'Top up tyre sealant'**
  String get jobSealantTopUp;

  /// No description provided for @jobBrakeBleed.
  ///
  /// In en, this message translates to:
  /// **'Bleed the brakes'**
  String get jobBrakeBleed;

  /// No description provided for @jobForkService.
  ///
  /// In en, this message translates to:
  /// **'Service the fork lowers'**
  String get jobForkService;

  /// No description provided for @jobShockService.
  ///
  /// In en, this message translates to:
  /// **'Service the rear shock'**
  String get jobShockService;

  /// No description provided for @jobBoltCheck.
  ///
  /// In en, this message translates to:
  /// **'Check bolt torque'**
  String get jobBoltCheck;

  /// No description provided for @jobShiftingBattery.
  ///
  /// In en, this message translates to:
  /// **'Charge the electronic shifting'**
  String get jobShiftingBattery;

  /// No description provided for @serviceLog.
  ///
  /// In en, this message translates to:
  /// **'Service log'**
  String get serviceLog;

  /// No description provided for @serviceLogIntro.
  ///
  /// In en, this message translates to:
  /// **'Everything done to this bike goes here, with the distance it had at the time.'**
  String get serviceLogIntro;

  /// No description provided for @serviceAddEntry.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get serviceAddEntry;

  /// No description provided for @entryAtDistance.
  ///
  /// In en, this message translates to:
  /// **'at {distance}'**
  String entryAtDistance(String distance);

  /// No description provided for @entryAtHome.
  ///
  /// In en, this message translates to:
  /// **'At home'**
  String get entryAtHome;

  /// No description provided for @entryFormAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to the service log'**
  String get entryFormAddTitle;

  /// No description provided for @entryFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get entryFormEditTitle;

  /// No description provided for @entryTitleField.
  ///
  /// In en, this message translates to:
  /// **'What was done?'**
  String get entryTitleField;

  /// No description provided for @entryNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get entryNotes;

  /// No description provided for @entryPlace.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get entryPlace;

  /// No description provided for @entryPlaceHelp.
  ///
  /// In en, this message translates to:
  /// **'A shop\'s name. Leave empty if you did it at home.'**
  String get entryPlaceHelp;

  /// No description provided for @entryCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get entryCost;

  /// No description provided for @entryCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get entryCurrency;

  /// No description provided for @entryPart.
  ///
  /// In en, this message translates to:
  /// **'About which part?'**
  String get entryPart;

  /// No description provided for @entryNoPart.
  ///
  /// In en, this message translates to:
  /// **'No particular part'**
  String get entryNoPart;

  /// No description provided for @entryReminder.
  ///
  /// In en, this message translates to:
  /// **'About which reminder?'**
  String get entryReminder;

  /// No description provided for @entryNoReminder.
  ///
  /// In en, this message translates to:
  /// **'No particular reminder'**
  String get entryNoReminder;

  /// No description provided for @entryErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Say what was done.'**
  String get entryErrorTitle;

  /// No description provided for @entryErrorCost.
  ///
  /// In en, this message translates to:
  /// **'Enter the cost as a number, with a three-letter currency like EUR.'**
  String get entryErrorCost;

  /// No description provided for @entryRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get entryRemoveTitle;

  /// No description provided for @entryRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'It is removed from the log. This cannot be undone.'**
  String get entryRemoveBody;

  /// No description provided for @entryRemoveDoneBody.
  ///
  /// In en, this message translates to:
  /// **'It is removed from the log. The reminder keeps counting from the day it was done.'**
  String get entryRemoveDoneBody;

  /// No description provided for @logFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get logFilterLabel;

  /// No description provided for @logFilterAll.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get logFilterAll;

  /// No description provided for @logFilterEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the log for this part yet.'**
  String get logFilterEmpty;

  /// No description provided for @logShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get logShowMore;

  /// No description provided for @logReplacedPart.
  ///
  /// In en, this message translates to:
  /// **'Replaced {part}'**
  String logReplacedPart(String part);

  /// No description provided for @logReplacedPartWith.
  ///
  /// In en, this message translates to:
  /// **'Replaced {part}: {make}'**
  String logReplacedPartWith(String part, String make);

  /// No description provided for @bikeServiceDue.
  ///
  /// In en, this message translates to:
  /// **'Service due'**
  String get bikeServiceDue;

  /// No description provided for @bikeServiceSoon.
  ///
  /// In en, this message translates to:
  /// **'Service due soon'**
  String get bikeServiceSoon;

  /// No description provided for @notificationReminderSoon.
  ///
  /// In en, this message translates to:
  /// **'Maintenance nearly due: {subject}.'**
  String notificationReminderSoon(String subject);

  /// No description provided for @notificationReminderDue.
  ///
  /// In en, this message translates to:
  /// **'Maintenance due: {subject}.'**
  String notificationReminderDue(String subject);

  /// No description provided for @actionLoadRoutes.
  ///
  /// In en, this message translates to:
  /// **'load the club\'s routes'**
  String get actionLoadRoutes;

  /// No description provided for @actionLoadRoute.
  ///
  /// In en, this message translates to:
  /// **'load this route'**
  String get actionLoadRoute;

  /// No description provided for @actionAddRoute.
  ///
  /// In en, this message translates to:
  /// **'add the route'**
  String get actionAddRoute;

  /// No description provided for @actionSaveRoute.
  ///
  /// In en, this message translates to:
  /// **'save the route'**
  String get actionSaveRoute;

  /// No description provided for @actionDeleteRoute.
  ///
  /// In en, this message translates to:
  /// **'delete the route'**
  String get actionDeleteRoute;

  /// No description provided for @actionLoadClubRides.
  ///
  /// In en, this message translates to:
  /// **'load the club\'s rides'**
  String get actionLoadClubRides;

  /// No description provided for @actionLoadClubRide.
  ///
  /// In en, this message translates to:
  /// **'load this club ride'**
  String get actionLoadClubRide;

  /// No description provided for @actionSaveClubRide.
  ///
  /// In en, this message translates to:
  /// **'save the club ride'**
  String get actionSaveClubRide;

  /// No description provided for @actionCancelClubRide.
  ///
  /// In en, this message translates to:
  /// **'cancel the club ride'**
  String get actionCancelClubRide;

  /// No description provided for @actionJoinClubRide.
  ///
  /// In en, this message translates to:
  /// **'say you are in'**
  String get actionJoinClubRide;

  /// No description provided for @actionLeaveClubRide.
  ///
  /// In en, this message translates to:
  /// **'take your name off'**
  String get actionLeaveClubRide;

  /// No description provided for @actionLoadCalendarFeed.
  ///
  /// In en, this message translates to:
  /// **'load your calendar address'**
  String get actionLoadCalendarFeed;

  /// No description provided for @actionSaveCalendarFeed.
  ///
  /// In en, this message translates to:
  /// **'change your calendar address'**
  String get actionSaveCalendarFeed;

  /// No description provided for @clubRidesTitle.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get clubRidesTitle;

  /// No description provided for @clubRidesHelp.
  ///
  /// In en, this message translates to:
  /// **'The club\'s next rides, and who is in.'**
  String get clubRidesHelp;

  /// No description provided for @clubRidesSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all rides'**
  String get clubRidesSeeAll;

  /// No description provided for @clubPlanRide.
  ///
  /// In en, this message translates to:
  /// **'Plan a ride'**
  String get clubPlanRide;

  /// No description provided for @clubRoutesTitle.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get clubRoutesTitle;

  /// No description provided for @clubRoutesHelp.
  ///
  /// In en, this message translates to:
  /// **'Lines the club shares, each one kept by the member who added it.'**
  String get clubRoutesHelp;

  /// No description provided for @clubRoutesSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all routes'**
  String get clubRoutesSeeAll;

  /// No description provided for @clubAddRoute.
  ///
  /// In en, this message translates to:
  /// **'Add a route'**
  String get clubAddRoute;

  /// No description provided for @clubRoutesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No routes yet. Add one from one of your rides or from a GPX file.'**
  String get clubRoutesEmpty;

  /// No description provided for @routesFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All surfaces'**
  String get routesFilterAll;

  /// No description provided for @routesSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get routesSortNewest;

  /// No description provided for @routesSortShortest.
  ///
  /// In en, this message translates to:
  /// **'Shortest'**
  String get routesSortShortest;

  /// No description provided for @routesSortLongest.
  ///
  /// In en, this message translates to:
  /// **'Longest'**
  String get routesSortLongest;

  /// No description provided for @routeSurfaceRoad.
  ///
  /// In en, this message translates to:
  /// **'Road'**
  String get routeSurfaceRoad;

  /// No description provided for @routeSurfaceGravel.
  ///
  /// In en, this message translates to:
  /// **'Gravel'**
  String get routeSurfaceGravel;

  /// No description provided for @routeSurfaceMountain.
  ///
  /// In en, this message translates to:
  /// **'Mountain'**
  String get routeSurfaceMountain;

  /// No description provided for @routeSurfaceMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get routeSurfaceMixed;

  /// No description provided for @routeAddedBy.
  ///
  /// In en, this message translates to:
  /// **'Added by {name}'**
  String routeAddedBy(String name);

  /// No description provided for @routeNotSharedBody.
  ///
  /// In en, this message translates to:
  /// **'This route is yours, but it is not in the club library.'**
  String get routeNotSharedBody;

  /// No description provided for @routeOpenGpx.
  ///
  /// In en, this message translates to:
  /// **'Download GPX'**
  String get routeOpenGpx;

  /// No description provided for @routeEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get routeEdit;

  /// No description provided for @routeWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Remove from club'**
  String get routeWithdraw;

  /// No description provided for @routeWithdrawConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this route from the club?'**
  String get routeWithdrawConfirmTitle;

  /// No description provided for @routeWithdrawConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'It stays yours and you can share it again at any time.'**
  String get routeWithdrawConfirmBody;

  /// No description provided for @routeShare.
  ///
  /// In en, this message translates to:
  /// **'Share again'**
  String get routeShare;

  /// No description provided for @routeDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete for good'**
  String get routeDelete;

  /// No description provided for @routeDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this route?'**
  String get routeDeleteConfirmTitle;

  /// No description provided for @routeDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The line is gone for good. Club rides that planned it keep their own details.'**
  String get routeDeleteConfirmBody;

  /// No description provided for @routeOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the member who added this route can change it.'**
  String get routeOwnerOnly;

  /// No description provided for @addRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a route'**
  String get addRouteTitle;

  /// No description provided for @addRouteHelp.
  ///
  /// In en, this message translates to:
  /// **'A route is a line on the map with a name. Nothing about how you rode it is shared.'**
  String get addRouteHelp;

  /// No description provided for @addRouteFromRide.
  ///
  /// In en, this message translates to:
  /// **'From one of my rides'**
  String get addRouteFromRide;

  /// No description provided for @addRouteFromFile.
  ///
  /// In en, this message translates to:
  /// **'From a GPX file'**
  String get addRouteFromFile;

  /// No description provided for @addRouteChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a GPX file'**
  String get addRouteChooseFile;

  /// No description provided for @addRouteNoRides.
  ///
  /// In en, this message translates to:
  /// **'You have no rides with a map yet. Import a ride first, then come back.'**
  String get addRouteNoRides;

  /// No description provided for @addRoutePreview.
  ///
  /// In en, this message translates to:
  /// **'This is the line the club will see'**
  String get addRoutePreview;

  /// No description provided for @addRoutePrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your privacy zones and your start and end trimming are already applied.'**
  String get addRoutePrivacyNote;

  /// No description provided for @addRouteDetails.
  ///
  /// In en, this message translates to:
  /// **'Name and details'**
  String get addRouteDetails;

  /// No description provided for @addRouteName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get addRouteName;

  /// No description provided for @addRouteDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get addRouteDescription;

  /// No description provided for @addRouteSurface.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get addRouteSurface;

  /// No description provided for @addRouteSave.
  ///
  /// In en, this message translates to:
  /// **'Add to the club library'**
  String get addRouteSave;

  /// No description provided for @editRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit the route'**
  String get editRouteTitle;

  /// No description provided for @ridesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rides planned yet. A coach can plan the club\'s next ride.'**
  String get ridesEmpty;

  /// No description provided for @ridesUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get ridesUpcoming;

  /// No description provided for @ridesPast.
  ///
  /// In en, this message translates to:
  /// **'Just happened'**
  String get ridesPast;

  /// No description provided for @rideCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get rideCancelled;

  /// No description provided for @rideFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get rideFull;

  /// No description provided for @rideSignedUp.
  ///
  /// In en, this message translates to:
  /// **'You are in'**
  String get rideSignedUp;

  /// No description provided for @rideCountIn.
  ///
  /// In en, this message translates to:
  /// **'{count} in'**
  String rideCountIn(int count);

  /// No description provided for @ridePlacesLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} places left'**
  String ridePlacesLeft(int count, int max);

  /// No description provided for @ridePaceEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get ridePaceEasy;

  /// No description provided for @ridePaceSteady.
  ///
  /// In en, this message translates to:
  /// **'Steady'**
  String get ridePaceSteady;

  /// No description provided for @ridePaceFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get ridePaceFast;

  /// No description provided for @rideNoDrop.
  ///
  /// In en, this message translates to:
  /// **'No-drop'**
  String get rideNoDrop;

  /// No description provided for @ridePlannedBy.
  ///
  /// In en, this message translates to:
  /// **'Planned by {name}'**
  String ridePlannedBy(String name);

  /// No description provided for @rideMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting point'**
  String get rideMeeting;

  /// No description provided for @rideRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get rideRoute;

  /// No description provided for @rideNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get rideNotes;

  /// No description provided for @rideWhoIsIn.
  ///
  /// In en, this message translates to:
  /// **'Who is in'**
  String get rideWhoIsIn;

  /// No description provided for @rideNobodyIn.
  ///
  /// In en, this message translates to:
  /// **'Nobody is in yet.'**
  String get rideNobodyIn;

  /// No description provided for @rideImIn.
  ///
  /// In en, this message translates to:
  /// **'I\'m in'**
  String get rideImIn;

  /// No description provided for @rideImOut.
  ///
  /// In en, this message translates to:
  /// **'Take me out'**
  String get rideImOut;

  /// No description provided for @rideEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit ride'**
  String get rideEdit;

  /// No description provided for @rideCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel ride'**
  String get rideCancel;

  /// No description provided for @rideCancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this ride?'**
  String get rideCancelConfirmTitle;

  /// No description provided for @rideCancelConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The riders who are in get a notification. The ride stays on the calendar, marked cancelled.'**
  String get rideCancelConfirmBody;

  /// No description provided for @rideCancelledReason.
  ///
  /// In en, this message translates to:
  /// **'This ride is cancelled.'**
  String get rideCancelledReason;

  /// No description provided for @rideFullReason.
  ///
  /// In en, this message translates to:
  /// **'This ride is full.'**
  String get rideFullReason;

  /// No description provided for @rideStartedReason.
  ///
  /// In en, this message translates to:
  /// **'This ride has already started.'**
  String get rideStartedReason;

  /// No description provided for @planRideTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan a ride'**
  String get planRideTitle;

  /// No description provided for @editRideTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit the ride'**
  String get editRideTitle;

  /// No description provided for @rideFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get rideFormTitle;

  /// No description provided for @rideFormMeetingName.
  ///
  /// In en, this message translates to:
  /// **'Meeting point name'**
  String get rideFormMeetingName;

  /// No description provided for @rideFormPickMeeting.
  ///
  /// In en, this message translates to:
  /// **'Pick the meeting point on the map'**
  String get rideFormPickMeeting;

  /// No description provided for @rideFormRoute.
  ///
  /// In en, this message translates to:
  /// **'Route (optional)'**
  String get rideFormRoute;

  /// No description provided for @rideFormNoRoute.
  ///
  /// In en, this message translates to:
  /// **'No route'**
  String get rideFormNoRoute;

  /// No description provided for @rideFormPace.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get rideFormPace;

  /// No description provided for @rideFormNoDrop.
  ///
  /// In en, this message translates to:
  /// **'No-drop'**
  String get rideFormNoDrop;

  /// No description provided for @rideFormNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get rideFormNotes;

  /// No description provided for @rideFormMaxRiders.
  ///
  /// In en, this message translates to:
  /// **'Maximum riders (optional)'**
  String get rideFormMaxRiders;

  /// No description provided for @rideFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save the ride'**
  String get rideFormSave;

  /// No description provided for @rideFormNeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Give the ride a title.'**
  String get rideFormNeedTitle;

  /// No description provided for @rideFormNeedMeeting.
  ///
  /// In en, this message translates to:
  /// **'Name the meeting point.'**
  String get rideFormNeedMeeting;

  /// No description provided for @rideFormNeedPoint.
  ///
  /// In en, this message translates to:
  /// **'Pick the meeting point on the map.'**
  String get rideFormNeedPoint;

  /// No description provided for @rideFormFuture.
  ///
  /// In en, this message translates to:
  /// **'Choose a date and time in the future.'**
  String get rideFormFuture;

  /// No description provided for @rideFormMaxRange.
  ///
  /// In en, this message translates to:
  /// **'The limit is a number from 1 to 500, or leave it empty.'**
  String get rideFormMaxRange;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar subscription'**
  String get calendarTitle;

  /// No description provided for @calendarHelp.
  ///
  /// In en, this message translates to:
  /// **'Subscribe the calendar on your phone or computer to the club\'s rides. The address is private: whoever has it sees the club\'s rides, never who is in.'**
  String get calendarHelp;

  /// No description provided for @calendarInactive.
  ///
  /// In en, this message translates to:
  /// **'No calendar address yet.'**
  String get calendarInactive;

  /// No description provided for @calendarActive.
  ///
  /// In en, this message translates to:
  /// **'A calendar address is active.'**
  String get calendarActive;

  /// No description provided for @calendarCreate.
  ///
  /// In en, this message translates to:
  /// **'Create the address'**
  String get calendarCreate;

  /// No description provided for @calendarReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace the address'**
  String get calendarReplace;

  /// No description provided for @calendarReplaceConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace the calendar address?'**
  String get calendarReplaceConfirmTitle;

  /// No description provided for @calendarReplaceConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The old address stops working at once and your calendar needs the new one.'**
  String get calendarReplaceConfirmBody;

  /// No description provided for @calendarDelete.
  ///
  /// In en, this message translates to:
  /// **'Stop the address'**
  String get calendarDelete;

  /// No description provided for @calendarDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop the calendar address?'**
  String get calendarDeleteConfirmTitle;

  /// No description provided for @calendarDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your calendar stops updating. You can make a new address at any time.'**
  String get calendarDeleteConfirmBody;

  /// No description provided for @calendarCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy the address'**
  String get calendarCopy;

  /// No description provided for @calendarAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get calendarAddressCopied;

  /// No description provided for @calendarShownOnce.
  ///
  /// In en, this message translates to:
  /// **'Copy it now. The server keeps only a hash, so it cannot show the address again; if you lose it, replace it.'**
  String get calendarShownOnce;

  /// No description provided for @notificationClubRidePlanned.
  ///
  /// In en, this message translates to:
  /// **'{ride}: the club planned a ride.'**
  String notificationClubRidePlanned(String ride);

  /// No description provided for @notificationClubRideChanged.
  ///
  /// In en, this message translates to:
  /// **'{ride}: the time or the meeting point changed.'**
  String notificationClubRideChanged(String ride);

  /// No description provided for @notificationClubRideCancelled.
  ///
  /// In en, this message translates to:
  /// **'{ride}: the ride is cancelled.'**
  String notificationClubRideCancelled(String ride);

  /// No description provided for @supporterSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Supporter'**
  String get supporterSignInTitle;

  /// No description provided for @supporterBecome.
  ///
  /// In en, this message translates to:
  /// **'Become a supporter'**
  String get supporterBecome;

  /// No description provided for @supporterKey.
  ///
  /// In en, this message translates to:
  /// **'Licence key'**
  String get supporterKey;

  /// No description provided for @supporterKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'Paste the key you were sent. It is checked offline, so nobody sees who you are.'**
  String get supporterKeyHelp;

  /// No description provided for @supporterActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get supporterActivate;

  /// No description provided for @supporterKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'That key is not valid. Check that you pasted all of it.'**
  String get supporterKeyInvalid;

  /// No description provided for @supporterAlreadyActivated.
  ///
  /// In en, this message translates to:
  /// **'You already have a supporter licence, or this key was already activated.'**
  String get supporterAlreadyActivated;

  /// No description provided for @supporterClubOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the owner of the club can activate a club licence.'**
  String get supporterClubOwnerOnly;

  /// No description provided for @supporterUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This server does not accept supporter licences.'**
  String get supporterUnavailable;

  /// No description provided for @supporterActivated.
  ///
  /// In en, this message translates to:
  /// **'Licence activated'**
  String get supporterActivated;

  /// No description provided for @supporterThanksName.
  ///
  /// In en, this message translates to:
  /// **'Thank you, {name}.'**
  String supporterThanksName(String name);

  /// No description provided for @supporterBody.
  ///
  /// In en, this message translates to:
  /// **'You just made Velomine a little freer. Nothing changes: everything stays everyone\'s, and your data stays yours.'**
  String get supporterBody;

  /// No description provided for @supporterSerialNumber.
  ///
  /// In en, this message translates to:
  /// **'Supporter no. {serial} · {date}'**
  String supporterSerialNumber(int serial, String date);

  /// No description provided for @supporterKeyVerified.
  ///
  /// In en, this message translates to:
  /// **'Key verified'**
  String get supporterKeyVerified;

  /// No description provided for @supporterReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get supporterReplay;

  /// No description provided for @supporterBadgeReplayHint.
  ///
  /// In en, this message translates to:
  /// **'Plays the licence moment again. Three quick taps.'**
  String get supporterBadgeReplayHint;

  /// No description provided for @supporterContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get supporterContinue;

  /// No description provided for @supporter.
  ///
  /// In en, this message translates to:
  /// **'Supporter'**
  String get supporter;

  /// No description provided for @supporterAppearsOnProfile.
  ///
  /// In en, this message translates to:
  /// **'appears on your profile'**
  String get supporterAppearsOnProfile;

  /// No description provided for @supporterHideBadge.
  ///
  /// In en, this message translates to:
  /// **'Hide supporter badge'**
  String get supporterHideBadge;

  /// No description provided for @supporterHideBadgeHelp.
  ///
  /// In en, this message translates to:
  /// **'The licence still counts. The badge is yours to show or hide.'**
  String get supporterHideBadgeHelp;

  /// No description provided for @actionLoadSupporter.
  ///
  /// In en, this message translates to:
  /// **'load your supporter licence'**
  String get actionLoadSupporter;

  /// No description provided for @actionActivateSupporter.
  ///
  /// In en, this message translates to:
  /// **'activate the licence'**
  String get actionActivateSupporter;

  /// No description provided for @actionSaveSupporter.
  ///
  /// In en, this message translates to:
  /// **'save your supporter badge'**
  String get actionSaveSupporter;
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
