import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import 'geo.dart';
import 'lap_range.dart';
import 'ride_series.dart';

/// Low heart rate in the route colour, high heart rate in the chart's heart-rate colour.
Color heartRateColor(
  double bpm,
  double min,
  double max,
  VelomineColors colors,
) {
  final high = colors.series['heartrate'] ?? colors.finish;
  final t = max > min ? ((bpm - min) / (max - min)).clamp(0.0, 1.0) : 1.0;
  return Color.lerp(colors.route, high, t)!;
}

/// Draws the route, its start and finish, the selected lap and the selected moment.
class RoutePainter extends CustomPainter {
  RoutePainter({
    required this.view,
    required this.data,
    required this.selected,
    required this.selectedLap,
    required this.colors,
    required this.heartRate,
    required this.showHeartRate,
  }) : super(repaint: Listenable.merge([selected, selectedLap]));

  final VelomineColors colors;

  final MapView view;
  final RideSeries data;
  final ValueNotifier<int?> selected;
  final ValueNotifier<LapRange?> selectedLap;
  final Series? heartRate;
  final bool showHeartRate;

  @override
  void paint(Canvas canvas, Size size) {
    final points = [for (final point in data.route) view.project(point)];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    // A pale edge under the line keeps it readable over any tile colour.
    canvas.drawPath(
      path,
      Paint()
        ..color = colors.halo.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    if (showHeartRate && heartRate != null) {
      final values = heartRate!.values;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      for (var i = 1; i < points.length; i++) {
        final value = values[data.routeIndex[i]];
        paint.color = value == null
            ? colors.route
            : heartRateColor(value, heartRate!.min, heartRate!.max, colors);
        canvas.drawLine(points[i - 1], points[i], paint);
      }
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..color = colors.route
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    _dot(canvas, points.first, colors.route, 7); // start
    _dot(canvas, points.last, colors.finish, 7); // finish

    // The selected lap, drawn over the route.
    final lap = selectedLap.value;
    if (lap != null) {
      final highlight = Path();
      var open = false;
      for (var i = 0; i < data.route.length; i++) {
        final t = data.time[data.routeIndex[i]];
        if (t < lap.startS || t > lap.endS) {
          open = false;
          continue;
        }
        final p = points[i];
        if (!open) {
          highlight.moveTo(p.dx, p.dy);
          open = true;
        } else {
          highlight.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        highlight,
        Paint()
          ..color = colors.finish
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    final index = selected.value;
    if (index != null) {
      final at = data.routePointAt(index);
      if (at != null) {
        final p = view.project(at);
        canvas.drawCircle(p, 11, Paint()..color = colors.halo);
        canvas.drawCircle(p, 8, Paint()..color = colors.finish);
        canvas.drawCircle(p, 3, Paint()..color = colors.halo);
      }
    }
  }

  void _dot(Canvas canvas, Offset at, Color color, double radius) {
    canvas.drawCircle(at, radius + 2, Paint()..color = colors.halo);
    canvas.drawCircle(at, radius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(RoutePainter old) =>
      old.view != view ||
      old.data != data ||
      old.colors != colors ||
      old.selectedLap != selectedLap ||
      old.heartRate != heartRate ||
      old.showHeartRate != showHeartRate;
}
