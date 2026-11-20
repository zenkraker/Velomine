import 'dart:math' as math;

import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/card_grid.dart';
import '../../core/widgets/range_selector.dart';
import '../../core/widgets/source_note.dart';
import '../../l10n/generated/app_localizations.dart';

/// The numbers a rider trains by — FTP, critical power and the VO2max estimate — above the power curve
/// and the best efforts. Under a number that Velomine worked out, a [SourceNote] says where it came from.
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
    final estimate = curve.ftp;
    final criticalPower = curve.criticalPower;
    final vo2Max = curve.vo2Max;
    final differs = estimate != null && estimate.watts != curve.currentFtpW;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        CardGrid(
          columns: 3,
          children: [
            AppCard(
              key: const Key('power-ftp-card'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.sm,
                children: [
                  Text(l10n.ftpCurrent, style: text.titleMedium),
                  _Number(
                    value: curve.currentFtpW?.toString() ?? '–',
                    unit: [
                      if (curve.currentFtpW != null) 'W',
                      if (curve.ftp?.wPerKg case final wPerKg?)
                        '· $wPerKg W/kg',
                    ].join(' '),
                  ),
                  if (ftpNote case final note?)
                    SourceNote(
                      note,
                      onTap: switch ((ftpRideId, onOpenRide)) {
                        (final id?, final open?) => () => open(id),
                        _ => null,
                      },
                    ),
                  // The estimate is a second opinion, so it is offered here and nowhere else: this is
                  // the number the member would change.
                  if (estimate != null) ...[
                    Text(
                      l10n.ftpEstimateToday(
                        estimate.watts,
                        estimate.method == '8min'
                            ? l10n.ftpMethod8
                            : l10n.ftpMethod20,
                      ),
                      key: const Key('ftp-estimate-today'),
                      style: text.bodySmall,
                    ),
                    SourceNote(
                      estimate.method == '8min'
                          ? l10n.ftpEstimateSource8(dateOnly(estimate.from))
                          : l10n.ftpEstimateSource20(dateOnly(estimate.from)),
                    ),
                    if (!readOnly && differs && onUseFtp != null)
                      FilledButton.tonal(
                        key: const Key('use-ftp'),
                        onPressed: () => onUseFtp!(estimate.watts),
                        child: Text(l10n.ftpUse(estimate.watts)),
                      ),
                  ],
                ],
              ),
            ),
            AppCard(
              key: const Key('critical-power-card'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.sm,
                children: [
                  Text(l10n.criticalPowerTitle, style: text.titleMedium),
                  if (criticalPower != null) ...[
                    _Number(
                      key: const Key('critical-power-row'),
                      value: '${criticalPower.cpW}',
                      unit:
                          'W · W′ ${_oneDecimal(criticalPower.wPrimeJ / 1000)} kJ',
                    ),
                    Text(
                      [
                        l10n.criticalPowerExplain,
                        if (criticalPower.peakW case final peak?)
                          l10n.criticalPowerPeak('$peak'),
                      ].join(' '),
                      style: text.bodySmall,
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
              ),
            ),
            if (!readOnly)
              AppCard(
                key: const Key('vo2max-card'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.sm,
                  children: [
                    Text(l10n.vo2MaxEstimate, style: text.titleMedium),
                    if (vo2Max != null) ...[
                      _Number(
                        value: vo2Max.value.toStringAsFixed(1),
                        unit: 'ml/kg/min',
                      ),
                      SourceNote(l10n.vo2MaxSource(dateOnly(vo2Max.from))),
                    ] else
                      Text(
                        curve.weightKg == null
                            ? l10n.vo2MaxNeedsWeight
                            : l10n.vo2MaxNeedsEffort,
                        style: text.bodySmall,
                      ),
                  ],
                ),
              ),
          ],
        ),
        CardGrid(
          columns: 3,
          hero: 2,
          children: [
            AppCard(
              key: const Key('power-curve-card'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.sm,
                children: [
                  RangeSelector<int>(
                    title: readOnly ? l10n.coachPowerCurve : l10n.powerCurve,
                    segmentKey: const Key('power-range'),
                    segments: [
                      ButtonSegment(value: 30, label: Text(l10n.range30Days)),
                      ButtonSegment(value: 90, label: Text(l10n.range90Days)),
                      ButtonSegment(value: 365, label: Text(l10n.rangeOneYear)),
                    ],
                    selected: days,
                    onChanged: onDays,
                  ),
                  if (!curve.hasPower)
                    Text(
                      l10n.powerCurveEmpty,
                      key: const Key('power-curve-empty'),
                      style: text.bodyMedium,
                    )
                  else ...[
                    Text(l10n.powerCurveSentence(days), style: text.bodySmall),
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
                          height: AppChart.height + 60,
                          child: CustomPaint(
                            painter: _PowerCurvePainter(
                              points: curve.points,
                              line: Theme.of(context).colorScheme.primary,
                              area: Theme.of(context).colorScheme.primary,
                              dot: Theme.of(context).colorScheme.primary,
                              grid: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                              labelStyle:
                                  (text.labelSmall ??
                                          const TextStyle(fontSize: 11))
                                      .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                              ftp: curve.currentFtpW,
                              ftpLabel: curve.currentFtpW == null
                                  ? null
                                  : l10n.ftpValue(curve.currentFtpW!),
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AppCard(
              key: const Key('best-efforts-card'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.sm,
                children: [
                  Text(l10n.powerBestEfforts, style: text.titleMedium),
                  if (!curve.hasPower)
                    Text(l10n.powerCurveEmpty, style: text.bodySmall)
                  else
                    _BestEffortsTable(
                      points: curve.points,
                      weightKg: curve.weightKg,
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
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

  /// A duration as the table and the axis write it: "5s", "1m", "1h".
  static String _shortDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m';
    return '${seconds ~/ 3600}h';
  }
}

/// The big number of a power card with its unit beside it, in the stat card's own type.
class _Number extends StatelessWidget {
  const _Number({super.key, required this.value, required this.unit});

  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final numbers = VelomineText.of(context);
    final text = Theme.of(context).textTheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: value, style: numbers.kpi),
          if (unit.isNotEmpty)
            TextSpan(
              text: ' $unit',
              style: text.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// Every duration the server sent, with its watts and its watts per kilogram when the weight is known.
class _BestEffortsTable extends StatelessWidget {
  const _BestEffortsTable({required this.points, this.weightKg});

  final List<PowerCurvePoint> points;
  final double? weightKg;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final numbers = text.bodySmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: IntrinsicColumnWidth(),
      },
      children: [
        TableRow(
          children: [
            Text(l10n.bestEffortsDuration, style: muted),
            Text(l10n.bestEffortsPower, style: muted, textAlign: TextAlign.end),
            if (weightKg != null)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.lg),
                child: Text(
                  l10n.bestEffortsWPerKg,
                  style: muted,
                  textAlign: TextAlign.end,
                ),
              ),
          ],
        ),
        for (final point in points)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  PowerSummary._shortDuration(point.seconds),
                  style: numbers,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  '${point.watts} W',
                  style: numbers,
                  textAlign: TextAlign.end,
                ),
              ),
              if (weightKg case final weight?)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg,
                    top: AppSpacing.xs,
                  ),
                  child: Text(
                    (point.watts / weight).toStringAsFixed(1),
                    style: numbers,
                    textAlign: TextAlign.end,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _PowerCurvePainter extends CustomPainter {
  _PowerCurvePainter({
    required this.points,
    required this.line,
    required this.area,
    required this.dot,
    required this.grid,
    required this.labelStyle,
    this.ftp,
    this.ftpLabel,
  });

  final List<PowerCurvePoint> points;
  final Color line;
  final Color area;
  final Color dot;
  final Color grid;
  final TextStyle labelStyle;

  /// The FTP in use, drawn as a dashed line across the curve.
  final int? ftp;
  final String? ftpLabel;

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

    // Horizontal grid at round steps, so a value can be read off the curve.
    final step = maxWatts / 3;
    for (var i = 0; i <= 3; i++) {
      final y = plot.bottom - plot.height * (i / 3);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), axis);
      _label(
        canvas,
        '${(step * i).round()}',
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

    // The area under the curve, fading to the base. It stops under the last effort: the curve has no
    // value past it, and a wedge reaching the right edge would claim one.
    final last = Offset(
      x(points.last.seconds.toDouble()),
      y(points.last.watts),
    );
    final first = Offset(
      x(points.first.seconds.toDouble()),
      y(points.first.watts),
    );
    final filled = Path.from(path)
      ..lineTo(last.dx, plot.bottom)
      ..lineTo(first.dx, plot.bottom)
      ..close();
    canvas.drawPath(
      filled,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [area.withValues(alpha: 0.3), area.withValues(alpha: 0)],
        ).createShader(plot),
    );
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

    // The FTP in use, dashed, so the curve is read against the number it is trained by.
    if (ftp case final ftp?) {
      final ftpY = y(ftp);
      const dash = 6.0, gap = 4.0;
      final paint = Paint()
        ..color = grid
        ..strokeWidth = 1.4;
      var dx = plot.left;
      while (dx < plot.right) {
        final end = math.min(dx + dash, plot.right);
        canvas.drawLine(Offset(dx, ftpY), Offset(end, ftpY), paint);
        dx = end + gap;
      }
      if (ftpLabel case final label?) {
        _label(canvas, label, Offset(plot.left + 6, ftpY - 14));
      }
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
      old.grid != grid ||
      old.labelStyle != labelStyle ||
      old.ftp != ftp;
}
