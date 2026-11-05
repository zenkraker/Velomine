import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:velomine_api/api.dart';

import '../../core/guard.dart';

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
  String? error;
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
      what: 'load your notifications',
    );
    loading = false;
    notifyListeners();
  }

  Future<void> markRead(NotificationResponse n) async {
    if (n.isRead) return;
    error = await guardCall(
      () => api.markNotificationRead(n.id),
      onUnauthorized,
      what: 'mark it read',
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
      what: 'mark them read',
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
String notificationText(NotificationResponse n) => switch (n.type) {
  'ride_ready' => 'Your ride ${n.subject} is ready.',
  'ride_failed' => '${n.subject} could not be read.',
  'ride_duplicate' => '${n.subject} was already uploaded, so it is hidden.',
  'signup_waiting' => '${n.subject} signed up and is waiting for approval.',
  'part_soon' => '${n.subject} is nearly worn.',
  'part_worn' => '${n.subject} is worn out. Time to replace it.',
  _ => n.subject,
};

/// Where tapping a notification goes, or null when there is nowhere to go.
String? notificationTarget(NotificationResponse n) => switch (n.type) {
  'ride_ready' ||
  'ride_failed' ||
  'ride_duplicate' when n.rideId != null => '/rides/${n.rideId}',
  'part_soon' || 'part_worn' when n.bikeId != null => '/bikes/${n.bikeId}',
  'signup_waiting' => '/admin',
  _ => null,
};
