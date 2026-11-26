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
import '../../core/widgets/week_day_row.dart';
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
    // The server sends one reason, the one it picked the suggested goal with: it explains the goal in force
    // only while that goal is the suggested one.
    final reason = goal == plan?.suggestedGoal ? plan?.suggestionReason : null;
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
        if (reason != null)
          Text(
            trainingSuggestionReason(l10n, reason),
            key: const Key('training-goal-reason'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
/// a rest day, or the day the plan starts. When it changed, one line says why above the targets.
class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.plan, required this.week});

  final TrainingPlanResponse? plan;
  final TrainingWeek? week;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          // Why today is not what the plan said this morning: the reason, and where the hard day went.
          if (session.easyReason case final reason?)
            Text(
              easyLine(l10n, reason, movedTo: session.easyMovedTo),
              key: const Key('training-today-reason'),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          if (block != null)
            Text(
              targetLine(l10n, block, estimated: session.heartRateEstimated),
              key: const Key('training-today-targets'),
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          SessionShape(blocks: session.blocks),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.lg,
            children: [
              // The one action a today card has by hand: no full page, and "Back to the plan" lives on the session.
              if (session.canMakeEasy)
                TextButton(
                  key: const Key('training-make-easy'),
                  onPressed: () => ref
                      .read(trainingViewModelProvider.notifier)
                      .makeEasy(session.id),
                  child: Text(l10n.trainingMakeEasy),
                ),
              CardLink(
                l10n.trainingOpenSession,
                key: const Key('training-open-session'),
                onPressed: () =>
                    context.push('/training/sessions/${session.id}'),
              ),
            ],
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
                plain: preview,
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

/// One day of a week, as the page's rows read it: the shared [WeekDayRow] with the day's session or its rest, and the
/// way to open it.
class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.date,
    required this.session,
    required this.today,
    this.plain = false,
  });

  final DateTime date;
  final TrainingWeekSession? session;
  final DateTime today;

  /// A row of the next-week preview, which the guideline draws plain: no way in.
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isToday = DateUtils.isSameDay(date, today);
    final session = this.session;

    return WeekDayRow(
      key: Key('training-day-${DateFormat('yyyy-MM-dd').format(date)}'),
      date: date,
      title: session == null ? l10n.trainingRest : sessionName(l10n, session),
      detail: session == null
          ? null
          : [
              sessionLength(session.minutes),
              if (isToday) l10n.trainingToday,
            ].join(' · '),
      // A planned day carries no badge: the name alone is the plan.
      state: session == null ? null : sessionState(l10n, session),
      tone:
          session != null &&
              (session.state == 'done' || session.state == 'easy')
          ? AppBadgeTone.good
          : AppBadgeTone.neutral,
      isToday: isToday,
      onTap: session == null || plain
          ? null
          : () => context.push('/training/sessions/${session.id}'),
    );
  }
}
