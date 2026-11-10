import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import '../../core/session.dart';

part 'auth_data.g.dart';

/// The sign-in endpoints as values: the ViewModels never see an exception.
///
/// Signing in and up already answer with [AuthProblem]; the two password
/// endpoints answer with a `Result` like every other data source.
class AuthData {
  AuthData(this._session);

  final Session _session;

  Future<({AuthProblem? problem, String? challenge})> signIn(
    String email,
    String password, {
    bool rememberMe = true,
  }) => _session.signIn(email, password, rememberMe: rememberMe);

  Future<AuthProblem?> completeTwoFactor(
    String challenge,
    String code, {
    required bool rememberMe,
  }) => _session.completeTwoFactor(challenge, code, rememberMe: rememberMe);

  Future<({AuthProblem? problem, bool approved})> signUp(
    String email,
    String displayName,
    String password,
  ) => _session.signUp(email, displayName, password);

  void retryRestore() => _session.retryRestore();

  Future<Result<void>> forgotPassword(String email) => _session.accounts
      .forgotPassword(ForgotPasswordRequest(email: email.trim()))
      .guard(FailureAction.resetPassword);

  Future<Result<void>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) => _session.accounts
      .resetPassword(
        ResetPasswordRequest(
          email: email.trim(),
          token: token,
          newPassword: newPassword.trim(),
        ),
      )
      .guard(FailureAction.resetPassword);
}

@Riverpod(keepAlive: true)
AuthData authData(Ref ref) => AuthData(ref.watch(sessionProvider));
