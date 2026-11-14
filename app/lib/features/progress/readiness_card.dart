import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../core/l10n.dart';
import '../../core/tokens.dart';

/// Today's readiness: a band, the advice, and the factors that produced it.
class ReadinessCard extends StatelessWidget {
  const ReadinessCard({super.key, required this.readiness});

  final ReadinessResponse readiness;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (readiness.score == null) {
      return Card(
        key: const Key('readiness-card'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.readiness, style: text.titleMedium),
              const SizedBox(height: 6),
              Text(l10n.readinessNoData, style: text.bodyMedium),
            ],
          ),
        ),
      );
    }

    final color = switch (readiness.band) {
      'hard' => const Color(0xFF2E7D32),
      'easy' => const Color(0xFFE07A3F),
      'rest' => scheme.error,
      _ => scheme.primary,
    };
    final title = switch (readiness.band) {
      'hard' => l10n.readinessHard,
      'easy' => l10n.readinessEasy,
      'rest' => l10n.readinessRest,
      _ => l10n.readinessNormal,
    };
    final advice = switch (readiness.band) {
      'hard' => l10n.readinessAdviceHard,
      'easy' => l10n.readinessAdviceEasy,
      'rest' => l10n.readinessAdviceRest,
      _ => l10n.readinessAdviceNormal,
    };

    return Card(
      key: const Key('readiness-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.readiness, style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Text(
                    '${readiness.score}',
                    key: const Key('readiness-score'),
                    style: text.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        key: const Key('readiness-band'),
                        style: text.titleSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(advice, style: text.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            if (!readiness.hasWellbeing) ...[
              const SizedBox(height: 10),
              Text(
                l10n.readinessLoadOnly,
                key: const Key('readiness-load-only'),
                style: text.bodySmall,
              ),
            ],
            if (readiness.factors.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(l10n.readinessWhy, style: text.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              for (final factor in readiness.factors)
                _FactorRow(factor: factor),
            ],
            const SizedBox(height: 10),
            Text(l10n.readinessNotMedical, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.factor});

  final ReadinessFactor factor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final label = switch (factor.key) {
      'form' => l10n.readinessFactorForm,
      'ramp' => l10n.readinessFactorRamp,
      'recentLoad' => l10n.readinessFactorRecentLoad,
      'wellbeing' => l10n.readinessFactorWellbeing,
      'rpe' => l10n.readinessFactorRpe,
      _ => factor.key,
    };
    final value = switch (factor.key) {
      'recentLoad' => '${factor.value.round()} TSS',
      'wellbeing' => '${factor.value.toStringAsFixed(1)}/5',
      'rpe' => '${factor.value.round()}/10',
      _ => factor.value.toStringAsFixed(1),
    };
    final effect = factor.effect;
    final effectText = '${effect > 0 ? '+' : ''}${effect.toStringAsFixed(0)}';
    final color = effect > 0
        ? const Color(0xFF2E7D32)
        : effect < 0
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.bodySmall)),
          Text(value, style: text.bodySmall),
          const SizedBox(width: 12),
          SizedBox(
            width: 34,
            child: Text(
              effectText,
              textAlign: TextAlign.right,
              style: text.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
