import 'package:flutter/foundation.dart';
import 'package:velomine_api/api.dart';

import '../../../core/failure.dart';
import '../../../core/guard.dart';
import 'ride_series.dart';

/// One ride: its numbers, its samples for the charts and map, and deleting it.
class RideDetailController extends ChangeNotifier {
  RideDetailController({
    required this.api,
    required this.bikesApi,
    required this.id,
    required this.onUnauthorized,
    this.pollInterval = const Duration(seconds: 1),
  });

  final RidesApi api;
  final BikesApi bikesApi;
  final String id;
  final VoidCallback onUnauthorized;
  final Duration pollInterval;

  /// The moment picked on a chart (an index into the samples), shared by every chart and the map.
  final selected = ValueNotifier<int?>(null);

  RideResponse? ride;

  /// The member's bikes, to pick the one ridden. Empty when they could not be loaded: the ride still shows.
  List<BikeResponse> bikes = [];
  RideSeries? data;

  /// How the ride felt, owned by this member. Loaded only for a ready ride.
  RideFeelResponse? feel;
  bool loading = true;
  bool savingFeel = false;
  bool notFound = false;
  Failure? error;
  bool _disposed = false;

  Future<void> load() async {
    for (var attempt = 0; attempt < 120 && !_disposed; attempt++) {
      try {
        ride = await api.getRide(id);
        if (ride == null) throw ApiException(404, 'No ride');
        if (ride!.status == 'processing') {
          loading = false;
          notifyListeners();
          await Future<void>.delayed(pollInterval);
          continue;
        }
        if (ride!.status == 'ready') {
          final streams = await api.getRideStreams(id, maxPoints: 1200);
          if (streams != null) data = RideSeries.from(streams);
          try {
            bikes = (await bikesApi.listBikes())?.bikes ?? [];
          } on Object {
            bikes = [];
          }
          try {
            feel = await api.wellbeingGetRideFeel(id);
          } on ApiException catch (e) {
            if (e.code == 401) onUnauthorized();
          } on Object {
            feel = null;
          }
        }
        error = null;
      } on ApiException catch (e) {
        if (e.code == 401) {
          onUnauthorized();
        } else if (e.code == 404) {
          notFound = true;
        } else {
          error = Failure(
            FailureKind.failed,
            code: e.code,
            action: FailureAction.loadRide,
          );
        }
      } on Object {
        error = Failure(
          FailureKind.unreachable,
          action: FailureAction.loadRide,
        );
      }
      break;
    }
    loading = false;
    if (!_disposed) notifyListeners();
  }

  /// Says which bike was ridden (null for none).
  Future<void> setBike(String? bikeId) async {
    try {
      ride =
          await api.setRideBike(
            id,
            SetRideBikeRequest(bikeId: Optional.present(bikeId)),
          ) ??
          ride;
      error = null;
    } on ApiException catch (e) {
      if (e.code == 401) onUnauthorized();
      error = Failure(
        FailureKind.failed,
        code: e.code,
        action: FailureAction.changeRideBike,
      );
    } on Object {
      error = Failure(
        FailureKind.unreachable,
        action: FailureAction.changeRideBike,
      );
    }
    notifyListeners();
  }

  /// Returns whether the RPE and note were saved.
  Future<bool> saveFeel(int rpe, String? notes) async {
    savingFeel = true;
    notifyListeners();
    final failure = await guardCall(
      () async {
        feel = await api.wellbeingSaveRideFeel(
          id,
          SaveRideFeelRequest(rpe: rpe, notes: Optional.present(notes)),
        );
      },
      onUnauthorized,
      doing: FailureAction.saveWellbeing,
    );
    savingFeel = false;
    error = failure;
    notifyListeners();
    return failure == null;
  }

  /// Returns whether the RPE and note were removed.
  Future<bool> deleteFeel() async {
    savingFeel = true;
    notifyListeners();
    final failure = await guardCall(
      () async {
        await api.wellbeingDeleteRideFeel(id);
        feel = RideFeelResponse(
          consentRequired: feel?.consentRequired ?? false,
          rpe: null,
          notes: null,
        );
      },
      onUnauthorized,
      doing: FailureAction.saveWellbeing,
    );
    savingFeel = false;
    error = failure;
    notifyListeners();
    return failure == null;
  }

  /// Returns whether the ride was deleted.
  Future<bool> delete() async {
    try {
      await api.deleteRide(id);
      return true;
    } on ApiException catch (e) {
      if (e.code == 401) onUnauthorized();
      error = Failure(
        FailureKind.failed,
        code: e.code,
        action: FailureAction.deleteRide,
      );
    } on Object {
      error = Failure(
        FailureKind.unreachable,
        action: FailureAction.deleteRide,
      );
    }
    notifyListeners();
    return false;
  }

  @override
  void dispose() {
    _disposed = true;
    selected.dispose();
    super.dispose();
  }
}
