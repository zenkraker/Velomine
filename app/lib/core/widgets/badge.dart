import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../tokens.dart';

/// What a badge says about the thing it labels: quiet by default, and the accent, the signal or the
/// warning colours when the word carries a state.
enum AppBadgeTone { neutral, good, care, warn, bad }

/// A small label beside a name or a title, as the mock-up's `vm-badge`: a ride's type, a power record,
/// what an athlete shares, a club's state.
class AppBadge extends StatelessWidget {
  const AppBadge(
    this.label, {
    super.key,
    this.tone = AppBadgeTone.neutral,
    this.icon,
  });

  final String label;
  final AppBadgeTone tone;

  /// A glyph before the label, for a badge that has no room for a word.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = VelomineColors.of(context);
    final (ground, ink) = switch (tone) {
      AppBadgeTone.neutral => (colors.cardRaised, scheme.onSurfaceVariant),
      AppBadgeTone.good => (colors.accentSoft, colors.onAccentSoft),
      AppBadgeTone.care => (colors.signalSoft, colors.signal),
      AppBadgeTone.warn => (colors.cardRaised, colors.warning),
      AppBadgeTone.bad => (colors.cardRaised, scheme.error),
    };
    return Container(
      height: AppBadgeSize.height,
      padding: const EdgeInsets.symmetric(horizontal: AppBadgeSize.sidePadding),
      decoration: BoxDecoration(
        color: ground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          if (icon case final icon?) Icon(icon, size: 14, color: ink),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: ink, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
