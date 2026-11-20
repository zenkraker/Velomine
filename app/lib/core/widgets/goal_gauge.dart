import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../l10n.dart';
import '../theme.dart';
import '../tokens.dart';

/// A goal's share of its target as a half circle: an accent arc on a track, round at both ends, with the
/// percentage in the middle. Past the target the arc stops at the end; the sentence says by how much.
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
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CustomPaint(
                key: gaugeKey,
                size: Size(double.infinity, height),
                painter: GoalGaugePainter(
                  progress: progress,
                  arc: colors.accentStrong,
                  track: scheme.surfaceContainerHighest,
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

/// The half circle itself. [progress] is clamped to 1, so an over-reached goal never draws past the end.
class GoalGaugePainter extends CustomPainter {
  GoalGaugePainter({
    required this.progress,
    required this.arc,
    required this.track,
  });

  final double progress;
  final Color arc;
  final Color track;

  static const double thickness = AppGauge.thickness;

  /// How much of the half circle is drawn: 0 to 1, never more.
  double get sweepFraction => progress.clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width / 2, size.height) - thickness / 2;
    if (radius <= 0) return;
    final centre = Offset(size.width / 2, size.height - thickness / 2);
    final rect = Rect.fromCircle(center: centre, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    // The half circle: from the left end, over the top, to the right end.
    canvas.drawArc(rect, math.pi, math.pi, false, paint..color = track);
    if (sweepFraction > 0) {
      canvas.drawArc(
        rect,
        math.pi,
        math.pi * sweepFraction,
        false,
        paint..color = arc,
      );
    }
  }

  @override
  bool shouldRepaint(GoalGaugePainter old) =>
      old.progress != progress || old.arc != arc || old.track != track;
}
