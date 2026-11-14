import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart' show distanceUnit;
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/units.dart';
import '../../core/widgets/empty_state.dart';
import '../../l10n/generated/app_localizations.dart';
import 'bike_forms.dart' show dateOnly, isoDate;
import 'bikes_view_models.dart';
import 'service_forms.dart';
import 'service_names.dart';

DateTime _today() => dateOnly(DateTime.now());

Color reminderColor(BuildContext context, String status) => switch (status) {
  'due' => Theme.of(context).colorScheme.error,
  'soon' => VelomineColors.of(context).wearSoon,
  'paused' => Theme.of(context).disabledColor,
  _ => VelomineColors.of(context).wearOk,
};

String reminderStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'due' => l10n.reminderStatusDue,
      'soon' => l10n.reminderStatusSoon,
      'paused' => l10n.reminderStatusPaused,
      _ => l10n.reminderStatusOk,
    };

/// "210 of 300 km · 7 of 10 h · 2.1 of 3 months", only the intervals the reminder has.
String reminderProgressText(
  AppLocalizations l10n,
  Units units,
  MaintenanceReminderResponse r,
) => [
  if (r.intervalDistanceM != null)
    '${l10n.wearDistance(units == Units.imperial ? (r.usedDistanceM / 1609.344).toStringAsFixed(0) : (r.usedDistanceM / 1000).toStringAsFixed(0), units == Units.imperial ? (r.intervalDistanceM! / 1609.344).toStringAsFixed(0) : (r.intervalDistanceM! / 1000).toStringAsFixed(0))} ${distanceUnit(units)}',
  if (r.intervalHours != null)
    l10n.wearHours(
      r.usedHours.toStringAsFixed(0),
      r.intervalHours!.toStringAsFixed(0),
    ),
  if (r.intervalMonths != null)
    l10n.wearMonths(
      NumberFormat('0.0').format(r.usedMonths),
      r.intervalMonths!,
    ),
].join(' · ');

/// The bike's reminders (most urgent first) and its service log. Reads and drives the bike's ViewModel.
class ServiceSection extends ConsumerWidget {
  const ServiceSection({super.key, required this.id});

  final String id;

  Future<void> _addReminder(
    BuildContext context,
    WidgetRef ref, {
    MaintenanceJob? job,
  }) async {
    final s = ref.read(bikeDetailViewModelProvider(id));
    final data = await showReminderForm(
      context,
      jobs: s.jobs,
      today: _today(),
      job: job,
      jobName: job == null ? null : serviceJobName(context.l10n, job.id),
    );
    if (data != null) {
      await ref
          .read(bikeDetailViewModelProvider(id).notifier)
          .addReminder(data.toCreate());
    }
  }

  Future<void> _editReminder(
    BuildContext context,
    WidgetRef ref,
    MaintenanceReminderResponse reminder,
  ) async {
    final data = await showReminderForm(
      context,
      jobs: const [],
      today: _today(),
      reminder: reminder,
    );
    if (data != null) {
      await ref
          .read(bikeDetailViewModelProvider(id).notifier)
          .editReminder(reminder.id, data.toUpdate(paused: reminder.isPaused));
    }
  }

  Future<void> _done(
    BuildContext context,
    WidgetRef ref,
    MaintenanceReminderResponse reminder,
  ) async {
    final day = await showDoneDialog(
      context,
      name: reminder.name,
      today: _today(),
    );
    if (day == null) return;
    final ok = await ref
        .read(bikeDetailViewModelProvider(id).notifier)
        .completeReminder(reminder.id, day);
    if (ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.reminderDoneSaved)));
    }
  }

  Future<void> _removeReminder(
    BuildContext context,
    WidgetRef ref,
    MaintenanceReminderResponse reminder,
  ) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reminderRemoveTitle),
        content: Text(l10n.reminderRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepIt),
          ),
          FilledButton(
            key: const Key('confirm-remove-reminder'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(bikeDetailViewModelProvider(id).notifier)
          .removeReminder(reminder.id);
    }
  }

  Future<void> _addEntry(BuildContext context, WidgetRef ref) async {
    final s = ref.read(bikeDetailViewModelProvider(id));
    final data = await showServiceEntryForm(
      context,
      today: _today(),
      parts: s.detail?.components ?? const [],
      reminders: s.detail?.reminders ?? const [],
    );
    if (data != null) {
      await ref
          .read(bikeDetailViewModelProvider(id).notifier)
          .addServiceEntry(data.toCreate());
    }
  }

  Future<void> _editEntry(
    BuildContext context,
    WidgetRef ref,
    ServiceEntryResponse entry,
  ) async {
    final s = ref.read(bikeDetailViewModelProvider(id));
    final data = await showServiceEntryForm(
      context,
      today: _today(),
      parts: s.detail?.components ?? const [],
      reminders: s.detail?.reminders ?? const [],
      entry: entry,
    );
    if (data != null) {
      await ref
          .read(bikeDetailViewModelProvider(id).notifier)
          .editServiceEntry(entry.id, data.toUpdate());
    }
  }

  Future<void> _removeEntry(
    BuildContext context,
    WidgetRef ref,
    ServiceEntryResponse entry,
  ) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.entryRemoveTitle),
        content: Text(
          entry.origin == 'reminder'
              ? l10n.entryRemoveDoneBody
              : l10n.entryRemoveBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepIt),
          ),
          FilledButton(
            key: const Key('confirm-remove-entry'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(bikeDetailViewModelProvider(id).notifier)
          .removeServiceEntry(entry.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(bikeDetailViewModelProvider(id));
    final notifier = ref.read(bikeDetailViewModelProvider(id).notifier);
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final reminders =
        s.detail?.reminders ?? const <MaintenanceReminderResponse>[];
    final parts = s.detail?.components ?? const <ComponentResponse>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            Text(l10n.service, style: text.titleLarge),
            FilledButton.icon(
              key: const Key('add-reminder'),
              onPressed: () => _addReminder(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.serviceAddReminder),
            ),
          ],
        ),
        if (reminders.isEmpty) ...[
          Text(l10n.serviceRemindersIntro, key: const Key('no-reminders')),
          if (s.jobs.isNotEmpty)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final job in s.jobs)
                  ActionChip(
                    key: Key('suggest-${job.id}'),
                    label: Text(serviceJobName(l10n, job.id)),
                    onPressed: () => _addReminder(context, ref, job: job),
                  ),
              ],
            ),
        ],
        for (final reminder in reminders)
          _ReminderCard(
            reminder: reminder,
            onDone: () => _done(context, ref, reminder),
            onEdit: () => _editReminder(context, ref, reminder),
            onPause: () =>
                notifier.setReminderPaused(reminder, !reminder.isPaused),
            onRemove: () => _removeReminder(context, ref, reminder),
          ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            Text(l10n.serviceLog, style: text.titleMedium),
            OutlinedButton.icon(
              key: const Key('add-entry'),
              onPressed: () => _addEntry(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.serviceAddEntry),
            ),
          ],
        ),
        if (parts.isNotEmpty && (s.log.isNotEmpty || s.logComponentId != null))
          DropdownButtonFormField<String?>(
            key: const Key('log-filter'),
            initialValue: s.logComponentId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.logFilterLabel),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(l10n.logFilterAll),
              ),
              for (final p in parts)
                DropdownMenuItem<String?>(
                  value: p.id,
                  child: Text(
                    partLabel(l10n, p),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: notifier.filterLog,
          ),
        if (s.logLoad.failure case final failure?)
          Row(
            children: [
              Expanded(
                child: Text(
                  failureText(l10n, failure),
                  key: const Key('log-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              TextButton(
                key: const Key('log-retry'),
                onPressed: notifier.loadLog,
                child: Text(l10n.retry),
              ),
            ],
          )
        else if (s.logLoad.running && s.log.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (s.log.isEmpty)
          s.logComponentId == null
              ? Text(l10n.serviceLogIntro, key: const Key('no-entries'))
              : EmptyState(
                  key: const Key('no-entries'),
                  message: l10n.logFilterEmpty,
                ),
        for (final entry in s.log)
          _EntryCard(
            entry: entry,
            onEdit: () => _editEntry(context, ref, entry),
            onRemove: () => _removeEntry(context, ref, entry),
          ),
        if (s.logHasMore)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('log-more'),
              onPressed: s.logLoad.running ? null : notifier.loadMoreLog,
              child: Text(l10n.logShowMore),
            ),
          ),
      ],
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  const _ReminderCard({
    required this.reminder,
    required this.onDone,
    required this.onEdit,
    required this.onPause,
    required this.onRemove,
  });

  final MaintenanceReminderResponse reminder;
  final VoidCallback onDone;
  final VoidCallback onEdit;
  final VoidCallback onPause;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final color = reminderColor(context, reminder.status);
    return Card(
      key: Key('reminder-${reminder.id}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Row(
              children: [
                Expanded(child: Text(reminder.name, style: text.titleMedium)),
                Text(
                  reminderStatusLabel(l10n, reminder.status),
                  key: Key('reminder-status-${reminder.id}'),
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (reminder.percent != null)
              Semantics(
                label: l10n.wearPercent(reminder.percent!),
                child: LinearProgressIndicator(
                  key: Key('reminder-bar-${reminder.id}'),
                  value: (reminder.percent! / 100).clamp(0.0, 1.0),
                  color: color,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            Text(
              reminderProgressText(
                l10n,
                ref.watch(unitsChoiceViewModelProvider),
                reminder,
              ),
              key: Key('reminder-text-${reminder.id}'),
            ),
            Text(
              l10n.reminderLastDone(isoDate(reminder.lastDoneOn)),
              style: text.bodySmall,
            ),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                FilledButton.tonal(
                  key: Key('reminder-done-${reminder.id}'),
                  onPressed: onDone,
                  child: Text(l10n.reminderDone),
                ),
                TextButton(
                  key: Key('reminder-edit-${reminder.id}'),
                  onPressed: onEdit,
                  child: Text(l10n.edit),
                ),
                TextButton(
                  key: Key('reminder-pause-${reminder.id}'),
                  onPressed: onPause,
                  child: Text(
                    reminder.isPaused
                        ? l10n.reminderResume
                        : l10n.reminderPause,
                  ),
                ),
                TextButton(
                  key: Key('reminder-remove-${reminder.id}'),
                  onPressed: onRemove,
                  child: Text(l10n.remove),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends ConsumerWidget {
  const _EntryCard({
    required this.entry,
    required this.onEdit,
    required this.onRemove,
  });

  final ServiceEntryResponse entry;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  /// "85.50 €", or the amount and code when the currency is unknown to the formatter.
  String _cost(String locale) {
    final amount = entry.costAmount!;
    final code = entry.costCurrency ?? '';
    try {
      return NumberFormat.simpleCurrency(
        locale: locale,
        name: code,
      ).format(amount);
    } on Object {
      return '${amount.toStringAsFixed(2)} $code';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final units = ref.watch(unitsChoiceViewModelProvider);
    final locale = Localizations.localeOf(context).toString();
    final distance =
        '${NumberFormat.decimalPattern(locale).format(units == Units.imperial ? (entry.bikeDistanceM / 1609.344).round() : (entry.bikeDistanceM / 1000).round())} ${distanceUnit(units)}';
    return Card(
      key: Key('entry-${entry.id}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text(entry.title, style: text.titleMedium),
            Text(
              [
                isoDate(entry.date),
                l10n.entryAtDistance(distance),
                entry.place ?? l10n.entryAtHome,
                if (entry.costAmount != null) _cost(locale),
              ].join(' · '),
              key: Key('entry-meta-${entry.id}'),
              style: text.bodySmall,
            ),
            if (entry.notes != null) Text(entry.notes!),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                TextButton(
                  key: Key('entry-edit-${entry.id}'),
                  onPressed: onEdit,
                  child: Text(l10n.edit),
                ),
                TextButton(
                  key: Key('entry-remove-${entry.id}'),
                  onPressed: onRemove,
                  child: Text(l10n.remove),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
