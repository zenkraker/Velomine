import 'package:velomine/core/telemetry.dart';

/// Records what the app reports, so a test can assert without Sentry.
class FakeTelemetryRuntime implements TelemetryRuntime {
  final logs =
      <
        ({TelemetryLevel level, String message, Map<String, Object> attributes})
      >[];
  final counts = <({String name, int value, Map<String, Object> attributes})>[];
  final distributions =
      <
        ({String name, num value, String? unit, Map<String, Object> attributes})
      >[];
  final gauges =
      <
        ({String name, num value, String? unit, Map<String, Object> attributes})
      >[];
  bool closed = false;

  @override
  Future<void> close() async => closed = true;

  @override
  void log(
    TelemetryLevel level,
    String message, {
    Map<String, Object> attributes = const {},
  }) => logs.add((level: level, message: message, attributes: attributes));

  @override
  void count(
    String name,
    int value, {
    Map<String, Object> attributes = const {},
  }) => counts.add((name: name, value: value, attributes: attributes));

  @override
  void distribution(
    String name,
    num value, {
    String? unit,
    Map<String, Object> attributes = const {},
  }) => distributions.add((
    name: name,
    value: value,
    unit: unit,
    attributes: attributes,
  ));

  @override
  void gauge(
    String name,
    num value, {
    String? unit,
    Map<String, Object> attributes = const {},
  }) => gauges.add((
    name: name,
    value: value,
    unit: unit,
    attributes: attributes,
  ));
}
