import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';

/// The mean efficiency factor of each week's steady rides, as a line: more power for the same heart rate over months.
class EfficiencyCard extends StatelessWidget {
  const EfficiencyCard({super.key, required this.weeks});

  final List<EfficiencyWeek> weeks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = (text.labelSmall ?? const TextStyle(fontSize: 11))
        .copyWith(color: scheme.onSurfaceVariant);
    return Card(
      key: const Key('efficiency-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
              Semantics(
                container: true,
                label: weeks
                    .map(
                      (week) => l10n.efficiencyWeekSemantics(
                        dateOnly(week.weekStart),
                        week.efficiencyFactor.toStringAsFixed(2),
                        week.rides,
                      ),
                    )
                    .join('. '),
                child: ExcludeSemantics(
                  child: SizedBox(
                    height: AppProgress.loadChartHeight,
                    child: CustomPaint(
                      key: const Key('efficiency-chart'),
                      size: Size.infinite,
                      painter: _EfficiencyPainter(
                        weeks: weeks,
                        line: scheme.primary,
                        grid: scheme.outlineVariant,
                        labelStyle: labelStyle,
                      ),
                    ),
                  ),
                ),
              ),
              Text(l10n.efficiencyHint, style: text.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _EfficiencyPainter extends CustomPainter {
  _EfficiencyPainter({
    required this.weeks,
    required this.line,
    required this.grid,
    required this.labelStyle,
  });

  final List<EfficiencyWeek> weeks;
  final Color line;
  final Color grid;
  final TextStyle labelStyle;

  static const _left = 34.0, _right = 8.0, _top = 8.0, _bottom = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (weeks.isEmpty) return;
    final plot = Rect.fromLTRB(
      _left,
      _top,
      size.width - _right,
      size.height - _bottom,
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    // A flat run fills the middle of the box instead of sitting on the bottom edge.
    var min = weeks.map((w) => w.efficiencyFactor).reduce(math.min);
    var max = weeks.map((w) => w.efficiencyFactor).reduce(math.max);
    if (max - min < 0.1) {
      final middle = (max + min) / 2;
      min = middle - 0.05;
      max = middle + 0.05;
    }

    double x(int index) => weeks.length == 1
        ? plot.center.dx
        : plot.left + index / (weeks.length - 1) * plot.width;
    double y(double value) =>
        plot.bottom - (value - min) / (max - min) * plot.height;

    final axis = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final value in [min, max]) {
      final at = y(value);
      canvas.drawLine(Offset(plot.left, at), Offset(plot.right, at), axis);
      _label(canvas, value.toStringAsFixed(2), Offset(plot.left - 6, at), true);
    }

    final path = Path();
    for (var i = 0; i < weeks.length; i++) {
      final point = Offset(x(i), y(weeks[i].efficiencyFactor));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    final dot = Paint()..color = line;
    for (var i = 0; i < weeks.length; i++) {
      canvas.drawCircle(Offset(x(i), y(weeks[i].efficiencyFactor)), 3, dot);
    }
    for (var i = 0; i < weeks.length; i++) {
      _label(
        canvas,
        dateOnly(weeks[i].weekStart),
        Offset(x(i), plot.bottom + 3),
        false,
        centerX: true,
      );
    }
  }

  void _label(
    Canvas canvas,
    String text,
    Offset at,
    bool alignRight, {
    bool centerX = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignRight
        ? at.dx - painter.width
        : centerX
        ? at.dx - painter.width / 2
        : at.dx;
    final dy = alignRight || centerX ? at.dy - painter.height / 2 : at.dy;
    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_EfficiencyPainter old) =>
      old.weeks != weeks ||
      old.line != line ||
      old.grid != grid ||
      old.labelStyle != labelStyle;
}
