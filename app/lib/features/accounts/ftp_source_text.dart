import 'package:velomine_api/api.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../core/format.dart';

/// How the FTP was set, in words: "Set by you on 12 Nov 2026", "From your ride on 12 Nov 2026".
/// [rideDate] is the day of the ride a test FTP came from, which a history row's own [setAt] is not.
String ftpSourceText(
  AppLocalizations l10n,
  String source,
  DateTime? setAt, {
  DateTime? rideDate,
}) {
  final when = dateOnly(source == 'test' ? (rideDate ?? setAt) : setAt);
  return switch (source) {
    'estimate' => l10n.ftpSourceEstimate(when),
    'test' => l10n.ftpSourceTest(when),
    'earlier' => l10n.ftpSourceEarlier(when),
    _ => l10n.ftpSourceManual(when),
  };
}

/// Where the profile's FTP came from, from the newest row of the history. Null when it has none.
/// [testRideStart] is the start of the ride a test FTP came from, which is the day of the effort, not the day
/// the number was accepted; null until it is read, and then the day it was set stands in.
String? profileFtpSourceText(
  AppLocalizations l10n,
  ProfileResponse profile, {
  DateTime? testRideStart,
}) {
  final source = profile.ftpSource.value;
  if (source == null) return null;
  return ftpSourceText(
    l10n,
    source,
    profile.ftpSetAt.value,
    rideDate: testRideStart,
  );
}

/// Reads the ride a test FTP came from, for the day of the effort. Null when there is none or it cannot be read.
Future<DateTime?> ftpRideStart(
  Future<RideResponse?> Function(String id) getRide,
  ProfileResponse profile,
) async {
  if (profile.ftpRideId.value case final id?) {
    final ride = await getRide(id);
    return ride?.startTime;
  }
  return null;
}

/// One entry of the history, as the sheet words it.
String ftpEntrySourceText(AppLocalizations l10n, FtpHistoryEntry entry) =>
    switch (entry.source_) {
      'estimate' => l10n.ftpFromTheEstimate,
      'test' => l10n.ftpFromYourRide,
      'earlier' => l10n.ftpBeforeHistory,
      _ => l10n.ftpYouTypedIt,
    };
