import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart' show GoRouterHelper;
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets/card_link.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
import '../../l10n/generated/app_localizations.dart';
import 'session_shape.dart';
import 'session_view_model.dart';
import 'training_goals.dart';
import 'training_text.dart';

/// One planned session: what it is and why, every block with its three targets, the shape of the day and, once a ride
/// was it, how it went and the score it earned. The score is the rider's own number and nobody else's. Moving or
/// skipping a session by hand is the next story.
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
        // The score leads the card below; the header says only where the day stands.
        sessionStateWord(l10n, session.state).toLowerCase(),
      ].join(' · '),
      children: [
        if (session.result.orElse(null) case final result?)
          _HowItWent(session: session, result: result),
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

/// How it went: the score, its kind line, planned beside done as facts, and the way to the ride.
class _HowItWent extends StatelessWidget {
  const _HowItWent({required this.session, required this.result});

  final TrainingWeekSession session;
  final SessionResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final done = result.doneEffort;
    return SectionCard(
      key: const Key('session-how-it-went'),
      title: l10n.sessionHowItWent,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: AppSpacing.sm,
          children: [
            Text(
              '${result.score}',
              key: const Key('session-score'),
              style: VelomineText.of(context).kpi,
            ),
            Text(
              l10n.sessionOfHundred,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        Text(sessionScoreKind(l10n, result.score), style: text.bodyMedium),
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.md,
          children: [
            _Fact(
              l10n.sessionTime,
              l10n.sessionPlannedDone(
                duration(result.plannedMinutes * 60.0),
                duration(result.doneMinutes * 60),
              ),
            ),
            _Fact(
              l10n.sessionEffortScore,
              l10n.sessionPlannedDone(
                '${result.plannedEffort.round()}',
                done == null ? '–' : '${done.round()}',
              ),
            ),
            if (result.mainSet case final main?)
              _Fact(l10n.sessionMainSet, _mainSet(l10n, main)),
          ],
        ),
        if (session.rideId case final rideId?)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CardLink(
              l10n.sessionOpenRide,
              onPressed: () => context.push('/rides/$rideId'),
            ),
          ),
      ],
    );
  }

  /// The main set's target against the ride's average, in the signal the rider could follow.
  static String _mainSet(AppLocalizations l10n, MainSetTarget main) {
    final watts = main.signal == 'power';
    final unit = watts ? 'W' : 'bpm';
    if (main.average case final average?) {
      return watts
          ? l10n.sessionMainSetWatts('${main.target}', '$average')
          : l10n.sessionMainSetBpm('${main.target}', '$average');
    }
    return l10n.sessionMainSetPlannedOnly('${main.target} $unit');
  }
}

/// One fact as the design writes it: its label, then the number under it.
class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: text.bodyMedium),
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
