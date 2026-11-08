import 'package:flutter/foundation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/guard.dart';

/// What the member shares with their club, and who has looked. Choices are none, coaches or club.
class SharingController extends ChangeNotifier {
  SharingController({required this.api, required this.onUnauthorized});

  final SharingApi api;
  final VoidCallback onUnauthorized;

  String rides = 'none';
  String analytics = 'none';
  String routes = 'none';
  List<ShareViewResponse> views = [];
  bool loading = false;
  bool saving = false;
  bool loaded = false;
  Failure? error;

  /// Forgets everything, e.g. after leaving the club or signing out.
  void reset() {
    rides = 'none';
    analytics = 'none';
    routes = 'none';
    views = [];
    loading = false;
    saving = false;
    loaded = false;
    error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    SharingResponse? sharing;
    ShareViewsResponse? views;
    error = await guardCall(
      () async {
        final results = await Future.wait([
          api.getSharing(),
          api.getShareViews(),
        ]);
        sharing = results[0] as SharingResponse?;
        views = results[1] as ShareViewsResponse?;
      },
      onUnauthorized,
      doing: FailureAction.loadSharing,
    );
    if (error == null) {
      if (sharing != null) {
        rides = sharing!.rides;
        analytics = sharing!.analytics;
        routes = sharing!.routes;
      }
      this.views = views?.views ?? [];
      loaded = true;
    }
    loading = false;
    notifyListeners();
  }

  /// Saves one change, keeping the other choices as they are. Returns the failure, or null.
  Future<Failure?> choose({
    String? rides,
    String? analytics,
    String? routes,
  }) async {
    final nextRides = rides ?? this.rides;
    final nextAnalytics = analytics ?? this.analytics;
    final nextRoutes = routes ?? this.routes;
    saving = true;
    notifyListeners();
    final failure = await guardCall(
      () => api.updateSharing(
        UpdateSharingRequest(
          rides: nextRides,
          analytics: nextAnalytics,
          routes: nextRoutes,
        ),
      ),
      onUnauthorized,
      doing: FailureAction.saveSharing,
    );
    if (failure == null) {
      this.rides = nextRides;
      this.analytics = nextAnalytics;
      this.routes = nextRoutes;
    }
    error = failure;
    saving = false;
    notifyListeners();
    return failure;
  }
}
