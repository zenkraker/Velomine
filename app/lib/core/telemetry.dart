import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What this device is allowed to contribute. The server is the source of truth
/// after sign-in; the local copy lets the SDK start before the first request.
class TelemetryChoice {
  const TelemetryChoice({
    this.crash = false,
    this.usage = false,
    this.dsn,
    this.termsVersion = 0,
  });

  final bool crash;
  final bool usage;
  final String? dsn;
  final int termsVersion;

  bool get enabled => (crash || usage) && (dsn?.isNotEmpty ?? false);
}

abstract interface class TelemetryStore {
  Future<TelemetryChoice> read();

  Future<void> write(TelemetryChoice choice);

  Future<void> clear();
}

class PreferencesTelemetryStore implements TelemetryStore {
  static const _crash = 'telemetryCrash';
  static const _usage = 'telemetryUsage';
  static const _dsn = 'telemetryDsn';
  static const _terms = 'telemetryTermsVersion';

  @override
  Future<TelemetryChoice> read() async {
    try {
      final prefs = SharedPreferencesAsync();
      return TelemetryChoice(
        crash: await prefs.getBool(_crash) ?? false,
        usage: await prefs.getBool(_usage) ?? false,
        dsn: await prefs.getString(_dsn),
        termsVersion: await prefs.getInt(_terms) ?? 0,
      );
    } on Object {
      return const TelemetryChoice();
    }
  }

  @override
  Future<void> write(TelemetryChoice choice) async {
    try {
      final prefs = SharedPreferencesAsync();
      await prefs.setBool(_crash, choice.crash);
      await prefs.setBool(_usage, choice.usage);
      await prefs.setInt(_terms, choice.termsVersion);
      if (choice.dsn == null || choice.dsn!.isEmpty) {
        await prefs.remove(_dsn);
      } else {
        await prefs.setString(_dsn, choice.dsn!);
      }
    } on Object {
      // Not kept; the SDK still runs for this session.
    }
  }

  @override
  Future<void> clear() async {
    try {
      final prefs = SharedPreferencesAsync();
      await prefs.remove(_crash);
      await prefs.remove(_usage);
      await prefs.remove(_dsn);
      await prefs.remove(_terms);
    } on Object {
      // Nothing stored.
    }
  }
}

final telemetryStoreProvider = Provider<TelemetryStore>(
  (ref) => PreferencesTelemetryStore(),
);

/// Lets the app stop the SDK immediately when the member withdraws consent.
abstract interface class TelemetryRuntime {
  Future<void> close();
}

class SentryTelemetryRuntime implements TelemetryRuntime {
  const SentryTelemetryRuntime();

  @override
  Future<void> close() async {
    try {
      await Sentry.close();
    } on Object {
      // Already closed, or never started.
    }
  }
}

final telemetryRuntimeProvider = Provider<TelemetryRuntime>(
  (ref) => const SentryTelemetryRuntime(),
);

/// Starts the app, with Sentry only when this device has opted in and the
/// server supplied a DSN. Self-hosted servers leave the DSN empty, so nothing
/// starts even if a stale local flag remains.
Future<void> runWithTelemetry({
  required TelemetryChoice choice,
  required Widget app,
}) async {
  if (!choice.enabled) {
    runApp(app);
    return;
  }

  var started = false;
  try {
    await SentryFlutter.init(
      (options) {
        options.dsn = choice.dsn;
        options.environment = kDebugMode ? 'development' : 'production';
        options.sendDefaultPii = false;
        options.maxRequestBodySize = MaxRequestBodySize.never;
        options.captureFailedRequests = false;
        options.attachScreenshot = false;
        options.attachViewHierarchy = false;
        options.enableUserInteractionBreadcrumbs = false;
        options.enableUserInteractionTracing = false;
        options.enableAutoNativeBreadcrumbs = false;
        options.reportPackages = false;
        options.enableAutoSessionTracking = true;
        options.enableNativeCrashHandling = true;
        options.anrEnabled = true;
        options.enableAutoPerformanceTracing = choice.usage;
        options.tracesSampleRate = choice.usage ? 0.05 : 0.0;
        options.maxBreadcrumbs = 50;
        options.attachStacktrace = true;
        options.debug = false;
        options.beforeSend = (event, hint) {
          if (!choice.crash) return null;
          event.user = null;
          event.request = null;
          return event;
        };
        options.beforeBreadcrumb = (breadcrumb, hint) {
          // URLs, request bodies and console output can carry member data.
          if (breadcrumb?.category == 'http' ||
              breadcrumb?.category == 'console') {
            return null;
          }
          return breadcrumb;
        };
        options.beforeSendSpan = (span, hint) {
          span.removeAttribute('http.request.body');
          span.removeAttribute('http.response.body');
          span.removeAttribute('http.url');
          span.removeAttribute('url.full');
          span.removeAttribute('url.query');
        };
      },
      appRunner: () {
        started = true;
        runApp(app);
      },
    );
  } on Object {
    if (!started) runApp(app);
  }
}
