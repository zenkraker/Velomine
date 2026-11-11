import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/l10n.dart';

/// Best efforts over a range, with an FTP suggestion and (for the member) VO2max.
class PowerSummary extends StatelessWidget {
  const PowerSummary({
    super.key,
    required this.curve,
    required this.days,
    required this.onDays,
    this.onUseFtp,
    this.readOnly = false,
  });

  final PowerCurveResponse curve;
  final int days;
  final Future<void> Function(int days) onDays;

  /// Null in a coach's read-only view: only the member can change their FTP.
  final Future<void> Function(int watts)? onUseFtp;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final vo2Max = curve.vo2Max;
    final labelStyle = (text.labelSmall ?? const TextStyle(fontSize: 11))
        .copyWith(color: scheme.onSurfaceVariant);

    return Card(
      key: const Key('power-curve-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    readOnly ? l10n.coachPowerCurve : l10n.powerCurve,
                    style: text.titleMedium,
                  ),
                ),
                if (!readOnly)
                  SegmentedButton<int>(
                    key: const Key('power-range'),
                    segments: [
                      ButtonSegment(value: 30, label: Text(l10n.range30Days)),
                      ButtonSegment(value: 90, label: Text(l10n.range90Days)),
                      ButtonSegment(value: 365, label: Text(l10n.rangeOneYear)),
                    ],
                    selected: {days},
                    onSelectionChanged: (s) => onDays(s.single),
                  ),
              ],
            ),
            if (!curve.hasPower) ...[
              const SizedBox(height: 10),
              Text(
                l10n.powerCurveEmpty,
                key: const Key('power-curve-empty'),
                style: text.bodyMedium,
              ),
            ] else ...[
              const SizedBox(height: 12),
              Semantics(
                container: true,
                label: l10n.powerCurveSummary(
                  '${_wattsNear(5)}',
                  '${_wattsNear(60)}',
                  '${_wattsNear(300)}',
                  '${_wattsNear(1200)}',
                  curve.ftp?.watts.toString() ?? '–',
                ),
                child: ExcludeSemantics(
                  child: SizedBox(
                    height: 180,
                    child: CustomPaint(
                      painter: _PowerCurvePainter(
                        points: curve.points,
                        line: scheme.primary,
                        dot: scheme.primary,
                        grid: scheme.outlineVariant,
                        labelStyle: labelStyle,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.powerBestEfforts, style: text.labelLarge),
              const SizedBox(height: 4),
              Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  for (final point in curve.points)
                    Text(
                      '${_shortDuration(point.seconds)} ${point.watts} W',
                      style: text.bodySmall,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                if (curve.currentFtpW != null)
                  _Estimate(
                    label: l10n.ftpCurrent,
                    value: '${curve.currentFtpW} W',
                    detail: curve.ftp?.wPerKg == null
                        ? null
                        : '${curve.ftp!.wPerKg} W/kg',
                  ),
                if (curve.ftp case final ftp?)
                  _Estimate(
                    label: l10n.ftpEstimate,
                    value: '${ftp.watts} W',
                    detail: ftp.method == '8min'
                        ? l10n.ftpMethod8
                        : l10n.ftpMethod20,
                  ),
                if (!readOnly && vo2Max != null)
                  _Estimate(
                    label: l10n.vo2MaxEstimate,
                    value: vo2Max.value.toStringAsFixed(1),
                    detail: l10n.vo2MaxFrom5Min,
                  ),
              ],
            ),
            if (!readOnly && curve.vo2Max == null && curve.hasPower) ...[
              const SizedBox(height: 6),
              Text(
                curve.weightKg == null
                    ? l10n.vo2MaxNeedsWeight
                    : l10n.vo2MaxNeedsEffort,
                style: text.bodySmall,
              ),
            ],
            if (!readOnly &&
                curve.ftp != null &&
                curve.ftp!.watts != curve.currentFtpW &&
                onUseFtp != null) ...[
              const SizedBox(height: 10),
              FilledButton.tonal(
                key: const Key('use-ftp'),
                onPressed: () => onUseFtp!(curve.ftp!.watts),
                child: Text(l10n.ftpUse(curve.ftp!.watts)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The best power at the point closest to [seconds]; the chart's points are a fixed set of durations.
  int _wattsNear(int seconds) {
    var best = curve.points.first;
    for (final point in curve.points) {
      if ((point.seconds - seconds).abs() < (best.seconds - seconds).abs()) {
        best = point;
      }
    }
    return best.watts;
  }

  static String _shortDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m';
    return '${seconds ~/ 3600}h';
  }
}

class _Estimate extends StatelessWidget {
  const _Estimate({required this.label, required this.value, this.detail});

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.labelSmall),
        Text(
          value,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (detail != null)
          SizedBox(width: 190, child: Text(detail!, style: text.bodySmall)),
      ],
    );
  }
}

class _PowerCurvePainter extends CustomPainter {
  _PowerCurvePainter({
    required this.points,
    required this.line,
    required this.dot,
    required this.grid,
    required this.labelStyle,
  });

  final List<PowerCurvePoint> points;
  final Color line;
  final Color dot;
  final Color grid;
  final TextStyle labelStyle;

  static const _logMax = 3600.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const left = 44.0;
    const right = 8.0;
    const top = 8.0;
    const bottom = 22.0;
    final plot = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final maxWatts = points.map((p) => p.watts).reduce(math.max).toDouble();
    final axis = Paint()
      ..color = grid
      ..strokeWidth = 1;

    // Horizontal grid at 0, half and the top of the curve.
    for (final fraction in [0.0, 0.5, 1.0]) {
      final y = plot.bottom - plot.height * fraction;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), axis);
      _label(
        canvas,
        '${(maxWatts * fraction).round()} W',
        Offset(plot.left - 6, y),
        alignRight: true,
      );
    }

    double x(double seconds) {
      final clamped = seconds.clamp(1, _logMax).toDouble();
      return plot.left + plot.width * (math.log(clamped) / math.log(_logMax));
    }

    double y(int watts) => maxWatts <= 0
        ? plot.bottom
        : plot.bottom - plot.height * (watts / maxWatts);

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = Offset(x(points[i].seconds.toDouble()), y(points[i].watts));
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
    for (final point in points) {
      canvas.drawCircle(
        Offset(x(point.seconds.toDouble()), y(point.watts)),
        3,
        Paint()..color = dot,
      );
    }

    for (final seconds in [1, 10, 60, 300, 1200, 3600]) {
      _label(
        canvas,
        PowerSummary._shortDuration(seconds),
        Offset(x(seconds.toDouble()), plot.bottom + 3),
        centerX: true,
      );
    }
  }

  void _label(
    Canvas canvas,
    String text,
    Offset at, {
    bool alignRight = false,
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
  bool shouldRepaint(_PowerCurvePainter old) =>
      old.points != points ||
      old.line != line ||
      old.dot != dot ||
      old.grid != grid ||
      old.labelStyle != labelStyle;
}
