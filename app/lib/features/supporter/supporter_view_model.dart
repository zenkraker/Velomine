import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import '../../core/user_message.dart';
import 'supporter_data.dart';
import 'supporter_state.dart';

part 'supporter_view_model.g.dart';

/// The member's supporter licence. Kept alive for the session; a sign-out
/// rebuilds it empty, so the next account never sees the last one's badge.
@Riverpod(keepAlive: true)
class SupporterViewModel extends _$SupporterViewModel {
  int _messageId = 0;

  /// Set before the first await, so a load started from [build] and one started
  /// by a screen asking again are not both asked of the server.
  bool _loading = false;

  @override
  SupporterState build() {
    if (ref.watch(signedInUserIdProvider) == null) {
      return const SupporterState();
    }
    Future.microtask(load);
    return const SupporterState();
  }

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(supporterDataProvider).status();
    _loading = false;
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        available: value?.available ?? false,
        riderLicence: value?.rider,
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  /// Activates a key. True once the licence is held, so the view can celebrate;
  /// a refused key stays in [SupporterState.activate] for the screen to word.
  Future<bool> activate(String key) async {
    if (state.activate.running) return false;
    state = state.copyWith(activate: state.activate.start());
    final result = await ref.read(supporterDataProvider).activate(key);
    if (!ref.mounted) return false;

    state = switch (result) {
      Ok(:final value) => state.copyWith(
        activate: state.activate.finish(result),
        available: value?.available ?? state.available,
        riderLicence: value?.rider ?? state.riderLicence,
      ),
      Failed() => state.copyWith(activate: state.activate.finish(result)),
    };
    return result is Ok;
  }

  /// Shows or hides the badge. The licence stays either way.
  Future<void> setHidden(bool hidden) async {
    if (state.hidden.running) return;
    state = state.copyWith(hidden: state.hidden.start());
    final result = await ref.read(supporterDataProvider).setHidden(hidden);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        hidden: state.hidden.finish(result),
        riderLicence: value ?? state.riderLicence,
      ),
      Failed() => state.copyWith(hidden: state.hidden.finish(result)),
    };
    if (result case Failed(:final failure)) _fail(failure);
  }

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );

  void _fail(Failure failure) => state = state.copyWith(
    messages: [...state.messages, FailureMessage(_messageId++, failure)],
  );
}
