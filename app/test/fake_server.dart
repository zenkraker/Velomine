import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:velomine/app.dart';
import 'package:velomine/core/hooks.dart';
import 'package:velomine/core/session.dart';
import 'package:velomine/core/theme_choice.dart';
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
  String? tileUrl; // what GET /server offers as a map background
  final bikes = <Map<String, Object?>>[];
  final parts =
      <String, List<Map<String, Object?>>>{}; // a bike's parts, by bike id
  final streams =
      <String, Map<String, Object?>>{}; // a ride's samples, by ride id
  /// Profiles by email; a missing one is the default (nothing set, weeks from Monday).
  final profiles = <String, Map<String, Object?>>{};

  /// What GET /analytics/totals answers, by period; a missing period has no rides.
  final totals = <String, List<Map<String, Object?>>>{};

  final goals = <Map<String, Object?>>[];

  /// How far each goal metric has got this period, for goal progress.
  final goalCurrent = <String, double>{};

  final notifications = <Map<String, Object?>>[];
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

    if (path == '/api/v1/server') {
      return json({
        'name': 'Velomine',
        'version': '0.0.0',
        'mapTileUrl': tileUrl,
        'mapAttribution': tileUrl == null ? null : '© Test Maps',
      });
    }

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

    final bikeReply = _bikes(request, path, json);
    if (bikeReply != null) return bikeReply;
    final moreReply = _more(request, path, caller, json);
    if (moreReply != null) return moreReply;

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
    final samples = RegExp(r'^/api/v1/rides/([^/]+)/streams$').firstMatch(path);
    if (samples != null) {
      final body = streams[samples.group(1)];
      return body == null ? http.Response('', 409) : json(body);
    }
    final rideBike = RegExp(r'^/api/v1/rides/([^/]+)/bike$').firstMatch(path);
    if (rideBike != null && request.method == 'PUT') {
      final ride = rides.firstWhere((r) => r['id'] == rideBike.group(1));
      ride['bikeId'] = (jsonDecode(request.body) as Map)['bikeId'];
      return json(ride);
    }
    final one = RegExp(r'^/api/v1/rides/([^/]+)$').firstMatch(path);
    if (one != null && request.method == 'DELETE') {
      rides.removeWhere((r) => r['id'] == one.group(1));
      return http.Response('', 204);
    }
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
      final found = rides.where((r) => r['id'] == one.group(1));
      return found.isEmpty ? http.Response('', 404) : json(found.first);
    }
    return http.Response('', 404);
  }
}

/// One notification as the server sends it.
Map<String, Object?> notificationJson(
  String id,
  String type,
  String subject, {
  String? rideId,
  String? bikeId,
  bool isRead = false,
}) => {
  'id': id,
  'type': type,
  'subject': subject,
  'rideId': rideId,
  'bikeId': bikeId,
  'componentId': null,
  'aboutUserId': null,
  'createdAt': '2026-11-04T09:00:00Z',
  'isRead': isRead,
};

/// One period's totals as the server sends them.
Map<String, Object?> totalsJson(
  String start,
  String end, {
  int rides = 0,
  double distanceM = 0,
  double movingS = 0,
  double elevationGainM = 0,
}) => {
  'start': start,
  'end': end,
  'rides': rides,
  'distanceM': distanceM,
  'movingS': movingS,
  'elevationGainM': elevationGainM,
};

extension on FakeServer {
  /// Profile, totals, goals and notifications.
  http.Response? _more(
    http.Request request,
    String path,
    FakeAccount caller,
    http.Response Function(Object?, [int]) json,
  ) {
    if (!path.startsWith('/api/v1/accounts/me/profile') &&
        !path.startsWith('/api/v1/analytics') &&
        !path.startsWith('/api/v1/notifications')) {
      return null;
    }
    final body = request.body.isEmpty
        ? <String, Object?>{}
        : jsonDecode(request.body) as Map<String, Object?>;

    if (path == '/api/v1/accounts/me/profile') {
      final profile = profiles.putIfAbsent(
        caller.email,
        () => {
          'displayName': caller.name,
          'ftpW': null,
          'weightKg': null,
          'maxHeartRate': null,
          'timeZone': null,
          'firstDayOfWeek': 'monday',
        },
      );
      if (request.method == 'PUT') profile.addAll(body);
      return json(profile);
    }

    if (path == '/api/v1/analytics/totals') {
      final period = request.url.queryParameters['period']!;
      return json({'period': period, 'totals': totals[period] ?? []});
    }

    Map<String, Object?> goalJson(Map<String, Object?> g) {
      final current = goalCurrent[g['metric']] ?? 0.0;
      final target = (g['target']! as num).toDouble();
      return {
        ...g,
        'periodStart': '2026-11-02',
        'periodEnd': '2026-11-08',
        'current': current,
        'percent': (current / target * 100).floor(),
        'reached': current >= target,
      };
    }

    if (path == '/api/v1/analytics/goals') {
      if (request.method == 'GET') {
        return json({
          'goals': [for (final g in goals) goalJson(g)],
        });
      }
      final g = {'id': 'goal-${goals.length + 1}', ...body};
      goals.add(g);
      return json(goalJson(g), 201);
    }
    final goal = RegExp(r'^/api/v1/analytics/goals/([^/]+)$').firstMatch(path);
    if (goal != null) {
      final index = goals.indexWhere((g) => g['id'] == goal.group(1));
      if (index < 0) return http.Response('', 404);
      if (request.method == 'DELETE') {
        goals.removeAt(index);
        return http.Response('', 204);
      }
      goals[index] = {...goals[index], 'target': body['target']};
      return json(goalJson(goals[index]));
    }

    if (path == '/api/v1/notifications') {
      return json({
        'notifications': notifications,
        'unreadCount': notifications.where((n) => n['isRead'] != true).length,
      });
    }
    if (path == '/api/v1/notifications/read') {
      for (final n in notifications) {
        n['isRead'] = true;
      }
      return http.Response('', 204);
    }
    final read = RegExp(r'^/api/v1/notifications/([^/]+)/read$')
        .firstMatch(path);
    if (read != null) {
      final found = notifications.where((n) => n['id'] == read.group(1));
      if (found.isEmpty) return http.Response('', 404);
      found.first['isRead'] = true;
      return http.Response('', 204);
    }
    return null;
  }

  http.Response? _bikes(
    http.Request request,
    String path,
    http.Response Function(Object?, [int]) json,
  ) {
    if (!path.startsWith('/api/v1/bikes')) return null;
    final body = request.body.isEmpty
        ? <String, Object?>{}
        : jsonDecode(request.body) as Map<String, Object?>;
    Map<String, Object?> bikeJson(Map<String, Object?> b) => {
      'isActive': true,
      'rideCount': 0,
      'distanceM': b['initialDistanceM'],
      'movingS': 0.0,
      'isDefault': false,
      'brand': null,
      'model': null,
      'purchasedOn': null,
      ...b,
    };
    Map<String, Object?> detail(String id) => {
      'bike': bikeJson(bikes.firstWhere((b) => b['id'] == id)),
      'components': parts[id] ?? [],
    };

    if (path == '/api/v1/bikes/component-types') {
      return json({
        'types': [
          {
            'id': 'chain',
            'name': 'Chain',
            'group': 'Drivetrain',
            'typicalDistanceM': 4000000.0,
            'typicalHours': null,
            'typicalMonths': null,
          },
          {
            'id': 'tubeless_sealant',
            'name': 'Tubeless sealant',
            'group': 'Wheels',
            'typicalDistanceM': null,
            'typicalHours': null,
            'typicalMonths': 3,
          },
        ],
      });
    }
    if (path == '/api/v1/bikes') {
      if (request.method == 'GET') {
        return json({
          'bikes': [for (final b in bikes) bikeJson(b)],
        });
      }
      final b = {
        'id': 'bike-${bikes.length + 1}',
        ...body,
        'isDefault': bikes.isEmpty,
      };
      bikes.add(b);
      return json(detail(b['id']! as String), 201);
    }
    final part = RegExp(r'^/api/v1/bikes/([^/]+)/components(?:/([^/]+))?$')
        .firstMatch(path);
    if (part != null) {
      final list = parts.putIfAbsent(part.group(1)!, () => []);
      if (request.method == 'POST') {
        list.add({
          'id': 'part-${list.length + 1}',
          'typeName': body['type'] == 'chain' ? 'Chain' : 'Tubeless sealant',
          'brand': null,
          'model': null,
          'removedOn': null,
          'expectedDistanceM': null,
          'expectedHours': null,
          'expectedMonths': null,
          'usedDistanceM': 0.0,
          'usedHours': 0.0,
          'usedMonths': 0.0,
          'wearPercent': null,
          'status': 'ok',
          ...body,
        });
        return json(detail(part.group(1)!), 201);
      }
      final index = list.indexWhere((p) => p['id'] == part.group(2));
      if (index < 0) return http.Response('', 404);
      if (request.method == 'DELETE') {
        list.removeAt(index);
        return http.Response('', 204);
      }
      list[index] = {
        ...list[index],
        ...body,
        if (body['removedOn'] != null) 'status': 'retired',
      };
      return json(detail(part.group(1)!));
    }
    final one = RegExp(r'^/api/v1/bikes/([^/]+)(/default)?$').firstMatch(path);
    if (one == null) return null;
    final id = one.group(1)!;
    final index = bikes.indexWhere((b) => b['id'] == id);
    if (index < 0) return http.Response('', 404);
    if (one.group(2) != null) {
      for (final b in bikes) {
        b['isDefault'] = b['id'] == id;
      }
      return http.Response('', 204);
    }
    if (request.method == 'DELETE') {
      bikes.removeAt(index);
      return http.Response('', 204);
    }
    if (request.method == 'PUT') {
      bikes[index] = {
        ...bikes[index],
        ...body,
        if (body['isActive'] == false) 'isDefault': false,
      };
    }
    return json(detail(id));
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
  String? bikeId,
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
  'bikeId': bikeId,
};

/// Starts the app the way main.dart does, with the session restored first.
Future<void> startApp(
  WidgetTester tester,
  Session session, {
  FilePicker? pickFile,
  SsoStarter? startSso,
  ThemeChoice? themeChoice,
}) async {
  await tester.runAsync(session.restore);
  await tester.pumpWidget(
    VelomineApp(
      session: session,
      themeChoice: themeChoice ?? ThemeChoice(store: MemoryThemeStore()),
      pickFile: pickFile ?? () async => null,
      startSso: startSso ?? () async {},
      uploadPollInterval: const Duration(milliseconds: 10),
    ),
  );
  await tester.pumpAndSettle();
}

/// Keeps the theme choice in memory instead of the device's preferences.
class MemoryThemeStore implements ThemeChoiceStore {
  MemoryThemeStore([this.value]);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

Future<XFile?> fakeRideFile() async => XFile.fromData(
  Uint8List.fromList(utf8.encode('<gpx/>')),
  name: 'morning.gpx',
);

/// A ride's samples as the server sends them: one array per signal, null for a signal the ride does not have.
/// 60 samples a second apart, riding north at 10 m/s, climbing half a metre a second.
Map<String, Object?> streamsJson({
  bool position = true,
  bool cadence = false,
  bool speed = true,
}) {
  const n = 60;
  List<T> each<T>(T Function(int i) f) => [for (var i = 0; i < n; i++) f(i)];
  return {
    'time': each((i) => i * 1.0),
    'latitude': position ? each((i) => 46 + i * 10 / 111195) : null,
    'longitude': position ? each((_) => 11.0) : null,
    'altitude': each((i) => 300 + i * 0.5),
    'speed': speed ? each((_) => 10.0) : null,
    'distance': each((i) => i * 10.0),
    'heartRate': each((i) => 140 + i ~/ 6),
    'power': each((i) => i.isEven ? 180 : 220),
    'cadence': cadence ? each((_) => 90) : null,
    'temperature': null,
  };
}
