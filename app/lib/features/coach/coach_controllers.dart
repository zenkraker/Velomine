import 'package:flutter/foundation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/guard.dart';
import '../rides/detail/ride_series.dart';

/// The athletes a coach may look at: club members who shared rides or training.
class CoachAthletesController extends ChangeNotifier {
  CoachAthletesController({required this.api, required this.onUnauthorized});

  final ClubsApi api;
  final VoidCallback onUnauthorized;

  List<CoachAthleteResponse> athletes = [];
  bool loading = false;
  Failure? error;

  Future<void> refresh(String clubId) async {
    loading = true;
    error = null;
    notifyListeners();
    CoachAthletesResponse? list;
    error = await guardCall(
      () async => list = await api.coachListCoachAthletes(clubId),
      onUnauthorized,
      doing: FailureAction.loadAthletes,
    );
    if (error == null) athletes = list?.athletes ?? [];
    loading = false;
    notifyListeners();
  }
}

/// One athlete: their summary, their training range and their recent rides.
class CoachAthleteController extends ChangeNotifier {
  CoachAthleteController({
    required this.api,
    required this.onUnauthorized,
    this.days = 90,
  });

  final ClubsApi api;
  final VoidCallback onUnauthorized;
  int days;

  CoachAthleteResponse? summary;
  TrainingResponse? training;
  List<RideResponse> rides = [];
  bool loading = true;
  bool notFound = false;
  Failure? error;

  bool _disposed = false;
  int _trainingRequest = 0;

  Future<void> load(String clubId, String userId) async {
    _trainingRequest++;
    loading = true;
    notFound = false;
    error = null;
    notifyListeners();
    try {
      summary = await api.coachGetCoachAthlete(clubId, userId);
      if (summary == null) {
        notFound = true;
      } else {
        if (summary!.sharesAnalytics) {
          training = await api.coachGetCoachTraining(
            clubId,
            userId,
            days: days,
          );
        }
        if (summary!.sharesRides) {
          rides = (await api.coachListCoachRides(clubId, userId))?.rides ?? [];
        }
      }
    } on ApiException catch (e) {
      if (e.code == 401) {
        onUnauthorized();
      } else if (e.code == 404) {
        notFound = true;
      } else {
        error = Failure(
          FailureKind.failed,
          code: e.code,
          action: FailureAction.loadAthlete,
        );
      }
    } on Object {
      error = const Failure(
        FailureKind.unreachable,
        action: FailureAction.loadAthlete,
      );
    }
    if (_disposed) return;
    loading = false;
    notifyListeners();
  }

  Future<void> setDays(String clubId, String userId, int value) async {
    if (value == days) return;
    final request = ++_trainingRequest;
    days = value;
    training = null;
    error = null;
    notifyListeners();
    try {
      final result = await api.coachGetCoachTraining(
        clubId,
        userId,
        days: days,
      );
      // A slower earlier request must not overwrite the range the coach picked last.
      if (_disposed || request != _trainingRequest) return;
      training = result;
    } on ApiException catch (e) {
      if (_disposed || request != _trainingRequest) return;
      if (e.code == 401) {
        onUnauthorized();
        return;
      }
      if (e.code == 404) {
        notFound = true;
      } else {
        error = Failure(
          FailureKind.failed,
          code: e.code,
          action: FailureAction.loadAthlete,
        );
      }
    } on Object {
      if (_disposed || request != _trainingRequest) return;
      error = const Failure(
        FailureKind.unreachable,
        action: FailureAction.loadAthlete,
      );
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// One athlete's ride, read-only: the numbers, the samples and (only when shared) the route.
class CoachRideController extends ChangeNotifier {
  CoachRideController({required this.api, required this.onUnauthorized});

  final ClubsApi api;
  final VoidCallback onUnauthorized;

  final selected = ValueNotifier<int?>(null);
  RideResponse? ride;
  RideSeries? data;
  bool loading = true;
  bool notFound = false;
  Failure? error;

  Future<void> load(String clubId, String userId, String rideId) async {
    loading = true;
    notFound = false;
    error = null;
    notifyListeners();
    try {
      ride = await api.coachGetCoachRide(clubId, userId, rideId);
      if (ride == null) {
        notFound = true;
      } else if (ride!.status == 'ready') {
        try {
          final streams = await api.coachGetCoachRideStreams(
            clubId,
            userId,
            rideId,
            maxPoints: 1200,
          );
          if (streams != null) data = RideSeries.from(streams);
        } on ApiException {
          // No samples (still being read, or the file had none): the numbers still show.
        }
      }
    } on ApiException catch (e) {
      if (e.code == 401) {
        onUnauthorized();
      } else if (e.code == 404) {
        notFound = true;
      } else {
        error = Failure(
          FailureKind.failed,
          code: e.code,
          action: FailureAction.loadCoachRide,
        );
      }
    } on Object {
      error = const Failure(
        FailureKind.unreachable,
        action: FailureAction.loadCoachRide,
      );
    }
    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    selected.dispose();
    super.dispose();
  }
}
