import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';

/// Auto training as the Training page and the settings switch read it: the plan, the weeks the page shows, how
/// loading them went and the answer to turning it off.
class TrainingState {
  const TrainingState({
    this.plan,
    this.weeks = const [],
    this.load = const CommandState.idle(),
    this.week = const CommandState.idle(),
    this.turnOff = const CommandState.idle(),
    this.messages = const [],
  });

  final TrainingPlanResponse? plan;

  /// This week, and next week as the preview on the week's last day. Empty while auto training is off.
  final List<TrainingWeek> weeks;

  final CommandState<TrainingPlanResponse?> load;
  final CommandState<TrainingWeeksResponse?> week;
  final CommandState<TrainingPlanResponse?> turnOff;
  final List<UserMessage> messages;

  /// Whether the rider turned auto training on. An operator's switch is the server's answer, not this one.
  bool get on => plan?.on_ ?? false;

  /// This week, once the server has answered.
  TrainingWeek? get thisWeek => weeks.firstOrNull;

  /// Next week's preview, which the server sends on the week's last day only.
  TrainingWeek? get nextWeek => weeks.length > 1 ? weeks[1] : null;

  TrainingState copyWith({
    TrainingPlanResponse? plan,
    List<TrainingWeek>? weeks,
    CommandState<TrainingPlanResponse?>? load,
    CommandState<TrainingWeeksResponse?>? week,
    CommandState<TrainingPlanResponse?>? turnOff,
    List<UserMessage>? messages,
  }) => TrainingState(
    plan: plan ?? this.plan,
    weeks: weeks ?? this.weeks,
    load: load ?? this.load,
    week: week ?? this.week,
    turnOff: turnOff ?? this.turnOff,
    messages: messages ?? this.messages,
  );
}
