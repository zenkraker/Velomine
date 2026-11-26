import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/units.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/segmented_control.dart';
import 'progress_filter_sheet.dart';
import 'progress_tabs.dart';
import 'progress_view_models.dart';
import 'totals_chart.dart';

/// How many rows the table lists before the rest wait behind "Show earlier".
const _totalsShown = 8;

/// Progress → Totals answers "What did I do each week, month and year?": one chart of the chosen
/// measure with its average, and one table under it.
class TotalsScreen extends ConsumerStatefulWidget {
  const TotalsScreen({super.key});

  @override
  ConsumerState<TotalsScreen> createState() => _TotalsScreenState();
}

class _TotalsScreenState extends ConsumerState<TotalsScreen> {
  /// The measure the chart counts. It belongs to the page, not the account: nothing else reads it.
  TotalsMeasure _measure = TotalsMeasure.distance;
  bool _showEarlier = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filters = ref.watch(progressFiltersViewModelProvider);
    final totals = ref.watch(totalsViewModelProvider);
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoint.compactWidth;
    final failure = totals.load.failure;

    return PageScaffold(
      title: l10n.navTotals,
      parent: l10n.navProgress,
      menu: PageMenu(
        buttonKey: const Key('totals-actions'),
        badge: filters.discipline != null,
        entries: [
          PageMenuEntry(
            key: const Key('totals-filter'),
            icon: Icons.filter_list,
            label: l10n.progressFilterTitle,
            onSelected: () => showProgressFilterSheet(context),
          ),
        ],
      ),
      children: [
        if (!wide) ProgressTabs(location: '/progress/totals'),
        if (failure != null)
          ErrorState(
            message: failureText(l10n, failure),
            onRetry: ref.read(totalsViewModelProvider.notifier).load,
            actionKey: const Key('totals-error'),
          ),
        if (totals.load.value case final data?)
          _TotalsCard(
            totals: data,
            measure: _measure,
            onMeasure: (measure) => setState(() => _measure = measure),
            period: SegmentedControl<String>(
              buttonKey: const Key('totals-period'),
              segments: [
                ButtonSegment(value: 'week', label: Text(l10n.periodWeeks)),
                ButtonSegment(value: 'month', label: Text(l10n.periodMonths)),
                ButtonSegment(value: 'year', label: Text(l10n.periodYears)),
              ],
              selected: filters.period,
              onChanged: (period) => ref
                  .read(progressFiltersViewModelProvider.notifier)
                  .setPeriod(period),
            ),
          ),
        if (totals.load.value case final data?)
          _TotalsTable(
            totals: data,
            showEarlier: _showEarlier,
            onShowEarlier: () => setState(() => _showEarlier = true),
          ),
      ],
    );
  }
}

/// The chosen measure per period: its name, its period control, the measure control and the chart.
class _TotalsCard extends ConsumerWidget {
  const _TotalsCard({
    required this.totals,
    required this.measure,
    required this.onMeasure,
    required this.period,
  });

  final TotalsResponse totals;
  final TotalsMeasure measure;
  final ValueChanged<TotalsMeasure> onMeasure;

  /// The page's own period control, beside the card's title.
  final Widget period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final units = ref.watch(unitsChoiceViewModelProvider);
    final average = totalsAverage(l10n, units, measure, totals.totals);
    final title = switch (measure) {
      TotalsMeasure.distance => switch (totals.period) {
        'week' => l10n.totalsTitleWeekly,
        'month' => l10n.totalsTitleMonthly,
        _ => l10n.totalsTitleYearly,
      },
      TotalsMeasure.time => l10n.goalMetricTime,
      TotalsMeasure.elevation => l10n.statClimbing,
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              period,
              if (average != null)
                Text(
                  average,
                  key: const Key('totals-average'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          SegmentedControl<TotalsMeasure>(
            buttonKey: const Key('totals-measure'),
            segments: [
              ButtonSegment(
                value: TotalsMeasure.distance,
                label: Text(l10n.statDistance),
              ),
              ButtonSegment(
                value: TotalsMeasure.time,
                label: Text(l10n.goalMetricTime),
              ),
              ButtonSegment(
                value: TotalsMeasure.elevation,
                label: Text(l10n.statClimbing),
              ),
            ],
            selected: measure,
            onChanged: onMeasure,
          ),
          TotalsChart(
            period: totals.period,
            totals: totals.totals,
            measure: measure,
          ),
        ],
      ),
    );
  }
}

/// The same totals as the chart, newest first, with every number. A long year stops at the first few
/// rows until the member asks for the earlier ones; the chart still has them all.
/// The periods as a table: one row per period, one column per number, right-aligned so the figures
/// line up, and the current period's row on the accent's soft ground.
class _TotalsTable extends ConsumerWidget {
  const _TotalsTable({
    required this.totals,
    required this.showEarlier,
    required this.onShowEarlier,
  });

  final TotalsResponse totals;
  final bool showEarlier;
  final VoidCallback onShowEarlier;

  /// The width of each column: the period reads long, the numbers stay narrow and right-aligned.
  static const _periodWidth = 140.0;
  static const _ridesWidth = 56.0;
  static const _numberWidth = 96.0;

  /// The table's own width: the columns above and the room either side of them, which is wider than a
  /// phone, so the card scrolls.
  static const _tableWidth =
      _periodWidth + _ridesWidth + _numberWidth * 3 + AppSpacing.xl * 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final units = ref.watch(unitsChoiceViewModelProvider);
    final text = Theme.of(context).textTheme;
    final rows = totals.totals.reversed.toList();
    final shown = showEarlier ? rows : rows.take(_totalsShown).toList();
    final colors = VelomineColors.of(context);
    // The current period is on the accent's soft ground, in the ink that sits on it, like every other
    // accent surface in the app.
    final currentStyle = text.bodySmall?.copyWith(
      color: colors.onAccentSoft,
      fontWeight: FontWeight.w600,
    );

    Widget cell(String value, double width, {TextStyle? style}) => SizedBox(
      width: width,
      child: Text(
        value,
        textAlign: TextAlign.right,
        style: style ?? text.bodySmall,
      ),
    );

    // A period with no rides has no rows to draw: the table says so instead of drawing its heading alone.
    if (rows.isEmpty) {
      return AppCard(
        key: const Key('totals-table'),
        child: EmptyState(message: l10n.totalsEmpty, framed: false),
      );
    }

    return AppCard(
      key: const Key('totals-table'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      // The table is as wide as the card when the card is wider than its columns: the period takes the
      // slack, so the numbers sit at the card's far edge instead of bunched on the left.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = math.max(_tableWidth, constraints.maxWidth);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(switch (totals.period) {
                            // The design's column heading is the period in the singular.
                            'week' => l10n.totalsColumnWeek,
                            'month' => l10n.totalsColumnMonth,
                            _ => l10n.totalsColumnYear,
                          }, style: text.labelSmall),
                        ),
                        cell(l10n.navRides, _ridesWidth),
                        cell(l10n.statDistance, _numberWidth),
                        cell(l10n.statMovingTime, _numberWidth),
                        cell(l10n.statClimbing, _numberWidth),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: tableWidth,
                    height: 1,
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  for (final (i, t) in shown.indexed)
                    Container(
                      key: Key('total-$i'),
                      color: i == 0 ? colors.accentSoft : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              i == 0
                                  ? switch (totals.period) {
                                      'week' => l10n.thisWeek,
                                      'month' => l10n.thisMonth,
                                      _ => l10n.thisYear,
                                    }
                                  : periodTitle(totals.period, t.start, t.end),
                              style: i == 0 ? currentStyle : text.bodySmall,
                            ),
                          ),
                          cell(
                            '${t.rides}',
                            _ridesWidth,
                            style: i == 0 ? currentStyle : null,
                          ),
                          cell(
                            km(units, t.distanceM),
                            _numberWidth,
                            style: i == 0 ? currentStyle : null,
                          ),
                          cell(
                            duration(t.movingS),
                            _numberWidth,
                            style: i == 0 ? currentStyle : null,
                          ),
                          cell(
                            elevation(units, t.elevationGainM),
                            _numberWidth,
                            style: i == 0 ? currentStyle : null,
                          ),
                        ],
                      ),
                    ),
                  if (rows.length > shown.length)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.xs,
                        ),
                        child: TextButton(
                          key: const Key('totals-more'),
                          onPressed: onShowEarlier,
                          child: Text(l10n.totalsShowEarlier),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
