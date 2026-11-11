import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import 'rides_state.dart';

/// The search field and the date range button above the ride list. The text stays in this widget while
/// the member types; the list is asked once they pause, so a word is not searched letter by letter.
class RideFilters extends StatefulWidget {
  const RideFilters({
    super.key,
    required this.query,
    required this.dateRange,
    required this.onQuery,
    required this.onDateRange,
  });

  /// The words the list is filtered by now.
  final String query;
  final DateSpan? dateRange;
  final ValueChanged<String> onQuery;
  final ValueChanged<DateSpan?> onDateRange;

  @override
  State<RideFilters> createState() => _RideFiltersState();
}

class _RideFiltersState extends State<RideFilters> {
  static const _pause = Duration(milliseconds: 400);

  late final TextEditingController _controller = TextEditingController(
    text: widget.query,
  );
  Timer? _timer;

  @override
  void didUpdateWidget(RideFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    // "Clear filters" empties the field from outside.
    if (widget.query != oldWidget.query &&
        widget.query != _controller.text.trim()) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _typed(String value) {
    _timer?.cancel();
    _timer = Timer(_pause, () => widget.onQuery(value));
    setState(() {});
  }

  void _submitted(String value) {
    _timer?.cancel();
    widget.onQuery(value);
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    widget.onQuery('');
    setState(() {});
  }

  Future<void> _pickDates() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final current = widget.dateRange;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today,
      initialDateRange: current == null
          ? null
          : DateTimeRange(start: current.from, end: current.to),
    );
    if (picked == null || !mounted) return;
    widget.onDateRange((from: picked.start, to: picked.end));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final range = widget.dateRange;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Row(
          spacing: AppSpacing.sm,
          children: [
            Expanded(
              child: TextField(
                key: const Key('ride-search'),
                controller: _controller,
                textInputAction: TextInputAction.search,
                onChanged: _typed,
                onSubmitted: _submitted,
                decoration: InputDecoration(
                  labelText: l10n.rideFilterSearch,
                  hintText: l10n.rideFilterSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          key: const Key('ride-search-clear'),
                          tooltip: l10n.rideFilterClearSearch,
                          onPressed: _clear,
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            IconButton.filledTonal(
              key: const Key('ride-dates'),
              tooltip: l10n.rideFilterDatesTooltip,
              onPressed: _pickDates,
              icon: const Icon(Icons.date_range),
            ),
          ],
        ),
        if (range != null)
          InputChip(
            key: const Key('ride-dates-chip'),
            label: Text(
              l10n.rideDateRange(dateOnly(range.from), dateOnly(range.to)),
            ),
            deleteButtonTooltipMessage: l10n.rideFilterRemoveDates,
            onPressed: _pickDates,
            onDeleted: () => widget.onDateRange(null),
          ),
      ],
    );
  }
}
