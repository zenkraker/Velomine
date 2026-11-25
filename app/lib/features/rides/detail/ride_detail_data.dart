import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../../core/failure.dart';
import '../../../core/providers.dart';
import '../../../core/result.dart';
import '../../../core/units.dart';
import 'ride_series.dart';

part 'ride_detail_data.g.dart';

/// The ride detail endpoints as values: the ViewModel never sees an exception.
class RideDetailData {
  RideDetailData(
    this._rides,
    this._bikes,
    this._sharing,
    this._analytics,
    this._accounts,
    this._training,
  );

  final RidesApi _rides;
  final BikesApi _bikes;
  final SharingApi _sharing;
  final AnalyticsApi _analytics;
  final AccountsApi _accounts;
  final TrainingApi _training;

  Future<Result<RideResponse?>> ride(String id) =>
      _rides.getRide(id).guard(FailureAction.loadRide);

  Future<Result<RideSeries?>> series(String id, Units units) async =>
      (await _rides
              .getRideStreams(id, maxPoints: 1200)
              .guard(FailureAction.loadRide))
          .map(
            (streams) =>
                streams == null ? null : RideSeries.from(streams, units),
          );

  Future<Result<List<LapResponse>>> laps(String id) async =>
      (await _rides.getRideLaps(id).guard(FailureAction.loadRide))
          .map((laps) => laps?.laps ?? const <LapResponse>[]);

  Future<Result<List<BikeResponse>>> bikes() async =>
      (await _bikes.listBikes().guard(FailureAction.loadBikes))
          .map((bikes) => bikes?.bikes ?? const <BikeResponse>[]);

  /// Who looked at this ride, most recent first. Only the owner can read it.
  Future<Result<List<ShareViewResponse>>> views(String id) async =>
      (await _sharing.getShareViews(rideId: id).guard(FailureAction.loadRide))
          .map((views) => views?.views ?? const <ShareViewResponse>[]);

  Future<Result<RideFeelResponse?>> feel(String id) =>
      _rides.wellbeingGetRideFeel(id).guard(FailureAction.loadRide);

  Future<Result<RideResponse?>> setBike(String id, String? bikeId) => _rides
      .setRideBike(id, SetRideBikeRequest(bikeId: Optional.present(bikeId)))
      .guard(FailureAction.changeRideBike);

  /// Every argument is sent, including null, so the sheet always writes the
  /// four values it shows.
  Future<Result<RideResponse?>> setType(
    String id, {
    String? discipline,
    String? assist,
    String? environment,
    bool? commute,
  }) => _rides
      .setRideType(
        id,
        SetRideTypeRequest(
          discipline: Optional.present(discipline),
          assist: Optional.present(assist),
          environment: Optional.present(environment),
          commute: Optional.present(commute),
        ),
      )
      .guard(FailureAction.changeRideType);

  /// Both texts replace what was there; null removes one. [version] is the ride's version as the member last
  /// saw it, so a change made elsewhere meanwhile is refused instead of overwritten.
  Future<Result<RideResponse?>> setDetails(
    String id, {
    String? title,
    String? description,
    required int version,
  }) => _rides
      .setRideDetails(
        id,
        SetRideDetailsRequest(
          title: Optional.present(title),
          description: Optional.present(description),
          version: Optional.present(version),
        ),
      )
      .guard(FailureAction.saveRideDetails);

  Future<Result<RideFeelResponse?>> saveFeel(
    String id,
    int rpe,
    String? notes,
  ) => _rides
      .wellbeingSaveRideFeel(
        id,
        SaveRideFeelRequest(rpe: rpe, notes: Optional.present(notes)),
      )
      .guard(FailureAction.saveWellbeing);

  Future<Result<void>> deleteFeel(String id) =>
      _rides.wellbeingDeleteRideFeel(id).guard(FailureAction.saveWellbeing);

  Future<Result<void>> deleteRide(String id) =>
      _rides.deleteRide(id).guard(FailureAction.deleteRide);

  /// Answers the auto-training session's question about this ride: yes ticks it, no leaves it open.
  Future<Result<void>> answerSession(
    String sessionId,
    String rideId, {
    required bool yes,
  }) => _training
      .matchTrainingSession(
        sessionId,
        MatchTrainingSessionRequest(rideId: rideId, answer: yes ? 'yes' : 'no'),
      )
      .guard(FailureAction.matchTrainingSession);

  /// Adopts the ride's suggestion: the server sets the FTP and records this ride as where it came from.
  Future<Result<ProfileResponse?>> acceptFtpSuggestion(String id) =>
      _analytics.acceptFtpSuggestion(id).guard(FailureAction.setFtp);

  Future<Result<void>> dismissFtpSuggestion(String id) =>
      _analytics.dismissFtpSuggestion(id).guard(FailureAction.setFtp);

  /// The member's profile, for the value a heart-rate note measured or the one a suggestion is above.
  Future<Result<ProfileResponse?>> profile() =>
      _accounts.getProfile().guard(FailureAction.loadRide);

  /// The member's open heart-rate suggestions, to find the one this ride caused.
  Future<Result<List<HeartRateSuggestionResponse>>>
  heartRateSuggestions() async =>
      (await _analytics.listHeartRateSuggestions().guard(
        FailureAction.loadRide,
      )).map(
        (list) => list?.suggestions ?? const <HeartRateSuggestionResponse>[],
      );

  Future<Result<ProfileResponse?>> acceptHeartRateSuggestion(String id) =>
      _analytics.acceptHeartRateSuggestion(id).guard(FailureAction.saveProfile);

  Future<Result<void>> dismissHeartRateSuggestion(String id) => _analytics
      .dismissHeartRateSuggestion(id)
      .guard(FailureAction.saveProfile);
}

@Riverpod(keepAlive: true)
RideDetailData rideDetailData(Ref ref) {
  final session = ref.watch(sessionProvider);
  return RideDetailData(
    session.rides,
    session.bikes,
    session.sharing,
    session.analytics,
    session.accounts,
    session.training,
  );
}
