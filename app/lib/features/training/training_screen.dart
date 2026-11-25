import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velomine_api/api.dart' show TrainingWeek, TrainingWeekSession;

import '../../core/confirm.dart';
import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badge.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
import '../profile/profile_screen.dart' show weekDayName;
import 'training_goals.dart';
import 'training_view_model.dart';

/// Training: the rider's auto-training plan, this week's sessions and the goal. It is a destination of its own while
/// auto training is on; its menu changes the setup or turns it off, and a row of the week opens its session.
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
    final failure = state.load.failure;
    final week = state.weeks?.weeks.firstOrNull;
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
        if (state.load.running && plan == null)
          const LoadingState.rows()
        else if (failure != null)
          ErrorState(
            message: failureText(l10n, failure),
            onRetry: ref.read(trainingViewModelProvider.notifier).load,
            actionKey: const Key('training-error'),
          )
        else ...[
          // A week with no session yet is one the planning has not written: the page says when the plan starts.
          if (week != null && week.sessions.isNotEmpty)
            _ThisWeek(week: week)
          else
            SectionCard(
              key: const Key('training-goal'),
              title: l10n.trainingGoalCard,
              children: [
                Text(
                  trainingGoalName(l10n, goal),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  trainingGoalLine(l10n, goal),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          Text(
            l10n.trainingPlanStarts(
              weekDayName(l10n, plan?.firstDayOfWeek ?? 'monday'),
            ),
            key: const Key('training-plan-starts'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// One row per day of the rider's week, with what it is and how it is going, and the one kind line under them. A
/// rest day has its own row, so a week the rider reads has all seven in it.
class _ThisWeek extends StatelessWidget {
  const _ThisWeek({required this.week});

  final TrainingWeek week;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final byDay = {
      for (final session in week.sessions)
        DateUtils.dateOnly(session.localDate): session,
    };
    // A session made easy and ridden is done: the week counts it, as the sweep's own "last week fully done" does.
    final done = week.sessions
        .where((s) => s.state == 'done' || s.state == 'easy')
        .length;
    final total = week.sessions.length;
    return AppCard(
      key: const Key('training-week'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Text(l10n.trainingWeekCard, style: text.titleMedium),
          ),
          for (var day = 0; day < 7; day++)
            _WeekRow(
              date: week.start.add(Duration(days: day)),
              session:
                  byDay[DateUtils.dateOnly(
                    week.start.add(Duration(days: day)),
                  )],
              isToday: DateUtils.isSameDay(
                today,
                week.start.add(Duration(days: day)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Text(
              total == 0
                  ? l10n.trainingWeekKindNothing
                  : done == total
                  ? l10n.trainingWeekLineAll(done, total)
                  : l10n.trainingWeekLine(
                      done,
                      total,
                      trainingWeekKind(l10n, done, total),
                    ),
              key: const Key('training-week-line'),
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.date,
    required this.session,
    required this.isToday,
  });

  final DateTime date;
  final TrainingWeekSession? session;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = VelomineColors.of(context);
    final state = session == null ? null : trainingStateText(l10n, session!);
    final detail = [
      if (session != null) duration(session!.minutes * 60.0),
      if (isToday) l10n.trainingWeekToday,
    ].join(' · ');
    return InkWell(
      key: Key('training-day-${DateFormat('yyyy-MM-dd').format(date)}'),
      onTap: session == null
          ? null
          : () => context.push('/training/sessions/${session!.id}'),
      child: Container(
        color: isToday ? colors.cardRaised : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Text(
                    '${date.day}',
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat.E(l10n.localeName).format(date),
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  Text(
                    session == null
                        ? l10n.trainingWeekRest
                        : sessionName(
                            l10n,
                            english: session!.englishName,
                            italian: session!.italianName,
                          ),
                    style: text.bodyMedium,
                  ),
                  if (detail.isNotEmpty)
                    Text(
                      detail,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (state != null)
              AppBadge(
                state,
                tone: session!.state == 'done'
                    ? AppBadgeTone.good
                    : AppBadgeTone.neutral,
              ),
          ],
        ),
      ),
    );
  }
}
