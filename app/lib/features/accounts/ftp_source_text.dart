import 'package:velomine_api/api.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../core/format.dart';

/// How the FTP was set, in words: "Set by you on 12 Nov 2026", "Set before 12 Nov 2026".
/// The profile shows it under the FTP field; Story 2 moves it into the shared `SourceNote`.
String ftpSourceText(AppLocalizations l10n, String source, DateTime? setAt) {
  final when = dateOnly(setAt);
  return switch (source) {
    'estimate' => l10n.ftpSourceEstimate(when),
    'test' => l10n.ftpSourceTest(when),
    'earlier' => l10n.ftpSourceEarlier(when),
    _ => l10n.ftpSourceManual(when),
  };
}

/// Where one entry of the history came from, as the sheet words it.
String ftpEntrySourceText(AppLocalizations l10n, FtpHistoryEntry entry) =>
    switch (entry.source_) {
      'estimate' => l10n.ftpFromTheEstimate,
      'test' => l10n.ftpFromYourRide,
      'earlier' => l10n.ftpBeforeHistory,
      _ => l10n.ftpYouTypedIt,
    };
