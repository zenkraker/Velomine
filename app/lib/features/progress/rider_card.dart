import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/units.dart';
import '../../core/widgets/card_link.dart';
import '../../core/widgets/form_sheet.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/source_note.dart';
import '../../core/widgets/stat_card.dart';
import '../rides/detail/power_record_chips.dart' show recordDuration;
import '../accounts/ftp_source_text.dart';
import '../../l10n/generated/app_localizations.dart';
import '../accounts/heart_rate_source_text.dart';
import 'events.dart';

/// Opens the whole card in a sheet; a best effort the rider taps opens its ride.
Future<void> showRiderCard(BuildContext context, RiderCardResponse card) async {
  final rideId = await showSheet<String>(
    context,
    builder: (_) => RiderCardSheet(card: card),
  );
  if (rideId != null && context.mounted) context.push('/rides/$rideId');
}

/// The same numbers on the page and in the sheet, so both read the same way.
String _watts(int? value) => value == null ? '–' : '$value W';

String _bpm(int? value) => value == null ? '–' : '$value bpm';

/// "5 s", "1 min": the windows the card lists, the way the power curve names them.
String _window(int seconds) =>
    seconds < 60 ? '${seconds}s' : '${seconds ~/ 60}m';

String? _ftpNote(AppLocalizations l10n, RiderCardResponse card) =>
    switch (card.ftpSource) {
      final source? => ftpSourceText(
        l10n,
        source,
        card.ftpSetAt,
        rideDate: card.ftpRideDate,
      ),
      null => null,
    };

/// The rider's own numbers at the top of Progress → Power: only the ones no other card on that page
/// already shows, each with where it came from, and the way to the whole card.
class RiderCard extends StatelessWidget {
  const RiderCard({super.key, required this.card, required this.onMore});

  final RiderCardResponse card;

  /// Opens the whole card in a sheet: every number, with where it came from.
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wPerKg = card.wattsPerKg;
    final weight = card.weightKg;
    final ftp = card.ftpW;
    // The peak is the window it was set in, so the note can name it.
    final peak = card.bests
        .where((best) => best.watts != null)
        .fold<RiderCardBest?>(
          null,
          (best, next) =>
              best == null || next.watts! > best.watts! ? next : best,
        );
    return SectionCard(
      key: const Key('rider-card'),
      title: l10n.riderCardTitle,
      children: [
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.lg,
          children: [
            _Number(
              key: const Key('rider-card-max-hr'),
              label: l10n.maxHeartRateField,
              value: _bpm(card.maxHeartRate),
              note: heartRateSourceText(
                l10n,
                card.maxHeartRateSource,
                card.maxHeartRateSetAt,
                rideDate: card.maxHeartRateRideDate,
                rideId: card.maxHeartRateRideId,
              ),
            ),
            _Number(
              key: const Key('rider-card-threshold-hr'),
              label: l10n.thresholdHeartRateField,
              value: _bpm(card.thresholdHeartRate),
              note: heartRateSourceText(
                l10n,
                card.thresholdHeartRateSource,
                card.thresholdHeartRateSetAt,
                threshold: true,
                rideDate: card.thresholdHeartRateRideDate,
                rideId: card.thresholdHeartRateRideId,
              ),
            ),
            _Number(
              key: const Key('rider-card-wkg'),
              label: l10n.riderCardFtpPerKilo,
              value: wPerKg == null
                  ? '–'
                  : '${NumberFormat('0.0').format(wPerKg)} W/kg',
              note: ftp == null || weight == null
                  ? null
                  : l10n.riderCardFtpAtWeight(ftp, weight),
            ),
            _Number(
              key: const Key('rider-card-peak'),
              label: l10n.riderCardPeak,
              value: _watts(card.peakPowerW),
              note: peak == null
                  ? null
                  : l10n.riderCardPeakNote(recordDuration(l10n, peak.seconds)),
            ),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: CardLink(
            l10n.riderCardWhole,
            key: const Key('rider-card-more'),
            onPressed: onMore,
          ),
        ),
      ],
    );
  }
}

/// One number of the card: its name, its value and the line saying where it came from.
class _Number extends StatelessWidget {
  const _Number({
    super.key,
    required this.label,
    required this.value,
    this.note,
  });

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final note = this.note;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: [
        Text(
          label,
          style: text.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (note != null) SourceNote(note),
      ],
    );
  }
}

/// Every row of the card, each with a line saying where the number came from.
class RiderCardSheet extends ConsumerWidget {
  const RiderCardSheet({super.key, required this.card});

  final RiderCardResponse card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final units = ref.watch(unitsChoiceViewModelProvider);
    final next = card.nextEvent;
    final criticalPower = card.criticalPowerW;
    final wPrimeJ = card.wPrimeJ;
    final peak = card.peakPowerW;
    final efficiency = card.efficiency;
    final thresholdNote = heartRateSourceText(
      l10n,
      card.thresholdHeartRateSource,
      card.thresholdHeartRateSetAt,
      threshold: true,
      rideDate: card.thresholdHeartRateRideDate,
      rideId: card.thresholdHeartRateRideId,
    );
    final maxNote = heartRateSourceText(
      l10n,
      card.maxHeartRateSource,
      card.maxHeartRateSetAt,
      rideDate: card.maxHeartRateRideDate,
      rideId: card.maxHeartRateRideId,
    );

    return SheetFrame(
      title: l10n.riderCardTitle,
      children: [
        _Row(
          key: const Key('rider-card-row-ftp'),
          value: card.wattsPerKg == null
              ? _watts(card.ftpW)
              : '${_watts(card.ftpW)} · '
                    '${NumberFormat('0.0').format(card.wattsPerKg)} W/kg',
          note: _ftpNote(l10n, card),
        ),
        _Row(
          key: const Key('rider-card-row-power'),
          value: criticalPower == null
              ? '–'
              : peak == null
              ? l10n.criticalPowerRow(
                  '$criticalPower',
                  NumberFormat('0.0').format((wPrimeJ ?? 0) / 1000),
                )
              : l10n.criticalPowerRowWithPeak(
                  '$criticalPower',
                  NumberFormat('0.0').format((wPrimeJ ?? 0) / 1000),
                  '$peak',
                ),
          note: criticalPower == null
              ? l10n.criticalPowerUnavailable
              : l10n.riderCardPowerNote,
        ),
        _Row(
          key: const Key('rider-card-row-bests'),
          valueWidget: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              for (final best in card.bests)
                TextButton(
                  key: Key('rider-card-best-${best.seconds}'),
                  onPressed: best.rideId == null
                      ? null
                      : () => Navigator.of(context).pop(best.rideId),
                  child: Text(
                    '${_window(best.seconds)} ${best.watts ?? '–'}'
                    '${best.watts == null ? '' : ' W'}',
                  ),
                ),
            ],
          ),
          note: l10n.riderCardBestsNote,
        ),
        _Row(
          key: const Key('rider-card-row-max-hr'),
          label: l10n.maxHeartRateField,
          value: _bpm(card.maxHeartRate),
          note: maxNote,
        ),
        _Row(
          key: const Key('rider-card-row-threshold-hr'),
          label: l10n.thresholdHeartRateField,
          value: _bpm(card.thresholdHeartRate),
          note: thresholdNote,
        ),
        _Row(
          key: const Key('rider-card-row-efficiency'),
          label: l10n.statEfficiency,
          value: switch (efficiency) {
            [] => '–',
            [final only] => NumberFormat('0.00').format(only.efficiencyFactor),
            [final first, ...] =>
              '${NumberFormat('0.00').format(first.efficiencyFactor)} → ${NumberFormat('0.00').format(efficiency.last.efficiencyFactor)}',
          },
          note: l10n.riderCardEfficiencyNote,
        ),
        _Row(
          key: const Key('rider-card-row-totals'),
          valueWidget: Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.sm,
            children: [
              StatFigure(label: l10n.statRides, value: '${card.rides}'),
              StatFigure(
                label: l10n.statMovingTime,
                value: duration(card.movingS),
              ),
              StatFigure(
                label: l10n.statDistance,
                value: km(units, card.distanceM),
              ),
              StatFigure(
                label: l10n.statClimbing,
                value: elevation(units, card.elevationGainM),
              ),
            ],
          ),
          note: l10n.riderCardTotalsNote,
        ),
        _Row(
          key: const Key('rider-card-row-form'),
          label: l10n.fitnessFatigueForm,
          value: [card.fitness, card.fatigue, card.form]
              .map((value) => value == null ? '–' : '${value.round()}')
              .join(' · '),
          note: l10n.riderCardEffortNote,
        ),
        _Row(
          key: const Key('rider-card-row-event'),
          value: next == null
              ? '–'
              : l10n.eventNext(next.name, daysAway(l10n, next.date)),
          note: l10n.riderCardEventNote,
        ),
      ],
    );
  }
}

/// One row of the full card: an optional name, the number, and where it came from.
class _Row extends StatelessWidget {
  const _Row({super.key, this.label, this.value, this.valueWidget, this.note});

  final String? label;
  final String? value;
  final Widget? valueWidget;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final note = this.note;
    final label = this.label;
    final value = this.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: [
        if (label != null)
          Text(
            label,
            style: text.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        if (valueWidget != null)
          valueWidget!
        else
          Text(
            value ?? '–',
            style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        if (note != null) SourceNote(note),
      ],
    );
  }
}
