import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/language_choice.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() => server = FakeServer());

  testWidgets('App_ShouldApplyTheAccountLanguage_WhenSignedIn', (tester) async {
    final rider = server.add('rider@example.com', language: 'it');
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));

    expect(containerOf(tester).read(languageChoiceViewModelProvider), 'it');
  });

  testWidgets('App_ShouldForgetTheAccountLanguage_WhenSignedOut', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', language: 'it');
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));
    expect(containerOf(tester).read(languageChoiceViewModelProvider), 'it');

    await openAccount(tester, 'sign-out');
    await tester.pumpAndSettle();

    expect(containerOf(tester).read(languageChoiceViewModelProvider), isNull);
  });
}
