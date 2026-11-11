import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:velomine_api/api.dart';

import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/form_sheet.dart';
import '../../l10n/generated/app_localizations.dart';
import 'bike_forms.dart' show dateOnly, isoDate;
import 'component_names.dart';
import 'service_names.dart';

String? _text(String value) => value.trim().isEmpty ? null : value.trim();

double? _number(String value) =>
    double.tryParse(value.trim().replaceAll(',', '.'));

/// A day up to today: a job cannot have been done in the future.
Future<DateTime?> _pickPastDate(BuildContext context, DateTime initial) =>
    showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1980),
      lastDate: dateOnly(DateTime.now()),
    );

// ---------------------------------------------------------------- reminders

class ReminderFormData {
  const ReminderFormData({
    required this.name,
    this.km,
    this.hours,
    this.months,
    required this.lastDoneOn,
  });

  final String name;
  final double? km;
  final double? hours;
  final int? months;
  final DateTime lastDoneOn;

  CreateReminderRequest toCreate() => CreateReminderRequest(
    name: name,
    intervalDistanceM: Optional.present(km == null ? null : km! * 1000),
    intervalHours: Optional.present(hours),
    intervalMonths: Optional.present(months),
    lastDoneOn: Optional.present(lastDoneOn),
  );

  UpdateReminderRequest toUpdate({required bool paused}) =>
      UpdateReminderRequest(
        name: name,
        intervalDistanceM: Optional.present(km == null ? null : km! * 1000),
        intervalHours: Optional.present(hours),
        intervalMonths: Optional.present(months),
        isPaused: Optional.present(paused),
      );
}

String _fmt(num? v) => v == null
    ? ''
    : (v == v.roundToDouble() ? v.round().toString() : v.toString());

/// Add a reminder (with the common [jobs] to start from), or change [reminder].
Future<ReminderFormData?> showReminderForm(
  BuildContext context, {
  required List<MaintenanceJob> jobs,
  required DateTime today,
  MaintenanceReminderResponse? reminder,
  MaintenanceJob? job,
  String? jobName,
}) => showFormSheet<ReminderFormData>(
  context,
  builder: (_) => _ReminderForm(
    jobs: jobs,
    today: today,
    reminder: reminder,
    startWith: job,
    startName: jobName,
  ),
);

class _ReminderForm extends StatefulWidget {
  const _ReminderForm({
    required this.jobs,
    required this.today,
    this.reminder,
    this.startWith,
    this.startName,
  });

  final List<MaintenanceJob> jobs;
  final DateTime today;
  final MaintenanceReminderResponse? reminder;
  final MaintenanceJob? startWith;
  final String? startName;

  @override
  State<_ReminderForm> createState() => _ReminderFormState();
}

enum _ReminderProblem { name, interval, limits }

class _ReminderFormState extends State<_ReminderForm> {
  late final _name = TextEditingController(text: widget.reminder?.name);
  late final _km = TextEditingController(
    text: _fmt(
      widget.reminder?.intervalDistanceM == null
          ? null
          : widget.reminder!.intervalDistanceM! / 1000,
    ),
  );
  late final _hours = TextEditingController(
    text: _fmt(widget.reminder?.intervalHours),
  );
  late final _months = TextEditingController(
    text: _fmt(widget.reminder?.intervalMonths),
  );
  late DateTime _lastDone = dateOnly(widget.today);
  _ReminderProblem? _problem;

  @override
  void initState() {
    super.initState();
    final job = widget.startWith;
    if (job != null) _useJob(job, name: widget.startName);
  }

  @override
  void dispose() {
    _name.dispose();
    _km.dispose();
    _hours.dispose();
    _months.dispose();
    super.dispose();
  }

  void _useJob(MaintenanceJob job, {required String? name}) {
    _km.text = _fmt(
      job.intervalDistanceM == null ? null : job.intervalDistanceM! / 1000,
    );
    _hours.text = _fmt(job.intervalHours);
    _months.text = _fmt(job.intervalMonths);
    if (name != null) _name.text = name;
  }

  void _submit() {
    final km = _number(_km.text),
        hours = _number(_hours.text),
        months = _number(_months.text);
    bool empty(TextEditingController c) => c.text.trim().isEmpty;
    bool bad(double? v, TextEditingController c) =>
        !empty(c) && (v == null || v <= 0);
    if (_name.text.trim().isEmpty) {
      setState(() => _problem = _ReminderProblem.name);
    } else if (empty(_km) && empty(_hours) && empty(_months)) {
      setState(() => _problem = _ReminderProblem.interval);
    } else if (bad(km, _km) || bad(hours, _hours) || bad(months, _months)) {
      setState(() => _problem = _ReminderProblem.limits);
    } else {
      Navigator.pop(
        context,
        ReminderFormData(
          name: _name.text.trim(),
          km: km,
          hours: hours,
          months: months?.round(),
          lastDoneOn: _lastDone,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final editing = widget.reminder != null;
    return FormSheet(
      title: editing ? l10n.reminderFormEditTitle : l10n.reminderFormAddTitle,
      saveKey: const Key('reminder-save'),
      onSave: _submit,
      error: switch (_problem) {
        null => null,
        _ReminderProblem.name => l10n.reminderErrorName,
        _ReminderProblem.interval => l10n.reminderErrorInterval,
        _ReminderProblem.limits => l10n.errorLimits,
      },
      children: [
        if (!editing && widget.jobs.isNotEmpty) ...[
          Text(
            l10n.serviceCommonJobs,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final job in widget.jobs)
                ActionChip(
                  key: Key('job-${job.id}'),
                  label: Text(serviceJobName(l10n, job.id)),
                  onPressed: () => setState(
                    () => _useJob(job, name: serviceJobName(l10n, job.id)),
                  ),
                ),
            ],
          ),
        ],
        AppTextField(
          fieldKey: const Key('reminder-name'),
          controller: _name,
          label: l10n.reminderName,
        ),
        Text(
          l10n.reminderIntervalHelp,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Row(
          spacing: AppSpacing.md,
          children: [
            Expanded(
              child: AppTextField(
                fieldKey: const Key('reminder-km'),
                controller: _km,
                label: 'km',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            Expanded(
              child: AppTextField(
                fieldKey: const Key('reminder-hours'),
                controller: _hours,
                label: l10n.hours,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            Expanded(
              child: AppTextField(
                fieldKey: const Key('reminder-months'),
                controller: _months,
                label: l10n.months,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        if (!editing)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('reminder-last-done'),
              icon: const Icon(Icons.event),
              label: Text(l10n.reminderLastDone(isoDate(_lastDone))),
              onPressed: () async {
                final d = await _pickPastDate(context, _lastDone);
                if (d != null) setState(() => _lastDone = dateOnly(d));
              },
            ),
          ),
      ],
    );
  }
}

/// Asks which day a job was done: today, or another day up to today. Returns null when cancelled.
Future<DateTime?> showDoneDialog(
  BuildContext context, {
  required String name,
  required DateTime today,
}) => showDialog<DateTime>(
  context: context,
  builder: (_) => _DoneDialog(name: name, today: dateOnly(today)),
);

class _DoneDialog extends StatefulWidget {
  const _DoneDialog({required this.name, required this.today});

  final String name;
  final DateTime today;

  @override
  State<_DoneDialog> createState() => _DoneDialogState();
}

class _DoneDialogState extends State<_DoneDialog> {
  late DateTime _day = widget.today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Text(l10n.reminderDoneBody),
          TextButton.icon(
            key: const Key('done-date'),
            icon: const Icon(Icons.event),
            label: Text(l10n.doneOnDate(isoDate(_day))),
            onPressed: () async {
              final d = await _pickPastDate(context, _day);
              if (d != null) setState(() => _day = dateOnly(d));
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('confirm-done'),
          onPressed: () => Navigator.pop(context, _day),
          child: Text(l10n.reminderDone),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------- service log

class ServiceEntryFormData {
  const ServiceEntryFormData({
    required this.date,
    required this.title,
    this.notes,
    this.place,
    this.cost,
    this.currency,
    this.componentId,
    this.reminderId,
  });

  final DateTime date;
  final String title;
  final String? notes;
  final String? place;
  final double? cost;
  final String? currency;
  final String? componentId;
  final String? reminderId;

  CreateServiceEntryRequest toCreate() => CreateServiceEntryRequest(
    date: date,
    title: title,
    notes: Optional.present(notes),
    place: Optional.present(place),
    costAmount: Optional.present(cost),
    costCurrency: Optional.present(cost == null ? null : currency),
    componentId: Optional.present(componentId),
    reminderId: Optional.present(reminderId),
  );

  UpdateServiceEntryRequest toUpdate() => UpdateServiceEntryRequest(
    date: date,
    title: title,
    notes: Optional.present(notes),
    place: Optional.present(place),
    costAmount: Optional.present(cost),
    costCurrency: Optional.present(cost == null ? null : currency),
    componentId: Optional.present(componentId),
    reminderId: Optional.present(reminderId),
  );
}

/// Add an entry to the log, or change [entry]. [parts] and [reminders] are the bike's, to link the entry to one.
Future<ServiceEntryFormData?> showServiceEntryForm(
  BuildContext context, {
  required DateTime today,
  required List<ComponentResponse> parts,
  required List<MaintenanceReminderResponse> reminders,
  ServiceEntryResponse? entry,
}) => showFormSheet<ServiceEntryFormData>(
  context,
  builder: (_) => _ServiceEntryForm(
    today: today,
    parts: parts,
    reminders: reminders,
    entry: entry,
  ),
);

class _ServiceEntryForm extends StatefulWidget {
  const _ServiceEntryForm({
    required this.today,
    required this.parts,
    required this.reminders,
    this.entry,
  });

  final DateTime today;
  final List<ComponentResponse> parts;
  final List<MaintenanceReminderResponse> reminders;
  final ServiceEntryResponse? entry;

  @override
  State<_ServiceEntryForm> createState() => _ServiceEntryFormState();
}

enum _EntryProblem { title, cost }

class _ServiceEntryFormState extends State<_ServiceEntryForm> {
  late final _title = TextEditingController(text: widget.entry?.title);
  late final _notes = TextEditingController(text: widget.entry?.notes);
  late final _place = TextEditingController(text: widget.entry?.place);
  late final _cost = TextEditingController(
    text: widget.entry?.costAmount == null
        ? ''
        : widget.entry!.costAmount!.toStringAsFixed(2),
  );
  late final _currency = TextEditingController(
    text: widget.entry?.costCurrency ?? _defaultCurrency(),
  );
  late DateTime _date = widget.entry == null
      ? dateOnly(widget.today)
      : dateOnly(widget.entry!.date);
  late String? _componentId = widget.entry?.componentId;
  late String? _reminderId = widget.entry?.reminderId;
  _EntryProblem? _problem;

  /// The currency of the country the device is set to, or euro when it cannot tell.
  static String _defaultCurrency() {
    try {
      final locale = ui.PlatformDispatcher.instance.locale;
      if (locale.countryCode == null) return 'EUR';
      return NumberFormat.simpleCurrency(locale: locale.toString())
              .currencyName ??
          'EUR';
    } on Object {
      return 'EUR';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _place.dispose();
    _cost.dispose();
    _currency.dispose();
    super.dispose();
  }

  void _submit() {
    final costText = _cost.text.trim();
    final cost = costText.isEmpty ? null : _number(costText);
    final currency = _currency.text.trim().toUpperCase();
    if (_title.text.trim().isEmpty) {
      setState(() => _problem = _EntryProblem.title);
    } else if (costText.isNotEmpty &&
        (cost == null ||
            cost < 0 ||
            !RegExp(r'^[A-Z]{3}$').hasMatch(currency))) {
      setState(() => _problem = _EntryProblem.cost);
    } else {
      Navigator.pop(
        context,
        ServiceEntryFormData(
          date: _date,
          title: _title.text.trim(),
          notes: _text(_notes.text),
          place: _text(_place.text),
          cost: cost,
          currency: cost == null ? null : currency,
          componentId: _componentId,
          reminderId: _reminderId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final editing = widget.entry != null;
    return FormSheet(
      title: editing ? l10n.entryFormEditTitle : l10n.entryFormAddTitle,
      saveKey: const Key('entry-save'),
      onSave: _submit,
      error: switch (_problem) {
        null => null,
        _EntryProblem.title => l10n.entryErrorTitle,
        _EntryProblem.cost => l10n.entryErrorCost,
      },
      children: [
        AppTextField(
          fieldKey: const Key('entry-title'),
          controller: _title,
          label: l10n.entryTitleField,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('entry-date'),
            icon: const Icon(Icons.event),
            label: Text(l10n.doneOnDate(isoDate(_date))),
            onPressed: () async {
              final d = await _pickPastDate(context, _date);
              if (d != null) setState(() => _date = dateOnly(d));
            },
          ),
        ),
        if (widget.parts.isNotEmpty)
          DropdownButtonFormField<String?>(
            key: const Key('entry-part'),
            initialValue: _componentId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.entryPart),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(l10n.entryNoPart),
              ),
              for (final p in widget.parts)
                DropdownMenuItem<String?>(
                  value: p.id,
                  child: Text(
                    partLabel(l10n, p),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _componentId = v),
          ),
        if (widget.reminders.isNotEmpty)
          DropdownButtonFormField<String?>(
            key: const Key('entry-reminder'),
            initialValue: _reminderId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.entryReminder),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(l10n.entryNoReminder),
              ),
              for (final r in widget.reminders)
                DropdownMenuItem<String?>(
                  value: r.id,
                  child: Text(r.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _reminderId = v),
          ),
        AppTextField(
          fieldKey: const Key('entry-place'),
          controller: _place,
          label: l10n.entryPlace,
          helper: l10n.entryPlaceHelp,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            Expanded(
              flex: 2,
              child: AppTextField(
                fieldKey: const Key('entry-cost'),
                controller: _cost,
                label: l10n.entryCost,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            Expanded(
              child: AppTextField(
                fieldKey: const Key('entry-currency'),
                controller: _currency,
                label: l10n.entryCurrency,
              ),
            ),
          ],
        ),
        AppTextField(
          fieldKey: const Key('entry-notes'),
          controller: _notes,
          label: l10n.entryNotes,
        ),
      ],
    );
  }
}

/// "Chain · Shimano CN-HG701": a part named for a list.
String partLabel(AppLocalizations l10n, ComponentResponse p) {
  final make = [p.brand, p.model].whereType<String>().join(' ');
  final name = componentTypeName(l10n, p.type, p.typeName);
  return make.isEmpty ? name : '$name · $make';
}
