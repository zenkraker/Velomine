import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart' show GoRouterHelper;
import 'package:velomine_api/api.dart'
    show
        BlockTarget,
        MainSetTarget,
        SessionResult,
        SessionNote,
        TrainingWeekSession;

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/card_link.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
import '../../l10n/generated/app_localizations.dart';
import '../profile/profile_screen.dart' show weekDayName;
import 'training_goals.dart';
import 'training_state.dart';
import 'training_view_model.dart';

/// One planned session: what it is and why, and, once a ride was it, how it went and the score it earned. The score is
/// the rider's own number and nobody else's. Moving or skipping a session by hand is the next story.
class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(trainingViewModelProvider);
    listenUserMessages(
      ref,
      context,
      trainingViewModelProvider.select((s) => s.messages),
      ref.read(trainingViewModelProvider.notifier).messageShown,
    );

    final session = state.session(id);
    if (session == null) return _missing(context, ref, state);

    final day = weekDayName(l10n, _dayOf(session.localDate));
    final stateText = trainingStateText(l10n, session);
    return PageScaffold(
      parent: l10n.navTraining,
      title: _name(l10n, session),
      subtitle: [
        '$day, ${DateFormat.MMMd(l10n.localeName).format(session.localDate)}',
        duration(session.minutes * 60.0),
        if (stateText != null) stateText.toLowerCase(),
      ].join(' · '),
      children: [
        if (session.result.orElse(null) case final result?)
          _howItWent(context, session, result),
        SectionCard(
          key: const Key('session-why'),
          title: l10n.sessionWhy,
          children: [
            Text(
              l10n.localeName.startsWith('it')
                  ? session.italianLine
                  : session.englishLine,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              l10n.sessionTechnical(session.technicalName.toLowerCase()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SectionCard(
          key: const Key('session-blocks'),
          title: l10n.sessionBlocks,
          children: [
            for (final block in session.blocks)
              _block(context, block, _name(l10n, session)),
            Text(
              l10n.sessionFeelExplanation,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            for (final note in session.notes) _note(context, note),
          ],
        ),
      ],
    );
  }

  Widget _missing(BuildContext context, WidgetRef ref, TrainingState state) {
    final l10n = context.l10n;
    final notifier = ref.read(trainingViewModelProvider.notifier);
    return PageScaffold(
      parent: l10n.navTraining,
      title: l10n.navTraining,
      children: [
        if (state.load.failure case final Failure failure?)
          ErrorState(
            message: failureText(l10n, failure),
            onRetry: notifier.load,
            actionKey: const Key('session-error'),
          )
        else if (state.load.running || state.load.idle)
          const LoadingState.rows()
        else
          EmptyState(
            key: const Key('session-gone'),
            message: l10n.sessionGone,
            icon: Icons.event_busy_outlined,
          ),
      ],
    );
  }

  /// The score, its kind line and planned beside done: the page's answer to "how did it go?".
  Widget _howItWent(
    BuildContext context,
    TrainingWeekSession session,
    SessionResult result,
  ) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final numbers = VelomineText.of(context);
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
              style: numbers.kpi,
            ),
            Text(
              l10n.sessionOfHundred,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        Text(
          sessionScoreKind(l10n, result.score),
          key: const Key('session-kind'),
          style: text.bodyMedium,
        ),
        _fact(
          context,
          l10n.sessionTime,
          l10n.sessionPlannedDone(
            duration(result.plannedMinutes * 60.0),
            duration(result.doneMinutes * 60),
          ),
        ),
        _fact(
          context,
          l10n.sessionEffortScore,
          l10n.sessionPlannedDone(
            '${result.plannedEffort.round()}',
            done == null ? '–' : '${done.round()}',
          ),
        ),
        if (result.mainSet case final main?)
          _fact(context, l10n.sessionMainSet, _mainSet(l10n, main)),
        if (session.rideId case final rideId?)
          CardLink(
            l10n.sessionOpenRide,
            onPressed: () => context.push('/rides/$rideId'),
          ),
      ],
    );
  }

  Widget _fact(BuildContext context, String label, String value) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: text.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value, style: text.bodyMedium)),
      ],
    );
  }

  /// The main set's target against the ride's average, in the signal the rider could follow.
  static String _mainSet(AppLocalizations l10n, MainSetTarget main) {
    final watts = main.signal == 'power';
    final average = main.average;
    final unit = watts ? 'W' : 'bpm';
    if (average == null) {
      return l10n.sessionMainSetPlannedOnly('${main.target} $unit');
    }
    return watts
        ? l10n.sessionMainSetWatts('${main.target}', '$average')
        : l10n.sessionMainSetBpm('${main.target}', '$average');
  }

  /// One block of the session: its length and its three targets. A block with no watt or heart-rate target is one the
  /// session rides by feel, so its feel is all it has to show.
  Widget _block(BuildContext context, BlockTarget block, String sessionLabel) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final targets = [
      if (block.wattsLow case final low?)
        l10n.sessionWatts(low, block.wattsHigh ?? low),
      if (block.heartRateLow case final low?)
        l10n.sessionBpm(low, block.heartRateHigh ?? low),
      l10n.sessionFeel(block.feelLow, block.feelHigh),
    ];
    final label = switch (block.role) {
      'warmup' => l10n.sessionBlockWarmup,
      'recovery' => l10n.sessionBlockRecovery,
      'cooldown' => l10n.sessionBlockCooldown,
      _ => sessionLabel,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              Text(label, style: text.bodyMedium),
              Text(
                targets.join(' · '),
                style: text.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(duration(block.minutes * 60.0), style: text.bodySmall),
      ],
    );
  }

  Widget _note(BuildContext context, SessionNote note) => Text(
    context.l10n.localeName.startsWith('it') ? note.italian : note.english,
    style: Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
  );

  static String _name(AppLocalizations l10n, TrainingWeekSession session) =>
      sessionName(
        l10n,
        english: session.englishName,
        italian: session.italianName,
      );

  /// The API spells a local date as midnight of that day; its weekday is what the rider reads.
  static String _dayOf(DateTime date) => const [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ][date.weekday - 1];
}
