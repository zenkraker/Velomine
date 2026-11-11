import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/theme.dart';

/// WCAG relative luminance of [color].
double _luminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double _contrast(Color foreground, Color background) {
  final a = _luminance(foreground);
  final b = _luminance(background);
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

void _expectBodyTextReadable(ThemeData theme, String name) {
  final scheme = theme.colorScheme;
  final pairs = {
    'onSurface on surface': (scheme.onSurface, scheme.surface),
    'onSurfaceVariant on surface': (scheme.onSurfaceVariant, scheme.surface),
    'onPrimary on primary': (scheme.onPrimary, scheme.primary),
    'error on surface': (scheme.error, scheme.surface),
  };
  pairs.forEach((label, colors) {
    expect(
      _contrast(colors.$1, colors.$2),
      greaterThanOrEqualTo(4.5),
      reason: '$label ($name)',
    );
  });
}

void main() {
  test('Theme_ShouldKeepBodyTextReadable_WhenBuiltForDay', () {
    _expectBodyTextReadable(dayTheme(), 'day');
  });

  test('Theme_ShouldKeepBodyTextReadable_WhenBuiltForNight', () {
    _expectBodyTextReadable(nightTheme(), 'night');
  });
}
