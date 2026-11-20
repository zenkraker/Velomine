import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'motion.dart';
import 'tokens.dart';

// The Velomine visual language (docs/design/language.md). Every colour below is a token in
// docs/design/tokens.json, Night first; test/design_tokens_test.dart keeps the two equal.

// Night.
const asphalt = Color(0xFF0E0F0C);
const graphite = Color(0xFF22241F);
const volt = Color(0xFFD4F23A);
const tailLight = Color(0xFFFF7A3D);
const mist = Color(0xFFE9EBE4);

// Day.
const cloudDancer = Color(0xFFF0EEE9);
const olive = Color(0xFF4E6300);
const ironOxide = Color(0xFFB24A22);
const forestInk = Color(0xFF18201E);

/// Colours the app draws with itself (cards, charts, maps, wear), one set per theme, so they stay readable on
/// either. Each field is the token of the same name in docs/design/tokens.json.
@immutable
class VelomineColors extends ThemeExtension<VelomineColors> {
  const VelomineColors({
    required this.accent,
    required this.onAccent,
    required this.accentStrong,
    required this.accentSoft,
    required this.onAccentSoft,
    required this.cardRaised,
    required this.glass,
    required this.track,
    required this.barMuted,
    required this.signal,
    required this.signalSoft,
    required this.warning,
    required this.mapGround,
    required this.mapRoad,
    required this.routeGlow,
    required this.route,
    required this.finish,
    required this.halo,
    required this.wearOk,
    required this.wearSoon,
    required this.series,
  });

  /// Volt as a fill: the main action. Text on it is [onAccent].
  final Color accent;
  final Color onAccent;

  /// The accent as text or a mark: links, the current bar, gauge arcs. Olive by day, so it reads on white.
  final Color accentStrong;

  /// The ground of a selected item and the text on it.
  final Color accentSoft;
  final Color onAccentSoft;

  /// A hovered row or an inset block inside a card.
  final Color cardRaised;

  /// Floating elements only: the nav pill, sheets, the info card over a map.
  final Color glass;

  /// The empty part of a gauge or progress bar.
  final Color track;

  /// Past periods beside the current one in a bar chart.
  final Color barMuted;

  /// A state that asks for care (go easy); the ground of a chip that carries it.
  final Color signal;
  final Color signalSoft;
  final Color warning;

  /// The dimmed map and its roads, and the blurred stroke under the route.
  final Color mapGround;
  final Color mapRoad;
  final Color routeGlow;

  /// The route line, its finish and the pale edge around markers, so they stand out on any map tile.
  final Color route;
  final Color finish;
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

  static const night = VelomineColors(
    accent: volt,
    onAccent: asphalt,
    accentStrong: volt,
    accentSoft: Color(0xFF3A3D34),
    onAccentSoft: volt,
    cardRaised: Color(0xFF2C2F28),
    glass: Color(0xD122241F),
    track: Color(0xFF2C2F28),
    barMuted: Color(0xFF6E7F25),
    signal: tailLight,
    signalSoft: Color(0xFF3D2416),
    warning: Color(0xFFFFC94D),
    mapGround: Color(0xFF15170F),
    mapRoad: Color(0xFF2E3128),
    routeGlow: Color(0x73D4F23A),
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
      'wprime': Color(0xFFC792EA),
    },
  );

  static const day = VelomineColors(
    accent: volt,
    onAccent: asphalt,
    accentStrong: olive,
    accentSoft: Color(0xFFEEF6CC),
    onAccentSoft: Color(0xFF2E3A00),
    cardRaised: Color(0xFFF7F5F1),
    glass: Color(0xC7FFFFFF),
    track: Color(0xFFECEAE4),
    barMuted: Color(0xFF8A9A55),
    signal: ironOxide,
    signalSoft: Color(0xFFFBE6DC),
    warning: Color(0xFF7A5C00),
    mapGround: Color(0xFFE4E1D9),
    mapRoad: Colors.white,
    routeGlow: Color(0xD9D4F23A),
    route: olive,
    finish: ironOxide,
    halo: Colors.white,
    wearOk: olive,
    wearSoon: Color(0xFF7A5C00),
    series: {
      'elevation': Color(0xFF6B7A7C),
      'speed': Color(0xFF0F4C4A),
      'power': ironOxide,
      'heartrate': Color(0xFFB3261E),
      'cadence': Color(0xFF7A5C00),
      'wprime': Color(0xFF8E44AD),
    },
  );

  @override
  VelomineColors copyWith() => this;

  @override
  VelomineColors lerp(VelomineColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

/// The two number styles the text theme has no slot for: a stat card's one big number, and a secondary number.
@immutable
class VelomineText extends ThemeExtension<VelomineText> {
  const VelomineText({required this.kpi, required this.stat});

  /// The one big number of a stat card: regular weight, size makes it stand out.
  final TextStyle kpi;

  /// A secondary number: a gauge's centre, a value in a list row.
  final TextStyle stat;

  static VelomineText of(BuildContext context) =>
      Theme.of(context).extension<VelomineText>() ?? _fallback;

  static const _fallback = VelomineText(
    kpi: TextStyle(fontSize: 40, height: 44 / 40, fontWeight: FontWeight.w400),
    stat: TextStyle(fontSize: 24, height: 28 / 24, fontWeight: FontWeight.w500),
  );

  @override
  VelomineText copyWith({TextStyle? kpi, TextStyle? stat}) =>
      VelomineText(kpi: kpi ?? this.kpi, stat: stat ?? this.stat);

  @override
  VelomineText lerp(VelomineText? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

ThemeData dayTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: olive,
        brightness: Brightness.light,
      ).copyWith(
        primary: olive,
        onPrimary: Colors.white,
        primaryContainer: VelomineColors.day.accentSoft,
        onPrimaryContainer: VelomineColors.day.onAccentSoft,
        secondary: const Color(0xFF5C625E),
        surface: cloudDancer,
        onSurface: forestInk,
        onSurfaceVariant: const Color(0xFF5C625E),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: VelomineColors.day.cardRaised,
        surfaceContainer: Colors.white,
        surfaceContainerHigh: VelomineColors.day.cardRaised,
        surfaceContainerHighest: VelomineColors.day.track,
        tertiary: ironOxide,
        error: const Color(0xFFB3261E),
        outline: const Color(0xFF8A8F8A),
        outlineVariant: const Color(0xFFE0DDD5),
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
        primaryContainer: VelomineColors.night.accentSoft,
        onPrimaryContainer: VelomineColors.night.onAccentSoft,
        secondary: mist,
        surface: asphalt,
        onSurface: mist,
        onSurfaceVariant: const Color(0xFFA6AA9E),
        surfaceContainerLowest: asphalt,
        surfaceContainerLow: const Color(0xFF181A15),
        surfaceContainer: graphite,
        surfaceContainerHigh: graphite,
        surfaceContainerHighest: VelomineColors.night.cardRaised,
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
  const figures = [FontFeature.tabularFigures()];
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: sans,
  );
  final baseText = base.textTheme.apply(fontFamily: sans);
  TextStyle? tabular(TextStyle? style) =>
      style?.copyWith(fontFeatures: figures);
  // Numbers line up in columns in every stat, table and clock. Sizes follow the type scale in tokens.json:
  // card-title 17, body 15, caption 13, axis 12.
  final text = baseText.copyWith(
    displayLarge: tabular(baseText.displayLarge),
    displayMedium: tabular(baseText.displayMedium),
    displaySmall: tabular(baseText.displaySmall),
    headlineLarge: tabular(baseText.headlineLarge),
    headlineMedium: tabular(baseText.headlineMedium),
    headlineSmall: tabular(baseText.headlineSmall),
    titleLarge: tabular(baseText.titleLarge),
    titleMedium: tabular(baseText.titleMedium)
        ?.copyWith(fontSize: 17, height: 24 / 17, fontWeight: FontWeight.w600),
    titleSmall: tabular(baseText.titleSmall),
    bodyLarge: tabular(baseText.bodyLarge)
        ?.copyWith(fontSize: 15, height: 22 / 15),
    bodyMedium: tabular(baseText.bodyMedium),
    bodySmall: tabular(baseText.bodySmall)
        ?.copyWith(fontSize: 13, height: 18 / 13),
    labelLarge: tabular(baseText.labelLarge),
    labelMedium: tabular(baseText.labelMedium),
    labelSmall: tabular(baseText.labelSmall)
        ?.copyWith(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500),
  );
  TextStyle displayStyle(TextStyle? style) => (style ?? const TextStyle())
      .copyWith(fontFamily: display, fontWeight: FontWeight.w400);
  final numbers = VelomineText(
    kpi: TextStyle(
      fontFamily: sans,
      fontSize: 40,
      height: 44 / 40,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.8,
      color: scheme.onSurface,
      fontFeatures: figures,
    ),
    stat: TextStyle(
      fontFamily: sans,
      fontSize: 24,
      height: 28 / 24,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.24,
      color: scheme.onSurface,
      fontFeatures: figures,
    ),
  );
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
    // The web has no snapshotting, so the platform's zoom keeps the old page on screen; fade instead.
    pageTransitionsTheme: kIsWeb ? webPageTransitions : null,
    textTheme: text.copyWith(
      displayLarge: displayStyle(text.displayLarge).copyWith(fontSize: 68),
      displayMedium: displayStyle(text.displayMedium).copyWith(fontSize: 56),
      displaySmall: displayStyle(text.displaySmall).copyWith(fontSize: 44),
      headlineLarge: displayStyle(text.headlineLarge).copyWith(fontSize: 40),
      headlineMedium: text.headlineMedium?.copyWith(fontSize: 34),
      headlineSmall: text.headlineSmall?.copyWith(fontSize: 28),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(textStyle: buttonLabel),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    // The one main action of a screen is volt in both themes, with dark text on it.
    filledButtonTheme: FilledButtonThemeData(
      style: pill().copyWith(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? scheme.onSurface.withValues(alpha: 0.12)
              : colors.accent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? scheme.onSurface.withValues(alpha: 0.38)
              : colors.onAccent,
        ),
        minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontFamily: sans, fontWeight: FontWeight.w700),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(style: pill()),
    textButtonTheme: TextButtonThemeData(style: pill()),
    // Cards stand out from the page by their fill alone: no border, no shadow. The gap between
    // them is the page's own spacing.
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
    ),
    // A chip is a hairline outline when it is off, and soft accent ground with no outline when it is on.
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      color: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primaryContainer
            : Colors.transparent,
      ),
      side: WidgetStateBorderSide.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? BorderSide.none
            : BorderSide(color: scheme.outlineVariant),
      ),
      labelStyle: TextStyle(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w500,
        color: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
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
    extensions: [colors, numbers],
  );
}
