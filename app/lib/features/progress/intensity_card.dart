import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/widgets/source_note.dart';
import '../../l10n/generated/app_localizations.dart';

/// How the riding in a range splits into easy, moderate and hard (Seiler's three zones), with the
/// label that split earns, and one small bar per week behind it.
class IntensityCard extends StatelessWidget {
  const IntensityCard({
    super.key,
    required this.intensity,
    this.weeks = const [],
  });

  final IntensityResponse intensity;

  /// The same split week by week; a range shorter than a week has one bar, and none when empty.
  final List<IntensityWeek> weeks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final small = text.bodySmall ?? const TextStyle();
    final scheme = Theme.of(context).colorScheme;
    final colors = (
      easy: scheme.primary,
      moderate: scheme.tertiary,
      hard: scheme.error,
    );
    final label = intensityLabel(l10n, intensity.label);
    final shares = l10n.intensityShares(
      '${intensity.easyPct}',
      '${intensity.moderatePct}',
      '${intensity.hardPct}',
    );

    return Card(
      key: const Key('intensity-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Text(l10n.intensityTitle, style: text.titleMedium),
            Semantics(
              container: true,
              label: label == null ? shares : '$label. $shares',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.xs,
                  children: [
                    if (label != null) Text(label, style: text.bodyMedium),
                    _Bar(
                      easyPct: intensity.easyPct,
                      moderatePct: intensity.moderatePct,
                      hardPct: intensity.hardPct,
                      colors: colors,
                      height: AppSpacing.sm,
                    ),
                    Text(shares, style: text.bodySmall),
                  ],
                ),
              ),
            ),
            if (weeks.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              for (final week in weeks)
                _WeekBar(week: week, colors: colors, style: small),
            ],
            SourceNote(l10n.intensitySource),
          ],
        ),
      ),
    );
  }
}

/// One stacked bar: easy, moderate and hard left to right. A share of 0 takes no room.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.easyPct,
    required this.moderatePct,
    required this.hardPct,
    required this.colors,
    required this.height,
  });

  final double easyPct;
  final double moderatePct;
  final double hardPct;
  final ({Color easy, Color moderate, Color hard}) colors;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        color: scheme.surfaceContainerHighest,
        child: Row(
          children: [
            for (final (share, color) in [
              (easyPct, colors.easy),
              (moderatePct, colors.moderate),
              (hardPct, colors.hard),
            ])
              if (share > 0)
                Expanded(
                  flex: (share * 10).round().clamp(1, 1000),
                  child: ColoredBox(color: color),
                ),
          ],
        ),
      ),
    );
  }
}

/// One week: the same three shares, a little smaller, under the last seven days' date.
class _WeekBar extends StatelessWidget {
  const _WeekBar({
    required this.week,
    required this.colors,
    required this.style,
  });

  final IntensityWeek week;
  final ({Color easy, Color moderate, Color hard}) colors;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final total = week.easyS + week.moderateS + week.hardS;
    double pct(double seconds) => total <= 0 ? 0 : seconds / total * 100;
    return Row(
      spacing: AppSpacing.sm,
      children: [
        SizedBox(
          width: AppProgress.dateWidth,
          child: Text(dateOnly(week.weekStart), style: style),
        ),
        Expanded(
          child: _Bar(
            easyPct: pct(week.easyS),
            moderatePct: pct(week.moderateS),
            hardPct: pct(week.hardS),
            colors: colors,
            height: AppSpacing.xs,
          ),
        ),
      ],
    );
  }
}

/// The label in words, as the story words it. Null for a label this build does not know.
String? intensityLabel(AppLocalizations l10n, String label) => switch (label) {
  'polarised' => l10n.intensityLabelPolarised,
  'pyramidal' => l10n.intensityLabelPyramidal,
  'threshold' => l10n.intensityLabelThreshold,
  'hiit' => l10n.intensityLabelHiit,
  'base' => l10n.intensityLabelBase,
  'mixed' => l10n.intensityLabelMixed,
  _ => null,
};
