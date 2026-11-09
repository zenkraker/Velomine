import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/command.dart';
import 'package:velomine/core/failure.dart';
import 'package:velomine/core/result.dart';
import 'package:velomine_api/api.dart';

void main() {
  test('Result_ShouldCarryTheValue_WhenTheCallSucceeds', () async {
    final result = await Future.value(42).guard(FailureAction.general);

    expect(result, isA<Ok<int>>());
    expect(result.valueOrNull, 42);
    expect(result.failureOrNull, isNull);
  });

  test('Result_ShouldCarryTheFailure_WhenTheServerRejects', () async {
    final result = await Future<int>.error(ApiException(409, 'conflict'))
        .guard(FailureAction.general);

    expect(result, isA<Failed<int>>());
    expect(result.failureOrNull?.kind, FailureKind.conflict);
    expect(result.valueOrNull, isNull);
  });

  test('Result_ShouldReportTheSessionEnded_WhenTheServerAnswers401', () async {
    var expired = false;
    final result = await Future<int>.error(ApiException(401, 'unauthorized'))
        .guard(FailureAction.general, onUnauthorized: () => expired = true);

    expect(expired, isTrue);
    expect(result.failureOrNull?.kind, FailureKind.sessionEnded);
  });

  test(
    'Result_ShouldReportUnreachable_WhenTheCallThrowsSomethingElse',
    () async {
      final result = await Future<int>.error(StateError('no network'))
          .guard(FailureAction.loadRides);

      expect(result.failureOrNull?.kind, FailureKind.unreachable);
      expect(result.failureOrNull?.action, FailureAction.loadRides);
    },
  );

  test('CommandState_ShouldReportTheOutcome_WhenTheCommandRuns', () {
    final running = const CommandState<int>.idle().start();
    expect(running.running, isTrue);
    expect(running.idle, isFalse);

    final failed = running.finish(
      const Failed(Failure(FailureKind.unreachable)),
    );
    expect(failed.running, isFalse);
    expect(failed.failed, isTrue);
    expect(failed.failure?.kind, FailureKind.unreachable);

    final completed = const CommandState<int>.idle().start().finish(
      const Ok(7),
    );
    expect(completed.completed, isTrue);
    expect(completed.value, 7);
  });
}
