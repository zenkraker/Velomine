import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/result.dart';
import 'coach_data.dart';
import 'coach_state.dart';

part 'coach_athlete_view_model.g.dart';

/// One athlete: the shared summary, training load, power curve, wellbeing and rides.
@riverpod
class CoachAthleteViewModel extends _$CoachAthleteViewModel {
  @override
  CoachAthleteState build(String clubId, String userId) {
    Future.microtask(load);
    return const CoachAthleteState();
  }

  Future<void> load() async {
    if (state.load.running) return;
    state = state.copyWith(load: state.load.start());
    final data = ref.read(coachDataProvider);

    final summaryResult = await data.athlete(clubId, userId);
    if (!ref.mounted) return;
    if (summaryResult case Failed(:final failure)) {
      state = failure.kind == FailureKind.missing
          ? state.copyWith(
              load: state.load.finish(const Ok(null)),
              notFound: true,
            )
          : state.copyWith(load: state.load.finish(summaryResult));
      return;
    }

    final summary = summaryResult.valueOrNull;
    TrainingResponse? training;
    PowerCurveResponse? powerCurve;
    CoachWellbeingResponse? wellbeing;
    List<RideResponse> rides = const [];

    if (summary != null) {
      if (summary.sharesAnalytics) {
        training = (await data.training(
          clubId,
          userId,
          state.days,
        )).valueOrNull;
        powerCurve = (await data.powerCurve(
          clubId,
          userId,
          state.days,
        )).valueOrNull;
      }
      if (summary.sharesWellbeing) {
        wellbeing = (await data.wellbeing(clubId, userId)).valueOrNull;
      }
      if (summary.sharesRides) {
        rides =
            (await data.rides(clubId, userId)).valueOrNull?.rides ?? const [];
      }
    }
    if (!ref.mounted) return;
    state = CoachAthleteState(
      summary: summary,
      training: training,
      powerCurve: powerCurve,
      wellbeing: wellbeing,
      rides: rides,
      days: state.days,
      load: state.load.finish(summaryResult),
      messages: state.messages,
    );
  }

  /// Changes the range shown by the training and power cards.
  Future<void> setDays(int value) async {
    if (value == state.days || state.range.running) return;
    state = state.copyWith(
      days: value,
      range: state.range.start(),
      clearTraining: true,
      clearPowerCurve: true,
    );
    final data = ref.read(coachDataProvider);
    final training = await data.training(clubId, userId, value);
    final curve = await data.powerCurve(clubId, userId, value);
    if (!ref.mounted) return;
    final failure = training.failureOrNull ?? curve.failureOrNull;
    state = state.copyWith(
      range: state.range.finish(
        failure == null ? const Ok(null) : Failed(failure),
      ),
      training: training.valueOrNull,
      powerCurve: curve.valueOrNull,
      clearTraining: training.valueOrNull == null,
      clearPowerCurve: curve.valueOrNull == null,
    );
  }
}
