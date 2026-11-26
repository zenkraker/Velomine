import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../accounts/ftp_source_text.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/placeholder_block.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/units.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/card_link.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/segmented_control.dart';
import '../../core/widgets/stat_card.dart';
import '../rides/ride_type_chips.dart';
import '../training/training_text.dart';
import '../training/training_view_model.dart' as auto_training;
import 'events.dart';
import 'progress_filter_sheet.dart';
import 'progress_tabs.dart';
import 'progress_view_models.dart';
import 'totals_chart.dart';

/// Where the FTP the power curve was read with came from, for its source note. [rideDate] is the day
/// of the ride a test FTP came from, which the history row's own `setAt` is not.
String? ftpSourceNote(
  AppLocalizations l10n,
  List<FtpHistoryEntry> history, {
  DateTime? rideDate,
}) {
  final newest = history.firstOrNull;
  if (newest == null) return null;
  return ftpSourceText(l10n, newest.source_, newest.setAt, rideDate: rideDate);
}

/// Progress: one overview that answers "how am I today and this week?" and opens the page that answers
/// the next question. The deep charts live on the four sub-pages; a training rider keeps the analysis
/// here, behind one fold for a simple mode.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filters = ref.watch(progressFiltersViewModelProvider);
    final totals = ref.watch(totalsViewModelProvider);
    final training = ref.watch(trainingViewModelProvider);
    // The auto-training week behind the Today strip, which is there only while the rider turned it on.
    final plan = ref.watch(auto_training.trainingViewModelProvider);
    final autoTraining =
        plan.on &&
        (ref.watch(sessionProvider).serverInfo?.autoTrainingEnabled ?? false);
    final todayWeek = autoTraining ? plan.thisWeek : null;
    final readiness = ref.watch(readinessViewModelProvider);
    final events = ref.watch(eventsViewModelProvider);
    final units = ref.watch(unitsChoiceViewModelProvider);
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoint.compactWidth;

    // Every card on the page says so when its own number did not arrive.
    final failures = [
      totals.load.failure,
      training.load.failure,
      readiness.load.failure,
    ].whereType<Failure>();

    // The period, in the gender the language needs: "Questa settimana", "Questo mese", "Quest'anno".
    final thisPeriod = switch (filters.period) {
      'week' => l10n.thisWeek,
      'month' => l10n.thisMonth,
      _ => l10n.thisYear,
    };
    final weeks = totals.load.value?.totals ?? const <PeriodTotals>[];
    final latestWeek = weeks.isEmpty ? null : weeks.last;
    final earlier = weeks.length > 1
        ? weeks.sublist(0, weeks.length - 1)
        : const <PeriodTotals>[];
    final averageM = earlier.isEmpty
        ? null
        : earlier.map((week) => week.distanceM).reduce((a, b) => a + b) /
              earlier.length;

    final readinessCard = switch (readiness.load.value) {
      // No score yet is a fact the card carries: a dash and what makes one appear, not a hole in the row.
      final r? when r.score == null => StatCard(
        key: const Key('metric-readiness'),
        title: l10n.readiness,
        value: '–',
        sentence: l10n.readinessNoData,
        link: l10n.wellbeing,
        onLink: () => context.go('/progress/wellbeing'),
      ),
      final r? => StatCard(
        key: const Key('metric-readiness'),
        title: l10n.readiness,
        value: '${r.score}',
        state: switch (r.band) {
          'hard' => l10n.readinessHard,
          'easy' => l10n.readinessEasy,
          'rest' => l10n.readinessRest,
          _ => l10n.readinessNormal,
        },
        stateCare: r.band == 'easy' || r.band == 'rest',
        sentence: switch (r.band) {
          'hard' => l10n.readinessAdviceHard,
          'easy' => l10n.readinessAdviceEasy,
          'rest' => l10n.readinessAdviceRest,
          _ => l10n.readinessAdviceNormal,
        },
        link: l10n.wellbeing,
        onLink: () => context.go('/progress/wellbeing'),
      ),
      null => null,
    };
    final formCard = switch (training.load.value) {
      final t? when t.days.isNotEmpty => StatCard(
        key: const Key('metric-form'),
        title: l10n.form,
        value: t.days.last.form.round().toString(),
        // The design's state word for a form under load.
        state: l10n.formStateBuilding,
        sentence: l10n.formFitnessFatigue(
          t.days.last.fitness.round(),
          t.days.last.fatigue.round(),
        ),
        // Two side by side on a phone: smaller number, no link, the card itself opens the page.
        compact: !wide,
        onTap: wide ? null : () => context.go('/progress/fitness'),
        link: wide ? l10n.fitness : null,
        onLink: wide ? () => context.go('/progress/fitness') : null,
      ),
      // A rider with no load in the range gets the card's empty state, not a hole in the row.
      _? => StatCard(
        key: const Key('metric-form'),
        title: l10n.form,
        value: '–',
        sentence: l10n.dailyLoadEmpty,
        compact: !wide,
        onTap: wide ? null : () => context.go('/progress/fitness'),
        link: wide ? l10n.fitness : null,
        onLink: wide ? () => context.go('/progress/fitness') : null,
      ),
      null => null,
    };
    // The week's distance against the recent average; two across on a phone it keeps its size down
    // and hands the tap to the whole card.
    StatCard? periodCard({required bool compact}) => switch (latestWeek) {
      final week? => StatCard(
        key: const Key('metric-period'),
        title: thisPeriod,
        value: distanceParts(units, week.distanceM).value,
        unit: distanceParts(units, week.distanceM).unit,
        // The sentence keeps the rides and the time the week took: the average alone does not say how
        // much riding it stands for.
        sentence: averageM == null
            ? l10n.periodTotals(
                week.rides,
                duration(week.movingS),
                elevation(units, week.elevationGainM),
              )
            : '${l10n.goalRideCount(week.rides)}, ${duration(week.movingS)}. '
                  '${l10n.weekAgainstAverage(week.distanceM > averageM
                      ? 'above'
                      : week.distanceM < averageM
                      ? 'below'
                      : 'other', km(units, averageM))}',
        compact: compact,
        onTap: compact ? () => context.go('/progress/totals') : null,
        link: compact ? null : l10n.navTotals,
        onLink: compact ? null : () => context.go('/progress/totals'),
      ),
      // Nothing ridden yet is a fact too: the card says so instead of leaving a hole. While the totals
      // are still on their way the page waits rather than claiming there are none.
      null when !totals.load.running => StatCard(
        key: const Key('metric-period'),
        title: thisPeriod,
        value: '–',
        sentence: l10n.totalsEmpty,
        compact: compact,
        onTap: compact ? () => context.go('/progress/totals') : null,
        link: compact ? null : l10n.navTotals,
        onLink: compact ? null : () => context.go('/progress/totals'),
      ),
      null => null,
    };
    final nextCard = _NextEventCard(next: events.next);
    final metrics = <Widget>[
      ?readinessCard,
      ?formCard,
      ?periodCard(compact: false),
      nextCard,
    ];

    final periods = SegmentedControl<String>(
      buttonKey: const Key('progress-period'),
      segments: [
        ButtonSegment(value: 'week', label: Text(l10n.periodWeeks)),
        ButtonSegment(value: 'month', label: Text(l10n.periodMonths)),
        ButtonSegment(value: 'year', label: Text(l10n.periodYears)),
      ],
      selected: filters.period,
      onChanged: (period) =>
          ref.read(progressFiltersViewModelProvider.notifier).setPeriod(period),
    );

    return PageScaffold(
      title: l10n.navProgress,
      subtitle: l10n.progressSubtitle,
      // No `⋯` menu: its one entry was the sport filter, which the chips below and the phone's title
      // chip already draw.
      // A phone chooses the sport from one chip in the title row; a wide window has the chips below.
      primaryAction: wide
          ? null
          : ActionChip(
              key: const Key('progress-filter-chip'),
              avatar: const Icon(Icons.expand_more, size: 18),
              label: Text(
                filters.discipline == null
                    ? l10n.rideFilterAll
                    : disciplineName(l10n, filters.discipline!),
              ),
              onPressed: () => showProgressFilterSheet(context),
            ),
      children: [
        // A phone has nowhere else for the sub-pages; from 600 dp the rail or the sidebar has them.
        if (!wide) ProgressTabs(location: '/progress'),
        if (failures.isNotEmpty)
          ErrorState(
            message: failureText(l10n, failures.first),
            // Retry reloads every number that failed, not only the chart's.
            onRetry: () {
              if (totals.load.failure != null) {
                ref.read(totalsViewModelProvider.notifier).load();
              }
              if (training.load.failure != null) {
                ref.read(trainingViewModelProvider.notifier).load();
              }
              if (readiness.load.failure != null) {
                ref.read(readinessViewModelProvider.notifier).load();
              }
            },
            actionKey: const Key('progress-error'),
          ),
        // A wide window chooses the sport with the chips on the page; a phone opens the same choice in
        // one chip in the title row, because five chips would take the top of the screen.
        if (wide) ...[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              FilterChip(
                key: const Key('progress-filter-all'),
                label: Text(l10n.rideFilterAll),
                selected: filters.discipline == null,
                onSelected: (_) => ref
                    .read(progressFiltersViewModelProvider.notifier)
                    .setDiscipline(null),
              ),
              for (final discipline in ['road', 'gravel', 'mountain', 'track'])
                FilterChip(
                  key: Key('progress-filter-$discipline'),
                  label: Text(disciplineName(l10n, discipline)),
                  selected: filters.discipline == discipline,
                  onSelected: (_) => ref
                      .read(progressFiltersViewModelProvider.notifier)
                      .setDiscipline(discipline),
                ),
            ],
          ),
        ],
        // Under the chips: today's session, a link to Training, and only while auto training is on.
        if (todayWeek != null) _TodayTrainingStrip(week: todayWeek),
        // A wide window puts the four facts in one row; a phone leads with readiness, puts Form and this
        // period side by side under it and ends with the next event, as the phone mock-up draws them.
        if (wide)
          StatCardRow(children: metrics)
        else ...[
          ?readinessCard,
          if (formCard != null && periodCard(compact: true) != null)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.lg,
                children: [
                  Expanded(child: formCard),
                  Expanded(child: periodCard(compact: true)!),
                ],
              ),
            )
          else ...[
            ?formCard,
            ?periodCard(compact: true),
          ],
          nextCard,
        ],
        // The chart's own loading state: the page is not empty while the totals arrive.
        if (totals.load.running && totals.load.value == null)
          Semantics(
            liveRegion: true,
            label: l10n.loading,
            child: const PlaceholderBlock(
              key: Key('totals-loading'),
              height: AppChart.height,
              radius: AppRadius.large,
            ),
          ),
        if (totals.load.value case final data?)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(switch (data.period) {
                      'week' => l10n.totalsTitleWeekly,
                      'month' => l10n.totalsTitleMonthly,
                      _ => l10n.totalsTitleYearly,
                    }, style: Theme.of(context).textTheme.titleMedium),
                    periods,
                  ],
                ),
                TotalsChart(period: data.period, totals: data.totals),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: CardLink(
                    l10n.navTotals,
                    key: const Key('progress-totals-link'),
                    onPressed: () => context.go('/progress/totals'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Days to the next event, and which event it is. With nothing planned it says so and still leads to
/// Goals, which is where an event is added.
class _NextEventCard extends ConsumerWidget {
  const _NextEventCard({required this.next});

  final EventResponse? next;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final units = ref.watch(unitsChoiceViewModelProvider);
    final event = next;
    if (event == null) {
      return StatCard(
        key: const Key('metric-next-event'),
        title: l10n.nextEvent,
        value: '–',
        sentence: l10n.noEventPlanned,
        link: l10n.navGoalsAndEvents,
        onLink: () => context.go('/goals'),
      );
    }
    final days = DateUtils.dateOnly(event.date)
        .difference(DateUtils.dateOnly(DateTime.now()))
        .inDays;
    return StatCard(
      key: const Key('metric-next-event'),
      title: l10n.nextEvent,
      value: days <= 0 ? l10n.eventToday : '$days',
      unit: days <= 0 ? null : (days == 1 ? l10n.dayUnit : l10n.daysUnit),
      sentence:
          '${event.name} · ${DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag()).format(event.date)}'
          '${eventDetail(l10n, units, event).isEmpty ? '' : ' · ${eventDetail(l10n, units, event)}'}',
      link: l10n.navGoalsAndEvents,
      onLink: () => context.go('/goals'),
    );
  }
}

/// Today's session as one slim line: "Today · Strong and steady 3×10 · 1 h 15", linking to Training. It is a link,
/// not a fact card, and it is not there while auto training is off.
class _TodayTrainingStrip extends StatelessWidget {
  const _TodayTrainingStrip({required this.week});

  final TrainingWeek week;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = VelomineColors.of(context);
    final today = DateUtils.dateOnly(DateTime.now());
    final session = week.sessions
        .where((session) => DateUtils.isSameDay(session.localDate, today))
        .firstOrNull;
    return AppCard(
      key: const Key('progress-today-training'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      onTap: () => context.go('/training'),
      child: Row(
        spacing: AppSpacing.md,
        children: [
          Expanded(
            child: Text(
              l10n.trainingTodayStrip(
                session == null
                    ? l10n.trainingRestDay
                    : '${sessionName(l10n, session)} · ${sessionLength(session.minutes)}',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            l10n.navTraining,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.accentStrong,
              fontWeight: FontWeight.w600,
            ),
          ),
          ExcludeSemantics(
            child: Icon(
              Icons.arrow_forward,
              size: AppTraining.stripIcon,
              color: palette.accentStrong,
            ),
          ),
        ],
      ),
    );
  }
}
