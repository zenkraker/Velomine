import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/guard.dart';
import '../../l10n/generated/app_localizations.dart';

/// The member's notifications and how many are unread. While signed in it checks again every [pollInterval],
/// so the bell shows news (a ride read, a part worn) without a reload.
class NotificationsController extends ChangeNotifier {
  NotificationsController({
    required this.api,
    required this.onUnauthorized,
    this.pollInterval = const Duration(minutes: 1),
  });

  final NotificationsApi api;
  final VoidCallback onUnauthorized;
  final Duration pollInterval;

  List<NotificationResponse> items = [];
  int unread = 0;
  bool loading = false;
  Failure? error;
  Timer? _timer;

  bool get running => _timer != null;

  void start() {
    if (running) return;
    refresh();
    _timer = Timer.periodic(pollInterval, (_) => refresh());
  }

  /// Signing out: stop checking and forget what was shown.
  void stop() {
    _timer?.cancel();
    _timer = null;
    items = [];
    unread = 0;
    error = null;
    notifyListeners();
  }

  /// Also called while a screen is being built, so it only tells listeners once the answer is in.
  Future<void> refresh() async {
    loading = true;
    error = await guardCall(
      () async {
        final list = await api.listNotifications();
        items = list?.notifications ?? [];
        unread = list?.unreadCount ?? 0;
      },
      onUnauthorized,
      doing: FailureAction.loadNotifications,
    );
    loading = false;
    notifyListeners();
  }

  Future<void> markRead(NotificationResponse n) async {
    if (n.isRead) return;
    error = await guardCall(
      () => api.markNotificationRead(n.id),
      onUnauthorized,
      doing: FailureAction.markRead,
    );
    if (error == null) {
      items = [
        for (final i in items) i.id == n.id ? i.copyWith(isRead: true) : i,
      ];
      if (unread > 0) unread--;
    }
    notifyListeners();
  }

  Future<void> markAllRead() async {
    error = await guardCall(
      api.markAllNotificationsRead,
      onUnauthorized,
      doing: FailureAction.markAllRead,
    );
    if (error == null) {
      items = [for (final i in items) i.copyWith(isRead: true)];
      unread = 0;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// The sentence for a notification. The server sends its type and subject; wording lives in the app.
String notificationText(AppLocalizations l10n, NotificationResponse n) =>
    switch (n.type) {
      'ride_ready' => l10n.notificationRideReady(n.subject),
      'ride_failed' => l10n.notificationRideFailed(n.subject),
      'ride_duplicate' => l10n.notificationRideDuplicate(n.subject),
      'signup_waiting' => l10n.notificationSignupWaiting(n.subject),
      'part_soon' => l10n.notificationPartSoon(n.subject),
      'part_worn' => l10n.notificationPartWorn(n.subject),
      'club_join_request' => l10n.notificationClubJoinRequest(n.subject),
      'club_join_approved' => l10n.notificationClubJoinApproved(n.subject),
      'club_join_declined' => l10n.notificationClubJoinDeclined(n.subject),
      _ => n.subject,
    };

/// Where tapping a notification goes, or null when there is nowhere to go.
String? notificationTarget(NotificationResponse n) => switch (n.type) {
  'ride_ready' ||
  'ride_failed' ||
  'ride_duplicate' when n.rideId != null => '/rides/${n.rideId}',
  'part_soon' || 'part_worn' when n.bikeId != null => '/bikes/${n.bikeId}',
  'signup_waiting' => '/admin',
  'club_join_request' ||
  'club_join_approved' ||
  'club_join_declined' => '/club',
  _ => null,
};
