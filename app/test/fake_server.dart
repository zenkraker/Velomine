import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:velomine/app.dart';
import 'package:velomine/core/hooks.dart';
import 'package:velomine/core/language_choice.dart';
import 'package:velomine/core/pkce.dart';
import 'package:velomine/core/session.dart';
import 'package:velomine/core/session_auth.dart';
import 'package:velomine/core/theme_choice.dart';
import 'package:velomine/core/token_store.dart';
import 'package:velomine_api/api.dart';

class FakeAccount {
  FakeAccount(
    this.email,
    this.password, {
    this.name = 'Test Rider',
    this.approved = true,
    List<String> roles = const ['member'],
  }) : id = 'id-${email.hashCode.abs()}',
       roles = [...roles];

  final String id;
  final String email;
  final String password;
  final String name;
  bool approved;
  bool locked = false;
  List<String> roles;
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

  /// What GET /analytics/training answers; null uses [trainingJson].
  Map<String, Object?>? training;

  /// The day counts asked for by GET /analytics/training, in order.
  final trainingRequests = <int>[];

  final goals = <Map<String, Object?>>[];

  /// How far each goal metric has got this period, for goal progress.
  final goalCurrent = <String, double>{};

  final notifications = <Map<String, Object?>>[];

  /// Club memberships by email, and the one club this fake hosts.
  final clubRoles = <String, String>{};
  String clubName = 'Test Club';
  String joinCode = 'JOIN1234';
  bool clubActive = true;

  /// What the (single) fake club member shares, and who looked.
  final sharingChoices = <String, String>{
    'rides': 'none',
    'analytics': 'none',
    'routes': 'none',
  };
  final shareViews = <Map<String, Object?>>[];

  /// What the admin settings screen is told, and the read-only status of what only the environment sets.
  final adminSettings = <String, Object?>{
    'signUpEnabled': true,
    'requireAdminApproval': true,
    'mapTileUrl': null,
    'mapAttribution': null,
  };
  bool smtpConfigured = false;

  /// How many export download links were asked for.
  int exportLinks = 0;

  /// Simulates a server that cannot be reached: every request fails before it is handled.
  bool unreachable = false;

  /// How long the access tokens the fake hands out last.
  int tokenExpiresIn = 3600;

  /// How many refresh-token exchanges were made.
  int refreshCount = 0;

  /// Who a test email was sent to, and what the mail server answered.
  final testEmails = <String>[];
  int testEmailStatus = 204;
  bool ssoConfigured = false;

  /// One-time codes the browser sign-in could have handed back, and the PKCE challenge the app sent for them.
  final ssoCodes = <String, FakeAccount>{};
  String? ssoChallenge;
  FakeAccount? _cookieUser;
  int _pollsLeft = 1;

  late final http.Client client = MockClient(_handle);

  FakeAccount add(
    String email, {
    String password = 'Rider-pass-123',
    bool approved = true,
    List<String> roles = const ['member'],
    String name = 'Test Rider',
    String? clubRole = 'member',
  }) {
    final account = FakeAccount(
      email,
      password,
      approved: approved,
      roles: roles,
      name: name,
    );
    accounts[email] = account;
    if (clubRole != null) clubRoles[email] = clubRole;
    return account;
  }

  /// Pretend the browser already holds a session cookie for this account.
  void signInBrowser(FakeAccount account) => _cookieUser = account;

  Session session({
    required bool useCookies,
    String? ssoError,
    TokenStore? tokenStore,
    DateTime Function()? now,
    String serverUrl = 'http://server',
  }) {
    final baseUrl = serverUrl;
    final auth = SessionAuth(
      baseUrl: baseUrl,
      store: tokenStore ?? MemoryTokenStore(),
      useCookies: useCookies,
      refreshClient: client,
      now: now,
    );
    final api = ApiClient(basePath: baseUrl, authentication: auth)
      ..client = client;
    return Session(
      client: api,
      auth: auth,
      useCookies: useCookies,
      serverUrl: baseUrl,
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
    if (unreachable) {
      throw http.ClientException('The server is unreachable.', request.url);
    }
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
        'emailAvailable': smtpConfigured,
      });
    }

    if (path == '/api/v1/accounts/sso') {
      return json({
        'enabled': ssoEnabled,
        'displayName': ssoEnabled ? 'Test IdP' : null,
        'loginUrl': ssoEnabled ? '/api/v1/accounts/sso/login' : null,
      });
    }

    if (path == '/api/v1/accounts/refresh') {
      final body = jsonDecode(request.body) as Map<String, Object?>;
      final saved = body['refreshToken'] as String?;
      final email = saved != null && saved.startsWith('r-')
          ? saved.substring(2)
          : null;
      final account = email == null ? null : accounts[email];
      if (account == null || !account.approved || account.locked) {
        return http.Response('', 401);
      }
      refreshCount++;
      return json({
        'tokenType': 'Bearer',
        'accessToken': 't-${account.email}',
        'expiresIn': tokenExpiresIn,
        'refreshToken': 'r-${account.email}',
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
        'expiresIn': tokenExpiresIn,
        'refreshToken': 'r-${account.email}',
      });
    }
    if (path == '/api/v1/accounts/sso/token') {
      final body = jsonDecode(request.body) as Map<String, Object?>;
      final account = ssoCodes.remove(body['code']); // a code is good once
      final proven =
          Pkce.fromVerifier(body['codeVerifier']! as String).challenge ==
          ssoChallenge;
      if (account == null || !proven) return http.Response('', 401);
      return json({
        'tokenType': 'Bearer',
        'accessToken': 't-${account.email}',
        'expiresIn': tokenExpiresIn,
        'refreshToken': 'r-${account.email}',
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
        clubRole: null,
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
    if (path == '/api/v1/accounts/me/export-link') {
      exportLinks++;
      return json({
        'path': '/api/v1/accounts/export/token-$exportLinks',
        'expiresAt': '2026-11-05T12:02:00Z',
      });
    }
    if (path == '/api/v1/accounts/me/delete') {
      final body = jsonDecode(request.body) as Map<String, Object?>;
      final confirmed = caller.password.isNotEmpty
          ? body['password'] == caller.password
          : (body['confirmEmail'] as String?)?.toLowerCase() == caller.email;
      if (!confirmed) return http.Response('{"detail":"no"}', 403);
      if (caller.roles.contains('admin') &&
          accounts.values.where((a) => a.roles.contains('admin')).length < 2) {
        return http.Response('{"detail":"only admin"}', 409);
      }
      accounts.remove(caller.email);
      _cookieUser = null;
      return http.Response('', 204);
    }
    if (!path.startsWith('/api/v1/accounts/me/profile') &&
        !path.startsWith('/api/v1/analytics') &&
        !path.startsWith('/api/v1/notifications') &&
        !path.startsWith('/api/v1/club') &&
        !path.startsWith('/api/v1/clubs') &&
        !path.startsWith('/api/v1/sharing') &&
        !path.startsWith('/api/v1/admin')) {
      return null;
    }
    if (path.startsWith('/api/v1/clubs')) {
      return _coach(request, path, caller, json);
    }
    if (path == '/api/v1/club' || path.startsWith('/api/v1/club/')) {
      return _club(request, path, caller, json);
    }
    if (path.startsWith('/api/v1/sharing')) {
      return _sharing(request, path, json);
    }
    if (path.startsWith('/api/v1/admin')) {
      if (!caller.roles.contains('admin')) return http.Response('', 403);
      return _admin(request, path, caller, json);
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
          'emailNotifications': true,
          'hasPassword': caller.password.isNotEmpty,
        },
      );
      if (request.method == 'PUT') profile.addAll(body);
      return json(profile);
    }

    if (path == '/api/v1/analytics/totals') {
      final period = request.url.queryParameters['period']!;
      return json({'period': period, 'totals': totals[period] ?? []});
    }

    if (path == '/api/v1/analytics/training') {
      final days =
          int.tryParse(request.url.queryParameters['days'] ?? '') ?? 90;
      trainingRequests.add(days);
      return json(training ?? trainingJson(days: days));
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

  Map<String, Object?> _adminClubJson() {
    final owner = accounts.values
        .where((a) => clubRoles[a.email] == 'owner')
        .firstOrNull;
    return {
      'id': 'club-1',
      'name': clubName,
      'joinCode': joinCode,
      'isActive': clubActive,
      'createdAt': '2026-11-02T08:00:00Z',
      'memberCount': clubRoles.length,
      'ownerId': owner?.id,
      'ownerName': owner?.name,
      'ownerEmail': owner?.email,
      'ownerRole': owner == null ? null : 'owner',
    };
  }

  Map<String, Object?>? _myClubJson(FakeAccount me) {
    final role = clubRoles[me.email];
    if (role == null) return null;
    final members =
        accounts.values.where((a) => clubRoles.containsKey(a.email)).toList()
          ..sort((a, b) {
            int rank(String? r) => r == 'owner'
                ? 0
                : r == 'coach'
                ? 1
                : 2;
            final byRole = rank(clubRoles[a.email])
                .compareTo(rank(clubRoles[b.email]));
            return byRole != 0 ? byRole : a.name.compareTo(b.name);
          });
    return {
      'id': 'club-1',
      'name': clubName,
      'isActive': clubActive,
      'myRole': role,
      'joinCode': role == 'owner' ? joinCode : null,
      'members': [
        for (final a in members)
          {
            'userId': a.id,
            'displayName': a.name,
            'role': clubRoles[a.email],
            'joinedAt': '2026-11-02T08:00:00Z',
          },
      ],
    };
  }

  http.Response _club(
    http.Request request,
    String path,
    FakeAccount caller,
    http.Response Function(Object?, [int]) json,
  ) {
    final body = request.body.isEmpty
        ? <String, Object?>{}
        : jsonDecode(request.body) as Map<String, Object?>;

    if (path == '/api/v1/club') {
      return json({'club': _myClubJson(caller)});
    }
    if (path == '/api/v1/club/join') {
      if (clubRoles.containsKey(caller.email)) {
        return http.Response('{"detail":"already in a club"}', 409);
      }
      if (!clubActive || body['code'] != joinCode) {
        return http.Response('', 404);
      }
      clubRoles[caller.email] = 'member';
      return json({'club': _myClubJson(caller)});
    }
    if (path == '/api/v1/club/leave') {
      if (!clubRoles.containsKey(caller.email)) return http.Response('', 404);
      if (clubRoles[caller.email] == 'owner') {
        return http.Response('{"detail":"owner"}', 409);
      }
      clubRoles.remove(caller.email);
      return http.Response('', 204);
    }
    if (path == '/api/v1/club/join-code') {
      if (clubRoles[caller.email] != 'owner') return http.Response('', 403);
      joinCode = 'NEWCODE1';
      return json({'joinCode': joinCode});
    }
    final member = RegExp(r'^/api/v1/club/members/([^/]+)/role$')
        .firstMatch(path);
    if (member != null) {
      if (clubRoles[caller.email] != 'owner') return http.Response('', 403);
      final target = accounts.values
          .where((a) => a.id == member.group(1))
          .firstOrNull;
      if (target == null || !clubRoles.containsKey(target.email)) {
        return http.Response('', 404);
      }
      final role = body['role']! as String;
      if (role != 'coach' && role != 'member') {
        return http.Response('', 400);
      }
      clubRoles[target.email] = role;
      return json({
        'userId': target.id,
        'displayName': target.name,
        'role': role,
        'joinedAt': '2026-11-02T08:00:00Z',
      });
    }
    return http.Response('', 404);
  }

  http.Response _sharing(
    http.Request request,
    String path,
    http.Response Function(Object?, [int]) json,
  ) {
    if (path == '/api/v1/sharing/views') {
      return json({'views': shareViews});
    }
    if (path == '/api/v1/sharing') {
      if (request.method == 'PUT') {
        final body = jsonDecode(request.body) as Map<String, Object?>;
        sharingChoices.addAll(body.cast<String, String>());
      }
      return json(sharingChoices);
    }
    return http.Response('', 404);
  }

  http.Response _coach(
    http.Request request,
    String path,
    FakeAccount caller,
    http.Response Function(Object?, [int]) json,
  ) {
    final role = clubRoles[caller.email];
    if (role != 'owner' && role != 'coach') return http.Response('', 404);

    Map<String, Object?> summary(FakeAccount a) => {
      'userId': a.id,
      'displayName': a.name,
      'sharesRides': sharingChoices['rides'] != 'none',
      'sharesAnalytics': sharingChoices['analytics'] != 'none',
      'sharesRoutes': sharingChoices['routes'] != 'none',
      'lastRideAt': rides.isEmpty ? null : rides.first['startTime'],
      'rides': rides.length,
      'distanceM': rides.fold<double>(
        0,
        (sum, r) => sum + ((r['distanceM'] as num?)?.toDouble() ?? 0),
      ),
      'tss7': 60.0,
      'tss42': 240.0,
    };

    final rideStreams = RegExp(
      r'^/api/v1/clubs/[^/]+/athletes/([^/]+)/rides/([^/]+)/streams$',
    ).firstMatch(path);
    final ride = RegExp(r'^/api/v1/clubs/[^/]+/athletes/([^/]+)/rides/([^/]+)$')
        .firstMatch(path);
    if (rideStreams != null || ride != null) {
      final match = rideStreams ?? ride!;
      if (sharingChoices['rides'] == 'none') return http.Response('', 404);
      final found = rides.where((r) => r['id'] == match.group(2));
      if (found.isEmpty) return http.Response('', 404);
      if (ride != null) return json(found.first);
      final stream = streams[match.group(2)];
      if (stream == null) return http.Response('', 409);
      final hidden = sharingChoices['routes'] == 'none';
      return json({
        ...stream,
        if (hidden) 'latitude': null,
        if (hidden) 'longitude': null,
      });
    }

    final ridesList = RegExp(r'^/api/v1/clubs/[^/]+/athletes/([^/]+)/rides$')
        .firstMatch(path);
    if (ridesList != null) {
      if (sharingChoices['rides'] == 'none') return http.Response('', 404);
      return json({'rides': rides, 'next': null});
    }

    final training = RegExp(r'^/api/v1/clubs/[^/]+/athletes/([^/]+)/training$')
        .firstMatch(path);
    if (training != null) {
      if (sharingChoices['analytics'] == 'none') return http.Response('', 404);
      final days =
          int.tryParse(request.url.queryParameters['days'] ?? '') ?? 90;
      return json(trainingJson(days: days));
    }

    final one = RegExp(r'^/api/v1/clubs/[^/]+/athletes/([^/]+)$')
        .firstMatch(path);
    if (one != null) {
      final found = accounts.values
          .where((a) => a.id == one.group(1))
          .firstOrNull;
      if (found == null) return http.Response('', 404);
      return json(summary(found));
    }

    if (RegExp(r'^/api/v1/clubs/[^/]+/athletes$').hasMatch(path)) {
      final athletes = accounts.values
          .where(
            (a) => a.email != caller.email && clubRoles.containsKey(a.email),
          )
          .map(summary)
          .toList();
      return json({'athletes': athletes});
    }
    return http.Response('', 404);
  }

  http.Response _admin(
    http.Request request,
    String path,
    FakeAccount caller,
    http.Response Function(Object?, [int]) json,
  ) {
    Map<String, Object?> userJson(FakeAccount a) => {
      'id': a.id,
      'email': a.email,
      'displayName': a.name,
      'isApproved': a.approved,
      'isLockedOut': a.locked,
      'roles': a.roles,
      'createdAt': '2026-11-02T08:00:00Z',
    };

    if (path == '/api/v1/admin/users') {
      return json({
        'users': [for (final a in accounts.values) userJson(a)],
      });
    }
    if (path == '/api/v1/admin/clubs') {
      if (request.method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, Object?>;
        final email = body['ownerEmail']! as String;
        final owner = accounts[email];
        if (owner == null) return http.Response('', 400);
        if (clubRoles.containsKey(email)) return http.Response('', 409);
        clubName = body['name']! as String;
        clubRoles[email] = 'owner';
        return json(_adminClubJson());
      }
      return json({
        'clubs': [_adminClubJson()],
      });
    }
    final owner = RegExp(r'^/api/v1/admin/clubs/([^/]+)/owner$')
        .firstMatch(path);
    if (owner != null) {
      final body = jsonDecode(request.body) as Map<String, Object?>;
      final target = accounts.values
          .where((a) => a.id == body['userId'])
          .firstOrNull;
      if (target == null || !clubRoles.containsKey(target.email)) {
        return http.Response('', 404);
      }
      for (final entry in clubRoles.entries.toList()) {
        if (entry.value == 'owner') clubRoles[entry.key] = 'member';
      }
      clubRoles[target.email] = 'owner';
      return json(_adminClubJson());
    }
    final club = RegExp(r'^/api/v1/admin/clubs/([^/]+)$').firstMatch(path);
    if (club != null) {
      final body = jsonDecode(request.body) as Map<String, Object?>;
      clubName = body['name']! as String;
      clubActive = body['isActive']! as bool;
      return json(_adminClubJson());
    }
    if (path == '/api/v1/admin/settings/test-email') {
      testEmails.add(caller.email);
      return testEmailStatus == 204
          ? http.Response('', 204)
          : http.Response('{"detail":"rejected"}', testEmailStatus);
    }
    if (path == '/api/v1/admin/overview') {
      return json({
        'accounts': accounts.length,
        'waitingForApproval': accounts.values.where((a) => !a.approved).length,
        'locked': accounts.values.where((a) => a.locked).length,
        'rides': rides.length,
        'rideFilesBytes': 1234567,
        'version': '0.1.0',
      });
    }
    if (path == '/api/v1/admin/settings') {
      if (request.method == 'PUT') {
        adminSettings.addAll(jsonDecode(request.body) as Map<String, Object?>);
      }
      return json({
        ...adminSettings,
        'smtp': {
          'configured': smtpConfigured,
          'host': smtpConfigured ? 'smtp.club.example' : null,
          'port': smtpConfigured ? 587 : null,
          'security': smtpConfigured ? 'starttls' : null,
          'from': smtpConfigured ? 'velomine@club.example' : null,
        },
        'sso': {
          'enabled': ssoConfigured,
          'displayName': ssoConfigured ? 'Club login' : null,
          'authority': ssoConfigured ? 'https://idp.club.example' : null,
        },
      });
    }
    final one = RegExp(
      r'^/api/v1/admin/users/([^/]+)(?:/(roles|lock|unlock))?$',
    ).firstMatch(path);
    if (one != null) {
      final found = accounts.values.where((a) => a.id == one.group(1));
      if (found.isEmpty) return http.Response('', 404);
      final target = found.first;
      if (target.id == caller.id && one.group(2) != 'roles') {
        return http.Response('', 409);
      }
      switch (one.group(2)) {
        case 'roles':
          final wanted = (jsonDecode(request.body) as Map)['roles'] as List;
          target.roles = {'member', ...wanted.cast<String>()}.toList();
          return json(userJson(target));
        case 'lock':
          target.locked = true;
        case 'unlock':
          target.locked = false;
        default:
          accounts.remove(target.email);
      }
      return http.Response('', 204);
    }
    return http.Response('', 404);
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
  double? intensityFactor,
  double? tss,
  double? trimp,
  List<Map<String, Object?>> heartRateZones = const [],
  List<Map<String, Object?>> powerZones = const [],
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
  'intensityFactor': intensityFactor,
  'tss': tss,
  'trimp': trimp,
  'avgHeartRate': avgHeartRate,
  'maxHeartRate': null,
  'avgCadence': avgCadence,
  'bikeId': bikeId,
  'heartRateZones': heartRateZones,
  'powerZones': powerZones,
};

/// One training zone as the ride detail receives it.
Map<String, Object?> zoneJson(int zone, int from, int? to, double seconds) => {
  'zone': zone,
  'from': from,
  'to': to,
  'seconds': seconds,
};

/// What GET /analytics/training answers by default: a little load on three days.
Map<String, Object?> trainingJson({
  int days = 90,
  double tss = 240,
  double trimp = 180,
  int rides = 3,
  double distanceM = 80000,
}) => {
  'dayCount': days,
  'from': '2026-08-07',
  'to': '2026-11-04',
  'rides': rides,
  'distanceM': distanceM,
  'movingS': 10800.0,
  'elevationGainM': 600.0,
  'tss': tss,
  'trimp': trimp,
  'days': [
    for (var i = 0; i < 3; i++)
      {
        'date': '2026-11-0${2 + i}',
        'rides': i == 2 ? 1 : 0,
        'distanceM': i == 2 ? distanceM : 0.0,
        'movingS': i == 2 ? 3600.0 : 0.0,
        'elevationGainM': i == 2 ? 200.0 : 0.0,
        'tss': i == 2 ? 60.0 : 0.0,
        'trimp': i == 2 ? 45.0 : 0.0,
        'fitness': 40.0 + i,
        'fatigue': 30.0 + i,
        'form': 10.0,
      },
  ],
};

/// Starts the app the way main.dart does, with the session restored first.
Future<void> startApp(
  WidgetTester tester,
  Session session, {
  FilePicker? pickFile,
  SsoStarter? startSso,
  ThemeChoice? themeChoice,
  LanguageChoice? languageChoice,
  LinkOpener? openLink,
  Future<void> Function()? onChangeServer,
}) async {
  await tester.runAsync(session.restore);
  final language =
      languageChoice ?? LanguageChoice(store: MemoryLanguageStore());
  await language.load();
  await tester.pumpWidget(
    VelomineApp(
      session: session,
      themeChoice: themeChoice ?? ThemeChoice(store: MemoryThemeStore()),
      languageChoice: language,
      pickFile: pickFile ?? () async => null,
      startSso: startSso ?? () async {},
      openLink: openLink ?? (_) async {},
      onChangeServer: onChangeServer,
      uploadPollInterval: const Duration(milliseconds: 10),
    ),
  );
  await tester.pumpAndSettle();
}

/// Keeps the refresh token in memory instead of the platform's secure storage.
class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this.token]);

  String? token;

  @override
  Future<String?> readRefreshToken() async => token;

  @override
  Future<void> writeRefreshToken(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
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

/// Keeps the language choice in memory instead of the device's preferences.
class MemoryLanguageStore implements LanguageChoiceStore {
  MemoryLanguageStore([this.value]);

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
