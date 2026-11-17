import 'dart:math' as math;

import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/widgets/range_selector.dart';
import '../../core/widgets/source_note.dart';
import '../../core/tokens.dart';
import '../../l10n/generated/app_localizations.dart';

/// Best efforts over a range, with an FTP suggestion and (for the member) VO2max. Under a number
/// that Velomine worked out, a [SourceNote] says where it came from.
class PowerSummary extends StatelessWidget {
  const PowerSummary({
    super.key,
    required this.curve,
    required this.days,
    required this.onDays,
    this.onUseFtp,
    this.ftpNote,
    this.ftpRideId,
    this.onOpenRide,
    this.readOnly = false,
  });

  final PowerCurveResponse curve;
  final int days;
  final Future<void> Function(int days) onDays;

  /// Null in a coach's read-only view: only the member can change their FTP.
  final Future<void> Function(int watts)? onUseFtp;

  /// Where the current FTP came from; the member's own history says it.
  final String? ftpNote;

  /// The ride the current FTP came from, when it came from one.
  final String? ftpRideId;

  /// Opens a ride by its id, for a note that can be read back.
  final void Function(String rideId)? onOpenRide;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final vo2Max = curve.vo2Max;
    final criticalPower = curve.criticalPower;
    final labelStyle = (text.labelSmall ?? const TextStyle(fontSize: 11))
        .copyWith(color: scheme.onSurfaceVariant);

    return Card(
      key: const Key('power-curve-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (readOnly)
              Text(l10n.coachPowerCurve, style: text.titleMedium)
            else
              RangeSelector<int>(
                title: l10n.powerCurve,
                segmentKey: const Key('power-range'),
                segments: [
                  ButtonSegment(value: 30, label: Text(l10n.range30Days)),
                  ButtonSegment(value: 90, label: Text(l10n.range90Days)),
                  ButtonSegment(value: 365, label: Text(l10n.rangeOneYear)),
                ],
                selected: days,
                onChanged: onDays,
              ),
            if (!curve.hasPower) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.powerCurveEmpty,
                key: const Key('power-curve-empty'),
                style: text.bodyMedium,
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.md),
              Text(l10n.powerBestEfforts, style: text.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: 4,
                children: [
                  for (final point in curve.points)
                    Text(
                      '${_shortDuration(point.seconds)} ${point.watts} W',
                      style: text.bodySmall,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (criticalPower != null) ...[
                Text(
                  l10n.criticalPowerRow(
                    '${criticalPower.cpW}',
                    _oneDecimal(criticalPower.wPrimeJ / 1000),
                    '${criticalPower.peakW ?? _wattsNear(1)}',
                  ),
                  key: const Key('critical-power-row'),
                  style: text.bodyMedium,
                ),
                SourceNote(
                  l10n.criticalPowerSource(
                    _durationList(l10n, criticalPower.durations),
                  ),
                ),
              ] else
                Text(
                  l10n.criticalPowerUnavailable,
                  key: const Key('critical-power-unavailable'),
                  style: text.bodySmall,
                ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.xl,
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
                    note: ftpNote,
                    onNoteTap: switch ((ftpRideId, onOpenRide)) {
                      (final id?, final open?) => () => open(id),
                      _ => null,
                    },
                  ),
                if (curve.ftp case final ftp?)
                  _Estimate(
                    label: l10n.ftpEstimate,
                    value: '${ftp.watts} W',
                    detail: ftp.method == '8min'
                        ? l10n.ftpMethod8
                        : l10n.ftpMethod20,
                    note: ftp.method == '8min'
                        ? l10n.ftpEstimateSource8(dateOnly(ftp.from))
                        : l10n.ftpEstimateSource20(dateOnly(ftp.from)),
                  ),
                if (!readOnly && vo2Max != null)
                  _Estimate(
                    label: l10n.vo2MaxEstimate,
                    value: vo2Max.value.toStringAsFixed(1),
                    detail: l10n.vo2MaxFrom5Min,
                    note: l10n.vo2MaxSource(dateOnly(vo2Max.from)),
                  ),
              ],
            ),
            if (!readOnly && curve.vo2Max == null && curve.hasPower) ...[
              const SizedBox(height: AppSpacing.sm),
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
              const SizedBox(height: AppSpacing.md),
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

  /// A fraction with one decimal in the app's language: "20.0", "20,0".
  static String _oneDecimal(double value) => NumberFormat('0.0').format(value);

  /// The used window lengths in words, as a list: "2, 5, 10 and 20 minutes".
  static String _durationList(AppLocalizations l10n, List<int> seconds) {
    final names = [for (final s in seconds) _durationName(l10n, s)];
    if (names.length < 2) return names.join();
    return l10n.criticalPowerDurationList(
      names.sublist(0, names.length - 1).join(', '),
      names.last,
    );
  }

  static String _durationName(AppLocalizations l10n, int seconds) =>
      seconds % 60 == 0
      ? l10n.criticalPowerMinutes(seconds ~/ 60)
      : l10n.criticalPowerSeconds(seconds);

  static String _shortDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m';
    return '${seconds ~/ 3600}h';
  }
}

class _Estimate extends StatelessWidget {
  const _Estimate({
    required this.label,
    required this.value,
    this.detail,
    this.note,
    this.onNoteTap,
  });

  final String label;
  final String value;
  final String? detail;

  /// Where the number came from, in one line under it.
  final String? note;
  final VoidCallback? onNoteTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final note = this.note;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.labelSmall),
        Text(
          value,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (detail != null)
          SizedBox(
            width: AppProgress.detailWidth,
            child: Text(detail!, style: text.bodySmall),
          ),
        if (note != null)
          SizedBox(
            width: AppProgress.detailWidth,
            child: SourceNote(note, onTap: onNoteTap),
          ),
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
