import 'dart:convert';

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
    return Failure(
      kind,
      code: e.code,
      action: doing,
      detail: _detail(e.message),
    );
  } on Object {
    return Failure(FailureKind.unreachable, action: doing);
  }
}

/// The sentence the server sent for a validation or conflict error, if it sent one.
///
/// FastEndpoints answers with ProblemDetails: `{"errors":{"generalErrors":["..."]}}` or a `detail` string. The
/// sentence is English today (bodies are not localized yet), but it is far more useful than "the server did not
/// accept that": it names the missing account, the duplicate name, and so on.
String? _detail(String? body) {
  if (body == null || body.isEmpty) return null;
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map) return null;
    final errors = decoded['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty && value.first is String) {
          final text = (value.first as String).trim();
          if (text.isNotEmpty) return text;
        }
      }
    }
    final detail = decoded['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail.trim();
    final title = decoded['title'];
    if (title is String &&
        title.trim().isNotEmpty &&
        !title.toLowerCase().contains('validation')) {
      return title.trim();
    }
  } on FormatException {
    return null;
  }
  return null;
}
