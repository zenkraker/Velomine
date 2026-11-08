import 'package:flutter/foundation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/guard.dart';

/// The signed-in account's club. One account belongs to one club, so a single club is the whole state.
class ClubController extends ChangeNotifier {
  ClubController({required this.api, required this.onUnauthorized});

  final ClubApi api;
  final VoidCallback onUnauthorized;

  ClubResponse? club;
  Failure? error;
  bool loading = false;

  /// True once the server has answered: only then can the app tell "no club" from "not asked yet".
  bool loaded = false;

  /// A change (join, leave, new code, role) is in flight.
  bool busy = false;

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    MyClubResponse? my;
    error = await guardCall(
      () async => my = await api.getMyClub(),
      onUnauthorized,
      doing: FailureAction.loadClub,
    );
    if (error == null) {
      club = my?.club;
      loaded = true;
    }
    loading = false;
    notifyListeners();
  }

  /// The club is gone with the session: a different account may see a different one.
  void reset() {
    club = null;
    error = null;
    loading = false;
    loaded = false;
    busy = false;
    notifyListeners();
  }

  /// Returns the reason it failed, for the join screen to explain; null on success.
  Future<Failure?> join(String code) async {
    busy = true;
    notifyListeners();
    MyClubResponse? my;
    final failure = await guardCall(
      () async => my = await api.joinClub(JoinClubRequest(code: code)),
      onUnauthorized,
      doing: FailureAction.joinClub,
    );
    if (failure == null) {
      club = my?.club;
      loaded = true;
    }
    busy = false;
    notifyListeners();
    return failure;
  }

  Future<Failure?> leave() async {
    busy = true;
    notifyListeners();
    final failure = await guardCall(
      api.leaveClub,
      onUnauthorized,
      doing: FailureAction.leaveClub,
    );
    if (failure == null) {
      club = null;
      loaded = true;
    }
    busy = false;
    notifyListeners();
    return failure;
  }

  Future<Failure?> rotateCode() async {
    busy = true;
    notifyListeners();
    final failure = await guardCall(
      api.rotateJoinCode,
      onUnauthorized,
      doing: FailureAction.rotateJoinCode,
    );
    busy = false;
    if (failure == null) {
      await refresh();
    } else {
      notifyListeners();
    }
    return failure;
  }

  Future<Failure?> setRole(String userId, String role) async {
    busy = true;
    notifyListeners();
    final failure = await guardCall(
      () => api.setClubMemberRole(userId, SetClubMemberRoleRequest(role: role)),
      onUnauthorized,
      doing: FailureAction.changeClubRole,
    );
    busy = false;
    if (failure == null) {
      await refresh();
    } else {
      notifyListeners();
    }
    return failure;
  }
}
