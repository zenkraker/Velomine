import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/generated/app_localizations.dart';

/// Today's readiness: the score, the band it falls in, the advice it gives, and the note that it is a
/// guide rather than a medical measure.
class ReadinessCard extends StatelessWidget {
  const ReadinessCard({super.key, required this.readiness});

  final ReadinessResponse readiness;

  /// The band's word, as the card's state chip says it.
  String bandWord(AppLocalizations l10n) => switch (readiness.band) {
    'hard' => l10n.readinessHard,
    'easy' => l10n.readinessEasy,
    'rest' => l10n.readinessRest,
    _ => l10n.readinessNormal,
  };

  /// Whether the band asks the rider to take care.
  bool get bandAsksForCare =>
      readiness.band == 'easy' || readiness.band == 'rest';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = VelomineColors.of(context);

    if (readiness.score == null) {
      return AppCard(
        key: const Key('readiness-card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Text(l10n.readiness, style: text.titleMedium),
            Text(l10n.readinessNoData, style: text.bodyMedium),
          ],
        ),
      );
    }

    final advice = switch (readiness.band) {
      'hard' => l10n.readinessAdviceHard,
      'easy' => l10n.readinessAdviceEasy,
      'rest' => l10n.readinessAdviceRest,
      _ => l10n.readinessAdviceNormal,
    };
    final chip = bandAsksForCare ? colors.signalSoft : colors.accentSoft;
    final chipInk = bandAsksForCare ? colors.signal : colors.onAccentSoft;

    return AppCard(
      key: const Key('readiness-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Text(l10n.readiness, style: text.titleMedium),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                '${readiness.score}',
                key: const Key('readiness-score'),
                style: VelomineText.of(context).kpi,
              ),
              Container(
                height: AppStatCard.stateHeight,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: chip,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  bandWord(l10n),
                  key: const Key('readiness-band'),
                  style: text.bodySmall?.copyWith(
                    color: chipInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Text(
            advice,
            style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (!readiness.hasWellbeing)
            Text(
              l10n.readinessLoadOnly,
              key: const Key('readiness-load-only'),
              style: text.bodySmall,
            ),
          Text(l10n.readinessNotMedical, style: text.bodySmall),
        ],
      ),
    );
  }
}

/// Why the readiness is what it is: one row per factor with its value and its effect, drawn from a centre
/// line, right in the accent when it raises the score and left in the signal when it lowers it.
class ReadinessWhyCard extends StatelessWidget {
  const ReadinessWhyCard({super.key, required this.readiness});

  final ReadinessResponse readiness;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final score = readiness.score;
    if (score == null || readiness.factors.isEmpty) {
      return const SizedBox.shrink();
    }
    return AppCard(
      key: const Key('readiness-why'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xs,
        children: [
          Text(
            l10n.readinessWhyScore(score),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          // Every bar is drawn against the largest effect on the card, so the rows compare.
          ...() {
            final largest = readiness.factors.fold<double>(
              0,
              (most, f) => f.effect.abs() > most ? f.effect.abs() : most,
            );
            return [
              for (final factor in readiness.factors)
                _FactorRow(factor: factor, largest: largest),
            ];
          }(),
        ],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.factor, required this.largest});

  final ReadinessFactor factor;

  /// The largest effect on the card, which sets the longest bar.
  final double largest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
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
    final colors = VelomineColors.of(context);
    final color = effect > 0
        ? colors.accentStrong
        : effect < 0
        ? colors.signal
        : muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.bodySmall)),
          Flexible(
            child: Text(value, style: text.bodySmall?.copyWith(color: muted)),
          ),
          const SizedBox(width: AppSpacing.md),
          // The bar takes the room left over, so a narrow card or a large text size never overflows.
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppProgress.effectBarWidth,
              ),
              child: SizedBox(
                height: AppProgress.effectBarHeight,
                width: double.infinity,
                child: CustomPaint(
                  painter: _EffectPainter(
                    fraction: largest <= 0
                        ? 0
                        : (effect.abs() / largest).clamp(0, 1),
                    up: effect >= 0,
                    color: color,
                    middle: muted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: AppProgress.effectWidth,
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

/// A bar drawn from a centre line: right when the factor raises the score, left when it lowers it.
class _EffectPainter extends CustomPainter {
  const _EffectPainter({
    required this.fraction,
    required this.up,
    required this.color,
    required this.middle,
  });

  final double fraction;
  final bool up;
  final Color color;
  final Color middle;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.width / 2;
    final line = Paint()
      ..color = middle.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(centre, 0), Offset(centre, size.height), line);
    final width = centre * fraction;
    if (width <= 0) return;
    final bar = Rect.fromLTWH(
      up ? centre : centre - width,
      0,
      width,
      size.height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar, const Radius.circular(AppSpacing.xs)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _EffectPainter old) =>
      old.fraction != fraction ||
      old.up != up ||
      old.color != color ||
      old.middle != middle;
}
