import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import '../../core/user_message.dart';
import 'privacy_data.dart';
import 'privacy_state.dart';

part 'privacy_view_model.g.dart';

/// The member's privacy choices. Route-scoped, so leaving the screen drops
/// them; a sign-out or account change rebuilds it empty.
@riverpod
class PrivacyViewModel extends _$PrivacyViewModel {
  int _messageId = 0;

  @override
  PrivacyState build() {
    if (ref.watch(signedInUserIdProvider) == null) return const PrivacyState();
    Future.microtask(load);
    return const PrivacyState();
  }

  Future<void> load() async {
    if (state.load.running) return;
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(privacyDataProvider).load();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        privacy: value ?? state.privacy,
        loaded: true,
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  /// Saves every switch and both trims in one request, so a half-saved screen
  /// cannot leave the member believing something is hidden when it is not.
  Future<void> saveSettings({
    required bool hideHeartRate,
    required bool hidePower,
    required bool hideCadence,
    required bool hideSpeed,
    required bool hideElevation,
    required bool hideTemperature,
    required int trimStartM,
    required int trimEndM,
  }) async {
    if (state.save.running) return;
    state = state.copyWith(save: state.save.start());
    final result = await ref
        .read(privacyDataProvider)
        .save(
          UpdatePrivacyRequest(
            hideHeartRate: hideHeartRate,
            hidePower: hidePower,
            hideCadence: hideCadence,
            hideSpeed: hideSpeed,
            hideElevation: hideElevation,
            hideTemperature: hideTemperature,
            trimStartM: trimStartM,
            trimEndM: trimEndM,
          ),
        );
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        save: state.save.finish(result),
        privacy: value ?? state.privacy,
      ),
      Failed(:final failure) => _failed(result, failure),
    };
  }

  Future<void> addZone({
    required String name,
    required double latitude,
    required double longitude,
    required int radiusM,
  }) async {
    if (state.save.running) return;
    state = state.copyWith(save: state.save.start());
    final result = await ref
        .read(privacyDataProvider)
        .addZone(
          CreatePrivacyZoneRequest(
            name: name,
            latitude: latitude,
            longitude: longitude,
            radiusM: radiusM,
          ),
        );
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => state.copyWith(save: state.save.finish(result)),
      Failed(:final failure) => _failed(result, failure),
    };
    if (result.isOk) await load();
  }

  Future<void> deleteZone(String id) async {
    if (state.save.running) return;
    state = state.copyWith(save: state.save.start());
    final result = await ref.read(privacyDataProvider).deleteZone(id);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => state.copyWith(save: state.save.finish(result)),
      Failed(:final failure) => _failed(result, failure),
    };
    if (result.isOk) await load();
  }

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );

  PrivacyState _failed<T>(Result<T> result, Failure failure) => state.copyWith(
    save: state.save.finish(result),
    messages: [...state.messages, FailureMessage(_messageId++, failure)],
  );
}
