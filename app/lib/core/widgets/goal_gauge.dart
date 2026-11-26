import 'package:fl_chart/fl_chart.dart' as fl;
import 'package:material_ui/material_ui.dart';

import '../l10n.dart';
import '../theme.dart';
import '../tokens.dart';

/// A goal's share of its target as a half circle: an accent arc on a track, round at both ends, with the
/// percentage in the middle. Past the target the arc stops at the end; the sentence says by how much.
///
/// The arc is `fl_chart`'s `GaugeChart`, clamped at its own maximum; every colour and the thickness come
/// from the tokens here, because fl_chart's theme is Flutter-Material's fallback and not Velomine's.
class GoalGauge extends StatelessWidget {
  const GoalGauge({
    super.key,
    required this.progress,
    this.height = AppGauge.height,
    this.gaugeKey = const Key('goal-gauge'),
  });

  /// A key on the gauge itself, so a page with several goals can find each one's.
  final Key gaugeKey;

  /// The share of the target reached, 1.0 for a goal met. Anything above 1.0 draws a full arc.
  final double progress;

  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = VelomineColors.of(context);
    final shown = (progress * 100).clamp(0, 999).round();
    final percent = context.l10n.goalPercent(shown);
    return Semantics(
      label: percent,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            // The gauge draws a whole circle in its box, so the box is twice the gauge tall and its
            // lower half is clipped: what stays is the half circle over a round base.
            clipBehavior: Clip.hardEdge,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: height * 2 - AppGauge.thickness,
                child: fl.GaugeChart(
                  key: gaugeKey,
                  fl.GaugeChartData.progress(
                    value: progress.clamp(0.0, 1.0),
                    color: colors.accentStrong,
                    width: AppGauge.thickness,
                    backgroundColor: colors.track,
                    startDegreeOffset: 180,
                    sweepAngle: 180,
                    strokeCap: StrokeCap.round,
                    touchData: fl.GaugeTouchData(enabled: false),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  percent,
                  style: VelomineText.of(context).stat.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
