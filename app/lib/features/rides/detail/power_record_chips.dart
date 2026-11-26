import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../../core/l10n.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/badge.dart';
import '../../../l10n/generated/app_localizations.dart';

/// "5 s", "1 min", "20 min": the same words the server uses for a record's subject.
String recordDuration(AppLocalizations l10n, int seconds) => seconds < 60
    ? l10n.recordDurationSeconds(seconds)
    : l10n.recordDurationMinutes(seconds ~/ 60);

/// The ride's personal power records as compact chips: the best ever and the best in 90 days.
class PowerRecordChips extends StatelessWidget {
  const PowerRecordChips({super.key, required this.records});

  final List<PowerRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final record in records)
          AppBadge(
            record.kind == 'all_time'
                ? l10n.powerRecordAllTime(
                    recordDuration(l10n, record.durationS),
                    record.watts,
                  )
                : l10n.powerRecordNinetyDays(
                    recordDuration(l10n, record.durationS),
                    record.watts,
                  ),
            key: Key('power-record-${record.durationS}-${record.kind}'),
            tone: AppBadgeTone.good,
          ),
      ],
    );
  }
}
