import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';

part 'coach_data.g.dart';

/// The coach-scoped club endpoints as values.
class CoachData {
  CoachData(this._api);

  final ClubsApi _api;

  Future<Result<CoachAthletesResponse?>> athletes(String clubId) =>
      _api.coachListCoachAthletes(clubId).guard(FailureAction.loadAthletes);

  Future<Result<CoachAthleteResponse?>> athlete(String clubId, String userId) =>
      _api
          .coachGetCoachAthlete(clubId, userId)
          .guard(FailureAction.loadAthlete);

  Future<Result<TrainingResponse?>> training(
    String clubId,
    String userId,
    int days,
  ) => _api
      .coachGetCoachTraining(clubId, userId, days: days)
      .guard(FailureAction.loadAthlete);

  Future<Result<PowerCurveResponse?>> powerCurve(
    String clubId,
    String userId,
    int days,
  ) => _api
      .coachGetCoachPowerCurve(clubId, userId, days: days)
      .guard(FailureAction.loadAthlete);

  Future<Result<CoachWellbeingResponse?>> wellbeing(
    String clubId,
    String userId,
  ) => _api
      .coachGetCoachWellbeing(clubId, userId)
      .guard(FailureAction.loadAthlete);

  Future<Result<ListRidesResponse?>> rides(String clubId, String userId) =>
      _api.coachListCoachRides(clubId, userId).guard(FailureAction.loadRides);

  Future<Result<RideResponse?>> ride(
    String clubId,
    String userId,
    String rideId,
  ) => _api
      .coachGetCoachRide(clubId, userId, rideId)
      .guard(FailureAction.loadCoachRide);

  Future<Result<RideStreamsResponse?>> rideStreams(
    String clubId,
    String userId,
    String rideId,
  ) => _api
      .coachGetCoachRideStreams(clubId, userId, rideId, maxPoints: 1200)
      .guard(FailureAction.loadCoachRide);

  Future<Result<RideLapsResponse?>> rideLaps(
    String clubId,
    String userId,
    String rideId,
  ) => _api
      .coachGetCoachRideLaps(clubId, userId, rideId)
      .guard(FailureAction.loadCoachRide);
}

@Riverpod(keepAlive: true)
CoachData coachData(Ref ref) => CoachData(ref.watch(sessionProvider).coach);
