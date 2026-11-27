import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n.dart';
import '../motion.dart';
import '../saved_mark_view_model.dart';
import '../tokens.dart';
import 'bottom_action_bar.dart';
import 'badge.dart';

/// The "Saved." confirmation after a save: a small green badge with a check, faded in while [visible] and out
/// when not. Read once, when it shows, by a screen reader.
class SavedMark extends StatelessWidget {
  const SavedMark({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      excluding: !visible,
      child: Semantics(
        liveRegion: true,
        container: true,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: motionDuration(context, AppMotion.standard),
          curve: motionCurve(context, AppMotion.emphasized),
          child: AppBadge(
            context.l10n.saved,
            tone: AppBadgeTone.good,
            icon: Icons.check,
          ),
        ),
      ),
    );
  }
}

/// Draws the [SavedMark] in the bottom-right corner of the window, over every screen and above the floating
/// navigation pill on a phone, so it shows where the member is looking whatever the page's length. Put it once,
/// around the app's pages.
class SavedMarkHost extends ConsumerWidget {
  const SavedMarkHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < AppBreakpoint.compactWidth;
    return Stack(
      children: [
        child,
        PositionedDirectional(
          end: AppLayout.gutterFor(width),
          bottom:
              bottomClearanceOf(context) +
              (phone ? AppNav.pillClearance : 0) +
              AppSpacing.md,
          child: IgnorePointer(
            child: SavedMark(
              key: const Key('saved-mark'),
              visible: ref.watch(savedMarkViewModelProvider),
            ),
          ),
        ),
      ],
    );
  }
}
