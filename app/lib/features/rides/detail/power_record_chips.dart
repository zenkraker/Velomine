import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../../core/l10n.dart';
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
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final record in records)
          Container(
            key: Key('power-record-${record.durationS}-${record.kind}'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              record.kind == 'all_time'
                  ? l10n.powerRecordAllTime(
                      recordDuration(l10n, record.durationS),
                      record.watts,
                    )
                  : l10n.powerRecordNinetyDays(
                      recordDuration(l10n, record.durationS),
                      record.watts,
                    ),
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: colors.onTertiaryContainer),
            ),
          ),
      ],
    );
  }
}
