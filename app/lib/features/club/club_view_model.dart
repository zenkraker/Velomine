import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import '../../core/user_message.dart';
import 'club_data.dart';
import 'club_state.dart';

part 'club_view_model.g.dart';

/// The signed-in account's club and the changes to it. Kept alive for the
/// session; a sign-out rebuilds it empty, and the router reads it for redirects.
@Riverpod(keepAlive: true)
class ClubViewModel extends _$ClubViewModel {
  int _messageId = 0;

  @override
  ClubState build() {
    final userId = ref.watch(signedInUserIdProvider);
    if (userId == null) return const ClubState();
    Future.microtask(refresh);
    return const ClubState();
  }

  Future<void> refresh() async {
    if (state.load.running) return;
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(clubDataProvider).myClub();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        club: value?.club,
        loaded: true,
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  /// Returns whether the code was accepted; the join screen shows the reason
  /// inline from [ClubState.action].
  Future<bool> join(String code) async {
    if (state.action.running) return false;
    state = state.copyWith(action: state.action.start());
    final result = await ref.read(clubDataProvider).join(code);
    if (!ref.mounted) return false;
    if (result case Ok(:final value)) {
      state = state.copyWith(
        action: state.action.finish(result),
        club: value?.club,
        loaded: true,
      );
      return true;
    }
    state = state.copyWith(action: state.action.finish(result));
    return false;
  }

  Future<bool> leave() async {
    if (state.action.running) return false;
    state = state.copyWith(action: state.action.start());
    final result = await ref.read(clubDataProvider).leave();
    if (!ref.mounted) return false;
    if (result case Failed(:final failure)) {
      state = state.copyWith(action: state.action.finish(result));
      _fail(failure);
      return false;
    }
    state = ClubState(loaded: true, action: state.action.finish(result));
    return true;
  }

  Future<bool> rotateCode() async {
    final ok = await _run(
      () => ref.read(clubDataProvider).rotateCode(),
      after: refresh,
    );
    return ok;
  }

  /// Saves where the club meets and whether riders nearby may find it. Null
  /// coordinates clear the point.
  Future<bool> setLocation(
    double? latitude,
    double? longitude, {
    required bool isDiscoverable,
  }) => _runClub(
    () => ref
        .read(clubDataProvider)
        .setLocation(latitude, longitude, isDiscoverable: isDiscoverable),
  );

  Future<bool> setRole(String userId, String role) => _run(
    () => ref.read(clubDataProvider).setRole(userId, role),
    after: refresh,
  );

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );

  /// Runs a mutation that answers with the club, adopting the new club on success.
  Future<bool> _runClub(Future<Result<MyClubResponse?>> Function() call) async {
    if (state.action.running) return false;
    state = state.copyWith(action: state.action.start());
    final result = await call();
    if (!ref.mounted) return false;
    if (result case Ok(:final value)) {
      state = state.copyWith(
        action: state.action.finish(result),
        club: value?.club,
        loaded: true,
      );
      return true;
    }
    state = state.copyWith(action: state.action.finish(result));
    if (result case Failed(:final failure)) _fail(failure);
    return false;
  }

  /// Runs a mutation that answers with something else, then optionally refreshes.
  Future<bool> _run(
    Future<Result<Object?>> Function() call, {
    Future<void> Function()? after,
  }) async {
    if (state.action.running) return false;
    state = state.copyWith(action: state.action.start());
    final result = await call();
    if (!ref.mounted) return false;
    state = state.copyWith(action: state.action.finish(result));
    if (result case Failed(:final failure)) {
      _fail(failure);
      return false;
    }
    if (after != null) await after();
    return true;
  }

  void _fail(Failure failure) => state = state.copyWith(
    messages: [...state.messages, FailureMessage(_messageId++, failure)],
  );
}
