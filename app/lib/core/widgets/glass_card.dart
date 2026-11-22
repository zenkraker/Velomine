import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../tokens.dart';
import 'floating_nav_pill.dart' show pillBlurOf;

/// A translucent card for content that floats over a map: the facts of a ride on its route. It blurs what
/// is behind it only where the device can afford the blur (see [pillBlurOf]); everywhere else it is a
/// nearly solid panel in the glass colour.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = VelomineColors.of(context);
    final blur = pillBlurOf(context);
    final surface = ColoredBox(
      color: colors.glass,
      child: Padding(padding: padding, child: child),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xlarge),
        ),
        shadows: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
            blurRadius: AppSpacing.lg,
            offset: const Offset(0, AppSpacing.xs),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xlarge),
        child: blur > 0
            ? BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: surface,
              )
            : surface,
      ),
    );
  }
}
