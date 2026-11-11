import 'package:velomine_api/api.dart';

import '../../l10n/generated/app_localizations.dart';

/// The sentence for a notification. The server sends its type and subject; wording lives in the app.
String notificationText(AppLocalizations l10n, NotificationResponse n) =>
    switch (n.type) {
      'ride_ready' => l10n.notificationRideReady(n.subject),
      'ride_failed' => l10n.notificationRideFailed(n.subject),
      'ride_duplicate' => l10n.notificationRideDuplicate(n.subject),
      'ride_import' => l10n.notificationRideImport(n.subject),
      'signup_waiting' => l10n.notificationSignupWaiting(n.subject),
      'part_soon' => l10n.notificationPartSoon(n.subject),
      'part_worn' => l10n.notificationPartWorn(n.subject),
      'reminder_soon' => l10n.notificationReminderSoon(n.subject),
      'reminder_due' => l10n.notificationReminderDue(n.subject),
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
  'part_soon' ||
  'part_worn' ||
  'reminder_soon' ||
  'reminder_due' when n.bikeId != null => '/bikes/${n.bikeId}',
  'signup_waiting' => '/admin',
  'club_join_request' ||
  'club_join_approved' ||
  'club_join_declined' => '/club',
  _ => null,
};
