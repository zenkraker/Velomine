import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import '../../core/user_message.dart';
import '../routes/routes_data.dart';
import 'club_rides_data.dart';
import 'club_rides_state.dart';

part 'club_rides_view_model.g.dart';

/// The club's rides, route-scoped so a screen inside the club reloads them when it opens.
@riverpod
class ClubRidesViewModel extends _$ClubRidesViewModel {
  @override
  ClubRidesState build() {
    if (ref.watch(signedInUserIdProvider) == null) {
      return const ClubRidesState();
    }
    Future.microtask(refresh);
    return const ClubRidesState();
  }

  Future<void> refresh() async {
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(clubRidesDataProvider).list();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        upcoming: value?.upcoming ?? const [],
        past: value?.past ?? const [],
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );
}

/// One club ride, saying "I'm in" and taking it back.
@riverpod
class ClubRideDetailViewModel extends _$ClubRideDetailViewModel {
  int _messageId = 0;

  @override
  ClubRideDetailState build(String id) {
    Future.microtask(load);
    return const ClubRideDetailState();
  }

  Future<void> load() async {
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(clubRidesDataProvider).ride(id);
    if (!ref.mounted) return;
    if (result case Failed(:final failure)
        when failure.kind == FailureKind.missing) {
      state = state.copyWith(
        load: state.load.finish(const Ok(null)),
        notFound: true,
      );
      return;
    }
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        detail: value,
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  /// Says "I'm in"; a full, cancelled or started ride leaves a failure with the reason.
  Future<bool> join() =>
      _change(() => ref.read(clubRidesDataProvider).join(id));

  Future<bool> leave() async {
    state = state.copyWith(action: state.action.start());
    final result = await ref.read(clubRidesDataProvider).leave(id);
    if (!ref.mounted) return false;
    if (result case Failed(:final failure)) {
      state = state.copyWith(
        action: state.action.finish(Failed(failure)),
        messages: [...state.messages, FailureMessage(_messageId++, failure)],
      );
      return false;
    }
    state = state.copyWith(action: state.action.finish(const Ok(null)));
    await load();
    return true;
  }

  Future<bool> cancel() =>
      _change(() => ref.read(clubRidesDataProvider).cancel(id));

  Future<bool> _change(
    Future<Result<ClubRideDetailResponse?>> Function() call,
  ) async {
    final result = await _run(call);
    return result?.isOk ?? false;
  }

  Future<Result<ClubRideDetailResponse?>?> _run(
    Future<Result<ClubRideDetailResponse?>> Function() call,
  ) async {
    state = state.copyWith(action: state.action.start());
    final result = await call();
    if (!ref.mounted) return result;
    state = state.copyWith(action: state.action.finish(result));
    if (result case Failed(:final failure)) {
      state = state.copyWith(
        messages: [...state.messages, FailureMessage(_messageId++, failure)],
      );
      return result;
    }
    state = state.copyWith(detail: result.valueOrNull);
    return result;
  }

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );
}

/// Plans a ride, or changes one: the club's routes and, when editing, the ride as it is now.
@riverpod
class PlanRideViewModel extends _$PlanRideViewModel {
  int _messageId = 0;

  @override
  PlanRideState build(String id) {
    Future.microtask(load);
    return const PlanRideState();
  }

  bool get editing => id.isNotEmpty;

  Future<void> load() async {
    state = state.copyWith(load: state.load.start());
    final data = ref.read(clubRidesDataProvider);
    final routes = await ref.read(routesDataProvider).list();
    ClubRideDetailResponse? detail;
    Failure? failure = routes.failureOrNull;
    if (editing) {
      final result = await data.ride(id);
      detail = result.valueOrNull;
      failure = failure ?? result.failureOrNull;
    }
    if (!ref.mounted) return;
    state = PlanRideState(
      detail: detail,
      routes: routes.valueOrNull ?? const [],
      load: failure == null
          ? state.load.finish(const Ok(null))
          : state.load.finish(Failed(failure)),
      messages: state.messages,
    );
  }

  /// Plans or saves the ride; the id comes back when the server accepted it.
  Future<String?> save({
    required String title,
    required DateTime startsAt,
    required int utcOffsetMinutes,
    required String meetingName,
    required double latitude,
    required double longitude,
    required String pace,
    required bool noDrop,
    String? routeId,
    String? notes,
    int? maxRiders,
  }) async {
    if (state.action.running) return null;
    state = state.copyWith(action: state.action.start());
    final data = ref.read(clubRidesDataProvider);
    final Result<ClubRideDetailResponse?> result;
    if (editing) {
      result = await data.update(
        id,
        UpdateClubRideRequest(
          title: title,
          startsAt: startsAt,
          utcOffsetMinutes: utcOffsetMinutes,
          meetingName: meetingName,
          latitude: latitude,
          longitude: longitude,
          pace: pace,
          noDrop: Optional.present(noDrop),
          routeId: routeId == null
              ? const Optional.absent()
              : Optional.present(routeId),
          notes: notes == null || notes.trim().isEmpty
              ? const Optional.absent()
              : Optional.present(notes.trim()),
          maxRiders: maxRiders == null
              ? const Optional.absent()
              : Optional.present(maxRiders),
        ),
      );
    } else {
      result = await data.plan(
        PlanClubRideRequest(
          title: title,
          startsAt: startsAt,
          utcOffsetMinutes: utcOffsetMinutes,
          meetingName: meetingName,
          latitude: latitude,
          longitude: longitude,
          pace: pace,
          noDrop: Optional.present(noDrop),
          routeId: routeId == null
              ? const Optional.absent()
              : Optional.present(routeId),
          notes: notes == null || notes.trim().isEmpty
              ? const Optional.absent()
              : Optional.present(notes.trim()),
          maxRiders: maxRiders == null
              ? const Optional.absent()
              : Optional.present(maxRiders),
        ),
      );
    }
    if (!ref.mounted) return null;
    state = state.copyWith(action: state.action.finish(result));
    if (result case Failed(:final failure)) {
      state = state.copyWith(
        messages: [...state.messages, FailureMessage(_messageId++, failure)],
      );
      return null;
    }
    return result.valueOrNull?.ride.id;
  }

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );
}

/// The member's private calendar address.
@riverpod
class CalendarFeedViewModel extends _$CalendarFeedViewModel {
  int _messageId = 0;

  @override
  CalendarFeedState build() {
    Future.microtask(load);
    return const CalendarFeedState();
  }

  Future<void> load() async {
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(clubRidesDataProvider).feedStatus();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        active: value?.active ?? false,
        createdAt: value?.createdAt,
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  /// Makes a new address, which stops the old one; this is the only time it is shown.
  Future<bool> create() async {
    state = state.copyWith(action: state.action.start());
    final result = await ref.read(clubRidesDataProvider).createFeed();
    if (!ref.mounted) return false;
    state = state.copyWith(action: state.action.finish(result.map((_) {})));
    if (result case Failed(:final failure)) {
      state = state.copyWith(
        messages: [...state.messages, FailureMessage(_messageId++, failure)],
      );
      return false;
    }
    state = state.copyWith(
      active: true,
      address: result.valueOrNull?.url,
      createdAt: result.valueOrNull?.createdAt,
    );
    return true;
  }

  Future<bool> stop() async {
    state = state.copyWith(action: state.action.start());
    final result = await ref.read(clubRidesDataProvider).deleteFeed();
    if (!ref.mounted) return false;
    state = state.copyWith(action: state.action.finish(result));
    if (result case Failed(:final failure)) {
      state = state.copyWith(
        messages: [...state.messages, FailureMessage(_messageId++, failure)],
      );
      return false;
    }
    state = state.copyWith(active: false, clearAddress: true, createdAt: null);
    return true;
  }

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );
}
