import '../../core/format.dart';
import '../../l10n/generated/app_localizations.dart';

/// How a heart-rate number was set, in words: "Set by you on 12 Nov 2026", "Measured on your ride of 12 Nov 2026",
/// or how it is estimated. Null when there is no number at all.
/// [rideDate] is the day of the ride a measured number came from, which a history row's own [setAt] is not.
String? heartRateSourceText(
  AppLocalizations l10n,
  String? source,
  DateTime? setAt, {
  bool threshold = false,
  DateTime? rideDate,
}) => switch (source) {
  null => null,
  'manual' => l10n.heartRateSourceManual(dateOnly(setAt ?? rideDate)),
  'measured' => l10n.heartRateSourceMeasured(dateOnly(rideDate ?? setAt)),
  _ =>
    threshold
        ? l10n.heartRateSourceThresholdEstimate
        : l10n.heartRateSourceMaxEstimate,
};
