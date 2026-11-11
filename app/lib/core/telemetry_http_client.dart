import 'dart:async';

import 'package:http/http.dart' as http;

import 'telemetry.dart';

/// Times every API call and reports it through [TelemetryRuntime].
///
/// The URL is never sent: only the first route segment after `/api/v1` and the
/// HTTP method, so ride ids and share tokens cannot leak into a metric.
///
/// Every request goes through here, so this is the one place that turns a 401
/// into "the session ended", whatever the call was.
class TelemetryHttpClient extends http.BaseClient {
  TelemetryHttpClient({
    required this.inner,
    required this.telemetry,
    this.onUnauthorized,
  });

  final http.Client inner;
  final TelemetryRuntime telemetry;

  /// Called when the server answers 401. The session sets it once it exists; it ignores the call unless signed in.
  void Function()? onUnauthorized;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final started = Stopwatch()..start();
    final route = _route(request.url);
    try {
      final response = await inner.send(request);
      started.stop();
      if (response.statusCode == 401) onUnauthorized?.call();
      _record(
        route: route,
        method: request.method,
        status: response.statusCode,
        elapsed: started.elapsed,
      );
      return response;
    } on Object {
      started.stop();
      _record(
        route: route,
        method: request.method,
        reason: 'network',
        elapsed: started.elapsed,
      );
      rethrow;
    }
  }

  void _record({
    required String route,
    required String method,
    required Duration elapsed,
    int? status,
    String? reason,
  }) {
    final attributes = <String, Object>{
      'route': route,
      'method': method,
      'outcome': reason ?? (status != null && status >= 400 ? 'error' : 'ok'),
      'status': ?status,
      'reason': ?reason,
    };
    telemetry.count('api_requests', 1, attributes: attributes);
    telemetry.distribution(
      'api_request_duration',
      elapsed.inMilliseconds,
      unit: telemetryMilliseconds,
      attributes: attributes,
    );
    if (reason == 'network' || (status != null && status >= 400)) {
      telemetry.count('api_request_failures', 1, attributes: attributes);
    }
    if (reason == 'network' || (status != null && status >= 500)) {
      telemetry.log(
        TelemetryLevel.warning,
        'api request failed',
        attributes: attributes,
      );
    }
  }

  /// `/api/v1/rides/<id>` becomes `rides`; anything unexpected becomes `other`.
  static String _route(Uri uri) {
    final segments = uri.pathSegments;
    final api = segments.indexOf('api');
    if (api < 0 || api + 2 >= segments.length || segments[api + 1] != 'v1') {
      return 'other';
    }
    return segments[api + 2];
  }

  @override
  void close() => inner.close();
}
