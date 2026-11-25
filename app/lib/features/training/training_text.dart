import 'package:velomine_api/api.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../l10n/generated/app_localizations.dart';

/// The words of the training screens. The server sends every rider-facing session and goal text in English and
/// Italian together (`TrainingNames.md`), so the app picks the pair by the language it is showing instead of
/// holding a second copy. Only the words around them are in `app_en.arb` and `app_it.arb`.
String trainingText(
  AppLocalizations l10n, {
  required String english,
  required String italian,
}) => l10n.localeName.startsWith('it') ? italian : english;

/// The session's plain name, never the recipe code or the technical term.
String sessionName(AppLocalizations l10n, TrainingWeekSession session) =>
    trainingText(
      l10n,
      english: session.englishName,
      italian: session.italianName,
    );

/// The one line under the session's name: what it is, in plain words.
String sessionLine(AppLocalizations l10n, TrainingWeekSession session) =>
    trainingText(
      l10n,
      english: session.englishLine,
      italian: session.italianLine,
    );

/// A line the server sends under the targets, when a number cannot be given or needs explaining.
String noteText(AppLocalizations l10n, SessionNote note) =>
    trainingText(l10n, english: note.english, italian: note.italian);

/// A week's own line: the easy week, or that the plan gets more personal as rides come in.
String weekNoteText(AppLocalizations l10n, TrainingNote note) =>
    trainingText(l10n, english: note.english, italian: note.italian);

/// A block's name: the part it plays in the session, in the rider's words.
String blockRole(AppLocalizations l10n, String role) => switch (role) {
  'warmup' => l10n.trainingBlockWarmup,
  'recovery' => l10n.trainingBlockRecovery,
  'cooldown' => l10n.trainingBlockCooldown,
  _ => l10n.trainingBlockMain,
};

/// The set the rider follows today: the first main block, else the first block of a session without one.
BlockTarget? mainBlock(TrainingWeekSession session) =>
    session.blocks.where((block) => block.role == 'main').firstOrNull ??
    session.blocks.firstOrNull;

/// Whether a block is drawn as hard on the session's shape: an effort at feel 6 or more.
bool isHardBlock(BlockTarget block) => block.feelHigh >= 6;

/// One target range as a line reads it: "220–235 W", "220 W" when both ends agree.
String _range(int low, int high, String unit) =>
    low == high ? '$low $unit' : '$low–$high $unit';

/// "220–235 W", or "220 W" when both ends agree. Null without a watt target, which a rider without a power meter
/// has: `SessionNotes.AddPowerMeter` says why instead.
String? wattTarget(BlockTarget block) =>
    switch ((block.wattsLow, block.wattsHigh)) {
      (final low?, final high?) => _range(low, high, 'W'),
      _ => null,
    };

/// "152–160 bpm", marked as estimated when the server says the heart rate is.
String? heartRateTarget(
  AppLocalizations l10n,
  BlockTarget block, {
  required bool estimated,
}) {
  if (block.heartRateLow case final low?) {
    final range = _range(low, block.heartRateHigh ?? low, 'bpm');
    return estimated ? '$range (${l10n.trainingEstimated})' : range;
  }
  // An effort of two minutes or less has no heart-rate target: the session says heart rate lags there.
  return null;
}

/// "feel 5–6", always with its words: the scale alone says nothing.
String feelTarget(AppLocalizations l10n, BlockTarget block) =>
    block.feelLow == block.feelHigh
    ? l10n.trainingFeel('${block.feelLow}')
    : l10n.trainingFeel('${block.feelLow}–${block.feelHigh}');

/// One block's three targets on one line, the ones it has and in the order the rider reads them.
String targetLine(
  AppLocalizations l10n,
  BlockTarget block, {
  required bool estimated,
}) => [
  ?wattTarget(block),
  ?heartRateTarget(l10n, block, estimated: estimated),
  feelTarget(l10n, block),
].join(' · ');

/// A session's length as the design writes it: "1 h 15", "1 h", "40 min", from the day's minutes.
String sessionLength(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '$rest min';
  return rest == 0 ? '$hours h' : '$hours h $rest';
}

/// How a session is going, as the page header says it: "done", "skipped", "planned".
String sessionStateWord(AppLocalizations l10n, String state) => switch (state) {
  'done' => l10n.trainingStateDone,
  'easy' => l10n.trainingStateEasy,
  'moved' => l10n.trainingStateMoved,
  'skipped' => l10n.trainingStateSkipped,
  'missed' => l10n.trainingStateMissed,
  _ => l10n.trainingStatePlanned,
};

/// The state as the week's badge reads it, with the score once a ride ticked the session: "Done · 92", "Skipped",
/// or null while it is still planned, because the name alone is the plan.
String? sessionState(AppLocalizations l10n, TrainingWeekSession session) {
  if (session.state == 'planned') return null;
  if (session.state == 'done') {
    final score = session.result.orElse(null)?.score;
    return score == null
        ? l10n.trainingStateDone
        : l10n.trainingStateDoneScore(score);
  }
  return sessionStateWord(l10n, session.state);
}

/// Why today was made easy, in the four ways the owner approved. The check-in's own answers never reach the app: the
/// server sends this reason and nothing else.
String easyReasonText(AppLocalizations l10n, String reason) => switch (reason) {
  'slept_poorly' => l10n.trainingEasySleptPoorly,
  'tired' => l10n.trainingEasyTired,
  'sore' => l10n.trainingEasySore,
  'asked' => l10n.trainingEasyAsked,
  _ => l10n.trainingEasyFormLow,
};

/// "Easy today: you slept poorly. The hard day moves to Thursday.": the one line that says why today changed, on the
/// today card and in the notification.
String easyLine(AppLocalizations l10n, String reason, {DateTime? movedTo}) {
  final line = l10n.trainingEasyLine(easyReasonText(l10n, reason));
  if (movedTo == null) return line;
  return '$line ${l10n.trainingEasyMoved(_weekday(l10n, movedTo))}';
}

/// A day as a line names it: "Thursday", "giovedì".
String _weekday(AppLocalizations l10n, DateTime date) =>
    DateFormat('EEEE', l10n.localeName).format(date);

/// Why a day cannot take a session, as the move sheet says it under the day.
String moveRefusalText(AppLocalizations l10n, String reason) =>
    switch (reason) {
      'next_to_hard' => l10n.trainingMoveRefusedHard,
      'next_to_long_ride' => l10n.trainingMoveRefusedLongRide,
      'too_many_loaded_days' => l10n.trainingMoveRefusedLoaded,
      _ => l10n.trainingMoveRefusedSession,
    };

/// Why the rider skipped a session, in the words their own picker offers: "Tired", "Ill or injured", "No time",
/// "Other". The same words a coach reads beside a skipped day, so they live here once and both screens use them.
String trainingSkipReason(AppLocalizations l10n, String reason) =>
    switch (reason) {
      'tired' => l10n.trainingSkipReasonTired,
      'ill' => l10n.trainingSkipReasonIll,
      'no_time' => l10n.trainingSkipReasonNoTime,
      _ => l10n.trainingSkipReasonOther,
    };
