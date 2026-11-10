import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import '../../core/user_message.dart';

part 'two_factor_view_model.g.dart';

/// What the two-factor screen has loaded and what it is doing.
class TwoFactorScreenState {
  const TwoFactorScreenState({
    this.load = const CommandState.idle(),
    this.start = const CommandState.idle(),
    this.enable = const CommandState.idle(),
    this.disable = const CommandState.idle(),
    this.regenerate = const CommandState.idle(),
    this.message,
  });

  final CommandState<TwoFactorState?> load;
  final CommandState<TwoFactorSetup?> start;
  final CommandState<RecoveryCodesResponse?> enable;
  final VoidCommand disable;
  final CommandState<RecoveryCodesResponse?> regenerate;
  final UserMessage? message;

  TwoFactorScreenState copyWith({
    CommandState<TwoFactorState?>? load,
    CommandState<TwoFactorSetup?>? start,
    CommandState<RecoveryCodesResponse?>? enable,
    VoidCommand? disable,
    CommandState<RecoveryCodesResponse?>? regenerate,
    UserMessage? message,
    bool clearMessage = false,
  }) => TwoFactorScreenState(
    load: load ?? this.load,
    start: start ?? this.start,
    enable: enable ?? this.enable,
    disable: disable ?? this.disable,
    regenerate: regenerate ?? this.regenerate,
    message: clearMessage ? null : (message ?? this.message),
  );
}

/// The member's second factor. Route-scoped: it holds one visit, not the session.
@riverpod
class TwoFactorViewModel extends _$TwoFactorViewModel {
  int _messageId = 0;

  @override
  TwoFactorScreenState build() {
    Future.microtask(load);
    return const TwoFactorScreenState();
  }

  Future<void> load() async {
    if (state.load.running) return;
    state = state.copyWith(load: state.load.start());
    final result = await ref
        .read(sessionProvider)
        .accounts
        .getTwoFactor()
        .guard(FailureAction.loadSecurity);
    if (!ref.mounted) return;
    state = state.copyWith(load: state.load.finish(result));
    if (result case Failed(:final failure)) _fail(failure);
  }

  Future<void> start() async {
    if (state.start.running) return;
    state = state.copyWith(start: state.start.start(), clearMessage: true);
    final result = await ref
        .read(sessionProvider)
        .accounts
        .startTwoFactorEnrollment()
        .guard(FailureAction.changeSecurity);
    if (!ref.mounted) return;
    state = state.copyWith(start: state.start.finish(result));
    if (result case Failed(:final failure)) _fail(failure);
  }

  Future<void> enable({required String password, required String code}) async {
    if (state.enable.running) return;
    state = state.copyWith(enable: state.enable.start(), clearMessage: true);
    final result = await ref
        .read(sessionProvider)
        .accounts
        .enableTwoFactor(
          EnableTwoFactorRequest(password: password, code: code.trim()),
        )
        .guard(FailureAction.changeSecurity);
    if (!ref.mounted) return;
    state = state.copyWith(
      enable: state.enable.finish(result),
      load: const CommandState.idle(),
    );
    if (result case Failed(:final failure)) _fail(failure);
    await load();
  }

  Future<void> disable(String password) async {
    if (state.disable.running) return;
    state = state.copyWith(disable: state.disable.start(), clearMessage: true);
    final result = await ref
        .read(sessionProvider)
        .accounts
        .disableTwoFactor(PasswordConfirmation(password: password))
        .guard(FailureAction.changeSecurity);
    if (!ref.mounted) return;
    state = state.copyWith(
      disable: state.disable.finish(result),
      enable: const CommandState.idle(),
      regenerate: const CommandState.idle(),
    );
    if (result case Failed(:final failure)) _fail(failure);
    await load();
  }

  Future<void> regenerate(String password) async {
    if (state.regenerate.running) return;
    state = state.copyWith(
      regenerate: state.regenerate.start(),
      clearMessage: true,
    );
    final result = await ref
        .read(sessionProvider)
        .accounts
        .regenerateRecoveryCodes(PasswordConfirmation(password: password))
        .guard(FailureAction.changeSecurity);
    if (!ref.mounted) return;
    state = state.copyWith(regenerate: state.regenerate.finish(result));
    if (result case Failed(:final failure)) _fail(failure);
  }

  void messageShown(int id) {
    if (state.message?.id == id) state = state.copyWith(clearMessage: true);
  }

  void _fail(Failure failure) => state = state.copyWith(
    message: FailureMessage(++_messageId, failure),
  );
}
