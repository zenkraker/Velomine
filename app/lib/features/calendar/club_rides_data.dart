import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';

part 'club_rides_data.g.dart';

/// The club calendar endpoints as values: the ViewModels never see an exception.
class ClubRidesData {
  ClubRidesData(this._api);

  final ClubApi _api;

  Future<Result<ClubRideListResponse?>> list() =>
      _api.listClubRides().guard(FailureAction.loadClubRides);

  Future<Result<ClubRideDetailResponse?>> ride(String id) =>
      _api.getClubRide(id).guard(FailureAction.loadClubRide);

  Future<Result<ClubRideDetailResponse?>> plan(PlanClubRideRequest request) =>
      _api.planClubRide(request).guard(FailureAction.saveClubRide);

  Future<Result<ClubRideDetailResponse?>> update(
    String id,
    UpdateClubRideRequest request,
  ) => _api.updateClubRide(id, request).guard(FailureAction.saveClubRide);

  Future<Result<ClubRideDetailResponse?>> cancel(String id) =>
      _api.cancelClubRide(id).guard(FailureAction.cancelClubRide);

  Future<Result<ClubRideDetailResponse?>> join(String id) =>
      _api.joinClubRide(id).guard(FailureAction.joinClubRide);

  Future<Result<void>> leave(String id) =>
      _api.leaveClubRide(id).guard(FailureAction.leaveClubRide);

  Future<Result<CalendarFeedStatusResponse?>> feedStatus() =>
      _api.getCalendarFeed().guard(FailureAction.loadCalendarFeed);

  Future<Result<CalendarFeedAddressResponse?>> createFeed() =>
      _api.createCalendarFeed().guard(FailureAction.saveCalendarFeed);

  Future<Result<void>> deleteFeed() =>
      _api.deleteCalendarFeed().guard(FailureAction.saveCalendarFeed);
}

@Riverpod(keepAlive: true)
ClubRidesData clubRidesData(Ref ref) =>
    ClubRidesData(ref.watch(sessionProvider).clubs);
