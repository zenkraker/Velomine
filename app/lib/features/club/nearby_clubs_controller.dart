import 'package:flutter/foundation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/guard.dart';
import '../../core/location_service.dart';

/// Clubs within reach of the rider's position, and the one join request they may have open.
class NearbyClubsController extends ChangeNotifier {
  NearbyClubsController({required this.api, required this.onUnauthorized});

  final ClubApi api;
  final VoidCallback onUnauthorized;

  List<NearbyClubResponse> clubs = [];
  PendingJoinRequestResponse? request;
  Failure? error;
  bool loading = false;

  /// Asking to join or taking the ask back is in flight.
  bool busy = false;

  GeoPoint? position;
  int radiusKm = 50;

  Future<void> refresh(GeoPoint point, {int? radiusKm}) async {
    position = point;
    if (radiusKm != null) this.radiusKm = radiusKm;
    loading = true;
    error = null;
    notifyListeners();

    NearbyClubsResponse? nearby;
    MyJoinRequestResponse? mine;
    final failure = await guardCall(
      () async {
        nearby = await api.nearbyClubs(
          NearbyClubsRequest(
            latitude: Optional.present(point.latitude),
            longitude: Optional.present(point.longitude),
            radiusKm: Optional.present(this.radiusKm),
          ),
        );
        mine = await api.getMyJoinRequest();
      },
      onUnauthorized,
      doing: FailureAction.loadNearbyClubs,
    );

    if (failure == null) {
      clubs = nearby?.clubs ?? [];
      request = mine?.request;
    }
    loading = false;
    error = failure;
    notifyListeners();
  }

  /// Returns the reason it failed, for the row to explain; null on success.
  /// Reads the rider's open ask without needing a position; the club tab uses this.
  Future<void> loadRequest() async {
    MyJoinRequestResponse? mine;
    final failure = await guardCall(
      () async => mine = await api.getMyJoinRequest(),
      onUnauthorized,
      doing: FailureAction.loadJoinRequests,
    );
    if (failure == null) {
      request = mine?.request;
      notifyListeners();
    }
  }

  Future<Failure?> askToJoin(String clubId, String? note) async {
    busy = true;
    notifyListeners();
    final trimmed = note?.trim();
    MyJoinRequestResponse? mine;
    final failure = await guardCall(
      () async => mine = await api.requestToJoin(
        RequestToJoinRequest(
          clubId: clubId,
          note: trimmed == null || trimmed.isEmpty
              ? const Optional.absent()
              : Optional.present(trimmed),
        ),
      ),
      onUnauthorized,
      doing: FailureAction.requestJoinClub,
    );
    if (failure == null) request = mine?.request;
    busy = false;
    notifyListeners();
    return failure;
  }

  Future<Failure?> cancelRequest() async {
    busy = true;
    notifyListeners();
    final failure = await guardCall(
      api.cancelJoinRequest,
      onUnauthorized,
      doing: FailureAction.cancelJoinRequest,
    );
    if (failure == null) request = null;
    busy = false;
    notifyListeners();
    return failure;
  }

  void reset() {
    clubs = [];
    request = null;
    error = null;
    loading = false;
    busy = false;
    position = null;
    notifyListeners();
  }
}
