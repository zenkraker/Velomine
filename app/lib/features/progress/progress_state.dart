import 'package:material_ui/material_ui.dart';
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
    this.history = const [],
  });

  final CommandState<PowerCurveResponse?> load;
  final VoidCommand action;
  final List<UserMessage> messages;

  /// The member's own FTP history, newest first: it says where the current FTP came from. Empty
  /// when the history could not be read, and nothing to say is better than a wrong note.
  final List<FtpHistoryEntry> history;

  PowerState copyWith({
    CommandState<PowerCurveResponse?>? load,
    VoidCommand? action,
    List<UserMessage>? messages,
    List<FtpHistoryEntry>? history,
  }) => PowerState(
    load: load ?? this.load,
    action: action ?? this.action,
    messages: messages ?? this.messages,
    history: history ?? this.history,
  );
}

class FtpReminderState {
  const FtpReminderState({
    this.check,
    this.suggestion,
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  /// The check as the server answered it; null reason means there is nothing to show.
  final FtpCheckResponse? check;

  /// The FTP a ride suggests; while it is there the reminder stays quiet.
  final FtpSuggestionResponse? suggestion;
  final VoidCommand action;
  final List<UserMessage> messages;

  FtpReminderState copyWith({
    FtpCheckResponse? check,
    // Not `?? this`: a suggestion that was just answered has to be able to go away.
    FtpSuggestionResponse? suggestion,
    VoidCommand? action,
    List<UserMessage>? messages,
  }) => FtpReminderState(
    check: check ?? this.check,
    suggestion: suggestion,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}

class ReadinessState {
  const ReadinessState({this.load = const CommandState.idle()});

  final CommandState<ReadinessResponse?> load;
}

/// The member's open heart-rate suggestions, with the profile that says what each is above.
class HeartRateSuggestionState {
  const HeartRateSuggestionState({
    this.suggestions = const [],
    this.profile,
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final List<HeartRateSuggestionResponse> suggestions;
  final ProfileResponse? profile;
  final VoidCommand action;
  final List<UserMessage> messages;

  HeartRateSuggestionState copyWith({
    List<HeartRateSuggestionResponse>? suggestions,
    ProfileResponse? profile,
    VoidCommand? action,
    List<UserMessage>? messages,
  }) => HeartRateSuggestionState(
    suggestions: suggestions ?? this.suggestions,
    profile: profile ?? this.profile,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}

/// The rider's races and other events, next first.
class EventsState {
  const EventsState({
    this.events = const [],
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final List<EventResponse> events;
  final CommandState<List<EventResponse>> load;
  final VoidCommand action;
  final List<UserMessage> messages;

  /// The next one that has not happened yet, or null when there is none.
  EventResponse? get next {
    final today = DateUtils.dateOnly(DateTime.now());
    return events.where((e) => !e.date.isBefore(today)).firstOrNull;
  }

  EventsState copyWith({
    List<EventResponse>? events,
    CommandState<List<EventResponse>>? load,
    VoidCommand? action,
    List<UserMessage>? messages,
  }) => EventsState(
    events: events ?? this.events,
    load: load ?? this.load,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
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
