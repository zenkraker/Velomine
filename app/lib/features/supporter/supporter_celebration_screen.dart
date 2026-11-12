import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import 'supporter_badge.dart';

// The celebration is a 390 × 844 artboard, scaled to the device width; every
// number below is on that artboard. It is decorative: the climb's shape and its
// peak do not come from a ride.
// shortcut: the summit's ride is decoration, query the member's hardest climb when the server offers it.

const _ink = Color(0xFF0E0F0C);
const _paper = Color(0xFFF0EEE9);

const _effort = EffortCurve();
const _soft = Cubic(0.16, 1, 0.3, 1);
const _out = Cubic(0.2, 0.8, 0.2, 1);
const _spring = SpringCurve();

/// The timeline runs 5.1 s, one [AnimationController] driving the painter and the texts.
const _totalMs = 5100;

/// A window in the timeline: before it nothing, inside it the curve, after it done.
class Span {
  const Span(this.fromMs, this.toMs, this.curve);

  final int fromMs;
  final int toMs;
  final Curve curve;

  /// How far through, un-eased.
  double raw(double timeMs) =>
      ((timeMs - fromMs) / (toMs - fromMs)).clamp(0.0, 1.0);

  /// The eased progress, 0 before the window and 1 after it.
  double at(double timeMs) =>
      timeMs <= fromMs ? 0 : curve.transform(raw(timeMs));
}

/// A piecewise-linear curve over 20 stops: the rider's ramp, then the kick.
class EffortCurve extends Curve {
  const EffortCurve();

  static const stops = <double>[
    0,
    .02,
    .05,
    .09,
    .14,
    .20,
    .27,
    .35,
    .44,
    .54,
    .64,
    .73,
    .81,
    .87,
    .92,
    .955,
    .98,
    1,
    1,
    1,
  ];

  @override
  double transformInternal(double t) {
    final scaled = t.clamp(0, 1) * (stops.length - 1);
    final i = scaled.floor().clamp(0, stops.length - 2);
    return stops[i] + (stops[i + 1] - stops[i]) * (scaled - i);
  }
}

/// Soft, with a little overshoot: it peaks at about 1.08 a third of the way,
/// then settles on 1. The badge's pop and the summit dot.
class SpringCurve extends Curve {
  const SpringCurve();

  @override
  double transformInternal(double t) {
    final x = t.clamp(0, 1);
    if (x < .32) return 1.08 * (1 - math.pow(1 - x / .32, 3)).toDouble();
    final back = (x - .32) / .68;
    return 1.08 - .08 * (1 - math.pow(1 - back, 2)).toDouble();
  }
}

/// The licence activated: the full-screen moment, played once when the licence
/// arrives and again on a replay. Reduced motion jumps to its last frame.
class SupporterCelebrationScreen extends StatefulWidget {
  const SupporterCelebrationScreen({
    super.key,
    required this.licence,
    this.onContinue,
  });

  /// The rider's licence the moment celebrates.
  final RiderLicenceResponse licence;

  /// Leaves the celebration for the profile.
  final VoidCallback? onContinue;

  @override
  State<SupporterCelebrationScreen> createState() =>
      _SupporterCelebrationScreenState();
}

class _SupporterCelebrationScreenState extends State<SupporterCelebrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _totalMs),
  );

  @override
  void initState() {
    super.initState();
    // The frame is needed to know whether the system asks to reduce motion.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) replay();
    });
  }

  /// Plays the moment from the start, or shows its last frame when motion is reduced.
  void replay() {
    if (reduceMotion(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final licence = widget.licence;
    return Scaffold(
      backgroundColor: _ink,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final time = _controller.value * _totalMs;
          return LayoutBuilder(
            builder: (context, constraints) {
              final scale = constraints.maxWidth / 390;
              // A tall phone centres the artboard in what is left.
              final top = (constraints.maxHeight / scale - 844) / 2;
              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CelebrationPainter(time, scale, top),
                    ),
                  ),
                  _Overlay(
                    time: time,
                    scale: scale,
                    top: top,
                    l10n: l10n,
                    licence: licence,
                    onContinue: widget.onContinue,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// The texts and the button, over the painter's geometry.
class _Overlay extends StatelessWidget {
  const _Overlay({
    required this.time,
    required this.scale,
    required this.top,
    required this.l10n,
    required this.licence,
    required this.onContinue,
  });

  final double time;
  final double scale;
  final double top;
  final AppLocalizations l10n;
  final RiderLicenceResponse licence;
  final VoidCallback? onContinue;

  static const _chipIn = Span(250, 800, _soft);
  static const _chipOut = Span(2400, 2650, _out);
  static const _eyebrow = Span(2500, 3000, _soft);
  static const _headline = Span(2700, 3300, _soft);
  static const _body = Span(3100, 3700, _soft);
  // The serial follows the body once it has landed.
  static const _serial = Span(3300, 3900, _soft);
  static const _badge = Span(3700, 4150, _spring);
  static const _button = Span(4300, 4800, _soft);

  Widget _placed(double x, double y, double width, Widget child) => Positioned(
    left: x * scale,
    top: (top + y) * scale,
    width: width * scale,
    child: child,
  );

  /// A block of the moment: it rises a little as it fades in.
  Widget _enter(Span span, Widget child) {
    final eased = span.at(time);
    return Opacity(
      opacity: eased.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, (1 - eased) * 10 * scale),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final chipIn = _chipIn.at(time);
    final chipOut = _chipOut.at(time);
    final badgeIn = _badge.at(time);
    final buttonIn = _button.at(time);
    // The serif headline: the app's display font, or the system's serif when a screen stands alone.
    final serif = theme.textTheme.headlineMedium?.fontFamily ?? 'serif';

    return Stack(
      children: [
        _placed(
          0,
          84,
          390,
          Center(
            child: Opacity(
              opacity: (chipIn * (1 - chipOut)).clamp(0, 1),
              child: Transform.scale(
                scale: 0.9 + 0.1 * chipIn,
                child: Container(
                  key: const Key('supporter-chip'),
                  height: 40 * scale,
                  padding: EdgeInsets.symmetric(horizontal: 18 * scale),
                  decoration: BoxDecoration(
                    border: Border.all(color: _paper.withValues(alpha: 0.18)),
                    borderRadius: BorderRadius.circular(20 * scale),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8 * scale,
                    children: [
                      CustomPaint(
                        size: Size.square(13 * scale),
                        painter: const _CheckPainter(),
                      ),
                      Text(
                        l10n.supporterKeyVerified.toUpperCase(),
                        style: text.labelSmall?.copyWith(
                          color: _paper.withValues(alpha: 0.8),
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _placed(
          0,
          380,
          390,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 14 * scale,
              children: [
                _enter(
                  _eyebrow,
                  Text(
                    l10n.supporterActivated.toUpperCase(),
                    key: const Key('supporter-eyebrow'),
                    textAlign: TextAlign.center,
                    style: text.labelMedium?.copyWith(
                      color: volt,
                      letterSpacing: 3.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _enter(
                  _headline,
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: l10n.supporterThanksName('')),
                        TextSpan(
                          text: licence.holder,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                    key: const Key('supporter-headline'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: serif,
                      fontSize: 34 * scale,
                      height: 1.1,
                      color: _paper,
                    ),
                  ),
                ),
                _enter(
                  _body,
                  Text(
                    l10n.supporterBody,
                    key: const Key('supporter-body'),
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: _paper.withValues(alpha: 0.66),
                      height: 1.5,
                    ),
                  ),
                ),
                _enter(
                  _serial,
                  Text(
                    l10n.supporterSerialNumber(
                      licence.serial,
                      dateOnly(licence.activatedAt),
                    ),
                    key: const Key('supporter-serial'),
                    textAlign: TextAlign.center,
                    style: text.labelSmall?.copyWith(
                      color: _paper.withValues(alpha: 0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: (top + 650) * scale,
          child: Opacity(
            opacity: badgeIn.clamp(0, 1),
            child: Transform.scale(
              scale: (0.85 + 0.15 * badgeIn).clamp(0.5, 1.2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 8 * scale,
                children: [
                  SupporterBadge(
                    key: const Key('supporter-celebration-badge'),
                    label: l10n.supporter,
                    style: text.labelLarge?.copyWith(color: _paper),
                    background: volt.withValues(alpha: 0.12),
                  ),
                  Text(
                    l10n.supporterAppearsOnProfile,
                    style: text.labelSmall?.copyWith(
                      color: _paper.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 24 * scale,
          right: 24 * scale,
          bottom: 28 * scale,
          child: Opacity(
            opacity: buttonIn.clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, (1 - buttonIn) * 24 * scale),
              child: SizedBox(
                height: 56 * scale,
                child: FilledButton(
                  key: const Key('supporter-continue'),
                  style: FilledButton.styleFrom(
                    backgroundColor: volt,
                    foregroundColor: _ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28 * scale),
                    ),
                  ),
                  onPressed: buttonIn > 0 ? onContinue : null,
                  child: Text(
                    l10n.supporterContinue,
                    style: text.labelLarge?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Everything the moment draws: the contour ellipses, the climb, the summit
/// burst and the mark. It repaints from the timeline, not from a rebuild.
class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter(this.time, this.scale, this.top);

  final double time;
  final double scale;
  final double top;

  static const _contours = Span(0, 1800, _soft);
  static const _turn = Span(1800, _totalMs, _soft);
  static const _profile = Span(400, 2400, _effort);
  static const _descent = Span(1500, 2800, _out);
  static const _burst = Span(2000, 3100, _out);
  static const _rings = Span(2050, 3350, _out);
  static const _mark = Span(2350, 2900, _out);

  /// The climb and its descent, in the mockup's 342 × 240 box.
  static final _climb = Path()
    ..moveTo(0, 214)
    ..cubicTo(20, 212, 34, 206, 48, 200)
    ..cubicTo(62, 194, 78, 190, 92, 176)
    ..cubicTo(106, 162, 112, 160, 122, 146)
    ..cubicTo(132, 132, 140, 122, 150, 112)
    ..cubicTo(160, 102, 164, 94, 171, 90);

  static final _descentLine = Path()
    ..moveTo(171, 90)
    ..cubicTo(182, 96, 196, 118, 214, 132)
    ..cubicTo(232, 146, 252, 170, 280, 190)
    ..cubicTo(304, 206, 322, 210, 342, 214);

  /// A point of the climb's box on the screen.
  Offset _at(double x, double y) =>
      Offset((24 + x) * scale, (top + 200 + y) * scale);

  @override
  void paint(Canvas canvas, Size size) {
    _drawContours(canvas);
    _drawClimb(canvas);
    _drawSummit(canvas);
  }

  /// Eight ellipses, drawn one after another, on a group that turns a full circle.
  void _drawContours(Canvas canvas) {
    final drawn = _contours.raw(time);
    if (drawn <= 0) return;
    final center = Offset(195 * scale, (top + 290) * scale);
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(_turn.at(time) * 2 * math.pi);
    for (var i = 0; i < 8; i++) {
      final eased = _soft.transform((drawn - i / 8).clamp(0.0, .6) / .6);
      if (eased <= 0) continue;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: 2 * (48 + (446 - 48) * i / 7) * scale * eased,
          height: 2 * (34 + (324 - 34) * i / 7) * scale * eased,
        ),
        Paint()
          ..color = volt.withValues(alpha: 0.08 * eased)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    canvas.restore();
  }

  /// The climb's line rises with the rider dot, then the descent draws in dashed.
  void _drawClimb(Canvas canvas) {
    final effort = _profile.at(time);
    canvas
      ..save()
      ..translate(24 * scale, (top + 200) * scale)
      ..scale(scale);
    final climb = _climb.computeMetrics().first;
    canvas.drawPath(
      climb.extractPath(0, climb.length * effort.clamp(0, 1)),
      Paint()
        ..color = _paper.withValues(alpha: 0.75 * _profile.raw(time))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    final dot = climb.getTangentForOffset(climb.length * effort.clamp(0, 1));
    if (dot != null && effort > 0) {
      // The dot pops in at the summit with the same overshoot as the badge.
      final pop = _spring.transform(((effort - .85) / .15).clamp(0.0, 1.0));
      canvas
        ..drawCircle(
          dot.position,
          26 * pop,
          Paint()..color = volt.withValues(alpha: 0.16),
        )
        ..drawCircle(dot.position, 7 * pop, Paint()..color = volt);
    }

    final descent = _descent.at(time);
    if (descent > 0) {
      final line = _descentLine.computeMetrics().first;
      final length = line.length * descent;
      final paint = Paint()
        ..color = _paper.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      // Dash 2, gap 6.
      for (var at = 0.0; at < length; at += 8) {
        canvas.drawPath(line.extractPath(at, math.min(at + 2, length)), paint);
      }
    }
    canvas.restore();
  }

  /// The summit: the burst of teeth, the rings and the mark drawing in.
  void _drawSummit(Canvas canvas) {
    final burst = _burst.at(time);
    final drawn = _rings.raw(time);
    final mark = _mark.at(time);
    if (drawn <= 0 && mark <= 0) return;
    final summit = _at(171, 90);
    canvas
      ..save()
      ..translate(summit.dx, summit.dy);

    if (burst > 0 && burst < 1) {
      for (var i = 0; i < 16; i++) {
        final radius = (6 + 78 * burst) * scale;
        canvas
          ..save()
          ..rotate(i * 22.5 * math.pi / 180)
          ..drawLine(
            Offset(0, -radius),
            Offset(0, -radius - 14 * scale * (1.5 - .85 * burst)),
            Paint()
              ..color = (i.isEven ? volt : _paper).withValues(alpha: 1 - burst)
              ..strokeWidth = 3 * scale
              ..strokeCap = StrokeCap.round,
          )
          ..restore();
      }
    }

    for (var i = 0; i < 3; i++) {
      final ring = ((drawn - i * .12) / .76).clamp(0.0, 1.0);
      if (ring <= 0) continue;
      final width = (80 + 256 * ring) * scale;
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: width, height: width * .7),
        Paint()
          ..color = volt.withValues(alpha: 1 - ring)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    if (mark > 0) {
      final box = Rect.fromCenter(
        center: Offset.zero,
        width: 120 * scale,
        height: 120 * scale,
      );
      // The 120 × 120 mark: outer M12 20 L60 100 L108 20, inner M36 20 L60 60 L84 20.
      Path chevron(double from, double to) => Path()
        ..moveTo(
          box.left + box.width * from / 120,
          box.top + box.height * 20 / 120,
        )
        ..lineTo(box.center.dx, box.top + box.height * 100 / 120)
        ..lineTo(
          box.right - box.width * to / 120,
          box.top + box.height * 20 / 120,
        );
      for (final (path, color) in [
        (chevron(12, 12), _paper),
        (chevron(36, 36), volt),
      ]) {
        final line = path.computeMetrics().first;
        canvas.drawPath(
          line.extractPath(0, line.length * mark.clamp(0, 1)),
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10 * scale
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CelebrationPainter old) =>
      old.time != time || old.scale != scale || old.top != top;
}

/// The small check beside "key verified".
class _CheckPainter extends CustomPainter {
  const _CheckPainter();

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..moveTo(size.width * .08, size.height * .55)
      ..lineTo(size.width * .38, size.height * .88)
      ..lineTo(size.width * .96, size.height * .12),
    Paint()
      ..color = volt
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );

  @override
  bool shouldRepaint(_CheckPainter old) => false;
}
