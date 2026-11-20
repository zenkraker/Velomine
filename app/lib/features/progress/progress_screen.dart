import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/placeholder_block.dart';
import '../../core/tokens.dart';
import '../../core/units.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/segmented_control.dart';
import '../../core/widgets/stat_card.dart';
import '../rides/ride_type_chips.dart';
import 'events.dart';
import 'progress_filter_sheet.dart';
import 'progress_tabs.dart';
import 'progress_view_models.dart';
import 'totals_chart.dart';

/// Progress: one overview that answers "how am I today and this week?" and opens the page that answers
/// the next question. The deep charts live on the four sub-pages, so this one fits in a screen.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filters = ref.watch(progressFiltersViewModelProvider);
    final totals = ref.watch(totalsViewModelProvider);
    final training = ref.watch(trainingViewModelProvider);
    final readiness = ref.watch(readinessViewModelProvider);
    final events = ref.watch(eventsViewModelProvider);
    final units = ref.watch(unitsChoiceViewModelProvider);
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoint.compactWidth;

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
      final r? => StatCard(
        key: const Key('metric-readiness'),
        title: l10n.readiness,
        value: r.score == null ? '–' : '${r.score}',
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
        sentence: l10n.formFitnessFatigue(
          t.days.last.fitness.round(),
          t.days.last.fatigue.round(),
        ),
        link: l10n.fitness,
        onLink: () => context.go('/progress/fitness'),
      ),
      _ => null,
    };
    final periodCard = switch (latestWeek) {
      final week? => StatCard(
        key: const Key('metric-period'),
        title: thisPeriod,
        value: distanceParts(units, week.distanceM).value,
        unit: distanceParts(units, week.distanceM).unit,
        sentence: averageM == null
            ? l10n.periodTotals(
                week.rides,
                duration(week.movingS),
                elevation(units, week.elevationGainM),
              )
            : l10n.weekAgainstAverage(
                week.distanceM > averageM
                    ? 'above'
                    : week.distanceM < averageM
                    ? 'below'
                    : 'other',
                km(units, averageM),
              ),
        link: l10n.navTotals,
        onLink: () => context.go('/progress/totals'),
      ),
      null => null,
    };
    final nextCard = _NextEventCard(next: events.next);
    final metrics = <Widget>[?readinessCard, ?formCard, ?periodCard, nextCard];

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

    final menu = PageMenu(
      buttonKey: const Key('progress-actions'),
      badge: filters.discipline != null,
      entries: [
        PageMenuEntry(
          key: const Key('progress-filter'),
          icon: Icons.filter_list,
          label: l10n.progressFilterTitle,
          onSelected: () => showProgressFilterSheet(context),
        ),
      ],
    );

    return PageScaffold(
      title: l10n.navProgress,
      subtitle: l10n.progressSubtitle,
      menu: menu,
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
        // one chip, because five chips would take the top of the screen.
        if (wide)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              ChoiceChip(
                key: const Key('progress-filter-all'),
                label: Text(l10n.rideFilterAll),
                selected: filters.discipline == null,
                onSelected: (_) => ref
                    .read(progressFiltersViewModelProvider.notifier)
                    .setDiscipline(null),
              ),
              for (final discipline in ['road', 'gravel', 'mountain', 'track'])
                ChoiceChip(
                  key: Key('progress-filter-$discipline'),
                  label: Text(disciplineName(l10n, discipline)),
                  selected: filters.discipline == discipline,
                  onSelected: (_) => ref
                      .read(progressFiltersViewModelProvider.notifier)
                      .setDiscipline(discipline),
                ),
            ],
          )
        else
          Row(
            children: [
              ActionChip(
                key: const Key('progress-filter-chip'),
                avatar: const Icon(Icons.expand_more, size: 18),
                label: Text(
                  filters.discipline == null
                      ? l10n.rideFilterAll
                      : disciplineName(l10n, filters.discipline!),
                ),
                onPressed: () => showProgressFilterSheet(context),
              ),
            ],
          ),
        // A wide window puts the four facts in one row; a phone leads with readiness, puts Form and this
        // period side by side under it and ends with the next event, as the phone mock-up draws them.
        if (wide)
          StatCardRow(children: metrics)
        else ...[
          ?readinessCard,
          if (formCard != null && periodCard != null)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.lg,
                children: [
                  Expanded(child: formCard),
                  Expanded(child: periodCard),
                ],
              ),
            )
          else ...[
            ?formCard,
            ?periodCard,
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
              height: 180,
              radius: 16,
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
