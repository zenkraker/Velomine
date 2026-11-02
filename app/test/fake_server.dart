import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:velomine/app.dart';
import 'package:velomine/core/hooks.dart';
import 'package:velomine/core/session.dart';
import 'package:velomine_api/api.dart';

class FakeAccount {
  FakeAccount(
    this.email,
    this.password, {
    this.name = 'Test Rider',
    this.approved = true,
    this.roles = const ['member'],
  }) : id = 'id-${email.hashCode.abs()}';

  final String id;
  final String email;
  final String password;
  final String name;
  bool approved;
  final List<String> roles;
}

/// A tiny stand-in for the Velomine server, answering the calls the app makes.
/// It checks the same things the real one does: the bearer token or session cookie, approval, and admin-only calls.
class FakeServer {
  final accounts = <String, FakeAccount>{};
  final rides = <Map<String, Object?>>[];
  final requests = <String>[]; // "METHOD /path", in order
  bool ssoEnabled = false;
  FakeAccount? _cookieUser;
  int _pollsLeft = 1;

  late final http.Client client = MockClient(_handle);

  FakeAccount add(
    String email, {
    String password = 'Rider-pass-123',
    bool approved = true,
    List<String> roles = const ['member'],
    String name = 'Test Rider',
  }) => accounts[email] = FakeAccount(
    email,
    password,
    approved: approved,
    roles: roles,
    name: name,
  );

  /// Pretend the browser already holds a session cookie for this account.
  void signInBrowser(FakeAccount account) => _cookieUser = account;

  Session session({required bool useCookies, String? ssoError}) {
    final bearer = HttpBearerAuth();
    final api = ApiClient(basePath: 'http://server', authentication: bearer)
      ..client = client;
    return Session(
      client: api,
      bearer: bearer,
      useCookies: useCookies,
      ssoError: ssoError,
    );
  }

  FakeAccount? _caller(http.Request request) {
    final header = request.headers['Authorization'];
    if (header != null && header.startsWith('Bearer t-')) {
      return accounts[header.substring('Bearer t-'.length)];
    }
    return _cookieUser;
  }

  Future<http.Response> _handle(http.Request request) async {
    final path = request.url.path;
    requests.add('${request.method} $path');
    http.Response json(Object? body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );
    final caller = _caller(request);

    if (path == '/api/v1/accounts/sso') {
      return json({
        'enabled': ssoEnabled,
        'displayName': ssoEnabled ? 'Test IdP' : null,
        'loginUrl': ssoEnabled ? '/api/v1/accounts/sso/login' : null,
      });
    }

    if (path == '/api/v1/accounts/login') {
      final body = jsonDecode(request.body) as Map<String, Object?>;
      final account = accounts[body['email']];
      if (account == null || account.password != body['password']) {
        return http.Response('', 401);
      }
      if (!account.approved) {
        return http.Response('{"error":"not_approved"}', 403);
      }
      if (body['useCookies'] == true) {
        _cookieUser = account;
        return http.Response('', 204);
      }
      return json({
        'tokenType': 'Bearer',
        'accessToken': 't-${account.email}',
        'expiresIn': 3600,
        'refreshToken': 'r',
      });
    }
    if (path == '/api/v1/accounts/logout') {
      _cookieUser = null;
      return http.Response('', 204);
    }
    if (path == '/api/v1/accounts/register') {
      final body = jsonDecode(request.body) as Map<String, Object?>;
      if ((body['password'] as String).length < 10) {
        return http.Response(
          '{"detail":"Passwords must be at least 10 characters."}',
          400,
        );
      }
      if (accounts.containsKey(body['email'])) {
        return http.Response(
          '{"detail":"Email \'${body['email']}\' is already taken."}',
          400,
        );
      }
      final account = add(
        body['email']! as String,
        password: body['password']! as String,
        approved: false,
        name: body['displayName']! as String,
      );
      return json({'id': account.id, 'isApproved': account.approved}, 201);
    }

    if (caller == null) return http.Response('', 401);

    if (path == '/api/v1/accounts/me') {
      return json({
        'id': caller.id,
        'email': caller.email,
        'displayName': caller.name,
        'roles': caller.roles,
      });
    }

    if (path == '/api/v1/accounts/users') {
      if (!caller.roles.contains('admin')) return http.Response('', 403);
      final pending = accounts.values.where((a) => !a.approved);
      return json([
        for (final a in pending)
          {
            'id': a.id,
            'email': a.email,
            'displayName': a.name,
            'isApproved': false,
            'createdAt': '2026-11-02T08:00:00Z',
          },
      ]);
    }
    final approve = RegExp(r'^/api/v1/accounts/users/([^/]+)/approve$')
        .firstMatch(path);
    if (approve != null) {
      accounts.values.firstWhere((a) => a.id == approve.group(1)).approved =
          true;
      return http.Response('', 204);
    }

    if (path == '/api/v1/rides' && request.method == 'GET') {
      return json({'rides': rides, 'next': null});
    }
    if (path == '/api/v1/rides/uploads') {
      rides.insert(
        0,
        rideJson('ride-new', 'processing', fileName: 'morning.gpx'),
      );
      _pollsLeft = 1;
      return json({'rideId': 'ride-new', 'status': 'processing'}, 202);
    }
    final one = RegExp(r'^/api/v1/rides/([^/]+)$').firstMatch(path);
    if (one != null && request.method == 'GET') {
      if (one.group(1) == 'ride-new' && _pollsLeft-- > 0) {
        return json(rides.first);
      }
      if (one.group(1) == 'ride-new') {
        rides[0] = rideJson(
          'ride-new',
          'ready',
          fileName: 'morning.gpx',
          distanceM: 24500,
          movingS: 3720,
          avgPowerW: 205,
          normalizedPowerW: 212,
        );
        return json(rides.first);
      }
      return json(rides.firstWhere((r) => r['id'] == one.group(1)));
    }
    return http.Response('', 404);
  }
}

/// Every field the server sends for a ride (the generated client expects all of them to be present).
Map<String, Object?> rideJson(
  String id,
  String status, {
  String fileName = 'ride.fit',
  String? error,
  double? distanceM,
  double? movingS,
  double? elevationGainM,
  double? avgSpeedMs,
  int? avgPowerW,
  int? normalizedPowerW,
  int? avgHeartRate,
  int? avgCadence,
}) => {
  'id': id,
  'status': status,
  'error': error,
  'duplicateOf': null,
  'fileName': fileName,
  'uploadedAt': '2026-11-02T08:00:00Z',
  'startTime': status == 'ready' ? '2026-11-01T07:30:00Z' : null,
  'utcOffsetMinutes': null,
  'device': null,
  'distanceM': distanceM,
  'elapsedS': movingS,
  'movingS': movingS,
  'elevationGainM': elevationGainM,
  'elevationLossM': null,
  'avgSpeedMs': avgSpeedMs,
  'maxSpeedMs': null,
  'speedSource': null,
  'avgPowerW': avgPowerW,
  'maxPowerW': null,
  'normalizedPowerW': normalizedPowerW,
  'avgHeartRate': avgHeartRate,
  'maxHeartRate': null,
  'avgCadence': avgCadence,
};

/// Starts the app the way main.dart does, with the session restored first.
Future<void> startApp(
  WidgetTester tester,
  Session session, {
  FilePicker? pickFile,
  SsoStarter? startSso,
}) async {
  await tester.runAsync(session.restore);
  await tester.pumpWidget(
    VelomineApp(
      session: session,
      pickFile: pickFile ?? () async => null,
      startSso: startSso ?? () async {},
      uploadPollInterval: const Duration(milliseconds: 10),
    ),
  );
  await tester.pumpAndSettle();
}

Future<XFile?> fakeRideFile() async => XFile.fromData(
  Uint8List.fromList(utf8.encode('<gpx/>')),
  name: 'morning.gpx',
);
