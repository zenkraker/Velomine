import '../../l10n/generated/app_localizations.dart';

/// Where a ride's effort score came from, in words: power, heart rate, how hard it felt or the watts estimated from
/// speed and slope. Null when the ride has no score, or when the source is one this app does not know.
String? effortSourceText(AppLocalizations l10n, String? source) =>
    switch (source) {
      'power' => l10n.effortFromPower,
      'heart_rate' => l10n.effortFromHeartRate,
      'feel' => l10n.effortFromFeel,
      'estimated' => l10n.effortFromEstimated,
      _ => null,
    };
