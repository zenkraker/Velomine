import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../../core/format.dart';
import '../../../core/l10n.dart';
import 'lap_range.dart';

/// The ride's laps as a compact table. Tapping a lap highlights its range on every chart and the map.
class LapTable extends StatelessWidget {
  const LapTable({super.key, required this.laps, required this.selectedLap});

  final List<LapResponse> laps;
  final ValueNotifier<LapRange?> selectedLap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    Widget cell(String value, {double? width}) => width == null
        ? Expanded(child: Text(value, style: text.bodySmall))
        : SizedBox(
            width: width,
            child: Text(value, style: text.bodySmall),
          );

    return Card(
      key: const Key('laps'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.lapsTitle, style: text.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                cell(l10n.lap, width: 64),
                cell(l10n.statMovingTime),
                cell(l10n.statDistance),
                cell(l10n.statAverageSpeed),
                cell(l10n.statAveragePower),
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
                            cell('${l10n.lap} ${lap.index}', width: 64),
                            cell(duration(lap.movingS)),
                            cell(km(lap.distanceM)),
                            cell(kmh(lap.avgSpeedMs)),
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
      ),
    );
  }
}
