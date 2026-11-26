import 'dart:async' show scheduleMicrotask;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velomine_api/api.dart';

import '../../core/confirm.dart';
import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/units.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
import 'events.dart';
import 'progress_view_models.dart';

/// Every event the rider added, next first, each one editable and deletable.
class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final event = await showEventForm(context);
    if (event != null) {
      await ref.read(eventsViewModelProvider.notifier).add(event);
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    EventResponse event,
  ) async {
    final changed = await showEventForm(context, event: event);
    if (changed == null) return;
    await ref
        .read(eventsViewModelProvider.notifier)
        .update(
          event.id,
          UpdateEventRequest(
            name: changed.name,
            date: changed.date,
            kind: changed.kind,
            distanceM: changed.distanceM,
            elevationGainM: changed.elevationGainM,
            notes: changed.notes,
          ),
        );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    EventResponse event,
  ) async {
    final l10n = context.l10n;
    final ok = await confirmDestructive(
      context,
      title: l10n.eventDeleteTitle,
      body: l10n.eventDeleteBody(event.name),
      action: l10n.delete,
      key: const Key('confirm-delete-event'),
      cancelLabel: l10n.keepIt,
    );
    if (ok) await ref.read(eventsViewModelProvider.notifier).delete(event.id);
  }

  /// The event's day's rides, so the rider picks the one that was it.
  Future<void> _linkRide(
    BuildContext context,
    WidgetRef ref,
    EventResponse event,
  ) async {
    final notifier = ref.read(eventsViewModelProvider.notifier);
    final rides = await notifier.ridesOn(event.date);
    if (!context.mounted || rides == null) return;
    // One ride that day can only be the event's ride: it is linked without asking.
    if (rides.length == 1) {
      await notifier.linkRide(event.id, rides.single.id);
      return;
    }
    final picked = await showRidePicker(
      context,
      rides: rides,
      units: ref.read(unitsChoiceViewModelProvider),
    );
    if (picked == null) return;
    await notifier.linkRide(event.id, picked.id);
  }

  /// The sheet or dialog opens after the menu has closed, so the two never fight for the tap.
  void _later(BuildContext context, VoidCallback open) => scheduleMicrotask(() {
    if (context.mounted) open();
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(eventsViewModelProvider);
    final units = ref.watch(unitsChoiceViewModelProvider);
    final notifier = ref.read(eventsViewModelProvider.notifier);

    listenUserMessages(
      ref,
      context,
      eventsViewModelProvider.select((s) => s.messages),
      notifier.messageShown,
    );

    return PageScaffold(
      title: l10n.eventsTitle,
      parent: l10n.navGoals,
      onBack: () => context.pop(),
      primaryAction: FilledButton.icon(
        key: const Key('add-event'),
        onPressed: s.action.running ? null : () => _add(context, ref),
        icon: const Icon(Icons.event_outlined),
        label: Text(l10n.eventAdd),
      ),
      children: [
        if (s.load.failure case final failure?)
          ErrorState(
            message: failureText(l10n, failure),
            actionKey: const Key('events-error'),
            onRetry: s.load.running ? null : notifier.load,
          )
        else if (s.load.running && s.events.isEmpty)
          const LoadingState.rows(key: Key('events-loading'))
        else if (s.events.isEmpty)
          EmptyState(
            key: const Key('no-events'),
            message: l10n.noEvents,
            icon: Icons.event_busy_outlined,
          )
        else
          for (final event in s.events)
            _EventCard(
              event: event,
              units: units,
              onEdit: () => _later(context, () => _edit(context, ref, event)),
              onLinkRide: () =>
                  _later(context, () => _linkRide(context, ref, event)),
              onUnlinkRide: () => notifier.unlinkRide(event.id),
              onDelete: () =>
                  _later(context, () => _delete(context, ref, event)),
            ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.units,
    required this.onEdit,
    required this.onLinkRide,
    required this.onUnlinkRide,
    required this.onDelete,
  });

  final EventResponse event;
  final Units units;
  final VoidCallback onEdit;
  final VoidCallback onLinkRide;
  final VoidCallback onUnlinkRide;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final upcoming = !event.date.isBefore(DateUtils.dateOnly(DateTime.now()));
    return SectionCard(
      key: Key('event-${event.id}'),
      title: event.name,
      description: eventDetail(l10n, units, event),
      menu: PageMenu(
        buttonKey: Key('event-actions-${event.id}'),
        entries: [
          PageMenuEntry(
            key: Key('event-edit-${event.id}'),
            label: l10n.edit,
            icon: Icons.edit_outlined,
            onSelected: onEdit,
          ),
          if (event.rideId == null)
            PageMenuEntry(
              key: Key('event-link-${event.id}'),
              label: l10n.eventLinkRide,
              icon: Icons.directions_bike_outlined,
              onSelected: onLinkRide,
            )
          else
            PageMenuEntry(
              key: Key('event-unlink-${event.id}'),
              label: l10n.eventUnlinkRide,
              icon: Icons.link_off,
              onSelected: onUnlinkRide,
            ),
          PageMenuEntry(
            key: Key('event-delete-${event.id}'),
            label: l10n.delete,
            icon: Icons.delete_outline,
            destructive: true,
            onSelected: onDelete,
          ),
        ],
      ),
      children: [
        Text(
          '${dateOnly(event.date)} · ${daysAway(l10n, event.date)}',
          key: Key('event-when-${event.id}'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: upcoming ? theme.colorScheme.primary : null,
          ),
        ),
        if (event.notes case final notes? when notes.isNotEmpty)
          Text(notes, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
