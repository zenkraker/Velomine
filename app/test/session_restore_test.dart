import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;
  late MemoryTokenStore store;

  setUp(() {
    server = FakeServer();
    server.add('rider@example.com', name: 'Alex Rider');
    store = MemoryTokenStore();
  });

  testWidgets('SessionRestore_ShouldOpenAppWithoutPassword_WhenTokenIsSaved', (
    tester,
  ) async {
    store.token = 'r-rider@example.com';
    server.rides.add(rideJson('r1', 'ready', distanceM: 42300, movingS: 5400));

    await startApp(
      tester,
      server.session(useCookies: false, tokenStore: store),
    );

    expect(find.byKey(const Key('upload')), findsOneWidget);
    expect(find.text('Alex Rider'), findsOneWidget);
    expect(server.refreshCount, 1);
    expect(server.requests, contains('POST /api/v1/accounts/refresh'));
    expect(server.requests, isNot(contains('POST /api/v1/accounts/login')));
  });

  testWidgets('SessionRestore_ShouldAskPassword_WhenRefused', (tester) async {
    store.token = 'r-nobody@example.com';

    await startApp(
      tester,
      server.session(useCookies: false, tokenStore: store),
    );

    expect(find.byKey(const Key('sign-in')), findsOneWidget);
    expect(store.token, isNull);
  });

  testWidgets('SessionRestore_ShouldKeepTokenAndOfferRetry_WhenUnreachable', (
    tester,
  ) async {
    store.token = 'r-rider@example.com';
    server.unreachable = true;

    final session = server.session(useCookies: false, tokenStore: store);
    await startApp(tester, session);

    expect(find.byKey(const Key('sign-in')), findsOneWidget);
    expect(find.textContaining('Could not reach the server'), findsOneWidget);
    expect(find.byKey(const Key('retry-session')), findsOneWidget);
    expect(store.token, 'r-rider@example.com');

    // The retry path itself is covered in session_auth_test; keep this test on the screen and the kept token.
  });

  testWidgets('SessionRestore_ShouldClearToken_WhenSigningOut', (tester) async {
    store.token = 'r-rider@example.com';

    await startApp(
      tester,
      server.session(useCookies: false, tokenStore: store),
    );
    await tester.tap(find.byKey(const Key('sign-out')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign-in')), findsOneWidget);
    expect(store.token, isNull);
  });
}
