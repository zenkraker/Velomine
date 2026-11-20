import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/providers.dart';
import '../../core/rider_mode.dart';
import 'profile_data.dart';
import 'rider_mode_state.dart';

part 'rider_mode_view_model.g.dart';

/// Saves the member's rider mode. The mode itself stays in `session.me`: this only runs the save through one
/// queue and says whether it worked, so a failed save keeps the old mode and the sheet can show why.
@Riverpod(keepAlive: true)
class RiderModeViewModel extends _$RiderModeViewModel {
  /// Saves run one after another, so a dismissal's save cannot land after a mode chosen meanwhile.
  Future<void> _queue = Future.value();

  @override
  RiderModeState build() {
    // A sign-out or another account rebuilds this empty, so the next member is asked.
    ref.watch(signedInUserIdProvider);
    return const RiderModeState();
  }

  /// The sheet is open or was dismissed, so it does not open again in this session.
  void promptShown() {
    if (!state.promptHandled) state = state.copyWith(promptHandled: true);
  }

  /// Opening the sheet starts on a clean slate: a save that failed last time is not shown again.
  void clearSave() =>
      state = RiderModeState(promptHandled: state.promptHandled);

  /// Saves [mode] on the account. With [onlyIfUnset] the call is skipped when the account already has a mode,
  /// which is what a dismissal sends: it must never overwrite a choice made meanwhile.
  ///
  /// Returns true when the account holds the mode (or already did).
  Future<bool> choose(RiderMode mode, {bool onlyIfUnset = false}) {
    final done = _queue.then((_) => _choose(mode, onlyIfUnset));
    // The queue only waits, so one failed save never stops the next.
    _queue = done.then((_) {}, onError: (_) {});
    return done;
  }

  Future<bool> _choose(RiderMode mode, bool onlyIfUnset) async {
    if (!ref.mounted) return false;
    if (onlyIfUnset &&
        ref.read(sessionViewModelProvider).me?.riderMode != null) {
      return true;
    }

    state = state.copyWith(save: state.save.start());
    final result = await ref.read(profileDataProvider).setRiderMode(mode);
    if (!ref.mounted) return false;
    state = state.copyWith(save: state.save.finish(result));

    final updated = result.valueOrNull;
    if (updated == null) return false;
    ref.read(sessionProvider).adoptMe(updated);
    return true;
  }
}
