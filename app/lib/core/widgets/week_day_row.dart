import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../tokens.dart';
import 'badge.dart';

/// One day of a week: its date, what is planned or how it went, one line of detail and the state beside it, as the
/// week's mock-ups draw every row. The Training page's week and the coach's plan card read a week this way, so the row
/// lives here once. [onTap] opens the day's session; without it the row is plain text.
class WeekDayRow extends StatelessWidget {
  const WeekDayRow({
    super.key,
    required this.date,
    required this.title,
    this.detail,
    this.state,
    this.tone = AppBadgeTone.neutral,
    this.isToday = false,
    this.onTap,
  });

  final DateTime date;

  /// The session's name, or "Rest".
  final String title;

  /// The line under the name: the length, planned beside done, "Skipped · no time".
  final String? detail;

  /// The badge's word: the day's state, or null for a planned day, whose name alone is the plan.
  final String? state;

  final AppBadgeTone tone;

  /// The day the rider is on, drawn on the raised surface.
  final bool isToday;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();

    final row = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isToday ? VelomineColors.of(context).cardRaised : null,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Row(
        spacing: AppSpacing.md,
        children: [
          SizedBox(
            width: AppTraining.dateWidth,
            child: Column(
              children: [
                Text(
                  '${date.day}',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat.E(locale).format(date),
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // The name, its line and the state: the badge sits at the row's end when there is room for it, and drops
          // under the name when the card is too narrow, so a long name or a narrow card never runs over the edge.
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: text.bodyMedium),
                    if (detail case final detail?)
                      Text(
                        detail,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                if (state case final state?) AppBadge(state, tone: tone),
              ],
            ),
          ),
        ],
      ),
    );

    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}
