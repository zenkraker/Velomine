import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/l10n.dart';
import 'package:velomine/core/location_service.dart';
import 'package:velomine/core/providers.dart';
import 'package:velomine/features/club/location_picker.dart';

import 'fake_server.dart';

void main() {
  Future<void> openPicker(WidgetTester tester, GeoPoint? position) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationServiceProvider.overrideWithValue(
            FakeLocationService(position),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: const [Locale('en')],
          home: const LocationPickerScreen(
            tileUrl: 'https://tiles.example/{z}/{x}/{y}.png',
            attribution: 'OpenStreetMap',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('LocationPickerScreen_ShouldShowInlineError_WhenLocationFails', (
    tester,
  ) async {
    await openPicker(tester, null);

    expect(find.byKey(const Key('location-error')), findsOneWidget);
    expect(
      find.text('Your device did not share its position.'),
      findsOneWidget,
    );
    // No snackbar: the line under the map is the message.
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'LocationPickerScreen_ShouldSayWhatToDo_WhenTheMapIsNotMovedYet',
    (tester) async {
      await openPicker(tester, null);

      await tester.tap(find.byKey(const Key('location-use')));
      await tester.pumpAndSettle();

      expect(find.text('Drag the map to the place first.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets(
    'LocationPickerScreen_ShouldMoveToTheDevice_WhenTheCurrentLocationIsAsked',
    (tester) async {
      await openPicker(tester, (latitude: 46.07, longitude: 11.12));

      await tester.tap(find.byKey(const Key('location-current')));
      await tester.pumpAndSettle();

      expect(find.text('46.07000, 11.12000'), findsOneWidget);
      expect(find.byKey(const Key('location-error')), findsNothing);
    },
  );

  testWidgets(
    'LocationPickerScreen_ShouldReadTheNewPoint_WhenTheMapIsDragged',
    (tester) async {
      await openPicker(tester, (latitude: 46.0, longitude: 11.0));
      final before = tester.widget<Text>(
        find.byKey(const Key('location-readout')),
      );

      await tester.drag(
        find.byKey(const Key('location-map')),
        const Offset(150, 0),
      );
      await tester.pumpAndSettle();
      final after = tester.widget<Text>(
        find.byKey(const Key('location-readout')),
      );
      expect(after.data, isNot(before.data));
    },
  );
}
