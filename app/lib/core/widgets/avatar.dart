import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../tokens.dart';

/// The initials that stand for a member in a row, a member list or an athlete card, as the mock-up's
/// `vm-avatar` draws it: one circle, the first two initials, a ground from the palette.
///
/// The ground follows the name, so the same member keeps the same circle between screens and rebuilds.
/// The full name is the semantic label; the initials are decoration.
class Avatar extends StatelessWidget {
  const Avatar(this.name, {super.key, this.size = AppAvatar.size});

  /// The member's display name: "Marco Riva" draws "MR", "Marco" draws "M".
  final String name;

  /// The circle's diameter. A row uses [AppAvatar.size].
  final double size;

  /// Up to two initials: the first letter of the first and the last word.
  static String initialsOf(String name) {
    final words = name
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    final letters =
        words.first.characters.first +
        (words.length > 1 ? words.last.characters.first : '');
    return letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VelomineColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    // Three of the design's own ground/ink pairs, so a roster does not read as one repeated circle.
    final palette = [
      (colors.accentSoft, colors.onAccentSoft),
      (colors.cardRaised, scheme.onSurface),
      (colors.signalSoft, colors.signal),
    ];
    final (ground, ink) =
        palette[name.codeUnits.fold(0, (a, b) => a + b) % palette.length];
    return Semantics(
      label: name,
      container: true,
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: ground, shape: BoxShape.circle),
          // The circle keeps its size in a row, so the initials shrink to fit when the system text is
          // very large instead of running out of the circle.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Text(
                initialsOf(name),
                maxLines: 1,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: ink, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
