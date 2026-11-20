import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/rider_mode.dart';
import '../../core/tokens.dart';
import '../../core/widgets/form_sheet.dart';
import '../../core/widgets/inline_error.dart';
import '../../l10n/generated/app_localizations.dart';
import 'rider_mode_view_model.dart';

/// Opens the rider mode question: the first-launch prompt, or the same sheet from Settings.
///
/// [firstTime] is the prompt. Dismissing it (back, swipe or a tap outside) closes it at once and saves just
/// riding in the background; dismissing the Settings sheet changes nothing. "Decide later" waits for its save
/// instead. That asymmetry is deliberate: a member who is not sure gets an answer that sticks, a member who
/// closes the question is not held up by a slow server.
Future<void> showRiderModeSheet(
  BuildContext context, {
  required bool firstTime,
}) {
  // The sheet opens on a clean slate, so a failure from a previous opening is not shown again.
  ProviderScope.containerOf(
    context,
    listen: false,
  ).read(riderModeViewModelProvider.notifier).clearSave();
  return showSheet<void>(
    context,
    builder: (_) => _RiderModeSheet(firstTime: firstTime),
  );
}

class _RiderModeSheet extends ConsumerStatefulWidget {
  const _RiderModeSheet({required this.firstTime});

  final bool firstTime;

  @override
  ConsumerState<_RiderModeSheet> createState() => _RiderModeSheetState();
}

class _RiderModeSheetState extends ConsumerState<_RiderModeSheet> {
  /// A mode was chosen or "Decide later" was saved: a dismissal must not save over it.
  bool _decided = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final situation = ref.watch(riderModeSituationProvider);
    final save = ref.watch(riderModeViewModelProvider).save;
    final failure = save.failure;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop || _decided || !widget.firstTime) return;
        _decided = true;
        // Closes at once: the save is not awaited, and the prompt does not reopen in this session.
        unawaited(
          ref
              .read(riderModeViewModelProvider.notifier)
              .choose(defaultRiderMode, onlyIfUnset: true),
        );
      },
      child: SheetFrame(
        key: widget.firstTime ? const Key('rider-mode-prompt') : null,
        title: l10n.riderModeQuestion,
        children: [
          for (final mode in RiderMode.values)
            _RiderModeOption(
              mode: mode,
              selected: situation.mode == mode,
              onTap: save.running ? null : () => _choose(mode),
            ),
          if (failure != null)
            InlineError(
              failureText(l10n, failure),
              key: const Key('rider-mode-error'),
            ),
          // Not sure yet: just riding is saved and the question does not come back.
          TextButton(
            key: const Key('rider-mode-later'),
            onPressed: save.running ? null : () => _choose(defaultRiderMode),
            child: Text(l10n.riderModeLater),
          ),
        ],
      ),
    );
  }

  /// Waits for the save; the sheet closes only when the account holds the mode.
  Future<void> _choose(RiderMode mode) async {
    final saved = await ref
        .read(riderModeViewModelProvider.notifier)
        .choose(mode);
    if (!mounted || !saved) return;
    _decided = true;
    Navigator.of(context).pop();
  }
}

/// One answer: its name, a sentence saying who it is for, and a mark on the one in use. At least 48 dp tall,
/// and a screen reader says which one is selected.
class _RiderModeOption extends StatelessWidget {
  const _RiderModeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final RiderMode mode;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: InkWell(
          key: Key('rider-mode-${mode.slug}'),
          borderRadius: BorderRadius.circular(AppRadius.medium),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.md,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpacing.xs,
                      children: [
                        Text(
                          riderModeName(l10n, mode),
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          riderModeExplanation(l10n, mode),
                          style: text.bodySmall?.copyWith(
                            color: selected
                                ? scheme.onPrimaryContainer
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      key: const Key('rider-mode-selected'),
                      color: scheme.onPrimaryContainer,
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

/// The name of a mode in the language on screen.
String riderModeName(AppLocalizations l10n, RiderMode mode) => switch (mode) {
  RiderMode.justRiding => l10n.riderModeJustRiding,
  RiderMode.withGoals => l10n.riderModeWithGoals,
  RiderMode.training => l10n.riderModeTraining,
};

/// One sentence saying who the mode is for, in words a new member knows.
String riderModeExplanation(AppLocalizations l10n, RiderMode mode) =>
    switch (mode) {
      RiderMode.justRiding => l10n.riderModeJustRidingBody,
      RiderMode.withGoals => l10n.riderModeWithGoalsBody,
      RiderMode.training => l10n.riderModeTrainingBody,
    };
