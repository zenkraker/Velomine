import '../../core/format.dart';
import '../../l10n/generated/app_localizations.dart';

/// Whether the rider or a ride set the number: `manual` or `measured`. An `estimate` (and a missing number) is not set,
/// so its field stays empty and nothing is written when it is left alone.
bool heartRateIsSet(String? source) =>
    source == 'manual' || source == 'measured';

/// How a heart-rate number was set, in words: "Set by you on 12 Nov 2026", "Measured on your ride of 12 Nov 2026",
/// or how it is estimated. Null when there is no number at all.
/// [rideDate] is the day of the ride a measured number came from, which a history row's own [setAt] is not; a
/// measured number whose [rideId] is gone says the ride was deleted, because nothing is left to open.
String? heartRateSourceText(
  AppLocalizations l10n,
  String? source,
  DateTime? setAt, {
  bool threshold = false,
  DateTime? rideDate,
  String? rideId,
}) => switch (source) {
  null => null,
  'manual' => l10n.heartRateSourceManual(dateOnly(setAt ?? rideDate)),
  'measured' =>
    rideId == null
        ? l10n.heartRateSourceMeasuredDeleted
        : l10n.heartRateSourceMeasured(dateOnly(rideDate ?? setAt)),
  _ =>
    threshold
        ? l10n.heartRateSourceThresholdEstimate
        : l10n.heartRateSourceMaxEstimate,
};
