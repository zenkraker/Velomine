import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:velomine/core/telemetry_http_client.dart';

import 'fake_telemetry.dart';

void main() {
  test(
    'TelemetryHttpClient_ShouldReportRouteAndStatus_WhenTheRequestSucceeds',
    () async {
      final telemetry = FakeTelemetryRuntime();
      final client = TelemetryHttpClient(
        inner: MockClient((_) async => http.Response('ok', 200)),
        telemetry: telemetry,
      );

      await client.get(
        Uri.parse('https://example.test/api/v1/rides/secret-id'),
      );

      final request = telemetry.counts.first;
      expect(request.name, 'api_requests');
      expect(request.attributes['route'], 'rides');
      expect(request.attributes['method'], 'GET');
      expect(request.attributes['status'], 200);
      expect(request.attributes.values.join(' '), isNot(contains('secret-id')));
      expect(telemetry.gauges, isEmpty);
    },
  );

  test(
    'TelemetryHttpClient_ShouldReportFailure_WhenTheServerAnswers5xx',
    () async {
      final telemetry = FakeTelemetryRuntime();
      final client = TelemetryHttpClient(
        inner: MockClient((_) async => http.Response('no', 503)),
        telemetry: telemetry,
      );

      await client.get(Uri.parse('https://example.test/api/v1/rides'));

      final failure = telemetry.counts.firstWhere(
        (entry) => entry.name == 'api_request_failures',
      );
      expect(failure.attributes['status'], 503);
      expect(telemetry.logs, isNotEmpty);
    },
  );

  test(
    'TelemetryHttpClient_ShouldReportNetworkFailure_WhenTheRequestThrows',
    () async {
      final telemetry = FakeTelemetryRuntime();
      final client = TelemetryHttpClient(
        inner: MockClient(
          (request) async => throw http.ClientException('offline', request.url),
        ),
        telemetry: telemetry,
      );

      await expectLater(
        client.get(Uri.parse('https://example.test/api/v1/server')),
        throwsA(isA<http.ClientException>()),
      );

      final failure = telemetry.counts.firstWhere(
        (entry) => entry.name == 'api_request_failures',
      );
      expect(failure.attributes['reason'], 'network');
      expect(failure.attributes['route'], 'server');
      expect(telemetry.logs, isNotEmpty);
    },
  );
}
