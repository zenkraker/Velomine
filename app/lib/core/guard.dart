import 'package:flutter/foundation.dart';
import 'package:velomine_api/api.dart';

import 'failure.dart';

/// Runs a call and keeps a failure as a kind for the screen to word; a 401 means the session ended.
Future<Failure?> guardCall(
  Future<void> Function() call,
  VoidCallback onUnauthorized, {
  FailureAction doing = FailureAction.general,
}) async {
  try {
    await call();
    return null;
  } on ApiException catch (e) {
    if (e.code == 401) {
      onUnauthorized();
      return null;
    }
    final kind = switch (e.code) {
      400 => FailureKind.rejected,
      404 => FailureKind.missing,
      409 => FailureKind.conflict,
      502 => FailureKind.mailRejected,
      _ => FailureKind.failed,
    };
    return Failure(kind, code: e.code, action: doing);
  } on Object {
    return Failure(FailureKind.unreachable, action: doing);
  }
}
