import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hooks.dart';
import '../../core/l10n.dart';
import '../../home_shell.dart' show feedbackUrl;

/// "Velomine plans your week from your rides. It is new: tell us what feels wrong." with the feedback form,
/// where auto training is switched on and where it is set up.
class AutoTrainingNote extends ConsumerWidget {
  const AutoTrainingNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        text: '${l10n.autoTrainingSentence} ',
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: InkWell(
              key: const Key('training-feedback'),
              onTap: () => ref.read(linkOpenerProvider)(feedbackUrl),
              child: Text(
                l10n.autoTrainingFeedback,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}
