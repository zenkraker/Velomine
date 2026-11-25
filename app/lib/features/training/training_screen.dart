import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velomine_api/api.dart';

import '../../core/confirm.dart';
import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badge.dart';
import '../../core/widgets/card_link.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
import '../profile/profile_screen.dart' show weekDayName;
import 'session_shape.dart';
import 'training_goals.dart';
import 'training_text.dart';
import 'training_view_model.dart';

/// Training: what the rider rides today, this week and why. The plan, the goal and the switch come from story 1's
/// setup; today's session, the week's rows and the preview are the planning story.
class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  Future<void> _turnOff(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final sure = await confirmDestructive(
      context,
      title: l10n.autoTrainingOffTitle,
      body: l10n.autoTrainingOffBody,
      action: l10n.autoTrainingOffAction,
      key: const Key('training-off-confirm'),
    );
    if (!sure || !context.mounted) return;
    final turnedOff = await ref
        .read(trainingViewModelProvider.notifier)
        .turnOff();
    // The destination goes with the switch: the rider lands on their rides.
    if (turnedOff && context.mounted) context.go('/rides');
  }

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

    final plan = state.plan;
    final goal = plan?.goal ?? plan?.suggestedGoal ?? 'fitter';
    final failure = state.load.failure ?? state.week.failure;
    final firstLoad =
        state.weeks.isEmpty &&
        (state.load.running || state.week.running || plan == null);
    // A wide window puts this week and the goal side by side, two to one; a phone stacks them.
    final expanded =
        MediaQuery.sizeOf(context).width >= AppBreakpoint.expandedWidth;
    final weeks = [
      if (state.thisWeek case final week? when week.sessions.isNotEmpty)
        _WeekCard(week: week),
      if (state.nextWeek case final week? when week.sessions.isNotEmpty)
        _WeekCard(week: week, preview: true),
    ];
    final goalCard = SectionCard(
      key: const Key('training-goal'),
      title: l10n.trainingGoalCard,
      children: [
        Text(
          trainingGoalName(l10n, goal),
          style: VelomineText.of(context).stat,
        ),
        Text(
          trainingSuggestionReason(l10n, plan?.suggestionReason ?? ''),
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
    return PageScaffold(
      title: l10n.navTraining,
      subtitle: [
        trainingGoalName(l10n, goal),
        if (plan?.hoursPerWeek case final hours?) l10n.trainingHoursLine(hours),
      ].join(' · '),
      menu: PageMenu(
        buttonKey: const Key('training-menu'),
        entries: [
          PageMenuEntry(
            key: const Key('training-change-setup'),
            label: l10n.trainingChangeSetup,
            icon: Icons.tune,
            onSelected: () => context.push('/training/setup'),
          ),
          PageMenuEntry(
            key: const Key('training-turn-off'),
            label: l10n.autoTrainingOffAction,
            icon: Icons.power_settings_new,
            destructive: true,
            onSelected: () => _turnOff(context, ref),
          ),
        ],
      ),
      children: [
        if (failure != null)
          ErrorState(
            message: failureText(l10n, failure),
            onRetry: ref.read(trainingViewModelProvider.notifier).load,
            actionKey: const Key('training-error'),
          )
        else if (firstLoad)
          const LoadingState.rows()
        else ...[
          _TodayCard(plan: plan, week: state.thisWeek),
          if (expanded && weeks.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.lg,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(spacing: AppSpacing.lg, children: weeks),
                ),
                Expanded(child: goalCard),
              ],
            )
          else ...[
            ...weeks,
            goalCard,
          ],
        ],
      ],
    );
  }
}

/// Today: the session with its length, one sentence of purpose, the main set's targets and the session's shape, or
/// a rest day, or the day the plan starts.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.plan, required this.week});

  final TrainingPlanResponse? plan;
  final TrainingWeek? week;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = DateUtils.dateOnly(DateTime.now());
    final session = week?.sessions
        .where((session) => DateUtils.isSameDay(session.localDate, today))
        .firstOrNull;

    final Widget content;
    if (session != null) {
      final block = mainBlock(session);
      content = Column(
        key: const Key('training-today-session'),
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: AppSpacing.sm,
            children: [
              Text(
                sessionName(l10n, session),
                style: VelomineText.of(context).stat,
              ),
              Text(
                sessionLength(session.minutes),
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Text(sessionLine(l10n, session), style: text.bodyMedium),
          if (block != null)
            Text(
              targetLine(l10n, block, estimated: session.heartRateEstimated),
              key: const Key('training-today-targets'),
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          SessionShape(blocks: session.blocks),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CardLink(
              l10n.trainingOpenSession,
              key: const Key('training-open-session'),
              onPressed: () => context.push('/training/sessions/${session.id}'),
            ),
          ),
        ],
      );
    } else if (plan?.lastPlannedFor == null) {
      // The planning has not run yet: say when the first week begins instead of showing a rest day that is not one.
      content = Text(
        l10n.trainingPlanStarts(
          weekDayName(l10n, plan?.firstDayOfWeek ?? 'monday'),
        ),
        key: const Key('training-plan-starts'),
        style: VelomineText.of(context).stat,
      );
    } else {
      content = Column(
        key: const Key('training-today-rest'),
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Text(l10n.trainingRestDay, style: VelomineText.of(context).stat),
          Text(
            l10n.trainingRestDaySentence,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      );
    }

    return AppCard(
      key: const Key('training-today'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Text(
            l10n.trainingTodayCaption(DateFormat.EEEE(locale).format(today)),
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          content,
        ],
      ),
    );
  }
}

/// One week: a row per day of the rider's week, the day's state as a badge, and one line of how the week is going.
class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.week, this.preview = false});

  final TrainingWeek week;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final today = DateUtils.dateOnly(DateTime.now());
    final done = week.sessions
        .where((session) => session.state == 'done' || session.state == 'easy')
        .length;

    return SectionCard(
      key: Key(preview ? 'training-next-week' : 'training-this-week'),
      title: preview ? l10n.trainingNextWeek : l10n.trainingThisWeek,
      description: week.note == null ? null : weekNoteText(l10n, week.note!),
      children: [
        Column(
          spacing: AppSpacing.xs,
          children: [
            for (var day = 0; day < 7; day++)
              _DayRow(
                date: DateUtils.addDaysToDate(week.start, day),
                session: week.sessions
                    .where(
                      (session) => DateUtils.isSameDay(
                        session.localDate,
                        DateUtils.addDaysToDate(week.start, day),
                      ),
                    )
                    .firstOrNull,
                today: today,
              ),
          ],
        ),
        if (week.sessions.isNotEmpty)
          Text(
            done == week.sessions.length
                ? l10n.trainingWeekLineAll(done, week.sessions.length)
                : l10n.trainingWeekLine(
                    done,
                    week.sessions.length,
                    trainingWeekKind(l10n, done, week.sessions.length),
                  ),
            key: const Key('training-week-summary'),
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
      ],
    );
  }
}

/// One day of a week: its date, what is planned or "Rest", and how it went.
class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.date,
    required this.session,
    required this.today,
  });

  final DateTime date;
  final TrainingWeekSession? session;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final isToday = DateUtils.isSameDay(date, today);
    final session = this.session;
    final state = session == null ? null : sessionState(l10n, session);

    return InkWell(
      key: Key('training-day-${DateFormat('yyyy-MM-dd').format(date)}'),
      onTap: session == null
          ? null
          : () => context.push('/training/sessions/${session.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isToday ? VelomineColors.of(context).cardRaised : null,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            SizedBox(
              width: AppTraining.dateWidth,
              child: Column(
                children: [
                  Text(
                    '${date.day}',
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat.E(locale).format(date),
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // The name and the length wrap onto a second line rather than running under the badge.
            Expanded(
              child: Wrap(
                spacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    session == null
                        ? l10n.trainingRest
                        : sessionName(l10n, session),
                    style: text.bodyMedium,
                  ),
                  if (session != null)
                    Text(
                      [
                        sessionLength(session.minutes),
                        if (isToday) l10n.trainingToday,
                      ].join(' · '),
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            // A planned day carries no badge: the name alone is the plan.
            if (state != null)
              AppBadge(
                state,
                tone: session!.state == 'done' || session.state == 'easy'
                    ? AppBadgeTone.good
                    : AppBadgeTone.neutral,
              ),
          ],
        ),
      ),
    );
  }
}
