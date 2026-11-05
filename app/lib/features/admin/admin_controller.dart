import 'package:flutter/foundation.dart';
import 'package:velomine_api/api.dart';

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
  SettingsResponse? settings;
  OverviewResponse? overview;
  bool loading = false;
  bool saving = false;
  String? error;

  /// The outcome of the last test email: null before one was sent.
  String? testEmailResult;
  bool testEmailFailed = false;

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
        ]);
        users = (results[0] as ListAdminUsersResponse?)?.users ?? [];
        settings = results[1] as SettingsResponse?;
        overview = results[2] as OverviewResponse?;
      },
      onUnauthorized,
      what: 'load the admin pages',
    );
    loading = false;
    notifyListeners();
  }

  /// Runs a change to one account, then reads the accounts and the overview again. Returns whether it worked.
  Future<bool> _change(Future<void> Function() call, String what) async {
    error = await guardCall(call, onUnauthorized, what: what);
    error ??= await guardCall(
      () async {
        users = (await api.listAdminUsers())?.users ?? users;
        overview = await api.getOverview() ?? overview;
      },
      onUnauthorized,
      what: 'reload the accounts',
    );
    notifyListeners();
    return error == null;
  }

  Future<bool> approve(AdminUserSummary u) =>
      _change(() => accounts.approveUser(u.id), 'approve ${u.email}');

  Future<bool> setRoles(AdminUserSummary u, List<String> roles) =>
      _change(() async {
        await api.setUserRoles(u.id, SetUserRolesRequest(roles: roles));
      }, 'change the roles');

  Future<bool> lock(AdminUserSummary u) =>
      _change(() => api.lockUser(u.id), 'lock the account');

  Future<bool> unlock(AdminUserSummary u) =>
      _change(() => api.unlockUser(u.id), 'unlock the account');

  Future<bool> delete(AdminUserSummary u) =>
      _change(() => api.deleteUser(u.id), 'delete the account');

  /// Sends a test email to the signed-in admin and records how it went for the settings screen.
  Future<void> sendTestEmail() async {
    testEmailResult = null;
    final problem = await guardCall(
      api.sendTestEmail,
      onUnauthorized,
      what: 'send the test email',
    );
    testEmailFailed = problem != null;
    testEmailResult = problem ?? 'Test email sent to your own address.';
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
      what: 'save the settings',
    );
    if (saved != null) settings = saved;
    saving = false;
    notifyListeners();
    return error == null;
  }
}
