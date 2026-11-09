import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';

part 'club_data.g.dart';

/// The club endpoints as values: the ViewModels never see an exception.
class ClubData {
  ClubData(this._api);

  final ClubApi _api;

  Future<Result<MyClubResponse?>> myClub() =>
      _api.getMyClub().guard(FailureAction.loadClub);

  Future<Result<MyClubResponse?>> join(String code) =>
      _api.joinClub(JoinClubRequest(code: code)).guard(FailureAction.joinClub);

  Future<Result<void>> leave() =>
      _api.leaveClub().guard(FailureAction.leaveClub);

  Future<Result<JoinCodeResponse?>> rotateCode() =>
      _api.rotateJoinCode().guard(FailureAction.rotateJoinCode);

  Future<Result<MyClubResponse?>> setLocation(
    double? latitude,
    double? longitude, {
    required bool isDiscoverable,
  }) => _api
      .setClubLocation(
        SetClubLocationRequest(
          latitude: Optional.present(latitude),
          longitude: Optional.present(longitude),
          isDiscoverable: isDiscoverable,
        ),
      )
      .guard(FailureAction.updateClub);

  Future<Result<ClubMemberResponse?>> setRole(String userId, String role) =>
      _api
          .setClubMemberRole(userId, SetClubMemberRoleRequest(role: role))
          .guard(FailureAction.changeClubRole);

  Future<Result<NearbyClubsResponse?>> nearby(
    ({double latitude, double longitude}) point,
    int radiusKm,
  ) => _api
      .nearbyClubs(
        NearbyClubsRequest(
          latitude: Optional.present(point.latitude),
          longitude: Optional.present(point.longitude),
          radiusKm: Optional.present(radiusKm),
        ),
      )
      .guard(FailureAction.loadNearbyClubs);

  Future<Result<MyJoinRequestResponse?>> myJoinRequest() =>
      _api.getMyJoinRequest().guard(FailureAction.loadJoinRequests);

  Future<Result<MyJoinRequestResponse?>> requestToJoin(
    String clubId,
    String? note,
  ) {
    final trimmed = note?.trim();
    return _api
        .requestToJoin(
          RequestToJoinRequest(
            clubId: clubId,
            note: trimmed == null || trimmed.isEmpty
                ? const Optional.absent()
                : Optional.present(trimmed),
          ),
        )
        .guard(FailureAction.requestJoinClub);
  }

  Future<Result<void>> cancelJoinRequest() =>
      _api.cancelJoinRequest().guard(FailureAction.cancelJoinRequest);

  Future<Result<JoinRequestsResponse?>> joinRequests() =>
      _api.listJoinRequests().guard(FailureAction.loadJoinRequests);

  Future<Result<void>> approveJoinRequest(String id) =>
      _api.approveJoinRequest(id).guard(FailureAction.approveJoinRequest);

  Future<Result<void>> declineJoinRequest(String id) =>
      _api.declineJoinRequest(id).guard(FailureAction.declineJoinRequest);
}

@Riverpod(keepAlive: true)
ClubData clubData(Ref ref) => ClubData(ref.watch(sessionProvider).clubs);
