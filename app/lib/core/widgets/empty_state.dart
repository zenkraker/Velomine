import 'package:material_ui/material_ui.dart';

import '../tokens.dart';
import 'app_card.dart';

/// What a list says when it has nothing to show: one line, centred, with room around it and,
/// when there is one, the way forward.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon,
    this.action,
    this.framed = true,
  });

  final String message;
  final IconData? icon;

  /// A button that fills the emptiness: add the thing, clear the filters.
  final Widget? action;

  /// Its own card. False for an empty state that already sits inside a card or a sheet.
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.md,
        children: [
          if (icon case final icon?)
            Icon(icon, size: 32, color: scheme.onSurfaceVariant),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          ?action,
        ],
      ),
    );
    if (!framed) return content;
    return AppCard(child: Center(child: content));
  }
}
