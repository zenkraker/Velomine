import 'package:intl/intl.dart' show DateFormat;
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import '../../l10n/generated/app_localizations.dart';
import '../training/training_goals.dart';
import '../training/training_text.dart';

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
      'club_plan_ending' => l10n.notificationClubPlanEnding(_day(n.subject)),
      'club_plan_ended' => l10n.notificationClubPlanEnded(_day(n.subject)),
      'club_ride_planned' => l10n.notificationClubRidePlanned(n.subject),
      'club_ride_changed' => l10n.notificationClubRideChanged(n.subject),
      'club_ride_cancelled' => l10n.notificationClubRideCancelled(n.subject),
      'power_record' => l10n.notificationPowerRecord(n.subject),
      'ftp_suggested' => l10n.notificationFtpSuggested(n.subject),
      'heart_rate_measured' => _heartRate(l10n, n.subject, measured: true),
      'heart_rate_suggested' => _heartRate(l10n, n.subject, measured: false),
      // The day's session, a session made easy, moved or skipped: the notice carries the session and its reason, so
      // the app words the sentence in the language on screen.
      'training_today' => l10n.notificationTrainingToday(
        _trainingName(l10n, n),
      ),
      'training_easy' => _trainingEasy(l10n, n),
      'training_moved' => l10n.notificationTrainingMoved(
        _trainingName(l10n, n),
        _trainingDay(l10n, n.notice.orElse(null)?.localDate),
      ),
      'training_skipped' => l10n.notificationTrainingSkipped(
        _trainingName(l10n, n),
        _trainingDay(l10n, n.notice.orElse(null)?.localDate),
      ),
      // "Was this your Thursday strong and steady?": the same question the ride's page asks, answered there.
      'training_session_question' => switch (n.training.orElse(null)) {
        final question? => trainingQuestion(
          l10n,
          question.localDate,
          trainingText(
            l10n,
            english: question.englishName,
            italian: question.italianName,
          ),
        ),
        null => n.subject,
      },
      _ => n.subject,
    };

/// The session a training notice is about, in the language on screen; the subject keeps the account's own name.
String _trainingName(AppLocalizations l10n, NotificationResponse n) =>
    switch (n.notice.orElse(null)) {
      final notice? => trainingText(
        l10n,
        english: notice.englishName,
        italian: notice.italianName,
      ),
      null => n.subject.split('|').first,
    };

/// "Thursday": the day a training notice is about, from the session when the notice still has it.
String _trainingDay(AppLocalizations l10n, DateTime? day) =>
    day == null ? '' : DateFormat('EEEE', l10n.localeName).format(day);

/// "Easy today: you slept poorly. The hard day moves to Thursday.", the same line the today card shows.
String _trainingEasy(AppLocalizations l10n, NotificationResponse n) {
  final notice = n.notice.orElse(null);
  final reason = notice?.easyReason ?? n.subject.split('|').first;
  // A subject of "reason|yyyy-MM-dd" carries the day the hard session moved to, for a session that has since gone.
  final moved =
      notice?.easyMovedTo ??
      DateTime.tryParse(n.subject.split('|').skip(1).firstOrNull ?? '');
  return easyLine(l10n, reason, movedTo: moved);
}

/// A heart-rate notice's subject is "Maximum 192 bpm" or "Threshold 165 bpm", the same in every language.
String _heartRate(
  AppLocalizations l10n,
  String subject, {
  required bool measured,
}) {
  final match = RegExp(r'^(Maximum|Threshold) (\d+) bpm$').firstMatch(subject);
  if (match == null) return subject;
  final bpm = int.parse(match.group(2)!);
  final isMax = match.group(1) == 'Maximum';
  return switch ((measured, isMax)) {
    (true, true) => l10n.notificationHeartRateMaxMeasured(bpm),
    (true, false) => l10n.notificationHeartRateThresholdMeasured(bpm),
    (false, true) => l10n.notificationHeartRateMaxSuggested(bpm),
    (false, false) => l10n.notificationHeartRateThresholdSuggested(bpm),
  };
}

/// A plan notice's subject is the last paid day as yyyy-MM-dd; the sentence names it in the language on screen.
String _day(String subject) => dateOnly(DateTime.tryParse(subject));

/// Where tapping a notification goes, or null when there is nowhere to go.
String? notificationTarget(NotificationResponse n) => switch (n.type) {
  'training_easy' || 'training_moved' || 'training_skipped'
      when n.notice.orElse(null) != null =>
    '/training/sessions/${n.notice.orElse(null)!.sessionId}',
  'training_today' => '/training',
  'ride_ready' ||
  'ride_failed' ||
  'ride_duplicate' ||
  'power_record' ||
  'ftp_suggested' ||
  'heart_rate_measured' ||
  'heart_rate_suggested' ||
  'training_session_question' when n.rideId != null => '/rides/${n.rideId}',
  'part_soon' ||
  'part_worn' ||
  'reminder_soon' ||
  'reminder_due' when n.bikeId != null => '/bikes/${n.bikeId}',
  'signup_waiting' => '/admin',
  'club_join_request' ||
  'club_join_approved' ||
  'club_join_declined' ||
  'club_plan_ending' ||
  'club_plan_ended' => '/club',
  'club_ride_planned' || 'club_ride_changed' || 'club_ride_cancelled'
      when n.plannedRideId != null =>
    '/club/rides/${n.plannedRideId}',
  _ => null,
};
