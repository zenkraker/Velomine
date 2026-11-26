import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';

/// The member's goals, the call that reads them and the writes in flight.
class GoalsState {
  const GoalsState({
    this.goals = const [],
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final List<GoalResponse> goals;
  final CommandState<ListGoalsResponse?> load;
  final VoidCommand action;
  final List<UserMessage> messages;

  GoalsState copyWith({
    List<GoalResponse>? goals,
    CommandState<ListGoalsResponse?>? load,
    VoidCommand? action,
    List<UserMessage>? messages,
  }) => GoalsState(
    goals: goals ?? this.goals,
    load: load ?? this.load,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}
