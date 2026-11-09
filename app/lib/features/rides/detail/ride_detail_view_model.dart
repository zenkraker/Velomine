import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../../core/failure.dart';
import '../../../core/providers.dart';
import '../../../core/result.dart';
import '../../../core/user_message.dart';
import 'ride_detail_data.dart';
import 'ride_detail_state.dart';

part 'ride_detail_view_model.g.dart';

/// One ride, read fresh on the detail route. A processing upload is polled
/// until the server has read it.
@riverpod
class RideDetailViewModel extends _$RideDetailViewModel {
  static const _watchAttempts = 120;

  int _messageId = 0;

  @override
  RideDetailState build(String id) {
    Future.microtask(load);
    return const RideDetailState();
  }

  Future<void> load() async {
    if (state.load.running) return;
    state = state.copyWith(load: state.load.start(), notFound: false);
    final data = ref.read(rideDetailDataProvider);
    final interval = ref.read(ridePollIntervalProvider);

    RideResponse? ride;
    for (var attempt = 0; attempt < _watchAttempts; attempt++) {
      final result = await data.ride(id);
      if (!ref.mounted) return;
      if (result case Failed(:final failure)) {
        state = failure.kind == FailureKind.missing
            ? state.copyWith(
                load: state.load.finish(const Ok(null)),
                notFound: true,
              )
            : state.copyWith(load: state.load.finish(result));
        return;
      }
      ride = result.valueOrNull;
      if (ride == null) {
        state = state.copyWith(
          load: state.load.finish(const Ok(null)),
          notFound: true,
        );
        return;
      }
      if (ride.status != 'processing') break;

      state = state.copyWith(ride: ride, load: state.load.finish(result));
      await Future<void>.delayed(interval);
      if (!ref.mounted) return;
      state = state.copyWith(load: state.load.start());
    }
    if (ride == null) {
      state = state.copyWith(load: state.load.finish(const Ok(null)));
      return;
    }

    if (ride.status != 'ready') {
      state = state.copyWith(ride: ride, load: state.load.finish(Ok(ride)));
      return;
    }

    // A missing piece leaves the ride usable: laps, bikes and the feel are the
    // extras, not the job.
    final series = (await data.series(id)).valueOrNull;
    final laps = (await data.laps(id)).valueOrNull ?? const [];
    final bikes = (await data.bikes()).valueOrNull ?? const [];
    final feel = (await data.feel(id)).valueOrNull;
    if (!ref.mounted) return;
    state = RideDetailState(
      ride: ride,
      series: series,
      laps: laps,
      bikes: bikes,
      feel: feel,
      load: state.load.finish(Ok(ride)),
      messages: state.messages,
    );
  }

  /// Says which bike was ridden (null for none).
  Future<void> setBike(String? bikeId) =>
      _action(() => ref.read(rideDetailDataProvider).setBike(id, bikeId));

  /// Sets the four independent ride dimensions.
  Future<bool> setType({
    String? discipline,
    String? assist,
    String? environment,
    bool? commute,
  }) => _action(
    () => ref
        .read(rideDetailDataProvider)
        .setType(
          id,
          discipline: discipline,
          assist: assist,
          environment: environment,
          commute: commute,
        ),
  );

  Future<bool> saveFeel(int rpe, String? notes) =>
      _feel(() => ref.read(rideDetailDataProvider).saveFeel(id, rpe, notes));

  Future<bool> deleteFeel() => _feel(() async {
    final result = await ref.read(rideDetailDataProvider).deleteFeel(id);
    return result.map(
      (_) => RideFeelResponse(
        consentRequired: state.feel?.consentRequired ?? false,
        rpe: null,
        notes: null,
      ),
    );
  });

  /// Returns whether the ride was deleted.
  Future<bool> deleteRide() async {
    if (state.action.running) return false;
    state = state.copyWith(action: state.action.start());
    final result = await ref.read(rideDetailDataProvider).deleteRide(id);
    if (!ref.mounted) return false;
    state = state.copyWith(action: state.action.finish(result));
    if (result case Failed(:final failure)) {
      _fail(failure);
      return false;
    }
    return true;
  }

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );

  Future<bool> _action(Future<Result<RideResponse?>> Function() call) async {
    if (state.action.running) return false;
    state = state.copyWith(action: state.action.start());
    final result = await call();
    if (!ref.mounted) return false;
    state = state.copyWith(action: state.action.finish(result));
    if (result case Failed(:final failure)) {
      _fail(failure);
      return false;
    }
    final ride = result.valueOrNull;
    if (ride != null) state = state.copyWith(ride: ride);
    return true;
  }

  Future<bool> _feel(Future<Result<RideFeelResponse?>> Function() call) async {
    if (state.feelCommand.running) return false;
    state = state.copyWith(feelCommand: state.feelCommand.start());
    final result = await call();
    if (!ref.mounted) return false;
    state = state.copyWith(feelCommand: state.feelCommand.finish(result));
    if (result case Failed(:final failure)) {
      _fail(failure);
      return false;
    }
    final feel = result.valueOrNull;
    if (feel != null) state = state.copyWith(feel: feel);
    return true;
  }

  void _fail(Failure failure) => state = state.copyWith(
    messages: [...state.messages, FailureMessage(_messageId++, failure)],
  );
}
