import 'package:flutter/foundation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/guard.dart';

/// What the club's owner has to answer: riders who asked to join.
class JoinRequestsController extends ChangeNotifier {
  JoinRequestsController({required this.api, required this.onUnauthorized});

  final ClubApi api;
  final VoidCallback onUnauthorized;

  List<JoinRequestResponse> requests = [];
  Failure? error;
  bool loading = false;
  bool busy = false;

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    JoinRequestsResponse? list;
    final failure = await guardCall(
      () async => list = await api.listJoinRequests(),
      onUnauthorized,
      doing: FailureAction.loadJoinRequests,
    );
    if (failure == null) requests = list?.requests ?? [];
    loading = false;
    error = failure;
    notifyListeners();
  }

  Future<Failure?> approve(String id) async {
    busy = true;
    notifyListeners();
    final failure = await guardCall(
      () => api.approveJoinRequest(id),
      onUnauthorized,
      doing: FailureAction.approveJoinRequest,
    );
    busy = false;
    if (failure == null) {
      await refresh();
    } else {
      notifyListeners();
    }
    return failure;
  }

  Future<Failure?> decline(String id) async {
    busy = true;
    notifyListeners();
    final failure = await guardCall(
      () => api.declineJoinRequest(id),
      onUnauthorized,
      doing: FailureAction.declineJoinRequest,
    );
    busy = false;
    if (failure == null) {
      await refresh();
    } else {
      notifyListeners();
    }
    return failure;
  }

  void reset() {
    requests = [];
    error = null;
    loading = false;
    busy = false;
    notifyListeners();
  }
}
