import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/theme.dart';
import 'supporter_view_model.dart';

/// The Velomine mark drawn inline, so no font or image asset is needed: the
/// outer chevron and the lime inner one, on a 120-unit artboard.
///
/// The colours are the celebration's own, so the mark is the same on any
/// background.
abstract final class Chevron {
  static const _artboard = 120;

  static Path _path(Size box, double from, double to) => Path()
    ..moveTo(box.width * from / _artboard, box.height * 20 / _artboard)
    ..lineTo(box.width * 60 / _artboard, box.height * 100 / _artboard)
    ..lineTo(box.width * to / _artboard, box.height * 20 / _artboard);

  static void _draw(Canvas canvas, Size box, Path path, Color color) =>
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10 * box.width / _artboard
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

  /// The whole mark: the pale outer chevron, then the lime inner one.
  static void paint(Canvas canvas, Size box) {
    _draw(canvas, box, _path(box, 12, 108), cloudDancer);
    _draw(canvas, box, _path(box, 36, 84), volt);
  }

  /// The mark as a widget, for a badge's small icon.
  static Widget widget(double side) =>
      CustomPaint(size: Size.square(side), painter: const _ChevronPainter());
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter();

  @override
  void paint(Canvas canvas, Size size) => Chevron.paint(canvas, size);

  @override
  bool shouldRepaint(_ChevronPainter old) => false;
}

/// The supporter badge: the chevron and "Supporter" on the lime-tinted pill, the
/// same mark on the profile and on the celebration screen.
///
/// Three taps within half a second call [onReplay], which opens the celebration
/// again; [hint] says so to a screen reader.
class SupporterBadge extends StatefulWidget {
  const SupporterBadge({
    super.key,
    required this.label,
    this.hint,
    this.onReplay,
    this.style,
    this.background,
  });

  final String label;
  final String? hint;
  final VoidCallback? onReplay;

  /// The text's style; the celebration's pill sets its own.
  final TextStyle? style;

  /// The pill's fill, when it stands on a background of its own.
  final Color? background;

  @override
  State<SupporterBadge> createState() => _SupporterBadgeState();
}

class _SupporterBadgeState extends State<SupporterBadge> {
  static const _window = Duration(milliseconds: 500);
  final _taps = <DateTime>[];

  void _tap() {
    final now = DateTime.now();
    _taps
      ..removeWhere((t) => now.difference(t) > _window)
      ..add(now);
    if (_taps.length < 3) return;
    _taps.clear();
    widget.onReplay?.call();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: widget.onReplay != null,
      label: widget.label,
      hint: widget.hint,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onReplay == null ? null : _tap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: widget.background ?? volt.withValues(alpha: 0.12),
            border: Border.all(color: volt.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.sm,
            children: [
              Chevron.widget(16),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: widget.style ?? text.labelLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The profile's supporter section: "become a supporter" while there is no
/// licence, then the badge, its replay and the switch that hides it.
class SupporterSection extends ConsumerStatefulWidget {
  const SupporterSection({
    super.key,
    required this.onReplay,
    required this.onBecomeSupporter,
    required this.onOpen,
  });

  /// Opens the celebration again, for the badge's triple tap and the replay button.
  final VoidCallback onReplay;

  /// Opens the activation screen, while the member has no licence yet.
  final VoidCallback onBecomeSupporter;

  /// Asks the server again when the profile is opened: the licence is kept alive with
  /// the session, so a second device's activation would not show otherwise.
  final VoidCallback onOpen;

  @override
  ConsumerState<SupporterSection> createState() => _SupporterSectionState();
}

class _SupporterSectionState extends ConsumerState<SupporterSection> {
  @override
  void initState() {
    super.initState();
    widget.onOpen();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = ref.watch(supporterViewModelProvider);
    final notifier = ref.read(supporterViewModelProvider.notifier);
    final failure = s.load.failure;
    if (failure != null) {
      return Row(
        key: const Key('supporter-load-error'),
        spacing: AppSpacing.sm,
        children: [
          Expanded(
            child: Text(
              failureText(l10n, failure),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          TextButton(
            key: const Key('supporter-retry'),
            onPressed: s.load.running ? null : notifier.load,
            child: Text(l10n.tryAgain),
          ),
        ],
      );
    }
    if (s.load.running) return const SizedBox(height: 48);
    if (s.becomeSupporter) {
      return Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.tonal(
          key: const Key('supporter-become'),
          onPressed: widget.onBecomeSupporter,
          child: Text(l10n.supporterBecome),
        ),
      );
    }
    if (s.riderLicence == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Row(
          spacing: AppSpacing.md,
          children: [
            if (s.badgeShown)
              Flexible(
                child: SupporterBadge(
                  key: const Key('supporter-badge'),
                  label: l10n.supporter,
                  hint: l10n.supporterBadgeReplayHint,
                  onReplay: widget.onReplay,
                ),
              ),
            // Above the badge itself, a pointer is not a touch, so the badge's three quick taps still count.
            IconButton(
              key: const Key('supporter-replay'),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size.square(48),
              ),
              tooltip: l10n.supporterReplay,
              onPressed: widget.onReplay,
              icon: const Icon(Icons.replay),
            ),
          ],
        ),
        SwitchListTile(
          key: const Key('supporter-hidden'),
          contentPadding: EdgeInsets.zero,
          value: s.badgeShown,
          title: Text(l10n.supporterHideBadge),
          subtitle: Text(l10n.supporterHideBadgeHelp),
          onChanged: s.hidden.running
              ? null
              : (show) => notifier.setHidden(!show),
        ),
      ],
    );
  }
}
