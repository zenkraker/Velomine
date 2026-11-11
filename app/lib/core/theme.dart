import 'package:flutter/material.dart';

import 'tokens.dart';

// Brand direction D, "Contour × Night Ride" (docs/design/brand-directions.html): the Contour palette by day,
// the Night Ride palette at night.

// Contour (day).
const cloudDancer = Color(0xFFF0EEE9);
const gravel = Color(0xFFC9BFAE);
const valleyTeal = Color(0xFF2E7D78);
const deepTeal = Color(0xFF0F4C4A);
const ironOxide = Color(0xFFB24A22);
const forestInk = Color(0xFF18201E);

// Night Ride.
const asphalt = Color(0xFF0E0F0C);
const graphite = Color(0xFF22241F);
const volt = Color(0xFFD4F23A);
const tailLight = Color(0xFFFF7A3D);
const mist = Color(0xFFE9EBE4);

/// Colours the app draws with itself (map, charts, wear), one set per theme, so they stay readable on either.
@immutable
class VelomineColors extends ThemeExtension<VelomineColors> {
  const VelomineColors({
    required this.route,
    required this.finish,
    required this.halo,
    required this.wearOk,
    required this.wearSoon,
    required this.series,
  });

  /// The route line, its start and the selected moment's ring.
  final Color route;
  final Color finish;

  /// The pale edge around the route and markers, so they stand out on any map tile.
  final Color halo;
  final Color wearOk;
  final Color wearSoon;

  /// One colour per chart, so a signal looks the same wherever it appears.
  final Map<String, Color> series;

  /// The app's themes carry these; any other theme (a screen shown on its own) gets the set for its brightness.
  static VelomineColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<VelomineColors>() ??
        (theme.brightness == Brightness.dark ? night : day);
  }

  static const day = VelomineColors(
    route: deepTeal,
    finish: ironOxide,
    halo: Colors.white,
    wearOk: deepTeal,
    wearSoon: Color(0xFF7A5C00),
    series: {
      'elevation': Color(0xFF6B7A7C),
      'speed': deepTeal,
      'power': ironOxide,
      'heartrate': Color(0xFFB3261E),
      'cadence': Color(0xFF7A5C00),
    },
  );

  static const night = VelomineColors(
    route: volt,
    finish: tailLight,
    halo: asphalt,
    wearOk: volt,
    wearSoon: Color(0xFFFFC94D),
    series: {
      'elevation': Color(0xFFA6AA9E),
      'speed': volt,
      'power': tailLight,
      'heartrate': Color(0xFFFF6F4F),
      'cadence': Color(0xFF9CC3E6),
    },
  );

  @override
  VelomineColors copyWith() => this;

  @override
  VelomineColors lerp(VelomineColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

ThemeData dayTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: deepTeal,
        brightness: Brightness.light,
      ).copyWith(
        primary: deepTeal,
        onPrimary: Colors.white,
        secondary: valleyTeal,
        surface: cloudDancer,
        onSurface: forestInk,
        tertiary: ironOxide,
        outlineVariant: gravel,
      );
  return _theme(scheme, VelomineColors.day);
}

ThemeData nightTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: volt,
        brightness: Brightness.dark,
      ).copyWith(
        primary: volt,
        onPrimary: asphalt,
        primaryContainer: const Color(0xFF3A3D34),
        onPrimaryContainer: volt,
        secondary: mist,
        surface: asphalt,
        onSurface: mist,
        onSurfaceVariant: const Color(0xFFA6AA9E),
        surfaceContainerLowest: asphalt,
        surfaceContainerLow: const Color(0xFF181A15),
        surfaceContainer: graphite,
        surfaceContainerHigh: graphite,
        surfaceContainerHighest: const Color(0xFF2C2F28),
        tertiary: tailLight,
        error: const Color(0xFFFF6F4F),
        outline: const Color(0xFF6B6F63),
        outlineVariant: const Color(0xFF3A3D34),
      );
  return _theme(scheme, VelomineColors.night);
}

ThemeData _theme(ColorScheme scheme, VelomineColors colors) {
  const sans = 'Geist';
  const display = 'Instrument Serif';
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: sans,
  );
  final baseText = base.textTheme.apply(fontFamily: sans);
  TextStyle? tabular(TextStyle? style) =>
      style?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  // Numbers line up in columns in every stat, table and clock.
  final text = baseText.copyWith(
    displayLarge: tabular(baseText.displayLarge),
    displayMedium: tabular(baseText.displayMedium),
    displaySmall: tabular(baseText.displaySmall),
    headlineLarge: tabular(baseText.headlineLarge),
    headlineMedium: tabular(baseText.headlineMedium),
    headlineSmall: tabular(baseText.headlineSmall),
    titleLarge: tabular(baseText.titleLarge),
    titleMedium: tabular(baseText.titleMedium),
    titleSmall: tabular(baseText.titleSmall),
    bodyLarge: tabular(baseText.bodyLarge),
    bodyMedium: tabular(baseText.bodyMedium),
    bodySmall: tabular(baseText.bodySmall),
    labelLarge: tabular(baseText.labelLarge),
    labelMedium: tabular(baseText.labelMedium),
    labelSmall: tabular(baseText.labelSmall),
  );
  TextStyle displayStyle(TextStyle? style) => (style ?? const TextStyle())
      .copyWith(fontFamily: display, fontWeight: FontWeight.w400);
  final buttonShape = WidgetStatePropertyAll<OutlinedBorder>(
    const StadiumBorder(),
  );
  final buttonLabel = const WidgetStatePropertyAll(
    TextStyle(fontFamily: sans, fontWeight: FontWeight.w600),
  );
  ButtonStyle pill() => ButtonStyle(
    shape: buttonShape,
    minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
    textStyle: buttonLabel,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: sans,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: text.copyWith(
      displayLarge: displayStyle(text.displayLarge),
      displayMedium: displayStyle(text.displayMedium),
      displaySmall: displayStyle(text.displaySmall),
      headlineLarge: displayStyle(text.headlineLarge),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(style: pill()),
    outlinedButtonTheme: OutlinedButtonThemeData(style: pill()),
    textButtonTheme: TextButtonThemeData(style: pill()),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: buttonLabel,
    ),
    navigationRailTheme: NavigationRailThemeData(
      indicatorColor: scheme.primaryContainer,
      selectedLabelTextStyle: const TextStyle(
        fontFamily: sans,
        fontWeight: FontWeight.w600,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
    ),
    extensions: [colors],
  );
}
