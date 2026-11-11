import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/theme.dart';

double _contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
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
