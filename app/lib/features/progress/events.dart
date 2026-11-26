import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/units.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/form_sheet.dart';
import '../../core/widgets/section_card.dart';
import '../../l10n/generated/app_localizations.dart';
import '../rides/ride_title.dart';

const eventKindIds = ['race', 'sportive', 'tour', 'other'];

const _metresPerMile = 1609.344;
const _metresPerFoot = 0.3048;

String eventKindName(AppLocalizations l10n, String kind) => switch (kind) {
  'race' => l10n.eventKindRace,
  'sportive' => l10n.eventKindSportive,
  'tour' => l10n.eventKindTour,
  _ => l10n.eventKindOther,
};

/// "Today", "in 3 days" or "in 3 weeks": how far away an event is, from its date alone.
String daysAway(AppLocalizations l10n, DateTime date) {
  final days = DateUtils.dateOnly(date)
      .difference(DateUtils.dateOnly(DateTime.now()))
      .inDays;
  if (days <= 0) return l10n.eventToday;
  if (days < 7) return l10n.eventInDays(days);
  return l10n.eventInWeeks((days / 7).round());
}

/// What an event is: its kind, its distance and its climbing, when it has them.
String eventDetail(AppLocalizations l10n, Units units, EventResponse event) => [
  eventKindName(l10n, event.kind),
  if (event.distanceM case final distance? when distance > 0)
    km(units, distance),
  if (event.elevationGainM case final climbing? when climbing > 0)
    elevation(units, climbing),
].join(' · ');

/// Asks for a new event, or for the changes to [event]. Returns what the rider typed, or null when cancelled.
Future<EventRequest?> showEventForm(
  BuildContext context, {
  EventResponse? event,
}) => showSheet(context, builder: (_) => EventFormSheet(event: event));

class EventFormSheet extends ConsumerStatefulWidget {
  const EventFormSheet({super.key, this.event});

  final EventResponse? event;

  @override
  ConsumerState<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends ConsumerState<EventFormSheet> {
  late final _name = TextEditingController(text: widget.event?.name);
  late final _distance = TextEditingController(
    text: _plain(
      widget.event?.distanceM == null
          ? null
          : widget.event!.distanceM! /
                (ref.read(unitsChoiceViewModelProvider) == Units.imperial
                    ? _metresPerMile
                    : 1000),
    ),
  );
  late final _climbing = TextEditingController(
    text: _plain(
      widget.event?.elevationGainM == null
          ? null
          : widget.event!.elevationGainM! /
                (ref.read(unitsChoiceViewModelProvider) == Units.imperial
                    ? _metresPerFoot
                    : 1),
    ),
  );
  late final _notes = TextEditingController(text: widget.event?.notes);
  late String _kind = widget.event?.kind ?? 'race';
  late DateTime _date =
      widget.event?.date ?? DateUtils.dateOnly(DateTime.now());
  bool _badName = false;

  static String _plain(double? value) => value == null
      ? ''
      : (value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString());

  @override
  void dispose() {
    _name.dispose();
    _distance.dispose();
    _climbing.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// The number the rider typed in the server's metres; null for an empty or unusable one.
  static double? _metres(TextEditingController controller, double factor) {
    final text = controller.text.trim().replaceAll(',', '.');
    final value = double.tryParse(text);
    return text.isEmpty || value == null || value < 0 ? null : value * factor;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = DateUtils.dateOnly(picked));
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _badName = true);
      return;
    }
    final units = ref.read(unitsChoiceViewModelProvider);
    Navigator.pop(
      context,
      EventRequest(
        name: name,
        date: _date,
        kind: Optional.present(_kind),
        distanceM: Optional.present(
          _metres(_distance, units == Units.imperial ? _metresPerMile : 1000),
        ),
        elevationGainM: Optional.present(
          _metres(_climbing, units == Units.imperial ? _metresPerFoot : 1),
        ),
        notes: Optional.present(
          _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final units = ref.watch(unitsChoiceViewModelProvider);
    final editing = widget.event != null;
    return FormSheet(
      title: editing ? l10n.eventChange : l10n.eventAdd,
      saveKey: const Key('event-save'),
      onSave: _submit,
      children: [
        AppTextField(
          fieldKey: const Key('event-name'),
          controller: _name,
          autofocus: !editing,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 100,
          label: l10n.eventName,
          errorText: _badName ? l10n.errorEventName : null,
          onDone: (_) => _submit(),
        ),
        DropdownButtonFormField<String>(
          key: const Key('event-kind'),
          initialValue: _kind,
          decoration: InputDecoration(labelText: l10n.eventKind),
          items: [
            for (final kind in eventKindIds)
              DropdownMenuItem(
                value: kind,
                child: Text(eventKindName(l10n, kind)),
              ),
          ],
          onChanged: (v) => setState(() => _kind = v ?? _kind),
        ),
        OutlinedButton.icon(
          key: const Key('event-date'),
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(dateOnly(_date)),
        ),
        Row(
          spacing: AppSpacing.md,
          children: [
            Expanded(
              child: _number(
                key: const Key('event-distance'),
                controller: _distance,
                label: l10n.eventDistance,
                unit: units == Units.imperial ? 'mi' : 'km',
              ),
            ),
            Expanded(
              child: _number(
                key: const Key('event-climbing'),
                controller: _climbing,
                label: l10n.eventClimbing,
                unit: units == Units.imperial ? 'ft' : 'm',
              ),
            ),
          ],
        ),
        AppTextField(
          fieldKey: const Key('event-notes'),
          controller: _notes,
          maxLength: 500,
          minLines: 2,
          maxLines: 4,
          label: l10n.eventNotes,
        ),
      ],
    );
  }

  Widget _number({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String unit,
  }) => AppTextField(
    fieldKey: key,
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
    label: label,
    suffix: unit,
  );
}

/// Picks one of the rider's rides of an event's day. Returns null when the rider dismisses it.
Future<RideResponse?> showRidePicker(
  BuildContext context, {
  required List<RideResponse> rides,
  required Units units,
}) => showSheet<RideResponse>(
  context,
  builder: (context) {
    final l10n = context.l10n;
    return SheetFrame(
      title: l10n.eventLinkRide,
      children: [
        if (rides.isEmpty)
          EmptyState(
            key: const Key('no-rides-that-day'),
            message: l10n.eventNoRidesThatDay,
            icon: Icons.directions_bike_outlined,
            framed: false,
          )
        else
          for (final ride in rides)
            ListTile(
              key: Key('pick-ride-${ride.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(rideTitle(l10n, ride)),
              subtitle: Text(
                [
                  if (ride.distanceM case final distance? when distance > 0)
                    km(units, distance),
                  if (ride.movingS case final moving? when moving > 0)
                    duration(moving),
                ].join(' · '),
              ),
              onTap: () => Navigator.pop(context, ride),
            ),
      ],
    );
  },
);

/// The next event as a card: its name, how far away it is, and the way to the whole list.
class NextEventCard extends ConsumerWidget {
  const NextEventCard({super.key, required this.next, required this.onAll});

  final EventResponse next;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SectionCard(
      key: const Key('next-event'),
      title: l10n.eventNext(next.name, daysAway(l10n, next.date)),
      description: eventDetail(
        l10n,
        ref.watch(unitsChoiceViewModelProvider),
        next,
      ),
      children: [
        if (next.notes case final notes? when notes.isNotEmpty)
          Text(notes, style: Theme.of(context).textTheme.bodyMedium),
        TextButton(
          key: const Key('all-events'),
          onPressed: onAll,
          child: Text(l10n.eventsAll),
        ),
      ],
    );
  }
}
