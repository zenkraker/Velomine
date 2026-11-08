import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/session_auth.dart';
import 'package:velomine_api/api.dart';

import 'fake_server.dart';

TokenResponse tokens(String email, {int expiresIn = 3600}) => TokenResponse(
  tokenType: 'Bearer',
  accessToken: 't-$email',
  expiresIn: expiresIn,
  refreshToken: 'r-$email',
);

void main() {
  late FakeServer server;
  late MemoryTokenStore store;

  setUp(() {
    server = FakeServer();
    server.add('rider@example.com');
    store = MemoryTokenStore();
  });

  SessionAuth auth({DateTime Function()? now}) => SessionAuth(
    baseUrl: 'http://server',
    store: store,
    useCookies: false,
    refreshClient: server.client,
    now: now,
  );

  test('SessionAuth_ShouldRestoreSavedSession_WhenTokenIsStored', () async {
    store.token = 'r-rider@example.com';

    final result = await auth().restore();

    expect(result, SessionRestore.restored);
    expect(server.refreshCount, 1);
    expect(store.token, 'r-rider@example.com');
  });

  test('SessionAuth_ShouldClearTokenAndSignOut_WhenRefused', () async {
    store.token = 'r-nobody@example.com';
    var signedOut = false;

    final session = auth()..onSignedOut = () => signedOut = true;
    final result = await session.restore();

    expect(result, SessionRestore.signedOut);
    expect(store.token, isNull);
    expect(signedOut, isTrue);
  });

  test('SessionAuth_ShouldKeepToken_WhenServerIsUnreachable', () async {
    store.token = 'r-rider@example.com';
    server.unreachable = true;

    final result = await auth().restore();

    expect(result, SessionRestore.unavailable);
    expect(store.token, 'r-rider@example.com');
  });

  test(
    'SessionAuth_ShouldWaitForUnavailableRefresh_WhenApplyingToParams',
    () async {
      store.token = 'r-rider@example.com';
      server.unreachable = true;
      final session = auth();
      await session.restore();

      await expectLater(
        session.applyToParams([], {}),
        throwsA(isA<SessionUnavailable>()),
      );
    },
  );

  test(
    'SessionAuth_ShouldRefreshBeforeRequest_WhenAccessTokenHasExpired',
    () async {
      var now = DateTime.utc(2026, 11, 6, 8);
      final session = auth(now: () => now);
      await session.accept(tokens('rider@example.com', expiresIn: 3600));

      final headers = <String, String>{};
      await session.applyToParams([], headers);
      expect(headers['Authorization'], 'Bearer t-rider@example.com');
      expect(server.refreshCount, 0);

      now = now.add(const Duration(hours: 2));
      final later = <String, String>{};
      await session.applyToParams([], later);

      expect(later['Authorization'], 'Bearer t-rider@example.com');
      expect(server.refreshCount, 1);
    },
  );

  test(
    'SessionAuth_ShouldShareOneRefresh_WhenTwoRequestsExpireAtOnce',
    () async {
      final session = auth();
      await session.accept(tokens('rider@example.com', expiresIn: 0));

      await Future.wait([
        session.applyToParams([], {}),
        session.applyToParams([], {}),
      ]);

      expect(server.refreshCount, 1);
    },
  );
}
