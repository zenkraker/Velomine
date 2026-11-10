import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/providers.dart';
import '../../core/result.dart';
import 'auth_data.dart';
import 'auth_state.dart';

part 'auth_view_models.g.dart';

/// The sign-in form. Route-scoped: it holds one attempt, not the session.
@riverpod
class SignInViewModel extends _$SignInViewModel {
  @override
  SignInState build() => const SignInState();

  Future<void> signIn(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    if (state.command.running) return;
    ref.read(sessionProvider).clearSsoError();
    state = state.copyWith(command: state.command.start(), clearProblem: true);
    final problem = await ref
        .read(authDataProvider)
        .signIn(email, password, rememberMe: rememberMe);
    if (!ref.mounted) return;
    state = state.copyWith(
      command: state.command.finish(const Ok(null)),
      problem: problem,
    );
  }

  void retryRestore() => ref.read(authDataProvider).retryRestore();
}

/// The sign-up form.
@riverpod
class RegisterViewModel extends _$RegisterViewModel {
  @override
  RegisterState build() => const RegisterState();

  Future<void> register(String email, String name, String password) async {
    if (state.command.running) return;
    state = state.copyWith(command: state.command.start(), clearProblem: true);
    final result = await ref
        .read(authDataProvider)
        .signUp(email, name, password);
    if (!ref.mounted) return;
    state = state.copyWith(
      command: state.command.finish(const Ok(null)),
      problem: result.problem,
      approved: result.problem == null ? result.approved : null,
    );
  }
}

/// Asking for a password-reset link.
@riverpod
class ForgotPasswordViewModel extends _$ForgotPasswordViewModel {
  @override
  ForgotState build() => const ForgotState();

  Future<void> send(String email) async {
    if (state.command.running) return;
    if (email.isEmpty) {
      state = state.copyWith(problem: ForgotProblem.missingEmail);
      return;
    }
    state = state.copyWith(
      command: state.command.start(),
      clearProblem: true,
      sent: false,
    );
    final result = await ref.read(authDataProvider).forgotPassword(email);
    if (!ref.mounted) return;
    final problem = switch (result.failureOrNull?.code) {
      503 => ForgotProblem.emailNotSetUp,
      429 => ForgotProblem.tooMany,
      null => null,
      _ => ForgotProblem.failed,
    };
    state = state.copyWith(
      command: state.command.finish(const Ok(null)),
      problem: problem,
      sent: problem == null,
    );
  }
}

/// Choosing a new password from the one-time link.
@riverpod
class ResetPasswordViewModel extends _$ResetPasswordViewModel {
  @override
  ResetState build() => const ResetState();

  Future<void> reset({
    String? token,
    String? email,
    required String password,
    required String confirm,
  }) async {
    if (state.command.running) return;
    if (token == null || token.isEmpty || email == null || email.isEmpty) {
      state = state.copyWith(problem: ResetProblem.invalidLink);
      return;
    }
    if (password.length < 10) {
      state = state.copyWith(problem: ResetProblem.tooShort);
      return;
    }
    if (password != confirm) {
      state = state.copyWith(problem: ResetProblem.mismatch);
      return;
    }

    state = state.copyWith(
      command: state.command.start(),
      clearProblem: true,
      done: false,
    );
    final result = await ref
        .read(authDataProvider)
        .resetPassword(email: email, token: token, newPassword: password);
    if (!ref.mounted) return;
    if (result.isOk) {
      // The reset changed the security stamp: any session on this device ends.
      await ref.read(sessionProvider).signOut();
      if (!ref.mounted) return;
    }
    final problem = switch (result.failureOrNull?.code) {
      400 => ResetProblem.invalidLink,
      429 => ResetProblem.tooMany,
      null => null,
      _ => ResetProblem.failed,
    };
    state = state.copyWith(
      command: state.command.finish(const Ok(null)),
      problem: problem,
      done: problem == null,
    );
  }
}
