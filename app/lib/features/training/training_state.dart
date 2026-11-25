import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';

/// Auto training as the Training page and the settings switch read it: the plan, how loading it went and the
/// answer to turning it off.
class TrainingState {
  const TrainingState({
    this.plan,
    this.load = const CommandState.idle(),
    this.turnOff = const CommandState.idle(),
    this.messages = const [],
  });

  final TrainingPlanResponse? plan;
  final CommandState<TrainingPlanResponse?> load;
  final CommandState<TrainingPlanResponse?> turnOff;
  final List<UserMessage> messages;

  /// Whether the rider turned auto training on. An operator's switch is the server's answer, not this one.
  bool get on => plan?.on_ ?? false;

  TrainingState copyWith({
    TrainingPlanResponse? plan,
    CommandState<TrainingPlanResponse?>? load,
    CommandState<TrainingPlanResponse?>? turnOff,
    List<UserMessage>? messages,
  }) => TrainingState(
    plan: plan ?? this.plan,
    load: load ?? this.load,
    turnOff: turnOff ?? this.turnOff,
    messages: messages ?? this.messages,
  );
}
