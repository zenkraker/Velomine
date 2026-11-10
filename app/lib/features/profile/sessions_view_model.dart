import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import '../../core/user_message.dart';

part 'sessions_view_model.g.dart';

class SessionsState {
  const SessionsState({
    this.load = const CommandState.idle(),
    this.revoke = const CommandState.idle(),
    this.logoutOthers = const CommandState.idle(),
    this.message,
  });

  final CommandState<List<SessionResponse>?> load;
  final VoidCommand revoke;
  final VoidCommand logoutOthers;
  final UserMessage? message;

  SessionsState copyWith({
    CommandState<List<SessionResponse>?>? load,
    VoidCommand? revoke,
    VoidCommand? logoutOthers,
    UserMessage? message,
    bool clearMessage = false,
  }) => SessionsState(
    load: load ?? this.load,
    revoke: revoke ?? this.revoke,
    logoutOthers: logoutOthers ?? this.logoutOthers,
    message: clearMessage ? null : (message ?? this.message),
  );
}

/// Where the member is signed in. Route-scoped: a fresh list each visit.
@riverpod
class SessionsViewModel extends _$SessionsViewModel {
  int _messageId = 0;

  @override
  SessionsState build() {
    Future.microtask(load);
    return const SessionsState();
  }

  Future<void> load() async {
    if (state.load.running) return;
    state = state.copyWith(load: state.load.start());
    final result = await ref
        .read(sessionProvider)
        .accounts
        .listSessions()
        .guard(FailureAction.loadSecurity);
    if (!ref.mounted) return;
    state = state.copyWith(load: state.load.finish(result));
    if (result case Failed(:final failure)) _fail(failure);
  }

  Future<void> revoke(String id) async {
    if (state.revoke.running) return;
    state = state.copyWith(revoke: state.revoke.start(), clearMessage: true);
    final result = await ref
        .read(sessionProvider)
        .accounts
        .revokeSession(id)
        .guard(FailureAction.changeSecurity);
    if (!ref.mounted) return;
    state = state.copyWith(revoke: state.revoke.finish(result));
    if (result case Failed(:final failure)) _fail(failure);
    await load();
  }

  Future<void> logoutOthers() async {
    if (state.logoutOthers.running) return;
    state = state.copyWith(
      logoutOthers: state.logoutOthers.start(),
      clearMessage: true,
    );
    final result = await ref
        .read(sessionProvider)
        .accounts
        .revokeOtherSessions()
        .guard(FailureAction.changeSecurity);
    if (!ref.mounted) return;
    state = state.copyWith(logoutOthers: state.logoutOthers.finish(result));
    if (result case Failed(:final failure)) _fail(failure);
    await load();
  }

  void messageShown(int id) {
    if (state.message?.id == id) state = state.copyWith(clearMessage: true);
  }

  void _fail(Failure failure) => state = state.copyWith(
    message: FailureMessage(++_messageId, failure),
  );
}
