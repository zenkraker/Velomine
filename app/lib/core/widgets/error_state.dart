import 'package:material_ui/material_ui.dart';

import '../l10n.dart';
import '../tokens.dart';

/// What a screen says when its data did not arrive: one message and, when the page can ask again, the way to.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.actionKey,
  });

  final String message;
  final VoidCallback? onRetry;

  /// A key on the retry button, for the test that presses it.
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.md,
          children: [
            Icon(Icons.cloud_off_outlined, size: 30, color: scheme.error),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null)
              OutlinedButton.icon(
                key: actionKey,
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.retry),
              ),
          ],
        ),
      ),
    );
  }
}
