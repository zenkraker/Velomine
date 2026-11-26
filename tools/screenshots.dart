import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Takes the screenshots the design checks ask for: one Chrome session on the
/// web UI, signed in, at each width a page is tested at.
///
/// The app is served by the web image at http://localhost:8080 after `just up`,
/// and the session cookie works only there, so this drives a real Chrome over
/// the DevTools protocol instead of a widget test. Chrome is the container's
/// `chrome-headless-shell` by default; `CHROME` overrides the binary.
///
/// ```
/// dart run tools/screenshots.dart --routes /rides,/progress --widths 390,1300
/// ```
///
/// Writes `.dev/screens/<route>-<width>.png` and fails when a page lands on the
/// sign-in screen or a capture is smaller than a blank page would be, because a
/// signed-out or blank screenshot is the harness's fault, not a pass.
Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  final cookies = options.signedOut ? <_Cookie>[] : await _signIn(options);
  if (!options.signedOut) await _prepare(options, cookies);
  final chrome = await _Chrome.start(options.chrome);
  try {
    await chrome.send('Network.enable');
    await chrome.send('Page.enable');
    for (final cookie in cookies) {
      await chrome.send('Network.setCookie', {
        'name': cookie.name,
        'value': cookie.value,
        'url': '${options.base}/',
      });
    }
    // The theme follows the system for a member who never chose one, and the
    // browser's preferred colour scheme is what the app reads. Emulating it is
    // how the Day and Night shots are taken from the same session.
    if (options.scheme case final scheme?) {
      await chrome.send('Emulation.setEmulatedMedia', {
        'media': 'screen',
        'features': [
          {'name': 'prefers-color-scheme', 'value': scheme},
        ],
      });
    }

    options.out.createSync(recursive: true);
    var failures = 0;
    for (final width in options.widths) {
      final height = _Options.heightFor(width);
      await chrome.send('Emulation.setDeviceMetricsOverride', {
        'width': width,
        'height': height,
        'deviceScaleFactor': 1,
        'mobile': width < 600,
      });
      for (final route in options.routes) {
        final url = '${options.base}$route';
        await chrome.send('Page.navigate', {'url': url});
        final bool ready;
        final Object? path;
        try {
          ready = await _settle(chrome);
          path = await chrome.evaluate('location.pathname');
        } on TimeoutException {
          // One page that never settles must not end the run for the pages after it.
          stderr.writeln('timed out: $url');
          failures++;
          continue;
        }
        final signInIsFailure = !options.signedOut;
        if (!ready ||
            (signInIsFailure && path.toString().startsWith('/sign-in'))) {
          stderr.writeln('not signed in or not drawn: $url');
          failures++;
          continue;
        }
        final data = await chrome.send('Page.captureScreenshot', {
          'format': 'png',
          'fromSurface': true,
        });
        final bytes = base64Decode(data['data'] as String);
        final file = File('${options.out.path}/${_slug(route)}-$width.png');
        file.writeAsBytesSync(bytes);
        // A long page scrolls inside Flutter, so further shots follow the page down.
        var previous = bytes;
        for (var step = 1; step <= options.scrolls; step++) {
          await chrome.send('Input.dispatchMouseEvent', {
            'type': 'mouseWheel',
            'x': width ~/ 2,
            'y': height ~/ 2,
            'deltaX': 0,
            'deltaY': height * 0.85,
          });
          await Future<void>.delayed(const Duration(milliseconds: 700));
          final more = await chrome.send('Page.captureScreenshot', {
            'format': 'png',
            'fromSurface': true,
          });
          final next = base64Decode(more['data'] as String);
          if (next.length == previous.length) break;
          previous = next;
          File('${options.out.path}/${_slug(route)}-$width-s$step.png')
              .writeAsBytesSync(next);
        }
        // A page that sends the route elsewhere (a destination that needs a
        // setting the account lacks) still gets a shot, but say so.
        if (path.toString() != route) {
          stdout.writeln('  redirected to $path');
        }
        stdout.writeln('${file.path}  ${bytes.length ~/ 1024} KB');
        // A blank page at any of these widths compresses far below this.
        if (bytes.length < 8000) {
          stderr.writeln('looks blank: ${file.path}');
          failures++;
        }
      }
    }
    if (failures > 0) exitCode = 1;
  } finally {
    await chrome.stop();
  }
}

/// The dev account, signed in once through the API so the browser carries the
/// same cookie the web app would have after its own form.
Future<List<_Cookie>> _signIn(_Options options) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('${options.base}/api/v1/accounts/login'),
    );
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({
        'email': options.email,
        'password': options.password,
        'useCookies': true,
        'rememberMe': true,
        'deviceLabel': 'screenshots',
      }),
    );
    final response = await request.close();
    if (response.statusCode != 204) {
      final body = await response.transform(utf8.decoder).join();
      throw StateError(
        'sign-in answered ${response.statusCode}: $body\n'
        'The dev account is in docs/development.md; two-factor must be off.',
      );
    }
    final cookies = <_Cookie>[];
    for (final header in response.headers['set-cookie'] ?? const <String>[]) {
      final pair = header.split(';').first;
      final cut = pair.indexOf('=');
      if (cut > 0) {
        cookies.add(_Cookie(pair.substring(0, cut), pair.substring(cut + 1)));
      }
    }
    if (cookies.isEmpty) throw StateError('sign-in set no cookie');
    return cookies;
  } finally {
    client.close(force: true);
  }
}

/// Waits until the page is loaded and Flutter has put its view on screen, then
/// gives the frame a moment to paint. False when the app never drew.
Future<bool> _settle(_Chrome chrome) async {
  final deadline = DateTime.now().add(const Duration(seconds: 25));
  var drawn = false;
  while (DateTime.now().isBefore(deadline)) {
    final state = await chrome.evaluate('document.readyState');
    final view = await chrome.evaluate(
      "document.querySelector('flutter-view, flt-glass-pane, flt-scene-host') != null",
    );
    drawn = view == true;
    if (state == 'complete' && drawn) break;
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  if (!drawn) return false;
  // Web fonts, tile images and the first chart frame arrive after the view does.
  await Future<void>.delayed(const Duration(milliseconds: 1200));
  return true;
}

String _slug(String route) {
  final trimmed = route.replaceAll(RegExp(r'^/+|/+$'), '');
  return trimmed.isEmpty ? 'home' : trimmed.replaceAll('/', '-');
}

class _Cookie {
  const _Cookie(this.name, this.value);

  final String name;
  final String value;
}

/// Puts the account in the mode whose layout shows every number and chart, so
/// the first-run "How do you ride?" sheet never covers a screenshot. It is the
/// answer a rider gives once, and it is idempotent.
Future<void> _prepare(_Options options, List<_Cookie> cookies) async {
  final client = HttpClient();
  try {
    final request = await client.putUrl(
      Uri.parse('${options.base}/api/v1/accounts/me/rider-mode'),
    );
    request.headers.contentType = ContentType.json;
    request.headers.set(
      HttpHeaders.cookieHeader,
      cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; '),
    );
    request.write(jsonEncode({'riderMode': 'training'}));
    final response = await request.close();
    await response.drain<void>();
    if (response.statusCode >= 300) {
      stderr.writeln(
        'rider mode not set (${response.statusCode}): '
        'a first-run sheet may cover the screenshots',
      );
    }
  } finally {
    client.close(force: true);
  }
}

/// A headless Chrome on a free port, its first page attached as a session, and
/// the DevTools commands the run needs.
class _Chrome {
  _Chrome._(this._process, this._socket);

  final Process _process;
  final WebSocket _socket;
  String _sessionId = '';
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  var _next = 0;

  static Future<_Chrome> start(String binary) async {
    final port = 9300 + DateTime.now().millisecondsSinceEpoch % 400;
    final process = await Process.start(binary, [
      '--headless',
      '--no-sandbox',
      '--disable-gpu',
      '--hide-scrollbars',
      '--user-data-dir=${Directory.systemTemp.createTempSync('velomine-shots').path}',
      '--remote-debugging-port=$port',
      'about:blank',
    ]);
    // Chrome writes its DevTools address to stderr; poll the HTTP endpoint
    // instead, so a version that logs differently still works.
    final client = HttpClient();
    String? address;
    try {
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (DateTime.now().isBefore(deadline) && address == null) {
        try {
          final request = await client.getUrl(
            Uri.parse('http://127.0.0.1:$port/json/version'),
          );
          final response = await request.close();
          final body = await response.transform(utf8.decoder).join();
          address = jsonDecode(body)['webSocketDebuggerUrl'] as String?;
        } on SocketException {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
    } finally {
      client.close(force: true);
    }
    if (address == null) {
      process.kill();
      throw StateError('Chrome did not open a DevTools port on $port');
    }
    final socket = await WebSocket.connect(address);
    final chrome = _Chrome._(process, socket);
    socket.listen(chrome._receive);
    final target = await chrome.send('Target.createTarget', {
      'url': 'about:blank',
    });
    final attached = await chrome.send('Target.attachToTarget', {
      'targetId': target['targetId'],
      'flatten': true,
    });
    chrome._sessionId = attached['sessionId'] as String;
    return chrome;
  }

  void _receive(Object? data) {
    final message = jsonDecode(data as String) as Map<String, dynamic>;
    final id = message['id'] as int?;
    if (id == null) return;
    final completer = _pending.remove(id);
    if (message['error'] case final error?) {
      completer?.completeError(StateError('$error'));
    } else {
      completer?.complete((message['result'] as Map).cast());
    }
  }

  /// One DevTools command on the attached page.
  Future<Map<String, dynamic>> send(
    String method, [
    Map<String, Object?> params = const {},
  ]) {
    final id = ++_next;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _socket.add(
      jsonEncode({
        'id': id,
        'method': method,
        'params': params,
        if (_sessionId.isNotEmpty) 'sessionId': _sessionId,
      }),
    );
    return completer.future.timeout(const Duration(seconds: 30));
  }

  /// The value of a JavaScript expression, awaited when it is a promise.
  Future<Object?> evaluate(String expression) async {
    final result = await send('Runtime.evaluate', {
      'expression': expression,
      'returnByValue': true,
      'awaitPromise': true,
    });
    return (result['result'] as Map)['value'];
  }

  Future<void> stop() async {
    try {
      await send('Browser.close');
    } on Object {
      // Closing the socket or the page first is fine: the process is going.
    }
    _socket.close();
    _process.kill();
  }
}

class _Options {
  _Options({
    required this.routes,
    required this.widths,
    required this.out,
    required this.base,
    required this.email,
    required this.password,
    required this.chrome,
    required this.scheme,
    required this.signedOut,
    required this.scrolls,
  });

  final List<String> routes;
  final List<int> widths;
  final Directory out;
  final String base;
  final String email;
  final String password;
  final String chrome;

  /// The colour scheme to emulate: `light`, `dark`, or null for the browser's.
  final String? scheme;

  /// Take the shots without signing in, for the pages a signed-out visitor sees.
  final bool signedOut;

  /// How many times to scroll down and shoot again, for pages longer than the window.
  final int scrolls;

  static const _devEmail = 'admin@velomine.local';
  static const _devPassword = 'Velomine-dev-1';
  static const _chromeDefault = 'chrome-headless-shell'; // on PATH: .devcontainer/Dockerfile links it from /opt

  /// The admin the stack seeds, from the `.env` that `just up` read, so this
  /// works whatever password the operator chose. The documented dev defaults
  /// are the fallback, for a stack started without one.
  static Map<String, String> _dotEnv() {
    final file = File('.env');
    if (!file.existsSync()) return const {};
    final values = <String, String>{};
    for (final line in file.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final cut = trimmed.indexOf('=');
      if (cut > 0) {
        values[trimmed.substring(0, cut)] = trimmed.substring(cut + 1).trim();
      }
    }
    return values;
  }

  /// A height per width, so a phone shot is a phone and a desktop shot is not.
  static int heightFor(int width) => switch (width) {
    < 600 => 844,
    < 840 => 1024,
    < 1200 => 1180,
    _ => 900,
  };

  static _Options parse(List<String> args) {
    String? value(String name) {
      final at = args.indexOf('--$name');
      return at >= 0 && at + 1 < args.length ? args[at + 1] : null;
    }

    final routes = (value('routes') ?? '')
        .split(',')
        .where((r) => r.isNotEmpty);
    if (routes.isEmpty) {
      stderr.writeln(
        'Usage: dart run tools/screenshots.dart --routes /rides,/progress '
        '[--widths 390,600,820,1300] [--out .dev/screens] '
        '[--base http://localhost:8080] [--theme day|night|system] [--signed-out] [--scrolls N]',
      );
      exit(64);
    }
    final theme = value('theme');
    final env = _dotEnv();
    return _Options(
      routes: routes.toList(),
      widths: (value('widths') ?? '390,600,820,1300')
          .split(',')
          .map(int.parse)
          .toList(),
      out: Directory(value('out') ?? '.dev/screens'),
      base: (value('base') ?? 'http://localhost:8080').replaceAll(
        RegExp(r'/+$'),
        '',
      ),
      email:
          value('email') ??
          Platform.environment['VELOMINE_EMAIL'] ??
          env['VELOMINE__ADMIN__EMAIL'] ??
          _devEmail,
      password:
          value('password') ??
          Platform.environment['VELOMINE_PASSWORD'] ??
          env['VELOMINE__ADMIN__PASSWORD'] ??
          _devPassword,
      chrome: Platform.environment['CHROME'] ?? _chromeDefault,
      scheme: switch (theme) {
        'day' || 'light' => 'light',
        'night' || 'dark' => 'dark',
        _ => null,
      },
      signedOut: args.contains('--signed-out'),
      scrolls: int.tryParse(value('scrolls') ?? '') ?? 0,
    );
  }
}
