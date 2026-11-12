import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/units.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() => server = FakeServer());

  testWidgets('Units_ShouldApplyTheAccountUnits_WhenSignedIn', (tester) async {
    final rider = server.add('rider@example.com', units: 'imperial');
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));

    expect(
      containerOf(tester).read(unitsChoiceViewModelProvider),
      Units.imperial,
    );
  });

  testWidgets('Units_ShouldBeMetric_WhenTheAccountNeverChose', (tester) async {
    final rider = server.add('rider@example.com');
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));

    expect(
      containerOf(tester).read(unitsChoiceViewModelProvider),
      Units.metric,
    );
  });

  testWidgets('Units_ShouldForgetTheAccountUnits_WhenSignedOut', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', units: 'imperial');
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));
    expect(
      containerOf(tester).read(unitsChoiceViewModelProvider),
      Units.imperial,
    );

    await openAccount(tester, 'sign-out');
    await tester.pumpAndSettle();

    expect(
      containerOf(tester).read(unitsChoiceViewModelProvider),
      Units.metric,
    );
  });

  test('KnownUnits_ShouldFallBackToMetric_WhenTheValueIsUnknown', () {
    expect(knownUnits(null), Units.metric);
    expect(knownUnits('parsecs'), Units.metric);
    expect(knownUnits('imperial'), Units.imperial);
    expect(knownUnits('metric'), Units.metric);
  });
}
