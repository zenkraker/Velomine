import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/units.dart';
import '../../core/location_service.dart';
import '../../core/providers.dart';
import '../../core/tokens.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../auth/auth_page.dart';
import '../../l10n/generated/app_localizations.dart';
import '../club/location_picker.dart';
import 'club_ride_widgets.dart';
import 'club_rides_view_model.dart';
import 'club_rides_state.dart';

const ridePaceIds = ['easy', 'steady', 'fast'];

/// Plans a ride, or changes one; the same form does both.
class PlanRideScreen extends ConsumerStatefulWidget {
  const PlanRideScreen({
    super.key,
    required this.rideId,
    required this.onSaved,
    this.tileUrl,
    this.attribution,
  });

  /// Empty when planning a new ride.
  final String rideId;
  final void Function(String id) onSaved;
  final String? tileUrl;
  final String? attribution;

  @override
  ConsumerState<PlanRideScreen> createState() => _PlanRideScreenState();
}

class _PlanRideScreenState extends ConsumerState<PlanRideScreen> {
  final _title = TextEditingController();
  final _meeting = TextEditingController();
  final _notes = TextEditingController();
  final _maxRiders = TextEditingController();
  late DateTime _date;
  late TimeOfDay _time;
  String _pace = 'steady';
  bool _noDrop = true;
  String? _routeId;
  GeoPoint? _point;
  bool _filled = false;
  String? _problem;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    _time = const TimeOfDay(hour: 8, minute: 0);
  }

  @override
  void dispose() {
    _title.dispose();
    _meeting.dispose();
    _notes.dispose();
    _maxRiders.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickMeeting() async {
    final picked = await Navigator.of(context).push<GeoPoint>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initial: _point,
          tileUrl: widget.tileUrl ?? '',
          attribution: widget.attribution ?? '',
          locationService: ref.read(locationServiceProvider),
        ),
      ),
    );
    if (picked != null) setState(() => _point = picked);
  }

  Future<void> _save(PlanRideState s, PlanRideViewModel notifier) async {
    final startsAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    final maxRiders = _maxRiders.text.trim().isEmpty
        ? null
        : int.tryParse(_maxRiders.text.trim());
    final problem = _title.text.trim().isEmpty
        ? 'title'
        : _meeting.text.trim().isEmpty
        ? 'meeting'
        : _point == null
        ? 'point'
        : startsAt.isBefore(DateTime.now())
        ? 'past'
        : maxRiders == null && _maxRiders.text.trim().isNotEmpty
        ? 'max'
        : maxRiders != null && (maxRiders < 1 || maxRiders > 500)
        ? 'max'
        : null;
    if (problem != null) {
      setState(() => _problem = problem);
      return;
    }

    setState(() => _problem = null);
    final id = await notifier.save(
      title: _title.text.trim(),
      startsAt: startsAt,
      utcOffsetMinutes: startsAt.timeZoneOffset.inMinutes,
      meetingName: _meeting.text.trim(),
      latitude: _point!.latitude,
      longitude: _point!.longitude,
      pace: _pace,
      noDrop: _noDrop,
      routeId: _routeId,
      notes: _notes.text,
      maxRiders: maxRiders,
    );
    if (id != null && mounted) widget.onSaved(id);
  }

  String? _problemText(AppLocalizations l10n) => switch (_problem) {
    'title' => l10n.rideFormNeedTitle,
    'meeting' => l10n.rideFormNeedMeeting,
    'point' => l10n.rideFormNeedPoint,
    'past' => l10n.rideFormFuture,
    'max' => l10n.rideFormMaxRange,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = ref.watch(planRideViewModelProvider(widget.rideId));
    final notifier = ref.read(
      planRideViewModelProvider(widget.rideId).notifier,
    );

    listenUserMessages(
      ref,
      context,
      planRideViewModelProvider(widget.rideId).select((s) => s.messages),
      notifier.messageShown,
    );

    final editing = widget.rideId.isNotEmpty;
    final detail = s.detail;
    if (editing && detail != null && !_filled) {
      _filled = true;
      final ride = detail.ride;
      _title.text = ride.title;
      _meeting.text = ride.meetingName;
      _notes.text = detail.notes ?? '';
      _maxRiders.text = ride.maxRiders?.toString() ?? '';
      _pace = ride.pace;
      _noDrop = ride.noDrop;
      _routeId = ride.routeId;
      _point = (
        latitude: detail.meetingLatitude,
        longitude: detail.meetingLongitude,
      );
      final local = ride.startsAt.toUtc().add(
        Duration(minutes: ride.utcOffsetMinutes),
      );
      _date = DateTime(local.year, local.month, local.day);
      _time = TimeOfDay(hour: local.hour, minute: local.minute);
    }

    if (s.load.running && (editing && detail == null)) {
      return const Center(child: CircularProgressIndicator());
    }

    final problem = _problemText(l10n);
    return PageScaffold(
      eyebrow: l10n.clubRidesEyebrow,
      title: editing ? l10n.editRideTitle : l10n.planRideTitle,
      maxWidth: AppLayout.contentNarrow,
      children: [
        // The form's fields, in one card; the page header already names it.
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                AppTextField(
                  fieldKey: const Key('ride-title'),
                  controller: _title,
                  label: l10n.rideFormTitle,
                ),
                Row(
                  spacing: AppSpacing.sm,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('ride-date'),
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          MaterialLocalizations.of(context)
                              .formatMediumDate(_date),
                        ),
                      ),
                    ),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('ride-time'),
                        onPressed: _pickTime,
                        icon: const Icon(Icons.schedule),
                        label: Text(_time.format(context)),
                      ),
                    ),
                  ],
                ),
                AppTextField(
                  fieldKey: const Key('ride-meeting'),
                  controller: _meeting,
                  label: l10n.rideFormMeetingName,
                ),
                OutlinedButton.icon(
                  key: const Key('ride-meeting-point'),
                  onPressed: _pickMeeting,
                  icon: const Icon(Icons.place_outlined),
                  label: Text(
                    _point == null
                        ? l10n.rideFormPickMeeting
                        : '${_point!.latitude.toStringAsFixed(5)}, ${_point!.longitude.toStringAsFixed(5)}',
                  ),
                ),
                DropdownButtonFormField<String?>(
                  key: const Key('ride-route'),
                  initialValue: _routeId,
                  decoration: InputDecoration(labelText: l10n.rideFormRoute),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.rideFormNoRoute),
                    ),
                    for (final route in s.routes)
                      DropdownMenuItem(
                        value: route.id,
                        child: Text(
                          '${route.name} · ${km(ref.watch(unitsChoiceViewModelProvider), route.distanceM)}',
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _routeId = value),
                ),
                DropdownButtonFormField<String>(
                  key: const Key('ride-pace'),
                  initialValue: _pace,
                  decoration: InputDecoration(labelText: l10n.rideFormPace),
                  items: [
                    for (final pace in ridePaceIds)
                      DropdownMenuItem(
                        value: pace,
                        child: Text(ridePaceName(l10n, pace)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _pace = value);
                  },
                ),
                SwitchListTile(
                  key: const Key('ride-no-drop'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.rideFormNoDrop),
                  value: _noDrop,
                  onChanged: (value) => setState(() => _noDrop = value),
                ),
                AppTextField(
                  fieldKey: const Key('ride-notes'),
                  controller: _notes,
                  label: l10n.rideFormNotes,
                ),
                AppTextField(
                  fieldKey: const Key('ride-max-riders'),
                  controller: _maxRiders,
                  label: l10n.rideFormMaxRiders,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        if (problem != null)
          AuthFailure(keyName: 'plan-ride-problem', message: problem),
        if (s.action.failure case final failure?)
          ErrorState(
            message: failureText(l10n, failure),
            actionKey: const Key('plan-ride-error'),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            key: const Key('save-ride'),
            onPressed: s.action.running ? null : () => _save(s, notifier),
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.rideFormSave),
          ),
        ),
      ],
    );
  }
}
