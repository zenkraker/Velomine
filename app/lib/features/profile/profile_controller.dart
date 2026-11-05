import 'package:flutter/foundation.dart';
import 'package:velomine_api/api.dart';

import '../../core/guard.dart';

/// The member's profile: what Velomine knows about them for training numbers and for their calendar.
class ProfileController extends ChangeNotifier {
  ProfileController({
    required this.api,
    required this.onUnauthorized,
    this.onSaved,
  });

  final AccountsApi api;
  final VoidCallback onUnauthorized;

  /// Called after a save, so screens that show the member's name can update.
  final VoidCallback? onSaved;

  ProfileResponse? profile;
  bool exporting = false;
  bool loading = true;
  bool saving = false;
  String? error;

  Future<void> load() async {
    error = await guardCall(
      () async => profile = await api.getProfile(),
      onUnauthorized,
      what: 'load your profile',
    );
    loading = false;
    notifyListeners();
  }

  /// Asks for a download link for all of the member's data. Returns the path on the server, or null when it failed
  /// (then [error] says why).
  Future<String?> exportLink() async {
    exporting = true;
    error = null;
    notifyListeners();
    ExportLinkResponse? link;
    error = await guardCall(
      () async => link = await api.createExportLink(),
      onUnauthorized,
      what: 'prepare your data',
    );
    exporting = false;
    notifyListeners();
    return link?.path;
  }

  /// Deletes the member's account and all its data. [password] confirms an account that has one, [confirmEmail] one
  /// that does not (single sign-on). Returns whether it was deleted; otherwise [error] says why.
  Future<bool> deleteAccount({String? password, String? confirmEmail}) async {
    error = null;
    try {
      await api.deleteMyAccount(
        DeleteMyAccountRequest(password: password, confirmEmail: confirmEmail),
      );
    } on ApiException catch (e) {
      error = switch (e.code) {
        401 => null,
        403 => 'That does not match. Nothing was deleted.',
        409 => 'You are the only admin. Make someone else an admin first.',
        _ => 'Could not delete the account (${e.code}). Try again.',
      };
      if (e.code == 401) onUnauthorized();
      notifyListeners();
      return false;
    } on Object {
      error = 'Could not reach the server. Try again.';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> save(UpdateProfileRequest request) async {
    saving = true;
    error = null;
    notifyListeners();
    ProfileResponse? saved;
    error = await guardCall(
      () async => saved = await api.updateProfile(request),
      onUnauthorized,
      what: 'save your profile',
    );
    if (saved != null) profile = saved;
    saving = false;
    notifyListeners();
    if (error == null) onSaved?.call();
    return error == null;
  }
}
