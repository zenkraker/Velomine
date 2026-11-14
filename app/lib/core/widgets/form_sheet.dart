import 'package:material_ui/material_ui.dart';

import '../l10n.dart';
import '../motion.dart';
import '../tokens.dart';

/// Opens a form as a bottom sheet that keeps the app's motion, and returns what the form pops.
Future<T?> showFormSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 640),
  // The sheet keeps the app's motion, or none when the system asks for none.
  sheetAnimationStyle: AnimationStyle(
    duration: motionDuration(context, AppMotion.standard),
  ),
  builder: builder,
);

/// The frame of a form sheet: a handle, a title, the fields in a scrolling column, an optional error line, and
/// Cancel / Save underneath.
class FormSheet extends StatelessWidget {
  const FormSheet({
    super.key,
    required this.title,
    required this.children,
    required this.saveKey,
    required this.onSave,
    this.error,
  });

  final String title;
  final List<Widget> children;

  /// The key of the Save button, for tests.
  final Key saveKey;
  final VoidCallback onSave;

  /// What is wrong with the input, shown above the buttons.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                ...children,
                if (error != null)
                  Text(
                    error!,
                    key: const Key('form-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                key: saveKey,
                onPressed: onSave,
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
