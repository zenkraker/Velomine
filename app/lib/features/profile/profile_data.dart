import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';

part 'profile_data.g.dart';

/// The profile endpoints as values: the ViewModel never sees an exception.
class ProfileData {
  ProfileData(this._api, {required this.onUnauthorized});

  final AccountsApi _api;
  final void Function() onUnauthorized;

  Future<Result<ProfileResponse?>> profile() => _api.getProfile().guard(
    FailureAction.loadProfile,
    onUnauthorized: onUnauthorized,
  );

  Future<Result<ProfileResponse?>> save(UpdateProfileRequest request) => _api
      .updateProfile(request)
      .guard(FailureAction.saveProfile, onUnauthorized: onUnauthorized);

  Future<Result<String?>> exportLink() async =>
      (await _api.createExportLink().guard(
        FailureAction.prepareData,
        onUnauthorized: onUnauthorized,
      )).map((link) => link?.path);

  Future<Result<Failure?>> changePassword(
    String current,
    String newPassword,
  ) async {
    final result = await _api
        .changePassword(
          ChangePasswordRequest(
            currentPassword: current,
            newPassword: newPassword,
          ),
        )
        .guard(FailureAction.changePassword, onUnauthorized: onUnauthorized);
    return result.map((_) => null);
  }

  /// Deleting answers with three meanings of its own: the password or email
  /// did not match, and the last admin may not go.
  Future<Result<void>> deleteAccount({
    String? password,
    String? confirmEmail,
  }) async {
    try {
      await _api.deleteMyAccount(
        DeleteMyAccountRequest(password: password, confirmEmail: confirmEmail),
      );
      return const Ok(null);
    } on ApiException catch (e) {
      if (e.code == 401) onUnauthorized();
      return Failed(
        Failure(
          switch (e.code) {
            401 => FailureKind.sessionEnded,
            403 => FailureKind.wrongConfirmation,
            409 => FailureKind.lastAdmin,
            _ => failureKindFor(e.code),
          },
          code: e.code,
          action: FailureAction.deleteAccount,
          detail: serverDetail(e.message),
        ),
      );
    } on Object {
      return const Failed(
        Failure(FailureKind.unreachable, action: FailureAction.deleteAccount),
      );
    }
  }
}

@Riverpod(keepAlive: true)
ProfileData profileData(Ref ref) {
  final session = ref.watch(sessionProvider);
  return ProfileData(session.accounts, onUnauthorized: session.sessionExpired);
}
