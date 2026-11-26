import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/widgets/form_sheet.dart';
import '../../core/widgets/segmented_control.dart';
import '../rides/ride_type_chips.dart';
import 'progress_view_models.dart';

/// The period and the sport, in one sheet, applied as they are chosen: the sport decides every number
/// on every Progress page.
Future<void> showProgressFilterSheet(BuildContext context) =>
    showSheet(context, builder: (_) => const ProgressFilterSheet());

/// The filters themselves. A wide window shows the same controls on the page.
class ProgressFilterSheet extends ConsumerWidget {
  const ProgressFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(progressFiltersViewModelProvider);
    final notifier = ref.read(progressFiltersViewModelProvider.notifier);
    final l10n = context.l10n;
    return SheetFrame(
      title: l10n.progressFilterTitle,
      children: [
        SegmentedControl<String>(
          buttonKey: const Key('progress-period'),
          segments: [
            ButtonSegment(value: 'week', label: Text(l10n.periodWeeks)),
            ButtonSegment(value: 'month', label: Text(l10n.periodMonths)),
            ButtonSegment(value: 'year', label: Text(l10n.periodYears)),
          ],
          selected: filters.period,
          onChanged: notifier.setPeriod,
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            FilterChip(
              key: const Key('progress-filter-all'),
              label: Text(l10n.rideFilterAll),
              selected: filters.discipline == null,
              onSelected: (_) => notifier.setDiscipline(null),
            ),
            for (final discipline in ['road', 'gravel', 'mountain', 'track'])
              FilterChip(
                key: Key('progress-filter-$discipline'),
                label: Text(disciplineName(l10n, discipline)),
                selected: filters.discipline == discipline,
                onSelected: (_) => notifier.setDiscipline(discipline),
              ),
          ],
        ),
      ],
    );
  }
}
