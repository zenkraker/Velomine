import 'package:material_ui/material_ui.dart' show DateUtils;
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';

/// The goals the setup offers, in the order it shows them. The codes stay internal; the names are in TrainingNames.md.
const trainingGoalIds = ['aerobic', 'fitter', 'faster', 'event', 'keep'];

/// The days of the week as the API spells them, in the order the chips show them.
const trainingDayIds = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

String trainingGoalName(AppLocalizations l10n, String? goal) => switch (goal) {
  'aerobic' => l10n.goalAerobic,
  'faster' => l10n.goalFaster,
  'event' => l10n.goalEvent,
  'keep' => l10n.goalKeep,
  _ => l10n.goalFitter,
};

/// The one line under a goal in the setup, and the reason on the Training page's goal card.
String trainingGoalLine(AppLocalizations l10n, String goal) => switch (goal) {
  'aerobic' => l10n.goalLineAerobic,
  'faster' => l10n.goalFasterLine,
  'event' => l10n.goalLineEvent,
  'keep' => l10n.goalLineKeep,
  _ => l10n.goalLineFitter,
};

/// The one-line reason the setup shows under the suggested goal, from the code the server picked it with.
String trainingSuggestionReason(AppLocalizations l10n, String reason) =>
    switch (reason) {
      'not_enough_riding' => l10n.goalReasonNotEnoughRiding,
      'regular_riding' => l10n.goalReasonRegularRiding,
      'event_soon' => l10n.goalReasonEventSoon,
      'after_break' => l10n.goalReasonAfterBreak,
      'power_rides' => l10n.goalReasonPowerRides,
      _ => l10n.goalReasonRegularRider,
    };

/// "Mon", "Tue": a chip's label, in the language on screen.
String trainingDayShort(AppLocalizations l10n, String day) {
  // 2024-01-01 was a Monday, so the index into the week is the offset from it.
  final date = DateTime(2024, 1, 1 + trainingDayIds.indexOf(day));
  return DateFormat.E(l10n.localeName).format(date);
}

/// The long-ride day Velomine picks when the rider leaves it to Velomine: the last free weekend day (Sunday,
/// else Saturday), else the last free day. Null without a free day, which the setup refuses anyway.
String? defaultLongRideDay(Iterable<String> days) {
  for (final day in const ['sunday', 'saturday']) {
    if (days.contains(day)) return day;
  }
  final free = trainingDayIds.where(days.contains).toList();
  return free.isEmpty ? null : free.last;
}

/// The days of the plan in the order the setup shows them.
List<String> orderedDays(Iterable<String> days) =>
    trainingDayIds.where(days.contains).toList();

/// The session a ride might be, in the words the mock-up gives: "Was this your Thursday strong and steady?" A session
/// name is lowercase inside the sentence, as every name in TrainingNames.md reads there.
String trainingQuestion(AppLocalizations l10n, DateTime day, String name) =>
    l10n.trainingQuestionTitle(
      DateFormat.EEEE(l10n.localeName).format(day),
      _lowerFirst(name),
    );

/// The same session once the rider said the ride was it: "This was your Thursday strong and steady."
String trainingLinked(AppLocalizations l10n, DateTime day, String name) =>
    l10n.trainingLinkedTitle(
      DateFormat.EEEE(l10n.localeName).format(day),
      _lowerFirst(name),
    );

/// "This ride looks like the session planned for yesterday", or tomorrow: the question only ever asks about the day
/// before or after.
String trainingQuestionLine(
  AppLocalizations l10n,
  DateTime day,
  DateTime rideDay,
) => DateUtils.isSameDay(day, rideDay.subtract(const Duration(days: 1)))
    ? l10n.trainingQuestionYesterday
    : l10n.trainingQuestionTomorrow;

String _lowerFirst(String text) =>
    text.isEmpty ? text : text[0].toLowerCase() + text.substring(1);

/// The kind line under this week's rows: never red, never a streak, and nothing to catch up on.
String trainingWeekKind(AppLocalizations l10n, int done, int total) => switch ((
  done,
  total,
)) {
  (0, _) => l10n.trainingWeekKindNothing,
  (final done, final total) when done >= total => l10n.trainingWeekKindOnTrack,
  (final done, final total) when done * 2 >= total =>
    l10n.trainingWeekKindOnTrack,
  _ => l10n.trainingWeekKindStarted,
};

/// The score's own kind line, from how it went: praise for a session ridden to plan, and never a complaint.
String sessionScoreKind(AppLocalizations l10n, int score) => switch (score) {
  >= 95 => l10n.sessionKindSpotOn,
  >= 85 => l10n.sessionKindOnPlan,
  >= 70 => l10n.sessionKindClose,
  >= 50 => l10n.sessionKindMost,
  _ => l10n.sessionKindAny,
};
