import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../motion.dart';
import '../theme.dart';
import '../tokens.dart';

/// The blur behind the glass on this device, 0 for none.
///
/// Every platform gets the blur the glass tokens ask for. Only a system that asks for high contrast
/// drops it, because glass over a blur is the one thing that makes text harder to read.
double pillBlurOf(BuildContext context) {
  if (MediaQuery.highContrastOf(context)) return 0;
  return AppNav.pillBlur;
}

/// One destination of the [FloatingNavPill]: an outlined icon, the filled one while selected, a label.
typedef NavPillItem = ({
  Key? key,
  Widget icon,
  Widget selectedIcon,
  String label,
});

/// The phone's navigation: a translucent stadium floating over the content, inset from the screen
/// edges and the bottom safe area, with a pill-shaped indicator behind the selected item.
///
/// Place it in a [Stack] over the page. [selected] null lights nothing (a pushed screen). When
/// [visible] is false it slides down and fades; under reduced motion the caller keeps it visible.
class FloatingNavPill extends StatelessWidget {
  const FloatingNavPill({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.visible = true,
  });

  final List<NavPillItem> items;
  final int? selected;
  final ValueChanged<int> onSelected;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final duration = motionDuration(context, AppMotion.standard);
    final curve = motionCurve(context, AppMotion.emphasized);
    final blur = pillBlurOf(context);
    final glass = VelomineColors.of(context).glass;
    final surface = ColoredBox(
      // Without the blur the glass turns nearly solid, so the content behind never shows through it.
      color: blur > 0
          ? glass
          : glass.withValues(alpha: AppNav.pillOpacityNoBlur),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          children: [
            for (final (i, item) in items.indexed)
              Expanded(
                child: _PillItem(
                  item: item,
                  selected: i == selected,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
    return Positioned(
      left: AppNav.pillMargin,
      right: AppNav.pillMargin,
      bottom: safeBottom + AppNav.pillMargin,
      height: AppNav.pillHeight,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          offset: Offset(0, visible ? 0 : AppNav.pillHiddenOffset),
          duration: duration,
          curve: curve,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: duration,
            curve: curve,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppNav.pillMaxWidth,
                ),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: const StadiumBorder(),
                    shadows: [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.18),
                        blurRadius: AppSpacing.xl,
                        offset: const Offset(0, AppSpacing.xs),
                      ),
                    ],
                  ),
                  child: ClipPath(
                    clipper: const ShapeBorderClipper(shape: StadiumBorder()),
                    child: blur > 0
                        ? BackdropFilter(
                            filter: ui.ImageFilter.blur(
                              sigmaX: blur,
                              sigmaY: blur,
                            ),
                            child: surface,
                          )
                        : surface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillItem extends StatelessWidget {
  const _PillItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavPillItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    final duration = motionDuration(context, AppMotion.standard);
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: item.label,
        child: InkResponse(
          key: item.key,
          onTap: onTap,
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
          customBorder: const StadiumBorder(),
          child: AnimatedContainer(
            duration: duration,
            curve: motionCurve(context, AppMotion.emphasized),
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: selected ? scheme.primaryContainer : Colors.transparent,
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: color, size: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  selected ? item.selectedIcon : item.icon,
                  // The pill's height is fixed, so its label grows only a little with the text size;
                  // it is never squeezed, because `nav-label` is a size the design fixes at 15.
                  MediaQuery.withClampedTextScaling(
                    maxScaleFactor: AppNav.maxLabelScale,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: VelomineText.of(context).navLabel.copyWith(
                        color: color,
                        fontWeight: selected ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
