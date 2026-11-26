import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../../core/format.dart';
import '../../../core/l10n.dart';
import 'lap_range.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/units.dart';

/// The ride's laps as a compact table. Tapping a lap highlights its range on every chart and the map.
///
/// The columns are the mock-up's: the lap, then distance, moving time and average power, each number at the
/// end of its column. Its caption row is a size under the numbers (`docs/design/pages/rides/RideDetailPage.html`).
class LapTable extends ConsumerWidget {
  const LapTable({super.key, required this.laps, required this.selectedLap});

  final List<LapResponse> laps;
  final ValueNotifier<LapRange?> selectedLap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final units = ref.watch(unitsChoiceViewModelProvider);
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget head(String label) => Expanded(
      child: Text(
        label,
        textAlign: TextAlign.right,
        style: text.bodySmall?.copyWith(color: muted),
      ),
    );
    Widget cell(String value) => Expanded(
      child: Text(value, textAlign: TextAlign.right, style: text.bodyMedium),
    );

    return SectionCard(
      key: const Key('laps'),
      title: l10n.lapsTitle,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.lap,
                    style: text.bodySmall?.copyWith(color: muted),
                  ),
                ),
                head(l10n.statDistance),
                head(l10n.statMovingTime),
                head(l10n.statAveragePower),
              ],
            ),
            const Divider(height: 12),
            ValueListenableBuilder<LapRange?>(
              valueListenable: selectedLap,
              builder: (context, range, _) => Column(
                children: [
                  for (final lap in laps)
                    InkWell(
                      key: Key(
                        range?.startS == lap.startS
                            ? 'lap-${lap.index}-selected'
                            : 'lap-${lap.index}',
                      ),
                      onTap: () =>
                          selectedLap.value = LapRange(lap.startS, lap.endS),
                      child: Container(
                        color: range?.startS == lap.startS
                            ? Theme.of(context).colorScheme.secondaryContainer
                            : null,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${lap.index}',
                                style: text.bodyMedium,
                              ),
                            ),
                            cell(km(units, lap.distanceM)),
                            cell(duration(lap.movingS)),
                            cell(
                              lap.avgPowerW == null
                                  ? '–'
                                  : '${lap.avgPowerW} W',
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
