import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../l10n/generated/app_localizations.dart';

String _periodWord(AppLocalizations l10n, String period) => switch (period) {
  'week' => l10n.periodWordWeek,
  'month' => l10n.periodWordMonth,
  _ => l10n.periodWordYear,
};

/// The short name of a period under its bar: "2 Nov" for a week, "Nov" for a month, "2026" for a year.
String periodLabel(String period, DateTime start) => switch (period) {
  'week' => DateFormat.MMMd().format(start),
  'month' => DateFormat.MMM().format(start),
  _ => DateFormat.y().format(start),
};

/// The full name of a period: "2 – 8 Nov 2026", "November 2026", "2026".
String periodTitle(
  String period,
  DateTime start,
  DateTime end,
) => switch (period) {
  'week' =>
    '${DateFormat.MMMd().format(start)} – ${DateFormat.yMMMd().format(end)}',
  'month' => DateFormat.yMMMM().format(start),
  _ => DateFormat.y().format(start),
};

/// Distance per period as bars, oldest on the left; the current period is the last bar.
class TotalsChart extends StatelessWidget {
  const TotalsChart({super.key, required this.period, required this.totals});

  final String period;
  final List<PeriodTotals> totals;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = Theme.of(context).textTheme.labelSmall!;
    final l10n = context.l10n;
    final current = totals.isEmpty ? null : totals.last;
    return Semantics(
      label: l10n.totalsSemantics(
        _periodWord(l10n, period),
        km(current?.distanceM ?? 0),
      ),
      child: SizedBox(
        height: 180,
        child: CustomPaint(
          size: Size.infinite,
          painter: _BarsPainter(
            values: [for (final t in totals) t.distanceM],
            labels: [for (final t in totals) periodLabel(period, t.start)],
            bar: scheme.primary.withValues(alpha: 0.55),
            currentBar: scheme.primary,
            labelStyle: label.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.values,
    required this.labels,
    required this.bar,
    required this.currentBar,
    required this.labelStyle,
  });

  final List<double> values;
  final List<String> labels;
  final Color bar;
  final Color currentBar;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const labelHeight = 18.0;
    const valueHeight = 16.0;
    final top = values.reduce(math.max);
    final slot = size.width / values.length;
    final chartHeight = size.height - labelHeight - valueHeight;
    // Labels thin out when bars are narrow, so they never overlap.
    final every = (48 / slot).ceil().clamp(1, values.length);

    for (var i = 0; i < values.length; i++) {
      final last = i == values.length - 1;
      final h = top <= 0 ? 0.0 : values[i] / top * chartHeight;
      final rect = Rect.fromLTWH(
        i * slot + slot * 0.15,
        valueHeight + chartHeight - h,
        slot * 0.7,
        math.max(h, values[i] > 0 ? 2 : 0),
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        Paint()..color = last ? currentBar : bar,
      );
      if ((values.length - 1 - i) % every == 0) {
        _text(
          canvas,
          labels[i],
          Offset(i * slot + slot / 2, size.height - labelHeight + 2),
        );
      }
      if (last || values[i] == top) {
        _text(
          canvas,
          km(values[i]),
          Offset(i * slot + slot / 2, rect.top - valueHeight),
        );
      }
    }
  }

  void _text(Canvas canvas, String text, Offset topCentre) {
    final p = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    p.paint(canvas, topCentre - Offset(p.width / 2, 0));
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.values != values || old.labels != labels || old.bar != bar;
}
