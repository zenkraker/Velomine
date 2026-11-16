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
}) => _confirm(
  context,
  title: title,
  body: body,
  action: action,
  key: key,
  cancelLabel: cancelLabel,
  destructive: true,
);

/// Asks before something that is not lost for good, such as approving a request: the same dialog with
/// a normal primary action. Returns true only when the action is chosen.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  required Key key,
  String? cancelLabel,
}) => _confirm(
  context,
  title: title,
  body: body,
  action: action,
  key: key,
  cancelLabel: cancelLabel,
  destructive: false,
);

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  required Key key,
  required bool destructive,
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
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      );
    },
  );
  return sure == true;
}
