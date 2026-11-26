import '../../core/widgets/inline_error.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/widgets/badge.dart';
import '../../core/widgets/loading_state.dart';
import 'supporter_view_model.dart';

/// The supporter badge: the licence ("Supporter no. 128 · 3 Oct 2026") in the shared good badge, on the
/// profile and on the celebration screen.
///
/// Three taps within half a second call [onReplay], which opens the celebration again; [hint] says so to a
/// screen reader.
class SupporterBadge extends StatefulWidget {
  const SupporterBadge({
    super.key,
    required this.label,
    this.hint,
    this.onReplay,
  });

  final String label;
  final String? hint;
  final VoidCallback? onReplay;

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
  Widget build(BuildContext context) => Semantics(
    button: widget.onReplay != null,
    label: widget.label,
    hint: widget.hint,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onReplay == null ? null : _tap,
      // The badge is one line by design; the tap area is the comfortable 48 dp around it.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.xxxl),
        child: Center(
          widthFactor: 1,
          child: AppBadge(widget.label, tone: AppBadgeTone.good),
        ),
      ),
    ),
  );
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
          Expanded(child: InlineError(failureText(l10n, failure))),
          TextButton(
            key: const Key('supporter-retry'),
            onPressed: s.load.running ? null : notifier.load,
            child: Text(l10n.tryAgain),
          ),
        ],
      );
    }
    if (s.load.running) return const LoadingState.rows(count: 1);
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
    final licence = s.riderLicence!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        if (s.badgeShown)
          Align(
            alignment: Alignment.centerLeft,
            child: SupporterBadge(
              key: const Key('supporter-badge'),
              label: l10n.supporterSerialNumber(
                licence.serial,
                dateOnly(licence.activatedAt),
              ),
              hint: l10n.supporterBadgeReplayHint,
              onReplay: widget.onReplay,
            ),
          ),
        // A link rather than a second target: the badge itself replays on three quick taps.
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('supporter-replay'),
            onPressed: widget.onReplay,
            child: Text(l10n.supporterReplayLink),
          ),
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
