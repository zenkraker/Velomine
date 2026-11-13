import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;
  late GoRouter router;
  setUp(() => server = FakeServer());

  Future<void> open(String location) async {
    router.go(location);
  }

  testWidgets('VerifyEmailScreen_ShouldConfirmTheAddress_WhenTheLinkIsOpened', (
    tester,
  ) async {
    server.smtpConfigured = true;
    server.add('new@example.com', approved: true);
    await startApp(
      tester,
      server.session(useCookies: false),
      onRouter: (created) => router = created,
    );

    // The real route reads the token from the fragment, as the email link carries it.
    await open('/verify-email#token=good-token&email=new%40example.com');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('verify-result')), findsOneWidget);
    expect(find.textContaining('confirmed'), findsOneWidget);
    expect(server.confirmedEmails, contains('new@example.com'));
  });

  testWidgets('VerifyEmailScreen_ShouldExplainABadLink_WhenTheTokenIsSpent', (
    tester,
  ) async {
    server.smtpConfigured = true;
    server.add('new@example.com', approved: true);
    await startApp(
      tester,
      server.session(useCookies: false),
      onRouter: (created) => router = created,
    );

    await open('/verify-email#token=spent-token&email=new%40example.com');
    await tester.pumpAndSettle();

    expect(find.textContaining('not valid'), findsOneWidget);
    expect(server.confirmedEmails, isNot(contains('new@example.com')));

    await tester.tap(find.byKey(const Key('verify-send-again')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('verify-resent')), findsOneWidget);
    expect(server.verificationEmails, contains('new@example.com'));
  });
}
