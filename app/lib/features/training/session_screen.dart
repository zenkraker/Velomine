import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
import 'session_shape.dart';
import 'session_view_model.dart';
import 'training_text.dart';

/// One planned session: why it is, every block with its three targets, and the shape of the day. A pushed screen over
/// the Training page. How the ride went and the buttons that change it are the later stories.
class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final provider = sessionViewModelProvider(id);
    final state = ref.watch(provider);
    final session = state.session;

    if (state.week.failure case final failure?) {
      return PageScaffold(
        parent: l10n.navTraining,
        title: l10n.navTraining,
        children: [
          ErrorState(
            message: failureText(l10n, failure),
            onRetry: ref.read(provider.notifier).retry,
            actionKey: const Key('session-error'),
          ),
        ],
      );
    }
    if (session == null) {
      return PageScaffold(
        parent: l10n.navTraining,
        title: l10n.navTraining,
        children: state.week.idle || state.week.running
            ? const [LoadingState.rows()]
            : [Text(l10n.trainingSessionMissing)],
      );
    }

    final notes = session.notes;
    return PageScaffold(
      parent: l10n.navTraining,
      title: sessionName(l10n, session),
      subtitle: [
        DateFormat('EEEE d MMM', locale).format(session.localDate),
        sessionLength(session.minutes),
        sessionState(l10n, session.state).toLowerCase(),
      ].join(' · '),
      children: [
        SectionCard(
          key: const Key('session-why'),
          title: l10n.trainingSessionWhy,
          children: [
            Text(sessionLine(l10n, session), style: text.bodyMedium),
            Text(
              l10n.trainingCoachesCall(session.technicalName),
              key: const Key('session-technical-name'),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        SectionCard(
          key: const Key('session-blocks'),
          title: l10n.trainingSessionTitle,
          children: [
            SessionShape(
              blocks: session.blocks,
              height: AppTraining.sessionShapeHeight,
            ),
            for (final (index, block) in session.blocks.indexed)
              _BlockRow(
                key: Key('session-block-$index'),
                block: block,
                estimated: session.heartRateEstimated,
              ),
            for (final note in notes)
              Text(
                noteText(l10n, note),
                key: Key('session-note-${note.code}'),
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            Text(
              l10n.trainingFeelExplained,
              key: const Key('session-feel'),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (session.heartRateEstimated)
              Text(
                l10n.trainingHeartEstimated,
                key: const Key('session-heart-estimated'),
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ],
    );
  }
}

/// One block: its name, its three targets with the number the rider can follow in bold, and its length.
class _BlockRow extends StatelessWidget {
  const _BlockRow({super.key, required this.block, required this.estimated});

  final BlockTarget block;
  final bool estimated;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final targets = [
      ?wattTarget(block),
      ?heartRateTarget(l10n, block, estimated: estimated),
      feelTarget(l10n, block),
    ];
    final rest = targets.skip(1).join(' · ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              Text(blockRole(l10n, block.role), style: text.bodyMedium),
              // The number the rider follows leads, in bold; the rest of the line says the other two.
              Wrap(
                children: [
                  Text(
                    targets.first,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (rest.isNotEmpty)
                    Text(
                      ' · $rest',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Text(
          duration(block.minutes * 60.0),
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
