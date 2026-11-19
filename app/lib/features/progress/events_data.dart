import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import '../rides/rides_data.dart';

part 'events_data.g.dart';

/// The events endpoints as values: the ViewModel never sees an exception.
class EventsData {
  EventsData(this._training, this._rides);

  final TrainingApi _training;
  final RidesApi _rides;

  Future<Result<List<EventResponse>>> list() async =>
      (await _training.listEvents().guard(FailureAction.loadProgress))
          .map((response) => response?.events ?? const <EventResponse>[]);

  Future<Result<EventResponse?>> add(EventRequest event) =>
      _training.addEvent(event).guard(FailureAction.addEvent);

  Future<Result<EventResponse?>> update(String id, UpdateEventRequest event) =>
      _training.updateEvent(id, event).guard(FailureAction.saveEvent);

  Future<Result<void>> delete(String id) =>
      _training.deleteEvent(id).guard(FailureAction.deleteEvent);

  /// The ride that was this event, or null to unlink it.
  Future<Result<EventResponse?>> setRide(String id, String? rideId) => _training
      .setEventRide(id, SetEventRideRequest(rideId: Optional.present(rideId)))
      .guard(FailureAction.saveEvent);

  /// The rides of one day an event could be: the ready ones, read in the member's own calendar, every page of them.
  Future<Result<List<RideResponse>>> ridesOn(DateTime day) async {
    final date = calendarDay(day);
    final rides = <RideResponse>[];
    String? cursor;
    do {
      final result = await _rides
          .listRides(cursor: cursor, from: date, to: date)
          .guard(FailureAction.loadRides);
      if (result case Failed(:final failure)) return Failed(failure);
      rides.addAll(
        result.valueOrNull?.rides.where((ride) => ride.status == 'ready') ??
            const [],
      );
      cursor = result.valueOrNull?.next;
    } while (cursor != null);
    return Ok(rides);
  }
}

@Riverpod(keepAlive: true)
EventsData eventsData(Ref ref) {
  final session = ref.watch(sessionProvider);
  return EventsData(session.training, session.rides);
}
