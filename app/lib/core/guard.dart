import 'package:flutter/foundation.dart';
import 'package:velomine_api/api.dart';

/// Runs a call and turns failures into a message the screen can show; a 401 means the session ended.
Future<String?> guardCall(
  Future<void> Function() action,
  VoidCallback onUnauthorized, {
  String what = 'do that',
}) async {
  try {
    await action();
    return null;
  } on ApiException catch (e) {
    if (e.code == 401) {
      onUnauthorized();
      return null;
    }
    if (e.code == 400) {
      return 'The server did not accept that. Check the values.';
    }
    if (e.code == 404) return 'It no longer exists.';
    return 'Could not $what (${e.code}). Try again.';
  } on Object {
    return 'Could not reach the server. Try again.';
  }
}
