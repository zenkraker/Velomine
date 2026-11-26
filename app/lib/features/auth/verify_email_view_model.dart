import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/command.dart';
import '../../core/result.dart';
import 'auth_data.dart';

part 'verify_email_view_model.g.dart';

/// Opening the link from the confirmation email: the check, then whether it worked, then the same link
/// asked for again.
class VerifyEmailState {
  const VerifyEmailState({
    this.command = const CommandState.idle(),
    this.confirmed,
    this.resent = false,
  });

  final VoidCommand command;

  /// Null while the address is being confirmed, then whether the link worked.
  final bool? confirmed;

  /// A new link was sent for an expired one.
  final bool resent;

  VerifyEmailState copyWith({
    VoidCommand? command,
    bool? confirmed,
    bool clearConfirmed = false,
    bool? resent,
  }) => VerifyEmailState(
    command: command ?? this.command,
    confirmed: clearConfirmed ? null : (confirmed ?? this.confirmed),
    resent: resent ?? this.resent,
  );
}

@riverpod
class VerifyEmailViewModel extends _$VerifyEmailViewModel {
  @override
  VerifyEmailState build() => const VerifyEmailState();

  Future<void> verify({String? email, String? token}) async {
    // A link works once: a second call (the screen built again) would turn "confirmed" into "invalid".
    if (state.command.running || state.confirmed == true) return;
    if (email == null || email.isEmpty || token == null || token.isEmpty) {
      state = state.copyWith(confirmed: false);
      return;
    }
    state = state.copyWith(
      command: state.command.start(),
      clearConfirmed: true,
      resent: false,
    );
    final result = await ref
        .read(authDataProvider)
        .verifyEmail(email: email, token: token);
    if (!ref.mounted) return;
    state = state.copyWith(
      command: state.command.finish(const Ok(null)),
      confirmed: result.isOk,
    );
  }

  /// The link was spent or never arrived: the same address, another confirmation email.
  Future<void> sendAgain(String? email) async {
    if (state.command.running || email == null || email.isEmpty) return;
    state = state.copyWith(command: state.command.start(), resent: false);
    final result = await ref.read(authDataProvider).resendVerification(email);
    if (!ref.mounted) return;
    state = state.copyWith(
      command: state.command.finish(const Ok(null)),
      resent: result.isOk,
    );
  }
}
