import '../../core/widgets/loading_state.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../rides/ride_title.dart';
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
          // What the athlete shares, in the design's order, right under their name.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (summary.sharesRides)
                AppBadge(l10n.sharesRides, tone: AppBadgeTone.good),
              if (summary.sharesAnalytics)
                AppBadge(l10n.sharesTraining, tone: AppBadgeTone.good),
              if (summary.sharesWellbeing)
                AppBadge(l10n.sharesWellbeing, tone: AppBadgeTone.good),
              if (summary.sharesRoutes)
                AppBadge(l10n.sharesRoutes, tone: AppBadgeTone.good),
            ],
          ),
          if (c.load.failure case final failure?)
            ErrorState(
              message: failureText(l10n, failure),
              actionKey: const Key('coach-athlete-error'),
            ),
          // The design's cards only: this week's plan, the shared rides, then the wellbeing scores. Read-only.
          CardGrid(
            key: const Key('coach-athlete-parts'),
            columns: 2,
            tabletColumns: 2,
            children: [
              if (c.plan case final plan?) _CoachPlanCard(plan: plan),
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
                        framed: false,
                      )
                    else
                      Column(
                        children: [
                          for (final (i, ride) in c.rides.indexed) ...[
                            if (i > 0) const Divider(),
                            _CoachRideRow(
                              ride: ride,
                              units: units,
                              onTap: () => onOpenRide(ride.id),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              if (c.wellbeing case final wellbeing?)
                _CoachWellbeingCard(wellbeing: wellbeing),
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

/// Why the rider skipped a session, in the words the rider's own picker offered, so a reason is spelled the same on
/// both screens. Null when the server withheld it, which is the "Ill or injured" case without the wellbeing grant: the
/// row then reads "Skipped" and its length.
String? _coachPlanSkipReason(AppLocalizations l10n, String? reason) =>
    reason == null ? null : trainingSkipReason(l10n, reason);

/// One shared ride as the mock-up's row: the ride's name over its day, distance and time.
class _CoachRideRow extends StatelessWidget {
  const _CoachRideRow({
    required this.ride,
    required this.units,
    required this.onTap,
  });

  final RideResponse ride;
  final Units units;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return ListTile(
      key: Key('coach-ride-${ride.id}'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.directions_bike),
      title: Text(
        rideTitle(l10n, ride),
        style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          DateFormat.MMMd(locale)
              .format((ride.startTime ?? ride.uploadedAt).toLocal()),
          km(units, ride.distanceM),
          duration(ride.movingS),
        ].join(' · '),
        style: text.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// What a coach may see of wellbeing: daily scores and per-ride RPE, never the member's notes, as the mock-up's
/// table draws them.
class _CoachWellbeingCard extends StatelessWidget {
  const _CoachWellbeingCard({required this.wellbeing});

  final CoachWellbeingResponse wellbeing;

  /// A cell that carries no value: the day has no check-in, or no ride of its own.
  static const _none = '–';

  static const _dayWidth = 88.0;
  static const _numberWidth = 56.0;
  static const _rpeWidth = 96.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final locale = Localizations.localeOf(context).toLanguageTag();
    final heads = [
      l10n.dayUnit,
      l10n.wellbeingFatigue,
      l10n.wellbeingSoreness,
      l10n.wellbeingMood,
      l10n.readinessFactorRpe,
    ];
    final rpeByDay = {
      for (final ride in wellbeing.rides) _dayOf(ride.date): ride.rpe,
    };
    final checkInByDay = {
      for (final checkIn in wellbeing.checkIns) _dayOf(checkIn.date): checkIn,
    };
    // Newest first, one row a day, whether it holds a check-in, an RPE, or both.
    final days = {...rpeByDay.keys, ...checkInByDay.keys}.toList()
      ..sort((a, b) => b.compareTo(a));

    Widget cell(String value, double width, {bool mutedText = false}) =>
        SizedBox(
          width: width,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: mutedText ? muted : text.bodySmall,
          ),
        );

    return SectionCard(
      key: const Key('coach-wellbeing'),
      title: l10n.coachWellbeing,
      description: l10n.coachWellbeingNoNotes,
      children: [
        if (days.isEmpty)
          Text(
            l10n.coachWellbeingEmpty,
            key: const Key('coach-wellbeing-empty'),
            style: text.bodyMedium,
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: _dayWidth,
                      child: Text(heads.first, style: text.labelSmall),
                    ),
                    for (final head in heads.skip(1).take(3))
                      cell(head, _numberWidth, mutedText: true),
                    cell(heads.last, _rpeWidth, mutedText: true),
                  ],
                ),
                const Divider(),
                for (final day in days)
                  Padding(
                    key: Key('coach-wellbeing-$day'),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: _dayWidth,
                          child: Text(
                            DateFormat.MMMd(locale).format(day),
                            style: text.bodySmall,
                          ),
                        ),
                        cell(
                          checkInByDay[day]?.fatigue.toString() ?? _none,
                          _numberWidth,
                        ),
                        cell(
                          checkInByDay[day]?.soreness.toString() ?? _none,
                          _numberWidth,
                        ),
                        cell(
                          checkInByDay[day]?.mood.toString() ?? _none,
                          _numberWidth,
                        ),
                        cell(
                          rpeByDay[day] == null
                              ? _none
                              : l10n.wellbeingRpeSaved(rpeByDay[day]!),
                          _rpeWidth,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The calendar day of a server date, without the time: both the scores and the RPE are kept a day at a time.
DateTime _dayOf(DateTime value) => DateTime(value.year, value.month, value.day);
