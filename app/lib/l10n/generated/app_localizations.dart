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
