import 'package:material_ui/material_ui.dart';

import '../l10n.dart';
import '../motion.dart';
import '../tokens.dart';

/// Opens [builder] as a bottom sheet that keeps the app's motion, and returns what the sheet pops.
/// The one place a sheet is opened, so the handle, the width and the reduced-motion rule are the same
/// everywhere. Dismissing (drag, barrier or back) returns null.
Future<T?> showSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: AppSheet.maxWidth),
  // The sheet keeps the app's motion, or none when the system asks for none.
  sheetAnimationStyle: AnimationStyle(
    duration: motionDuration(context, AppMotion.standard),
  ),
  builder: builder,
);

/// The frame of every bottom sheet: a title, the content in a scrolling column, and an optional [bottom]
/// widget pinned under it, above the keyboard and the safe area. The handle comes from [showSheet].
class SheetFrame extends StatelessWidget {
  const SheetFrame({
    super.key,
    required this.title,
    required this.children,
    this.bottom,
  });

  final String title;
  final List<Widget> children;

  /// A widget that stays visible under the scrolling content, such as the Save button.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSheet.gutter,
                AppSpacing.sm,
                AppSheet.gutter,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.md,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  ...children,
                ],
              ),
            ),
          ),
          if (bottom != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSheet.gutter,
                AppSpacing.sm,
                AppSheet.gutter,
                AppSpacing.lg,
              ),
              child: bottom,
            ),
        ],
      ),
    );
  }
}

/// A [SheetFrame] with a full-width Save button pinned at the bottom and an optional error line above it.
/// There is no Cancel: dismissing the sheet is the cancel.
class FormSheet extends StatelessWidget {
  const FormSheet({
    super.key,
    required this.title,
    required this.children,
    required this.saveKey,
    required this.onSave,
    this.error,
    this.saveLabel,
  });

  final String title;
  final List<Widget> children;

  /// The key of the Save button, for tests.
  final Key saveKey;

  /// Null while the form is saving, which disables the button.
  final VoidCallback? onSave;

  /// What is wrong with the input, shown above the button.
  final String? error;

  /// The button's text when the action is not "Save".
  final String? saveLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SheetFrame(
      title: title,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          if (error != null)
            Text(
              error!,
              key: const Key('form-error'),
              style: TextStyle(color: scheme.error),
            ),
          FilledButton(
            key: saveKey,
            onPressed: onSave,
            child: Text(saveLabel ?? context.l10n.save),
          ),
        ],
      ),
      children: children,
    );
  }
}
