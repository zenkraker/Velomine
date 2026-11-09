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
  loadRide,
  changeRideBike,
  changeRideType,
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
  loadSharing,
  saveSharing,
  loadAthletes,
  loadAthlete,
  loadCoachRide,
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

String _actionText(AppLocalizations l10n, FailureAction action) =>
    switch (action) {
      FailureAction.general => l10n.actionGeneral,
      FailureAction.loadRides => l10n.actionLoadRides,
      FailureAction.uploadRide => l10n.actionUploadRide,
      FailureAction.loadRide => l10n.actionLoadRide,
      FailureAction.changeRideBike => l10n.actionChangeRideBike,
      FailureAction.changeRideType => l10n.actionChangeRideType,
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
      FailureAction.loadSharing => l10n.actionLoadSharing,
      FailureAction.saveSharing => l10n.actionSaveSharing,
      FailureAction.loadAthletes => l10n.actionLoadAthletes,
      FailureAction.loadAthlete => l10n.actionLoadAthlete,
      FailureAction.loadCoachRide => l10n.actionLoadCoachRide,
    };

/// The sentence for a failure in the language on screen.
String failureText(AppLocalizations l10n, Failure failure) =>
    switch (failure.kind) {
      FailureKind.rejected => failure.detail ?? l10n.failureRejected,
      FailureKind.conflict => failure.detail ?? l10n.failureConflict,
      FailureKind.missing => l10n.failureMissing,
      FailureKind.mailRejected => l10n.failureMail,
      FailureKind.wrongConfirmation => l10n.failureWrongConfirmation,
      FailureKind.lastAdmin => l10n.failureLastAdmin,
      FailureKind.unreachable => l10n.failureUnreachable,
      FailureKind.failed => l10n.failureFailed(
        _actionText(l10n, failure.action),
        failure.code ?? 0,
      ),
    };
