import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../tokens.dart';
import 'app_card.dart';

/// One fact on a card: a title, one big number with its unit, one sentence that explains it and,
/// at most, one link to the page that shows the details.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.unit,
    this.sentence,
    this.state,
    this.stateCare = false,
    this.link,
    this.onLink,
    this.valueKey,
  });

  final String title;
  final String value;

  /// The unit beside the number, in the muted caption size.
  final String? unit;

  /// What the number means for the rider. It wraps.
  final String? sentence;

  /// A word such as "Go easy", shown as a chip after the number.
  final String? state;

  /// A state that asks for care is drawn in the signal colour.
  final bool stateCare;

  /// The name of the detail page, with an arrow. It and [onLink] come together.
  final String? link;
  final VoidCallback? onLink;

  /// A key on the number alone, for a test that reads it.
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final numbers = VelomineText.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Text(title, style: text.titleMedium),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: value, style: numbers.kpi),
                    if (unit case final unit?)
                      TextSpan(
                        text: ' $unit',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                key: valueKey,
              ),
              if (state case final state?) _StateChip(state, care: stateCare),
            ],
          ),
          if (sentence case final sentence?)
            Text(
              sentence,
              style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          if (link case final link?) _Link(link, onLink: onLink),
        ],
      ),
    );
  }
}

/// The cards of one summary row: equal height, four across on a desktop window, two on a tablet and
/// one under the other on a phone. It holds [StatCard]s only: a chart card would break the row.
class StatCardRow extends StatelessWidget {
  const StatCardRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final perRow = width >= AppBreakpoint.expandedWidth
        ? 4
        : width >= AppBreakpoint.compactWidth
        ? 2
        : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        for (var i = 0; i < children.length; i += perRow)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.lg,
              children: [
                for (final card in children.skip(i).take(perRow))
                  Expanded(child: card),
              ],
            ),
          ),
      ],
    );
  }
}

/// A secondary number with the name of what it counts, inside a chart card.
class StatFigure extends StatelessWidget {
  const StatFigure({
    super.key,
    required this.label,
    required this.value,
    this.valueKey,
  });

  final String label;
  final String value;

  /// A key on the number alone, for a test that reads it.
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs / 2,
      children: [
        Text(
          label,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        Text(value, key: valueKey, style: VelomineText.of(context).stat),
      ],
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip(this.label, {required this.care});

  final String label;
  final bool care;

  @override
  Widget build(BuildContext context) {
    final colors = VelomineColors.of(context);
    return Container(
      height: AppStatCard.stateHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: care ? colors.signalSoft : colors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: care ? colors.signal : colors.onAccentSoft,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link(this.label, {required this.onLink});

  final String label;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final colors = VelomineColors.of(context);
    return TextButton(
      onPressed: onLink,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(48, 48),
        foregroundColor: colors.accentStrong,
        textStyle: Theme.of(context).textTheme.bodySmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          // A narrow card wraps the label instead of overflowing its link.
          Flexible(child: Text(label)),
          const ExcludeSemantics(child: Icon(Icons.arrow_forward, size: 16)),
        ],
      ),
    );
  }
}
