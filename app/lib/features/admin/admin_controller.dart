import 'package:flutter/foundation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/guard.dart';

/// What an admin sees and does: every account, the settings, and the server overview.
class AdminController extends ChangeNotifier {
  AdminController({
    required this.api,
    required this.accounts,
    required this.onUnauthorized,
    required this.myId,
  });

  final AdminApi api;
  final AccountsApi accounts;
  final VoidCallback onUnauthorized;

  /// The signed-in admin, so the screen offers no lock or delete on their own account.
  final String? Function() myId;

  List<AdminUserSummary> users = [];
  List<AdminClubResponse> clubs = [];
  SettingsResponse? settings;
  OverviewResponse? overview;
  bool loading = false;
  bool saving = false;
  bool clubsBusy = false;
  Failure? error;

  /// How the last test email went: null before one was sent, then sent or the failure.
  bool testEmailSent = false;
  Failure? testEmailError;

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    error = await guardCall(
      () async {
        final results = await Future.wait([
          api.listAdminUsers(),
          api.getSettings(),
          api.getOverview(),
          api.clubsListAdminClubs(),
        ]);
        users = (results[0] as ListAdminUsersResponse?)?.users ?? [];
        settings = results[1] as SettingsResponse?;
        overview = results[2] as OverviewResponse?;
        clubs = (results[3] as AdminClubListResponse?)?.clubs ?? [];
      },
      onUnauthorized,
      doing: FailureAction.loadAdmin,
    );
    loading = false;
    notifyListeners();
  }

  /// Runs a change to one account, then reads the accounts and the overview again. Returns whether it worked.
  Future<bool> _change(
    Future<void> Function() call,
    FailureAction doing,
  ) async {
    error = await guardCall(call, onUnauthorized, doing: doing);
    error ??= await guardCall(
      () async {
        users = (await api.listAdminUsers())?.users ?? users;
        overview = await api.getOverview() ?? overview;
      },
      onUnauthorized,
      doing: FailureAction.reloadAccounts,
    );
    notifyListeners();
    return error == null;
  }

  Future<bool> approve(AdminUserSummary u) =>
      _change(() => accounts.approveUser(u.id), FailureAction.approveAccount);

  Future<bool> setRoles(AdminUserSummary u, List<String> roles) =>
      _change(() async {
        await api.setUserRoles(u.id, SetUserRolesRequest(roles: roles));
      }, FailureAction.changeRoles);

  Future<bool> lock(AdminUserSummary u) =>
      _change(() => api.lockUser(u.id), FailureAction.lockAccount);

  Future<bool> unlock(AdminUserSummary u) =>
      _change(() => api.unlockUser(u.id), FailureAction.unlockAccount);

  Future<bool> delete(AdminUserSummary u) =>
      _change(() => api.deleteUser(u.id), FailureAction.deleteAccount);

  /// Sends a test email to the signed-in admin and records how it went for the settings screen.
  Future<void> sendTestEmail() async {
    testEmailSent = false;
    testEmailError = await guardCall(
      api.sendTestEmail,
      onUnauthorized,
      doing: FailureAction.sendTestEmail,
    );
    testEmailSent = testEmailError == null;
    notifyListeners();
  }

  Future<bool> saveSettings(UpdateSettingsRequest request) async {
    saving = true;
    error = null;
    notifyListeners();
    SettingsResponse? saved;
    error = await guardCall(
      () async => saved = await api.updateSettings(request),
      onUnauthorized,
      doing: FailureAction.saveSettings,
    );
    if (saved != null) settings = saved;
    saving = false;
    notifyListeners();
    return error == null;
  }

  /// Creates a club with an existing account as its owner. Returns the reason it failed, or null.
  Future<Failure?> createClub(String name, String ownerEmail) async {
    clubsBusy = true;
    error = null;
    notifyListeners();
    final failure = await guardCall(
      () => api.clubsCreateClub(
        CreateClubRequest(name: name, ownerEmail: ownerEmail),
      ),
      onUnauthorized,
      doing: FailureAction.createClub,
    );
    error = failure;
    if (failure == null) await _reloadClubs();
    clubsBusy = false;
    notifyListeners();
    return failure;
  }

  /// Turns a club on or off. A disabled club takes no new joins but keeps its members and data.
  Future<Failure?> setClubActive(AdminClubResponse club, bool active) async {
    clubsBusy = true;
    error = null;
    notifyListeners();
    final failure = await guardCall(
      () => api.clubsUpdateClub(
        club.id,
        UpdateClubRequest(name: club.name, isActive: active),
      ),
      onUnauthorized,
      doing: FailureAction.updateClub,
    );
    error = failure;
    if (failure == null) await _reloadClubs();
    clubsBusy = false;
    notifyListeners();
    return failure;
  }

  /// Moves ownership to another member of the club, so the old owner can leave.
  Future<Failure?> setClubOwner(AdminClubResponse club, String userId) async {
    clubsBusy = true;
    error = null;
    notifyListeners();
    final failure = await guardCall(
      () => api.clubsSetClubOwner(club.id, SetClubOwnerRequest(userId: userId)),
      onUnauthorized,
      doing: FailureAction.setClubOwner,
    );
    error = failure;
    if (failure == null) await _reloadClubs();
    clubsBusy = false;
    notifyListeners();
    return failure;
  }

  Future<void> _reloadClubs() async {
    try {
      clubs = (await api.clubsListAdminClubs())?.clubs ?? clubs;
    } on Object {
      // Keeps the list it had; the next refresh reads it again.
    }
    notifyListeners();
  }
}
