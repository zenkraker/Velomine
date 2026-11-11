import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/features/progress/power_summary.dart';
import 'package:velomine/features/rides/detail/full_route_map.dart';
import 'package:velomine/features/rides/detail/lap_range.dart';
import 'package:velomine/features/rides/detail/ride_series.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';
import 'package:velomine_api/api.dart';

Widget powered(Widget child, {Locale locale = const Locale('en')}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  final curve = PowerCurveResponse(
    dayCount: 90,
    from: DateTime(2026, 1, 1),
    to: DateTime(2026, 4, 1),
    rides: 5,
    hasPower: true,
    currentFtpW: 250,
    weightKg: 70,
    points: [
      PowerCurvePoint(seconds: 5, watts: 900),
      PowerCurvePoint(seconds: 60, watts: 500),
      PowerCurvePoint(seconds: 300, watts: 350),
      PowerCurvePoint(seconds: 1200, watts: 280),
    ],
    ftp: FtpEstimate(
      watts: 260,
      method: '20min',
      from: DateTime(2026, 4, 1),
      wPerKg: 3.7,
    ),
    vo2Max: null,
  );

  testWidgets('PowerSummary_ShouldAnnounceBestPowersAndFtp_WhenRendered', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      powered(PowerSummary(curve: curve, days: 90, onDays: (_) async {})),
    );
    await tester.pump();

    expect(
      find.bySemanticsLabel(
        'Power curve. Best 5 seconds 900 watts, 1 minute 500, 5 minutes 350, '
        '20 minutes 280. Estimated FTP 260 watts.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('PowerSummary_ShouldAnnounceInItalian_WhenTheLanguageIsItalian', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      powered(
        PowerSummary(curve: curve, days: 90, onDays: (_) async {}),
        locale: const Locale('it'),
      ),
    );
    await tester.pump();

    expect(
      find.bySemanticsLabel(RegExp('Curva di potenza.*900 watt')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('FullRouteMap_ShouldAnnounceDistanceAndClimbing_WhenRendered', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final n = 3;
    final data = RideSeries.from(
      RideStreamsResponse(
        time: [for (var i = 0; i < n; i++) i * 600.0],
        latitude: const [46, 46.01, 46.02],
        longitude: const [11, 11.01, 11.02],
        altitude: const [300, 400, 350],
        speed: const [],
        distance: const [0, 12000, 24000],
        heartRate: const [],
        power: const [],
        cadence: const [],
        temperature: const [],
      ),
    );
    final selected = ValueNotifier<int?>(null);
    final selectedLap = ValueNotifier<LapRange?>(null);
    addTearDown(selected.dispose);
    addTearDown(selectedLap.dispose);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FullRouteMapScreen(
          data: data,
          selected: selected,
          selectedLap: selectedLap,
          elevationGainM: 420,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.bySemanticsLabel('Route map. 24.0 km, with 420 m of climbing.'),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
