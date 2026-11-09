import 'failure.dart';
import 'result.dart';

/// The state of one operation a ViewModel runs, modelled after the `Command`
/// objects in Flutter's architecture sample.
///
/// A command starts idle, reports `running` while the call is in flight, and
/// ends with an `Ok` or a `Failed` result. The view reads this instead of a
/// loose `bool` and `Failure?`, so a failed load can render inline and a failed
/// mutation can be shown once and consumed.
class CommandState<T> {
  const CommandState.idle() : running = false, result = null;

  const CommandState._(this.running, this.result);

  final bool running;
  final Result<T>? result;

  bool get idle => !running && result == null;

  bool get completed => result is Ok<T>;

  bool get failed => result is Failed<T>;

  Failure? get failure => switch (result) {
    Failed(:final failure) => failure,
    _ => null,
  };

  T? get value => switch (result) {
    Ok(:final value) => value,
    _ => null,
  };

  CommandState<T> start() => CommandState<T>._(true, null);

  CommandState<T> finish(Result<T> result) => CommandState<T>._(false, result);
}

/// The state of a command that returns nothing.
typedef VoidCommand = CommandState<void>;
