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

  /// No description provided for @clubMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String clubMemberCount(int count);

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
  /// **'In the brand\'s own form: 56, M, S3, 17.5\". Optional.'**
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
