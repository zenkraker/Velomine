import '../../core/command.dart';
import '../../core/session.dart';

/// What the sign-in form is doing, and why it last failed.
class SignInState {
  const SignInState({
    this.command = const CommandState.idle(),
    this.problem,
    this.challenge,
    this.rememberMe = true,
  });

  final VoidCommand command;
  final AuthProblem? problem;

  /// Set when the password was right and the account has a second factor: the screen asks for the code instead.
  final String? challenge;

  /// The stay-signed-in choice, kept until the code step finishes the same sign-in.
  final bool rememberMe;

  SignInState copyWith({
    VoidCommand? command,
    AuthProblem? problem,
    String? challenge,
    bool clearProblem = false,
    bool clearChallenge = false,
    bool? rememberMe,
  }) => SignInState(
    command: command ?? this.command,
    problem: clearProblem ? null : (problem ?? this.problem),
    challenge: clearChallenge ? null : (challenge ?? this.challenge),
    rememberMe: rememberMe ?? this.rememberMe,
  );
}

/// The sign-up form: created, and whether the account can sign in right away.
class RegisterState {
  const RegisterState({
    this.command = const CommandState.idle(),
    this.problem,
    this.outcome,
    this.email,
  });

  final VoidCommand command;
  final AuthProblem? problem;

  /// What the server said when the account was made; null until then.
  final RegisterOutcome? outcome;

  /// The address the account was made with: the screen says to confirm it, and offers to send the link again.
  final String? email;

  RegisterState copyWith({
    VoidCommand? command,
    AuthProblem? problem,
    bool clearProblem = false,
    RegisterOutcome? outcome,
    String? email,
  }) => RegisterState(
    command: command ?? this.command,
    problem: clearProblem ? null : (problem ?? this.problem),
    outcome: outcome ?? this.outcome,
    email: email ?? this.email,
  );
}

/// What creating the account left to do: nothing, an admin's approval, or opening the confirmation link.
enum RegisterOutcome { created, pendingApproval, needsConfirmation }

/// Why asking for a reset link did not work, kept as a kind for the screen to
/// word in the language showing now.
enum ForgotProblem { missingEmail, emailNotSetUp, tooMany, failed }

/// Asking for the confirmation link again, worded for the person who has not opened it yet.
enum ResendProblem { emailNotSetUp, tooMany, failed }

class ForgotState {
  const ForgotState({
    this.command = const CommandState.idle(),
    this.problem,
    this.sent = false,
  });

  final VoidCommand command;
  final ForgotProblem? problem;

  /// The answer always says a link was sent if the address exists, so the
  /// screen must not reveal who is registered.
  final bool sent;

  ForgotState copyWith({
    VoidCommand? command,
    ForgotProblem? problem,
    bool clearProblem = false,
    bool? sent,
  }) => ForgotState(
    command: command ?? this.command,
    problem: clearProblem ? null : (problem ?? this.problem),
    sent: sent ?? this.sent,
  );
}

/// Why a reset link did not work, kept as a kind for the screen to word.
enum ResetProblem { invalidLink, tooShort, mismatch, tooMany, failed }

class ResetState {
  const ResetState({
    this.command = const CommandState.idle(),
    this.problem,
    this.done = false,
  });

  final VoidCommand command;
  final ResetProblem? problem;
  final bool done;

  ResetState copyWith({
    VoidCommand? command,
    ResetProblem? problem,
    bool clearProblem = false,
    bool? done,
  }) => ResetState(
    command: command ?? this.command,
    problem: clearProblem ? null : (problem ?? this.problem),
    done: done ?? this.done,
  );
}
