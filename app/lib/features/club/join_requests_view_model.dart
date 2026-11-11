import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/result.dart';
import '../../core/user_message.dart';
import 'club_data.dart';
import 'club_view_model.dart';
import 'join_requests_state.dart';

part 'join_requests_view_model.g.dart';

/// The owner's inbox. Loaded only for the owner of a known club; emptied on sign
/// out, on leaving and when the role changes.
@Riverpod(keepAlive: true)
class JoinRequestsViewModel extends _$JoinRequestsViewModel {
  int _messageId = 0;

  @override
  JoinRequestsState build() {
    final (clubId, role) = ref.watch(
      clubViewModelProvider.select((s) => (s.club?.id, s.club?.myRole)),
    );
    if (clubId == null || role != 'owner') {
      return const JoinRequestsState();
    }
    Future.microtask(refresh);
    return const JoinRequestsState();
  }

  Future<void> refresh() async {
    if (state.load.running) return;
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(clubDataProvider).joinRequests();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        requests: value?.requests ?? const [],
        admissionBlocked: value?.admissionBlocked,
        clearAdmissionBlocked: value?.admissionBlocked == null,
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  Future<bool> approve(String id) =>
      _decide(() => ref.read(clubDataProvider).approveJoinRequest(id));

  Future<bool> decline(String id) =>
      _decide(() => ref.read(clubDataProvider).declineJoinRequest(id));

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );

  Future<bool> _decide(Future<Result<void>> Function() call) async {
    if (state.action.running) return false;
    state = state.copyWith(action: state.action.start());
    final result = await call();
    if (!ref.mounted) return false;
    if (result case Failed(:final failure)) {
      state = state.copyWith(action: state.action.finish(result));
      state = state.copyWith(
        messages: [...state.messages, FailureMessage(_messageId++, failure)],
      );
      return false;
    }
    state = state.copyWith(action: state.action.finish(result));
    await refresh();
    // A handled request changes the roster, so the club is read again.
    ref.invalidate(clubViewModelProvider);
    return true;
  }
}
