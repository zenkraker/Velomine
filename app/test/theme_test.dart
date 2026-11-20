import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/core/theme_choice.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
  });

  ThemeData current(WidgetTester tester) =>
      Theme.of(tester.element(find.byKey(const Key('account-menu'))));

  // The theme is chosen from the account menu: a phone has no room for its own icon.
  Future<void> choose(WidgetTester tester, String key) async {
    await openAccountMenu(tester);
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('ThemeController_ShouldFollowDeviceTheme_WhenNoneIsChosen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await startApp(tester, server.session(useCookies: true));

    expect(current(tester).colorScheme.surface, asphalt);
  });

  testWidgets('ThemeController_ShouldSwitchAndKeepTheme_WhenNightOrDayChosen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = MemoryThemeStore();
    await startApp(
      tester,
      server.session(useCookies: true),
      themeChoiceStore: store,
    );
    expect(current(tester).colorScheme.surface, cloudDancer);

    await choose(tester, 'theme-dark');
    expect(current(tester).colorScheme.primary, volt);
    expect(current(tester).extension<VelomineColors>()!.route, volt);
    expect(store.value, 'dark');

    await choose(tester, 'theme-light');
    expect(current(tester).colorScheme.primary, olive);
    expect(store.value, 'light');
  });

  test(
    'ThemeChoiceViewModel_ShouldReadSavedChoiceAndFallBackToDevice_WhenLoaded',
    () async {
      final night = ProviderContainer(
        overrides: [
          themeChoiceStoreProvider.overrideWithValue(MemoryThemeStore('dark')),
        ],
      );
      addTearDown(night.dispose);
      expect(
        await night.read(themeChoiceViewModelProvider.future),
        ThemeMode.dark,
      );

      final odd = ProviderContainer(
        overrides: [
          themeChoiceStoreProvider.overrideWithValue(
            MemoryThemeStore('purple'),
          ),
        ],
      );
      addTearDown(odd.dispose);
      expect(
        await odd.read(themeChoiceViewModelProvider.future),
        ThemeMode.system,
      );
    },
  );

  testWidgets('Theme_ShouldUseNightThemeWithCharts_WhenOpeningARide', (
    tester,
  ) async {
    server.rides.add(rideJson('ride-1', 'ready', distanceM: 24500));
    server.streams['ride-1'] = {
      'time': [0.0, 1.0, 2.0],
      'latitude': [46.0, 46.001, 46.002],
      'longitude': [11.0, 11.0, 11.0],
      'altitude': [300.0, 301.0, 302.0],
      'speed': null,
      'distance': null,
      'heartRate': [140, 141, 142],
      'power': null,
      'cadence': null,
      'temperature': null,
    };
    await startApp(
      tester,
      server.session(useCookies: true),
      themeChoiceStore: MemoryThemeStore('dark'),
    );

    await tester.tap(find.byKey(const Key('ride-ride-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('route-map')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ChoiceChip_ShouldUseSoftAccentGround_WhenSelected', (
    tester,
  ) async {
    final theme = nightTheme();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Row(
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: false,
                onSelected: (_) {},
              ),
              ChoiceChip(
                label: const Text('Road'),
                selected: true,
                onSelected: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    TextStyle labelStyle(String label) =>
        DefaultTextStyle.of(tester.element(find.text(label))).style;

    expect(labelStyle('All').color, theme.colorScheme.onSurfaceVariant);
    expect(labelStyle('Road').color, theme.colorScheme.onPrimaryContainer);
    Color? ground(String label) =>
        (tester
                    .widget<Ink>(
                      find
                          .descendant(
                            of: find.ancestor(
                              of: find.text(label),
                              matching: find.byType(ChoiceChip),
                            ),
                            matching: find.byType(Ink),
                          )
                          .first,
                    )
                    .decoration
                as ShapeDecoration?)
            ?.color;
    expect(ground('All') ?? Colors.transparent, Colors.transparent);
    expect(ground('Road'), theme.colorScheme.primaryContainer);
  });
}
