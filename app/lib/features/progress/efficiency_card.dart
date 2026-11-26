import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/area_chart.dart';

/// The mean efficiency factor of each week's steady rides, as a line: more power for the same heart rate over months.
class EfficiencyCard extends StatelessWidget {
  const EfficiencyCard({super.key, required this.weeks});

  final List<EfficiencyWeek> weeks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return AppCard(
      key: const Key('efficiency-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Text(l10n.efficiencyTitle, style: text.titleMedium),
          if (weeks.isEmpty)
            Text(
              l10n.efficiencyEmpty,
              key: const Key('efficiency-empty'),
              style: text.bodyMedium,
            )
          else ...[
            AreaChart(
              paintKey: const Key('efficiency-chart'),
              values: [for (final week in weeks) week.efficiencyFactor],
              labels: [for (final week in weeks) dateOnly(week.weekStart)],
              format: (value) => decimal(value, 2),
              semanticLabel: weeks
                  .map(
                    (week) => l10n.efficiencyWeekSemantics(
                      dateOnly(week.weekStart),
                      decimal(week.efficiencyFactor, 2),
                      week.rides,
                    ),
                  )
                  .join('. '),
              emptyMessage: l10n.efficiencyEmpty,
              height: AppProgress.loadChartHeight,
            ),
            Text(l10n.efficiencyHint, style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}
