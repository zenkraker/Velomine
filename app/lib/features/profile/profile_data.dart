import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import '../../core/rider_mode.dart';

part 'profile_data.g.dart';

/// The profile endpoints as values: the ViewModel never sees an exception.
class ProfileData {
  ProfileData(this._api, this._rides);

  final AccountsApi _api;
  final RidesApi _rides;

  Future<Result<ProfileResponse?>> profile() =>
      _api.getProfile().guard(FailureAction.loadProfile);

  /// When the ride a test FTP came from started; null when it cannot be read, and the note then uses the day
  /// the FTP was set.
  Future<DateTime?> rideStart(String id) async {
    final ride = await _rides.getRide(id).guard(FailureAction.loadProfile);
    return ride.valueOrNull?.startTime;
  }

  /// A ride's own local date: its start plus the offset it recorded, not the phone's zone. Null when it cannot be
  /// read.
  Future<DateTime?> rideLocalDate(String id) async {
    final ride = (await _rides.getRide(id).guard(FailureAction.loadProfile))
        .valueOrNull;
    if (ride?.startTime case final start?) {
      return start.add(Duration(minutes: ride!.utcOffsetMinutes ?? 0));
    }
    return null;
  }

  Future<Result<TelemetryResponse?>> telemetry() =>
      _api.getTelemetry().guard(FailureAction.loadProfile);

  Future<Result<TelemetryResponse?>> setTelemetry({
    required bool crash,
    required bool usage,
  }) => _api
      .setTelemetry(SetTelemetryRequest(crash: crash, usage: usage))
      .guard(FailureAction.saveProfile);

  Future<Result<ProfileResponse?>> save(UpdateProfileRequest request) =>
      _api.updateProfile(request).guard(FailureAction.saveProfile);

  /// How the member rides. The answer is the whole account, so the session can hold the saved mode at once.
  Future<Result<MeResponse?>> setRiderMode(RiderMode mode) => _api
      .setMyRiderMode(SetMyRiderModeRequest(riderMode: mode.slug))
      .guard(FailureAction.saveProfile);

  /// Sets the maximum (`max`) or the threshold heart rate the rider typed.
  Future<Result<ProfileResponse?>> setHeartRate(String kind, int bpm) => _api
      .setHeartRate(kind, SetHeartRateRequest(bpm: bpm))
      .guard(FailureAction.saveProfile);

  /// Back to the estimate: no set value.
  Future<Result<ProfileResponse?>> clearHeartRate(String kind) =>
      _api.clearHeartRate(kind).guard(FailureAction.saveProfile);

  Future<Result<String?>> exportLink() async =>
      (await _api.createExportLink().guard(FailureAction.prepareData))
          .map((link) => link?.path);

  Future<Result<Failure?>> changePassword(
    String current,
    String newPassword,
  ) async {
    final result = await _api
        .changePassword(
          ChangePasswordRequest(
            currentPassword: current.trim(),
            newPassword: newPassword.trim(),
          ),
        )
        .guard(FailureAction.changePassword);
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
        DeleteMyAccountRequest(
          password: password?.trim(),
          confirmEmail: confirmEmail?.trim(),
        ),
      );
      return const Ok(null);
    } on ApiException catch (e) {
      return Failed(
        Failure(
          switch (e.code) {
            401 => FailureKind.sessionEnded,
            403 when isDemoLocked(e.message) => FailureKind.demoLocked,
            403 => FailureKind.wrongConfirmation,
            409 => FailureKind.lastAdmin,
            _ => failureKindFor(e.code, e.message),
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
  return ProfileData(session.accounts, session.rides);
}
