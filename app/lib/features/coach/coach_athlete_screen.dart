import '../../core/widgets/loading_state.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../progress/power_summary.dart';
import '../rides/ride_title.dart';
import '../progress/training_summary.dart';
import '../training/training_goals.dart';
import '../training/training_text.dart';
import 'coach_athlete_view_model.dart';
import '../../core/tokens.dart';
import '../../core/widgets/badge.dart';
import '../../core/widgets/card_grid.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/week_day_row.dart';
import '../../core/units.dart';
import '../../l10n/generated/app_localizations.dart';

/// One athlete as their coach sees them: shared summary, training load and recent rides.
class CoachAthleteScreen extends ConsumerWidget {
  const CoachAthleteScreen({
    super.key,
    required this.clubId,
    required this.userId,
    required this.onOpenRide,
  });

  final String clubId;
  final String userId;
  final void Function(String rideId) onOpenRide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(coachAthleteViewModelProvider(clubId, userId));
    final l10n = context.l10n;
    final units = ref.watch(unitsChoiceViewModelProvider);
    final summary = c.summary;
    return PageScaffold(
      title: summary?.displayName ?? l10n.athletesTitle,
      parent: l10n.athletesTitle,
      subtitle: l10n.coachReadOnly,
      children: [
        if (c.notFound)
          EmptyState(
            key: const Key('coach-athlete-not-found'),
            message: l10n.coachAthleteNotFound,
            icon: Icons.person_off_outlined,
          )
        else if (c.load.running && summary == null)
          const LoadingState()
        else if (summary != null) ...[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (summary.sharesRides)
                AppBadge(l10n.sharesRides, tone: AppBadgeTone.good),
              if (summary.sharesAnalytics)
                AppBadge(l10n.sharesTraining, tone: AppBadgeTone.good),
              if (summary.sharesRoutes)
                AppBadge(l10n.sharesRoutes, tone: AppBadgeTone.good),
              if (summary.sharesWellbeing)
                AppBadge(l10n.sharesWellbeing, tone: AppBadgeTone.good),
            ],
          ),
          if (c.load.failure case final failure?)
            ErrorState(
              message: failureText(l10n, failure),
              actionKey: const Key('coach-athlete-error'),
            ),
          // Each shared part has its card, paired two by two on a wider window.
          CardGrid(
            key: const Key('coach-athlete-parts'),
            columns: 2,
            tabletColumns: 2,
            children: [
              if (c.plan case final plan?) _CoachPlanCard(plan: plan),
              if (c.training case final training?) ...[
                TrainingSummary(
                  training: training,
                  days: c.days,
                  onDays: (days) => ref
                      .read(
                        coachAthleteViewModelProvider(clubId, userId).notifier,
                      )
                      .setDays(days),
                ),
                DailyLoadCard(training: training),
                TrainingLoadCard(training: training),
              ],
              if (c.powerCurve case final curve?)
                PowerSummary(
                  curve: curve,
                  days: c.days,
                  onDays: (days) => ref
                      .read(
                        coachAthleteViewModelProvider(clubId, userId).notifier,
                      )
                      .setDays(days),
                  readOnly: true,
                ),
              if (c.wellbeing case final wellbeing?)
                _CoachWellbeingCard(wellbeing: wellbeing),
              if (summary.sharesRides)
                SectionCard(
                  key: const Key('coach-rides-card'),
                  title: l10n.shareRides,
                  children: [
                    if (c.rides.isEmpty)
                      EmptyState(
                        key: const Key('coach-no-rides'),
                        message: l10n.coachNoRides,
                        icon: Icons.directions_bike,
                      )
                    else
                      Column(
                        children: [
                          for (final ride in c.rides)
                            ListTile(
                              key: Key('coach-ride-${ride.id}'),
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.directions_bike),
                              // The ride's name leads, as the mock-up draws it; the day is the detail.
                              title: Text(rideTitle(l10n, ride)),
                              subtitle: Text(
                                '${DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).format((ride.startTime ?? ride.uploadedAt).toLocal())} · '
                                '${km(units, ride.distanceM)} · '
                                '${duration(ride.movingS)}',
                              ),
                              onTap: () => onOpenRide(ride.id),
                            ),
                        ],
                      ),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The athlete's auto plan for this week: the goal, the hours and one row per planned day. Read-only, with no score:
/// the server sends no score, no make-easy reason and no check-in answer, and logs the look as a "Plan".
class _CoachPlanCard extends StatelessWidget {
  const _CoachPlanCard({required this.plan});

  final CoachPlanResponse plan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final done = plan.sessions
        .where((session) => session.state == 'done' || session.state == 'easy')
        .length;

    return SectionCard(
      key: const Key('coach-plan'),
      title: l10n.coachPlan,
      children: [
        Text(
          [
            trainingGoalName(l10n, plan.goal),
            l10n.trainingHoursLine(plan.hoursPerWeek),
            // A week the planner has not written yet has no count to give.
            if (plan.sessions.isNotEmpty)
              l10n.coachPlanDone(done, plan.sessions.length),
          ].join(' · '),
          key: const Key('coach-plan-summary'),
          style: text.bodyMedium,
        ),
        Column(
          spacing: AppSpacing.xs,
          children: [
            for (final session in plan.sessions)
              _CoachPlanRow(session: session),
          ],
        ),
      ],
    );
  }
}

/// One planned day, as the week's rows read it: [WeekDayRow] with the session's own detail line. A skipped day says why
/// the rides grant carries; a skipped day whose reason is withheld says how long it was, like every other day.
class _CoachPlanRow extends StatelessWidget {
  const _CoachPlanRow({required this.session});

  final CoachPlanSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reason = _coachPlanSkipReason(l10n, session.skipReason);
    final detail = switch (session) {
      CoachPlanSession(state: 'skipped') when reason != null => [
        l10n.trainingStateSkipped,
        lowerFirst(reason),
      ].join(' · '),
      CoachPlanSession(:final riddenMinutes?) => l10n.coachPlanPlannedRidden(
        sessionLength(session.minutes),
        sessionLength(riddenMinutes),
      ),
      _ => sessionLength(session.minutes),
    };

    return WeekDayRow(
      key: Key(
        'coach-plan-${DateFormat('yyyy-MM-dd').format(session.localDate)}',
      ),
      date: session.localDate,
      title: trainingText(
        l10n,
        english: session.englishName,
        italian: session.italianName,
      ),
      detail: detail,
      state: session.state == 'planned'
          ? null
          : sessionStateWord(l10n, session.state),
      tone: session.state == 'done' || session.state == 'easy'
          ? AppBadgeTone.good
          : AppBadgeTone.neutral,
    );
  }
}

/// Why the rider skipped a session, in the coach's own words. Null when the server withheld it, which is the "Ill or
/// injured" case without the wellbeing grant: the row then reads "Skipped" and its length.
String? _coachPlanSkipReason(AppLocalizations l10n, String? reason) =>
    switch (reason) {
      'tired' => l10n.coachPlanSkippedTired,
      'ill' => l10n.coachPlanSkippedIll,
      'no_time' => l10n.coachPlanSkippedNoTime,
      'other' => l10n.coachPlanSkippedOther,
      _ => null,
    };

/// What a coach may see of wellbeing: daily scores and per-ride RPE, never the member's notes.
class _CoachWellbeingCard extends StatelessWidget {
  const _CoachWellbeingCard({required this.wellbeing});

  final CoachWellbeingResponse wellbeing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    String date(DateTime value) => DateFormat.MMMd(locale).format(value);

    return SectionCard(
      key: const Key('coach-wellbeing'),
      title: l10n.coachWellbeing,
      description: l10n.coachWellbeingNoNotes,
      children: [
        if (wellbeing.checkIns.isEmpty && wellbeing.rides.isEmpty)
          Text(l10n.coachWellbeingEmpty, style: text.bodyMedium),
        for (final checkIn in wellbeing.checkIns)
          Text(
            [
              date(checkIn.date),
              '${l10n.wellbeingShortFatigue} ${checkIn.fatigue}',
              '${l10n.wellbeingShortSoreness} ${checkIn.soreness}',
              '${l10n.wellbeingShortMood} ${checkIn.mood}',
              '${l10n.wellbeingShortStress} ${checkIn.stress}',
              '${l10n.wellbeingShortMotivation} ${checkIn.motivation}',
              if (checkIn.sleep.orElse(null) case final sleep?)
                '${l10n.wellbeingShortSleep} $sleep',
            ].join(' · '),
            style: text.bodySmall,
          ),
        for (final ride in wellbeing.rides)
          Text(
            '${date(ride.date)} · ${l10n.wellbeingRpeSaved(ride.rpe)}',
            style: text.bodySmall,
          ),
      ],
    );
  }
}
