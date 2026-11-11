import 'dart:convert';

import '../l10n/generated/app_localizations.dart';

/// What went wrong with a request, kept as a kind so the screen can say it in the language that is showing now.
enum FailureKind {
  /// The server did not accept the values (400).
  rejected,

  /// It does not exist, or the member may not see it (404).
  missing,

  /// The change conflicts with the current state (409).
  conflict,

  /// The mail server refused the message (502).
  mailRejected,

  /// The session ended, or the credentials were refused (401).
  sessionEnded,

  /// The account may not do this (403).
  forbidden,

  /// Too many attempts (429).
  throttled,

  /// Sign-in refused the email or password (401 on login).
  wrongPassword,

  /// The account is waiting for approval (403 on login or single sign-on).
  notApproved,

  /// The account is locked out (423).
  lockedOut,

  /// Sign-up is closed on this server (403 on register).
  signUpClosed,

  /// The password does not meet the rules (400 on register).
  weakPassword,

  /// The email address already has an account (400 on register).
  emailTaken,

  /// A confirmation did not match what the account holds.
  wrongConfirmation,

  /// This is the only admin, so the account cannot go.
  lastAdmin,

  /// Another error code.
  failed,

  /// The server could not be reached at all.
  unreachable,
}

/// What the request was doing, so the sentence can name it: "Could not load your rides (500)."
enum FailureAction {
  general,
  loadRides,
  uploadRide,
  importRides,
  loadImport,
  loadRide,
  changeRideBike,
  changeRideType,
  saveRideDetails,
  deleteRide,
  loadBikes,
  addBike,
  loadBike,
  saveBike,
  setDefaultBike,
  deleteBike,
  addPart,
  savePart,
  removePart,
  loadServiceLog,
  saveReminder,
  removeReminder,
  completeReminder,
  saveServiceEntry,
  removeServiceEntry,
  loadTemplates,
  saveTemplate,
  applyTemplate,
  loadProgress,
  addGoal,
  changeGoal,
  deleteGoal,
  saveWellbeing,
  setFtp,
  loadAdmin,
  reloadAccounts,
  approveAccount,
  changeRoles,
  lockAccount,
  unlockAccount,
  deleteAccount,
  sendTestEmail,
  saveSettings,
  loadProfile,
  prepareData,
  saveProfile,
  loadNotifications,
  markRead,
  markAllRead,
  loadClub,
  joinClub,
  leaveClub,
  rotateJoinCode,
  changeClubRole,
  loadAdminClubs,
  createClub,
  updateClub,
  setClubOwner,
  startClub,
  setClubPlan,
  loadSharing,
  saveSharing,
  loadPrivacy,
  savePrivacy,
  loadAthletes,
  loadAthlete,
  loadCoachRide,
  changePassword,
  resetPassword,
  loadNearbyClubs,
  requestJoinClub,
  cancelJoinRequest,
  loadJoinRequests,
  approveJoinRequest,
  declineJoinRequest,
  loadSecurity,
  changeSecurity,
}

class Failure {
  const Failure(
    this.kind, {
    this.code,
    this.action = FailureAction.general,
    this.detail,
  });

  final FailureKind kind;
  final int? code;
  final FailureAction action;

  /// A sentence from the server for a rejected request, when it sent one.
  final String? detail;
}

/// The kind a status code maps to when no more specific meaning is known.
FailureKind failureKindFor(int code) => switch (code) {
  400 => FailureKind.rejected,
  401 => FailureKind.sessionEnded,
  403 => FailureKind.forbidden,
  404 => FailureKind.missing,
  409 => FailureKind.conflict,
  423 => FailureKind.lockedOut,
  429 => FailureKind.throttled,
  502 => FailureKind.mailRejected,
  _ => FailureKind.failed,
};

/// The sentence the server sent for a validation or conflict error, if it sent one.
///
/// FastEndpoints answers with ProblemDetails: `{"errors":{"generalErrors":["..."]}}` or a `detail` string. The
/// sentence is English today (bodies are not localized yet), but it is far more useful than "the server did not
/// accept that": it names the missing account, the duplicate name, and so on.
String? serverDetail(String? body) {
  if (body == null || body.isEmpty) return null;
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map) return null;
    final errors = decoded['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty && value.first is String) {
          final text = (value.first as String).trim();
          if (text.isNotEmpty) return text;
        }
      }
    }
    final detail = decoded['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail.trim();
    final title = decoded['title'];
    if (title is String &&
        title.trim().isNotEmpty &&
        !title.toLowerCase().contains('validation')) {
      return title.trim();
    }
  } on FormatException {
    return null;
  }
  return null;
}

String _actionText(AppLocalizations l10n, FailureAction action) =>
    switch (action) {
      FailureAction.general => l10n.actionGeneral,
      FailureAction.loadRides => l10n.actionLoadRides,
      FailureAction.uploadRide => l10n.actionUploadRide,
      FailureAction.importRides => l10n.actionImportRides,
      FailureAction.loadImport => l10n.actionLoadImport,
      FailureAction.loadRide => l10n.actionLoadRide,
      FailureAction.changeRideBike => l10n.actionChangeRideBike,
      FailureAction.changeRideType => l10n.actionChangeRideType,
      FailureAction.saveRideDetails => l10n.actionSaveRideDetails,
      FailureAction.deleteRide => l10n.actionDeleteRide,
      FailureAction.loadBikes => l10n.actionLoadBikes,
      FailureAction.addBike => l10n.actionAddBike,
      FailureAction.loadBike => l10n.actionLoadBike,
      FailureAction.saveBike => l10n.actionSaveBike,
      FailureAction.setDefaultBike => l10n.actionSetDefaultBike,
      FailureAction.deleteBike => l10n.actionDeleteBike,
      FailureAction.addPart => l10n.actionAddPart,
      FailureAction.savePart => l10n.actionSavePart,
      FailureAction.removePart => l10n.actionRemovePart,
      FailureAction.loadServiceLog => l10n.actionLoadServiceLog,
      FailureAction.saveReminder => l10n.actionSaveReminder,
      FailureAction.removeReminder => l10n.actionRemoveReminder,
      FailureAction.completeReminder => l10n.actionCompleteReminder,
      FailureAction.saveServiceEntry => l10n.actionSaveServiceEntry,
      FailureAction.removeServiceEntry => l10n.actionRemoveServiceEntry,
      FailureAction.loadTemplates => l10n.actionLoadTemplates,
      FailureAction.saveTemplate => l10n.actionSaveTemplate,
      FailureAction.applyTemplate => l10n.actionApplyTemplate,
      FailureAction.loadProgress => l10n.actionLoadProgress,
      FailureAction.addGoal => l10n.actionAddGoal,
      FailureAction.changeGoal => l10n.actionChangeGoal,
      FailureAction.deleteGoal => l10n.actionDeleteGoal,
      FailureAction.saveWellbeing => l10n.actionSaveWellbeing,
      FailureAction.setFtp => l10n.actionSetFtp,
      FailureAction.loadAdmin => l10n.actionLoadAdmin,
      FailureAction.reloadAccounts => l10n.actionReloadAccounts,
      FailureAction.approveAccount => l10n.actionApproveAccount,
      FailureAction.changeRoles => l10n.actionChangeRoles,
      FailureAction.lockAccount => l10n.actionLockAccount,
      FailureAction.unlockAccount => l10n.actionUnlockAccount,
      FailureAction.deleteAccount => l10n.actionDeleteAccount,
      FailureAction.sendTestEmail => l10n.actionSendTestEmail,
      FailureAction.saveSettings => l10n.actionSaveSettings,
      FailureAction.loadProfile => l10n.actionLoadProfile,
      FailureAction.prepareData => l10n.actionPrepareData,
      FailureAction.saveProfile => l10n.actionSaveProfile,
      FailureAction.loadNotifications => l10n.actionLoadNotifications,
      FailureAction.markRead => l10n.actionMarkRead,
      FailureAction.markAllRead => l10n.actionMarkAllRead,
      FailureAction.loadClub => l10n.actionLoadClub,
      FailureAction.joinClub => l10n.actionJoinClub,
      FailureAction.leaveClub => l10n.actionLeaveClub,
      FailureAction.rotateJoinCode => l10n.actionRotateJoinCode,
      FailureAction.changeClubRole => l10n.actionChangeClubRole,
      FailureAction.loadAdminClubs => l10n.actionLoadAdminClubs,
      FailureAction.createClub => l10n.actionCreateClub,
      FailureAction.updateClub => l10n.actionUpdateClub,
      FailureAction.setClubOwner => l10n.actionSetClubOwner,
      FailureAction.startClub => l10n.actionStartClub,
      FailureAction.setClubPlan => l10n.actionSetClubPlan,
      FailureAction.loadSharing => l10n.actionLoadSharing,
      FailureAction.saveSharing => l10n.actionSaveSharing,
      FailureAction.loadPrivacy => l10n.actionLoadPrivacy,
      FailureAction.savePrivacy => l10n.actionSavePrivacy,
      FailureAction.loadAthletes => l10n.actionLoadAthletes,
      FailureAction.loadAthlete => l10n.actionLoadAthlete,
      FailureAction.loadCoachRide => l10n.actionLoadCoachRide,
      FailureAction.changePassword => l10n.actionChangePassword,
      FailureAction.resetPassword => l10n.actionResetPassword,
      FailureAction.loadNearbyClubs => l10n.actionLoadNearbyClubs,
      FailureAction.requestJoinClub => l10n.actionRequestJoinClub,
      FailureAction.cancelJoinRequest => l10n.actionCancelJoinRequest,
      FailureAction.loadJoinRequests => l10n.actionLoadJoinRequests,
      FailureAction.approveJoinRequest => l10n.actionApproveJoinRequest,
      FailureAction.declineJoinRequest => l10n.actionDeclineJoinRequest,
      FailureAction.loadSecurity => l10n.actionLoadSecurity,
      FailureAction.changeSecurity => l10n.actionChangeSecurity,
    };

/// The sentence for a failure in the language on screen.
String failureText(AppLocalizations l10n, Failure failure) =>
    switch (failure.kind) {
      FailureKind.rejected => failure.detail ?? l10n.failureRejected,
      FailureKind.conflict => failure.detail ?? l10n.failureConflict,
      FailureKind.missing => l10n.failureMissing,
      FailureKind.mailRejected => l10n.failureMail,
      FailureKind.sessionEnded => l10n.failureSessionEnded,
      FailureKind.forbidden => l10n.failureForbidden,
      FailureKind.throttled => l10n.failureTooMany,
      FailureKind.wrongPassword => l10n.authWrongPassword,
      FailureKind.notApproved => l10n.authNotApproved,
      FailureKind.lockedOut => l10n.authLockedOut,
      FailureKind.signUpClosed => l10n.authSignUpClosed,
      FailureKind.weakPassword => l10n.authWeakPassword,
      FailureKind.emailTaken => l10n.authEmailTaken,
      FailureKind.wrongConfirmation => l10n.failureWrongConfirmation,
      FailureKind.lastAdmin => l10n.failureLastAdmin,
      FailureKind.unreachable => l10n.failureUnreachable,
      FailureKind.failed => l10n.failureFailed(
        _actionText(l10n, failure.action),
        failure.code ?? 0,
      ),
    };
