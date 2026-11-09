import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';

/// How many periods the totals show: about a quarter of weeks, a year of
/// months, five years.
const periodCounts = {'week': 12, 'month': 12, 'year': 5};

class ProgressFiltersState {
  const ProgressFiltersState({
    this.period = 'week',
    this.discipline,
    this.trainingDays = 90,
    this.powerDays = 90,
  });

  final String period;
  final String? discipline;
  final int trainingDays;
  final int powerDays;

  ProgressFiltersState copyWith({
    String? period,
    String? discipline,
    bool clearDiscipline = false,
    int? trainingDays,
    int? powerDays,
  }) => ProgressFiltersState(
    period: period ?? this.period,
    discipline: clearDiscipline ? null : (discipline ?? this.discipline),
    trainingDays: trainingDays ?? this.trainingDays,
    powerDays: powerDays ?? this.powerDays,
  );
}

class TotalsState {
  const TotalsState({this.load = const CommandState.idle()});

  final CommandState<TotalsResponse?> load;
}

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

class TrainingState {
  const TrainingState({this.load = const CommandState.idle()});

  final CommandState<TrainingResponse?> load;
}

class PowerState {
  const PowerState({
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final CommandState<PowerCurveResponse?> load;
  final VoidCommand action;
  final List<UserMessage> messages;

  PowerState copyWith({
    CommandState<PowerCurveResponse?>? load,
    VoidCommand? action,
    List<UserMessage>? messages,
  }) => PowerState(
    load: load ?? this.load,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}

class ReadinessState {
  const ReadinessState({this.load = const CommandState.idle()});

  final CommandState<ReadinessResponse?> load;
}

class WellbeingState {
  const WellbeingState({
    this.today,
    this.checkIns,
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final WellbeingResponse? today;
  final CheckInsResponse? checkIns;
  final CommandState<WellbeingResponse?> load;
  final VoidCommand action;
  final List<UserMessage> messages;

  WellbeingState copyWith({
    WellbeingResponse? today,
    CheckInsResponse? checkIns,
    CommandState<WellbeingResponse?>? load,
    VoidCommand? action,
    List<UserMessage>? messages,
  }) => WellbeingState(
    today: today ?? this.today,
    checkIns: checkIns ?? this.checkIns,
    load: load ?? this.load,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}
