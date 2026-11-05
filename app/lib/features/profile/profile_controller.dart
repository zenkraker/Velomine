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
