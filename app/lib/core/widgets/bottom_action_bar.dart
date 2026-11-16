import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// The room a widget pinned to the bottom edge must leave: the keyboard when it is open, otherwise the
/// system's bottom safe area (the home indicator).
///
/// It is the larger of the two, never their sum: the keyboard already covers the safe area. When a
/// parent [Scaffold] has resized for the keyboard, the view insets seen below it are zero and the
/// parent has already removed what it covers from the view padding, so nothing is counted twice.
double bottomClearanceOf(BuildContext context) {
  final media = MediaQuery.of(context);
  return math.max(media.viewInsets.bottom, media.viewPadding.bottom);
}

/// A bar pinned to the bottom of a page, above the keyboard and the safe area, on the surface colour.
///
/// On a phone [child] fills the width. From the tablet width it keeps its natural width and sits at the
/// end of the content column ([maxWidth], inside the page gutter). Put it in [PageScaffold.bottomAction].
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.contentMax,
  });

  /// A full-width primary button, the usual content. [buttonKey] goes on the button itself, for tests.
  BottomActionBar.button({
    Key? key,
    Key? buttonKey,
    required String label,
    required VoidCallback? onPressed,
    bool busy = false,
    double maxWidth = AppLayout.contentMax,
  }) : this(
         key: key,
         maxWidth: maxWidth,
         child: _BarButton(
           key: buttonKey,
           label: label,
           onPressed: onPressed,
           busy: busy,
         ),
       );

  final Widget child;

  /// The width of the content column the bar lines up with.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= AppBreakpoint.compactWidth;
    final gutter = AppLayout.gutterFor(width);
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          gutter,
          AppSpacing.sm,
          gutter,
          AppSpacing.sm + bottomClearanceOf(context),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: wide
                ? Align(alignment: AlignmentDirectional.centerEnd, child: child)
                : SizedBox(width: double.infinity, child: child),
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.busy,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, AppBottomBar.buttonHeight),
      ),
      child: busy
          ? const SizedBox.square(
              dimension: AppBottomBar.busyIndicator,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
