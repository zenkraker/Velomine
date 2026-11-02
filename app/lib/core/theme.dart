import 'package:flutter/material.dart';

// The day palette from the brand direction (Cloud Dancer, deep teal, iron oxide).
// These are close approximations: the exact values are not in the repository yet.
const cloudDancer = Color(0xFFF0EEE9);
const deepTeal = Color(0xFF0E4D55);
const ironOxide = Color(0xFFB4533A);

ThemeData dayTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: deepTeal,
        brightness: Brightness.light,
      ).copyWith(
        primary: deepTeal,
        onPrimary: Colors.white,
        surface: cloudDancer,
        tertiary: ironOxide,
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: cloudDancer,
    appBarTheme: AppBarTheme(
      backgroundColor: cloudDancer,
      foregroundColor: scheme.onSurface,
      elevation: 0,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

/// One colour per chart, so a signal looks the same wherever it appears.
const seriesColors = <String, Color>{
  'elevation': Color(0xFF6B7A7C),
  'speed': deepTeal,
  'power': ironOxide,
  'heartrate': Color(0xFFB3261E),
  'cadence': Color(0xFF7A5C00),
};
