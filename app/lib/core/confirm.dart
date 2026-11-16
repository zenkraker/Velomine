import 'package:material_ui/material_ui.dart';

import 'l10n.dart';
import 'motion.dart';

/// Asks before something is lost for good: one dialog with Cancel and a red action that names what it does.
/// Returns true only when the action is chosen; Cancel, a tap outside and Back all return false.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  required Key key,
  String? cancelLabel,
}) async {
  final sure = await showDialog<bool>(
    context: context,
    animationStyle: reduceMotion(context) ? AnimationStyle.noAnimation : null,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel ?? context.l10n.cancel),
          ),
          FilledButton(
            key: key,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      );
    },
  );
  return sure == true;
}
