import '../l10n/generated/app_localizations.dart';

/// Where the heart-rate zones came from, in words: the model in use, the bpm they are fractions of, and, for a
/// maximum nobody set, that it is an estimate. Null when the response carries no model.
String? heartRateZonesSource(
  AppLocalizations l10n,
  String? model,
  int? bpm,
  String? source,
) => switch (model) {
  'threshold' when bpm != null => l10n.heartRateZonesFromThreshold('$bpm'),
  'max' when bpm != null =>
    source == 'estimate'
        ? l10n.heartRateZonesFromMaxEstimated('$bpm')
        : l10n.heartRateZonesFromMax('$bpm'),
  _ => null,
};
