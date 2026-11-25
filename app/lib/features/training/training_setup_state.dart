import 'package:velomine_api/api.dart';

import '../../core/command.dart';

/// What is wrong with the setup as it stands, so the view can say it in the language on screen.
enum TrainingSetupProblem { days, hours, maxHeartRate, birthYear }

/// The three answers of the setup, filled from the plan when there is one, and how loading and saving went.
class TrainingSetupState {
  const TrainingSetupState({
    this.load = const CommandState.idle(),
    this.save = const CommandState.idle(),
    this.goal,
    this.suggestedGoal,
    this.suggestionReason,
    this.days = const {},
    this.hours = '',
    this.longRideDay,
    this.maxHeartRateUnknown = true,
    this.maxHeartRate = '',
    this.birthYear = '',
    this.needsBirthYear = true,
    this.nextEventName,
    this.nextEventDate,
    this.problem,
  });

  final CommandState<TrainingPlanResponse?> load;
  final CommandState<TrainingPlanResponse?> save;

  /// The goal on the form: the saved one, else the suggested one.
  final String? goal;
  final String? suggestedGoal;

  /// The code of the reason the suggested goal carries, as the server picked it.
  final String? suggestionReason;

  final Set<String> days;
  final String hours;

  /// The chosen long-ride day, or null for "Velomine picks".
  final String? longRideDay;

  /// "I don't know": on when Velomine has no typed or measured maximum.
  final bool maxHeartRateUnknown;
  final String maxHeartRate;
  final String birthYear;

  /// Whether the setup has to ask for the year of birth, because the account has none.
  final bool needsBirthYear;

  final String? nextEventName;
  final DateTime? nextEventDate;

  /// The first thing that stops Start, or null when the setup can be saved.
  final TrainingSetupProblem? problem;

  /// Start is a form's submit: a missing year of birth keeps it disabled, as the guideline asks.
  bool get canStart =>
      !save.running && (!needsBirthYear || birthYear.trim().isNotEmpty);

  bool get loading => load.running && load.result == null;

  TrainingSetupState copyWith({
    CommandState<TrainingPlanResponse?>? load,
    CommandState<TrainingPlanResponse?>? save,
    String? goal,
    String? suggestedGoal,
    String? suggestionReason,
    Set<String>? days,
    String? hours,
    String? longRideDay,
    bool clearLongRideDay = false,
    bool? maxHeartRateUnknown,
    String? maxHeartRate,
    String? birthYear,
    bool? needsBirthYear,
    String? nextEventName,
    DateTime? nextEventDate,
    TrainingSetupProblem? problem,
    bool clearProblem = false,
  }) => TrainingSetupState(
    load: load ?? this.load,
    save: save ?? this.save,
    goal: goal ?? this.goal,
    suggestedGoal: suggestedGoal ?? this.suggestedGoal,
    suggestionReason: suggestionReason ?? this.suggestionReason,
    days: days ?? this.days,
    hours: hours ?? this.hours,
    longRideDay: clearLongRideDay ? null : (longRideDay ?? this.longRideDay),
    maxHeartRateUnknown: maxHeartRateUnknown ?? this.maxHeartRateUnknown,
    maxHeartRate: maxHeartRate ?? this.maxHeartRate,
    birthYear: birthYear ?? this.birthYear,
    needsBirthYear: needsBirthYear ?? this.needsBirthYear,
    nextEventName: nextEventName ?? this.nextEventName,
    nextEventDate: nextEventDate ?? this.nextEventDate,
    problem: clearProblem ? null : (problem ?? this.problem),
  );
}
