import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/result.dart';
import '../../core/units.dart';
import '../rides/detail/ride_series.dart';
import 'coach_data.dart';
import 'coach_state.dart';

part 'coach_ride_view_model.g.dart';

/// One athlete's ride, read-only: the numbers, the samples and, only when
/// shared, the route.
@riverpod
class CoachRideViewModel extends _$CoachRideViewModel {
  @override
  CoachRideState build(String clubId, String userId, String rideId) {
    Future.microtask(load);
    return const CoachRideState();
  }

  Future<void> load() async {
    if (state.load.running) return;
    state = state.copyWith(load: state.load.start());
    final data = ref.read(coachDataProvider);

    final rideResult = await data.ride(clubId, userId, rideId);
    if (!ref.mounted) return;
    if (rideResult case Failed(:final failure)) {
      state = failure.kind == FailureKind.missing
          ? state.copyWith(
              load: state.load.finish(const Ok(null)),
              notFound: true,
            )
          : state.copyWith(load: state.load.finish(rideResult));
      return;
    }

    final ride = rideResult.valueOrNull;
    var laps = const <LapResponse>[];
    RideSeries? series;
    if (ride != null && ride.status == 'ready') {
      // No samples or laps leaves the numbers usable; the file simply has none.
      series = switch (await data.rideStreams(clubId, userId, rideId)) {
        Ok(:final value) when value != null => RideSeries.from(
          value,
          ref.read(unitsChoiceViewModelProvider),
        ),
        _ => null,
      };
      laps =
          (await data.rideLaps(clubId, userId, rideId)).valueOrNull?.laps ??
          const [];
    }
    if (!ref.mounted) return;
    state = CoachRideState(
      ride: ride,
      laps: laps,
      data: series,
      load: state.load.finish(rideResult),
      messages: state.messages,
    );
  }
}
