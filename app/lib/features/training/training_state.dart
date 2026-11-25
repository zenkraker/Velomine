import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';

/// Auto training as the Training page and the settings switch read it: the plan, this week, how loading them went
/// and the answers to turning it off and to a session's question. A sign-out rebuilds it empty.
class TrainingState {
  const TrainingState({
    this.plan,
    this.weeks,
    this.load = const CommandState.idle(),
    this.turnOff = const CommandState.idle(),
    this.answer = const CommandState.idle(),
    this.messages = const [],
  });

  final TrainingPlanResponse? plan;

  /// This week, and next week on its last day: the sessions with their state and, when a ride did one, its score.
  final TrainingWeeksResponse? weeks;

  final CommandState<TrainingPlanResponse?> load;
  final CommandState<TrainingPlanResponse?> turnOff;

  /// Answering "Was this your …?": yes or no, run by the ride page.
  final VoidCommand answer;

  final List<UserMessage> messages;

  /// Whether the rider turned auto training on. An operator's switch is the server's answer, not this one.
  bool get on => plan?.on_ ?? false;

  /// The session of this week with that id, or null when it is next week's or gone.
  TrainingWeekSession? session(String id) {
    for (final week in weeks?.weeks ?? const <TrainingWeek>[]) {
      for (final session in week.sessions) {
        if (session.id == id) return session;
      }
    }
    return null;
  }

  TrainingState copyWith({
    TrainingPlanResponse? plan,
    TrainingWeeksResponse? weeks,
    CommandState<TrainingPlanResponse?>? load,
    CommandState<TrainingPlanResponse?>? turnOff,
    VoidCommand? answer,
    List<UserMessage>? messages,
  }) => TrainingState(
    plan: plan ?? this.plan,
    weeks: weeks ?? this.weeks,
    load: load ?? this.load,
    turnOff: turnOff ?? this.turnOff,
    answer: answer ?? this.answer,
    messages: messages ?? this.messages,
  );
}
