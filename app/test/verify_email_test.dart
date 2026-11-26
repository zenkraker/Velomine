import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:velomine/core/widgets/loading_state.dart';

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

  testWidgets('VerifyEmailScreen_ShouldOfferANewLink_WhenTheLinkExpired', (
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

  testWidgets(
    'VerifyEmailScreen_ShouldShowTheLoadingState_WhenTheLinkIsBeingChecked',
    (tester) async {
      server.smtpConfigured = true;
      server.add('new@example.com', approved: true);
      await startApp(
        tester,
        server.session(useCookies: false),
        onRouter: (created) => router = created,
      );

      final gate = server.delayNext('/api/v1/accounts/email/verify');
      await open('/verify-email#token=good-token&email=new%40example.com');
      await tester.pump();
      await tester.pump();

      // The screen's first state is the shared loading state, not an indicator of its own.
      expect(find.byType(LoadingState), findsOneWidget);
      expect(find.textContaining('Confirming'), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('verify-result')), findsOneWidget);
      expect(find.byType(LoadingState), findsNothing);
    },
  );

  for (final width in [390.0, 600.0, 820.0, 1300.0]) {
    testWidgets(
      'VerifyEmailScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        server.smtpConfigured = true;
        server.add('new@example.com', approved: true);
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await startApp(
          tester,
          server.session(useCookies: false),
          onRouter: (created) => router = created,
        );

        // A spent link, so the screen shows the result and the way to a new one, its longest state.
        await open('/verify-email#token=spent-token&email=new%40example.com');
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('verify-result')), findsOneWidget);
        expect(find.byKey(const Key('verify-send-again')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'VerifyEmailScreen_ShouldOfferGoToSignInWithoutABackArrow_WhenTheLinkWorks',
    (tester) async {
      server.smtpConfigured = true;
      server.add('new@example.com', approved: true);
      await startApp(
        tester,
        server.session(useCookies: false),
        onRouter: (created) => router = created,
      );

      await open('/verify-email#token=good-token&email=new%40example.com');
      await tester.pumpAndSettle();

      expect(find.text('Go to sign in'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
    },
  );
}
