import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/features/rides/detail/lap_range.dart';
import 'package:velomine/features/rides/detail/ride_series.dart';
import 'package:velomine/features/rides/detail/route_map.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';
import 'package:velomine_api/api.dart';
import 'package:velomine/core/units.dart';
import 'package:velomine/core/l10n.dart';

void main() {
  testWidgets('RouteMap_ShouldScaleItsLabels_WhenTheSystemTextIsLarger', (
    tester,
  ) async {
    final n = 60;
    final data = RideSeries.from(
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
