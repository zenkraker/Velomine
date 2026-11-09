import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';
import '../rides/detail/ride_series.dart';

class CoachAthletesState {
  const CoachAthletesState({
    this.athletes = const [],
    this.load = const CommandState.idle(),
    this.messages = const [],
  });

  final List<CoachAthleteResponse> athletes;
  final CommandState<CoachAthletesResponse?> load;
  final List<UserMessage> messages;

  CoachAthletesState copyWith({
    List<CoachAthleteResponse>? athletes,
    CommandState<CoachAthletesResponse?>? load,
    List<UserMessage>? messages,
  }) => CoachAthletesState(
    athletes: athletes ?? this.athletes,
    load: load ?? this.load,
    messages: messages ?? this.messages,
  );
}

class CoachAthleteState {
  const CoachAthleteState({
    this.summary,
    this.training,
    this.powerCurve,
    this.wellbeing,
    this.rides = const [],
    this.days = 90,
    this.notFound = false,
    this.load = const CommandState.idle(),
    this.range = const CommandState.idle(),
    this.messages = const [],
  });

  final CoachAthleteResponse? summary;
  final TrainingResponse? training;
  final PowerCurveResponse? powerCurve;
  final CoachWellbeingResponse? wellbeing;
  final List<RideResponse> rides;
  final int days;
  final bool notFound;
  final CommandState<CoachAthleteResponse?> load;

  /// Loading a different range for the same athlete.
  final VoidCommand range;
  final List<UserMessage> messages;

  CoachAthleteState copyWith({
    CoachAthleteResponse? summary,
    bool clearSummary = false,
    TrainingResponse? training,
    bool clearTraining = false,
    PowerCurveResponse? powerCurve,
    bool clearPowerCurve = false,
    CoachWellbeingResponse? wellbeing,
    bool clearWellbeing = false,
    List<RideResponse>? rides,
    int? days,
    bool? notFound,
    CommandState<CoachAthleteResponse?>? load,
    VoidCommand? range,
    List<UserMessage>? messages,
  }) => CoachAthleteState(
    summary: clearSummary ? null : (summary ?? this.summary),
    training: clearTraining ? null : (training ?? this.training),
    powerCurve: clearPowerCurve ? null : (powerCurve ?? this.powerCurve),
    wellbeing: clearWellbeing ? null : (wellbeing ?? this.wellbeing),
    rides: rides ?? this.rides,
    days: days ?? this.days,
    notFound: notFound ?? this.notFound,
    load: load ?? this.load,
    range: range ?? this.range,
    messages: messages ?? this.messages,
  );
}

class CoachRideState {
  const CoachRideState({
    this.ride,
    this.laps = const [],
    this.data,
    this.notFound = false,
    this.load = const CommandState.idle(),
    this.messages = const [],
  });

  final RideResponse? ride;
  final List<LapResponse> laps;
  final RideSeries? data;
  final bool notFound;
  final CommandState<RideResponse?> load;
  final List<UserMessage> messages;

  CoachRideState copyWith({
    RideResponse? ride,
    List<LapResponse>? laps,
    RideSeries? data,
    bool? notFound,
    CommandState<RideResponse?>? load,
    List<UserMessage>? messages,
  }) => CoachRideState(
    ride: ride ?? this.ride,
    laps: laps ?? this.laps,
    data: data ?? this.data,
    notFound: notFound ?? this.notFound,
    load: load ?? this.load,
    messages: messages ?? this.messages,
  );
}
