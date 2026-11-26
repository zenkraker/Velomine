import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/core/tokens.dart';

/// docs/design/tokens.json, read from the app folder where `flutter test` runs.
Map<String, dynamic> _tokens() =>
    jsonDecode(File('../docs/design/tokens.json').readAsStringSync())
        as Map<String, dynamic>;

/// `#rrggbb` or `rgba(r, g, b, a)` as a [Color].
Color _parse(String value) {
  final hex = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(value);
  if (hex != null) return Color(0xFF000000 | int.parse(hex[1]!, radix: 16));
  final rgba = RegExp(r'^rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)$')
      .firstMatch(value);
  if (rgba != null) {
    return Color.fromARGB(
      (double.parse(rgba[4]!) * 255).round(),
      int.parse(rgba[1]!),
      int.parse(rgba[2]!),
      int.parse(rgba[3]!),
    );
  }
  throw FormatException('Not a colour token', value);
}

/// Every colour token, as the theme built for [theme] carries it.
Map<String, Color> _themeColours(ThemeData theme) {
  final s = theme.colorScheme;
  final c = theme.extension<VelomineColors>()!;
  return {
    'canvas': s.surface,
    'card': s.surfaceContainer,
    'card-raised': c.cardRaised,
    'glass': c.glass,
    'hairline': s.outlineVariant,
    'track': c.track,
    'ink': s.onSurface,
    'ink-muted': s.onSurfaceVariant,
    'accent': c.accent,
    'on-accent': c.onAccent,
    'accent-strong': s.primary,
    'accent-soft': s.primaryContainer,
    'on-accent-soft': s.onPrimaryContainer,
    'bar-muted': c.barMuted,
    'signal': s.tertiary,
    'signal-soft': c.signalSoft,
    'warning': c.warning,
    'danger': s.error,
    'map-ground': c.mapGround,
    'map-road': c.mapRoad,
    'route-glow': c.routeGlow,
    for (final e in c.series.entries) 'series-${e.key}': e.value,
  };
}

void _expectThemeMatchesTokens(ThemeData theme, String themeId) {
  final colours = _themeColours(theme);
  final tokens = (_tokens()['color'] as Map)['tokens'] as List;
  for (final token in tokens.cast<Map<String, dynamic>>()) {
    final name = token['name'] as String;
    final value = (token['value'] as Map)[themeId] as String;
    expect(
      colours.containsKey(name),
      isTrue,
      reason: '$name has no place in the theme',
    );
    expect(colours[name], _parse(value), reason: '$name ($themeId)');
  }
}

void main() {
  test('DesignTokens_ShouldMatchTheTheme_WhenBuiltForNight', () {
    _expectThemeMatchesTokens(nightTheme(), 'night');
  });

  test('DesignTokens_ShouldMatchTheTheme_WhenBuiltForDay', () {
    _expectThemeMatchesTokens(dayTheme(), 'day');
  });

  test(
    'DesignTokens_ShouldMatchTheLayoutConstants_WhenSpacingAndRadiiAreRead',
    () {
      final tokens = _tokens();
      double px(String family, String name) {
        final list = (tokens[family] as Map)['tokens'] as List;
        final value =
            list.cast<Map<String, dynamic>>().firstWhere(
                  (t) => t['name'] == name,
                )['value']
                as String;
        return double.parse(value.replaceAll('px', ''));
      }

      expect(
        [
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xxxl,
        ],
        [
          for (final n in ['xs', 'sm', 'md', 'lg', 'xl', 'xxl', 'xxxl'])
            px('spacing', 'space-$n'),
        ],
      );
      expect(
        [AppRadius.small, AppRadius.medium, AppRadius.large, AppRadius.xlarge],
        [
          for (final n in ['sm', 'md', 'lg', 'xl']) px('radius', 'radius-$n'),
        ],
      );
    },
  );

  test('VelomineText_ShouldFollowTheTypeScale_WhenTheThemeIsBuilt', () {
    final numbers = nightTheme().extension<VelomineText>()!;
    expect(numbers.kpi.fontSize, 40);
    expect(numbers.kpi.fontWeight, FontWeight.w400);
    expect(numbers.stat.fontSize, 24);
    // nav-label 15/500: the pill and the sidebar never wear Material's labelLarge 14.
    expect(numbers.navLabel.fontSize, 15);
    expect(numbers.navLabel.fontWeight, FontWeight.w500);
    final text = dayTheme().textTheme;
    // card-title 17/24, semibold: the slot a card's title is written in.
    expect(text.titleMedium!.fontSize, 17);
    expect(text.titleMedium!.fontWeight, FontWeight.w600);
    expect(text.titleMedium!.height, closeTo(24 / 17, 0.001));
    expect(text.bodyLarge!.fontSize, 15);
    // The design has one body size, so the default body slot carries it too:
    // a widget that reaches for bodyMedium must never render an off-scale 14.
    expect(text.bodyMedium!.fontSize, 15);
    expect(text.bodySmall!.fontSize, 13);
    expect(text.labelSmall!.fontSize, 12);
  });

  test('Theme_ShouldPadTapTargets_WhenTheWebResolvesThePlatform', () {
    // linux/macOS/windows (what the web build reports) resolve an unset target to shrinkWrap, so a
    // 32 dp chip would have a 32 dp tap area under the design's 48 dp minimum.
    expect(dayTheme().materialTapTargetSize, MaterialTapTargetSize.padded);
    expect(nightTheme().materialTapTargetSize, MaterialTapTargetSize.padded);
  });

  test('TextTheme_ShouldCarryTabularFigures_WhenANumberSitsInAColumn', () {
    for (final theme in [dayTheme(), nightTheme()]) {
      final text = theme.textTheme;
      for (final style in [
        text.bodyMedium,
        text.bodySmall,
        text.labelSmall,
        text.titleMedium,
      ]) {
        expect(
          style!.fontFeatures,
          contains(const FontFeature.tabularFigures()),
          reason: '${style.fontSize}',
        );
      }
    }
    expect(tabularFigures, contains(const FontFeature.tabularFigures()));
  });

  test('VelomineText_ShouldSpaceAJoinCode_WhenAThemeIsBuilt', () {
    final code = nightTheme().extension<VelomineText>()!.code;
    expect(code.fontSize, 22);
    expect(code.fontWeight, FontWeight.w600);
    // 0.08em, as the mock-up's `vm-code` draws it, and nothing like the old letterSpacing 4.
    expect(code.letterSpacing, closeTo(22 * 0.08, 0.001));
    expect(code.fontFeatures, contains(const FontFeature.tabularFigures()));
  });

  test('VelomineText_ShouldSetTheAuthWordmarkInInk_WhenAThemeIsBuilt', () {
    final theme = dayTheme();
    final wordmark = theme.extension<VelomineText>()!.wordmark;
    // 28/32 display in ink, per `docs/design/pages/bundle.css` `.vm-auth .brand`.
    expect(wordmark.fontSize, 28);
    expect(wordmark.height, closeTo(32 / 28, 0.001));
    expect(wordmark.fontFamily, 'Instrument Serif');
    expect(wordmark.color, theme.colorScheme.onSurface);
    expect(AppAuth.width, 440);
  });
}
