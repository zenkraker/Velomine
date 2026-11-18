import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';

part 'events_data.g.dart';

/// The events endpoints as values: the ViewModel never sees an exception.
class EventsData {
  EventsData(this._training);

  final TrainingApi _training;

  Future<Result<List<EventResponse>>> list() async =>
      (await _training.listEvents().guard(FailureAction.loadProgress))
          .map((response) => response?.events ?? const <EventResponse>[]);

  Future<Result<EventResponse?>> add(EventRequest event) =>
      _training.addEvent(event).guard(FailureAction.addEvent);

  Future<Result<EventResponse?>> update(String id, UpdateEventRequest event) =>
      _training.updateEvent(id, event).guard(FailureAction.saveEvent);

  Future<Result<void>> delete(String id) =>
      _training.deleteEvent(id).guard(FailureAction.deleteEvent);
}

@Riverpod(keepAlive: true)
EventsData eventsData(Ref ref) {
  final session = ref.watch(sessionProvider);
  return EventsData(session.training);
}
