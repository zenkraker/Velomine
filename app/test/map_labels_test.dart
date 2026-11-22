import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/features/rides/detail/lap_range.dart';
import 'package:velomine/features/rides/detail/ride_series.dart';
import 'package:velomine/features/rides/detail/route_map.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';
import 'package:velomine_api/api.dart';
import 'package:velomine/core/units.dart';
import 'package:velomine/core/l10n.dart';
import 'package:velomine/core/tokens.dart';

/// A straight north-going route of 60 samples, enough for a map to draw.
RideSeries _route() {
  final n = 60;
  return RideSeries.from(
    RideStreamsResponse(
      time: [for (var i = 0; i < n; i++) i.toDouble()],
      latitude: [for (var i = 0; i < n; i++) 46 + i * 10 / 111195],
      longitude: List.filled(n, 11.0),
      altitude: const [],
      speed: const [],
      distance: const [],
      heartRate: const [],
      power: const [],
      cadence: const [],
      temperature: const [],
    ),
    Units.metric,
  );
}

void main() {
  /// The ride's map with the glass facts card on it.
  Future<void> pumpMapWithFacts(WidgetTester tester) async {
    final selected = ValueNotifier<int?>(null);
    final selectedLap = ValueNotifier<LapRange?>(null);
    addTearDown(selected.dispose);
    addTearDown(selectedLap.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.noScaling,
          ),
          child: Scaffold(
            body: RouteMap(
              data: _route(),
              selected: selected,
              selectedLap: selectedLap,
              title: 'Sunday ride',
              date: '2 Nov',
              facts: const [(label: '42.2', value: 'km')],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'RouteMap_ShouldInsetTheFactsCardBySpaceLg_WhenTheRideHasATitle',
    (tester) async {
      await pumpMapWithFacts(tester);

      final map = tester.getRect(find.byKey(const Key('route-map')));
      final card = tester.getRect(find.byKey(const Key('map-facts')));

      expect(card.left - map.left, AppSpacing.lg);
      expect(map.right - card.right, AppSpacing.lg);
      expect(map.bottom - card.bottom, AppSpacing.lg);
    },
  );

  testWidgets(
    'RouteMap_ShouldDrawTheFactsCardAtTheExtraLargeRadius_WhenTheRideHasATitle',
    (tester) async {
      await pumpMapWithFacts(tester);

      final card = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byKey(const Key('map-facts')),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final shape = (card.decoration as ShapeDecoration).shape;

      expect(
        (shape as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(AppRadius.xlarge),
      );
    },
  );

  testWidgets('RouteMap_ShouldScaleItsLabels_WhenTheSystemTextIsLarger', (
    tester,
  ) async {
    final data = _route();
    final selected = ValueNotifier<int?>(null);
    final selectedLap = ValueNotifier<LapRange?>(null);
    addTearDown(selected.dispose);
    addTearDown(selectedLap.dispose);

    Future<double> labelHeight(double scale) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: RouteMap(
                data: data,
                selected: selected,
                selectedLap: selectedLap,
                tileUrl: 'https://tile.example/{z}/{x}/{y}.png',
                attribution: 'OpenStreetMap contributors',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return tester.getSize(find.byKey(const Key('map-attribution'))).height;
    }

    final normal = await labelHeight(1);
    final large = await labelHeight(2);

    expect(large, greaterThan(normal));
  });
}
