import 'package:velomine_api/api.dart';

import 'failure.dart';

/// The outcome of an operation that can fail in an expected way.
///
/// A data source returns this instead of letting an `ApiException` escape, so a
/// ViewModel only ever deals with values. It mirrors the Android data-layer
/// guidance: `Result<T>` (or a typed exception) at the layer boundary.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  bool get isFailed => this is Failed<T>;

  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Failed() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Failed(:final failure) => failure,
    Ok() => null,
  };

  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok(transform(value)),
    Failed(:final failure) => Failed(failure),
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Failed<T> extends Result<T> {
  const Failed(this.failure);

  final Failure failure;
}

/// Turns a call that throws into a value.
///
/// This is the only place an API exception becomes a [Failure]; ViewModels and
/// views never catch one.
extension GuardFuture<T> on Future<T> {
  Future<Result<T>> guard(FailureAction doing) async {
    try {
      return Ok(await this);
    } on ApiException catch (e) {
      return Failed(
        Failure(
          failureKindFor(e.code, e.message),
          code: e.code,
          action: doing,
          detail: serverDetail(e.message),
        ),
      );
    } on Object {
      return Failed(Failure(FailureKind.unreachable, action: doing));
    }
  }
}
