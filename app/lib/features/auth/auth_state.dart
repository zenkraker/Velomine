import '../../core/command.dart';
import '../../core/session.dart';

/// What the sign-in form is doing, and why it last failed.
class SignInState {
  const SignInState({this.command = const CommandState.idle(), this.problem});

  final VoidCommand command;
  final AuthProblem? problem;

  SignInState copyWith({
    VoidCommand? command,
    AuthProblem? problem,
    bool clearProblem = false,
  }) => SignInState(
    command: command ?? this.command,
    problem: clearProblem ? null : (problem ?? this.problem),
  );
}

/// The sign-up form: created, and whether the account can sign in right away.
class RegisterState {
  const RegisterState({
    this.command = const CommandState.idle(),
    this.problem,
    this.approved,
  });

  final VoidCommand command;
  final AuthProblem? problem;

  /// Null until the account is created; then whether it may sign in now.
  final bool? approved;

  RegisterState copyWith({
    VoidCommand? command,
    AuthProblem? problem,
    bool clearProblem = false,
    bool? approved,
  }) => RegisterState(
    command: command ?? this.command,
    problem: clearProblem ? null : (problem ?? this.problem),
    approved: approved ?? this.approved,
  );
}

/// Why asking for a reset link did not work, kept as a kind for the screen to
/// word in the language showing now.
enum ForgotProblem { missingEmail, emailNotSetUp, tooMany, failed }

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
