//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class TrainingPlanResponse {
  /// Returns a new [TrainingPlanResponse] instance.
  TrainingPlanResponse({
    required this.on_,
    required this.goal,
    required this.suggestedGoal,
    required this.suggestionReason,
    this.days = const [],
    required this.hoursPerWeek,
    required this.longRideDay,
    required this.lastPlannedFor,
    required this.maxHeartRate,
    required this.maxHeartRateSource,
    required this.birthYear,
    required this.nextEventName,
    required this.nextEventDate,
    required this.firstDayOfWeek,
  });

  final bool on_;

  final String? goal;

  final String suggestedGoal;

  final String suggestionReason;

  final List<String> days;

  final int? hoursPerWeek;

  final String? longRideDay;

  final DateTime? lastPlannedFor;

  final int? maxHeartRate;

  final String? maxHeartRateSource;

  final int? birthYear;

  final String? nextEventName;

  final DateTime? nextEventDate;

  final String firstDayOfWeek;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TrainingPlanResponse &&
    other.on_ == on_ &&
    other.goal == goal &&
    other.suggestedGoal == suggestedGoal &&
    other.suggestionReason == suggestionReason &&
    _deepEquality.equals(other.days, days) &&
    other.hoursPerWeek == hoursPerWeek &&
    other.longRideDay == longRideDay &&
    other.lastPlannedFor == lastPlannedFor &&
    other.maxHeartRate == maxHeartRate &&
    other.maxHeartRateSource == maxHeartRateSource &&
    other.birthYear == birthYear &&
    other.nextEventName == nextEventName &&
    other.nextEventDate == nextEventDate &&
    other.firstDayOfWeek == firstDayOfWeek;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (on_.hashCode) +
    (goal == null ? 0 : goal!.hashCode) +
    (suggestedGoal.hashCode) +
    (suggestionReason.hashCode) +
    (days.hashCode) +
    (hoursPerWeek == null ? 0 : hoursPerWeek!.hashCode) +
    (longRideDay == null ? 0 : longRideDay!.hashCode) +
    (lastPlannedFor == null ? 0 : lastPlannedFor!.hashCode) +
    (maxHeartRate == null ? 0 : maxHeartRate!.hashCode) +
    (maxHeartRateSource == null ? 0 : maxHeartRateSource!.hashCode) +
    (birthYear == null ? 0 : birthYear!.hashCode) +
    (nextEventName == null ? 0 : nextEventName!.hashCode) +
    (nextEventDate == null ? 0 : nextEventDate!.hashCode) +
    (firstDayOfWeek.hashCode);

  @override
  String toString() => 'TrainingPlanResponse[on_=$on_, goal=$goal, suggestedGoal=$suggestedGoal, suggestionReason=$suggestionReason, days=$days, hoursPerWeek=$hoursPerWeek, longRideDay=$longRideDay, lastPlannedFor=$lastPlannedFor, maxHeartRate=$maxHeartRate, maxHeartRateSource=$maxHeartRateSource, birthYear=$birthYear, nextEventName=$nextEventName, nextEventDate=$nextEventDate, firstDayOfWeek=$firstDayOfWeek]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'on'] = this.on_;
    if (this.goal != null) {
      json[r'goal'] = this.goal;
    } else {
      json[r'goal'] = null;
    }
      json[r'suggestedGoal'] = this.suggestedGoal;
      json[r'suggestionReason'] = this.suggestionReason;
      json[r'days'] = this.days;
    if (this.hoursPerWeek != null) {
      json[r'hoursPerWeek'] = this.hoursPerWeek;
    } else {
      json[r'hoursPerWeek'] = null;
    }
    if (this.longRideDay != null) {
      json[r'longRideDay'] = this.longRideDay;
    } else {
      json[r'longRideDay'] = null;
    }
    if (this.lastPlannedFor != null) {
      json[r'lastPlannedFor'] = _dateFormatter.format(this.lastPlannedFor!);
    } else {
      json[r'lastPlannedFor'] = null;
    }
    if (this.maxHeartRate != null) {
      json[r'maxHeartRate'] = this.maxHeartRate;
    } else {
      json[r'maxHeartRate'] = null;
    }
    if (this.maxHeartRateSource != null) {
      json[r'maxHeartRateSource'] = this.maxHeartRateSource;
    } else {
      json[r'maxHeartRateSource'] = null;
    }
    if (this.birthYear != null) {
      json[r'birthYear'] = this.birthYear;
    } else {
      json[r'birthYear'] = null;
    }
    if (this.nextEventName != null) {
      json[r'nextEventName'] = this.nextEventName;
    } else {
      json[r'nextEventName'] = null;
    }
    if (this.nextEventDate != null) {
      json[r'nextEventDate'] = _dateFormatter.format(this.nextEventDate!);
    } else {
      json[r'nextEventDate'] = null;
    }
      json[r'firstDayOfWeek'] = this.firstDayOfWeek;
    return json;
  }

  /// Clones this instance of [TrainingPlanResponse] and returns a new one where some of the
  /// properties have changed.
  TrainingPlanResponse copyWith({
    bool? on_,
    String? goal,
    bool goalSetToNull = false,
    String? suggestedGoal,
    String? suggestionReason,
    List<String>? days,
    int? hoursPerWeek,
    bool hoursPerWeekSetToNull = false,
    String? longRideDay,
    bool longRideDaySetToNull = false,
    DateTime? lastPlannedFor,
    bool lastPlannedForSetToNull = false,
    int? maxHeartRate,
    bool maxHeartRateSetToNull = false,
    String? maxHeartRateSource,
    bool maxHeartRateSourceSetToNull = false,
    int? birthYear,
    bool birthYearSetToNull = false,
    String? nextEventName,
    bool nextEventNameSetToNull = false,
    DateTime? nextEventDate,
    bool nextEventDateSetToNull = false,
    String? firstDayOfWeek,
  }) => TrainingPlanResponse(
    on_: on_ ?? this.on_,
    goal: goalSetToNull ? null : goal ?? this.goal,
    suggestedGoal: suggestedGoal ?? this.suggestedGoal,
    suggestionReason: suggestionReason ?? this.suggestionReason,
    days: days ?? this.days,
    hoursPerWeek: hoursPerWeekSetToNull ? null : hoursPerWeek ?? this.hoursPerWeek,
    longRideDay: longRideDaySetToNull ? null : longRideDay ?? this.longRideDay,
    lastPlannedFor: lastPlannedForSetToNull ? null : lastPlannedFor ?? this.lastPlannedFor,
    maxHeartRate: maxHeartRateSetToNull ? null : maxHeartRate ?? this.maxHeartRate,
    maxHeartRateSource: maxHeartRateSourceSetToNull ? null : maxHeartRateSource ?? this.maxHeartRateSource,
    birthYear: birthYearSetToNull ? null : birthYear ?? this.birthYear,
    nextEventName: nextEventNameSetToNull ? null : nextEventName ?? this.nextEventName,
    nextEventDate: nextEventDateSetToNull ? null : nextEventDate ?? this.nextEventDate,
    firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
  );

  /// Returns a new [TrainingPlanResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TrainingPlanResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'on'), 'Required key "TrainingPlanResponse[on]" is missing from JSON.');
        assert(json[r'on'] != null, 'Required key "TrainingPlanResponse[on]" has a null value in JSON.');
        assert(json.containsKey(r'goal'), 'Required key "TrainingPlanResponse[goal]" is missing from JSON.');
        assert(json.containsKey(r'suggestedGoal'), 'Required key "TrainingPlanResponse[suggestedGoal]" is missing from JSON.');
        assert(json[r'suggestedGoal'] != null, 'Required key "TrainingPlanResponse[suggestedGoal]" has a null value in JSON.');
        assert(json.containsKey(r'suggestionReason'), 'Required key "TrainingPlanResponse[suggestionReason]" is missing from JSON.');
        assert(json[r'suggestionReason'] != null, 'Required key "TrainingPlanResponse[suggestionReason]" has a null value in JSON.');
        assert(json.containsKey(r'days'), 'Required key "TrainingPlanResponse[days]" is missing from JSON.');
        assert(json[r'days'] != null, 'Required key "TrainingPlanResponse[days]" has a null value in JSON.');
        assert(json.containsKey(r'hoursPerWeek'), 'Required key "TrainingPlanResponse[hoursPerWeek]" is missing from JSON.');
        assert(json.containsKey(r'longRideDay'), 'Required key "TrainingPlanResponse[longRideDay]" is missing from JSON.');
        assert(json.containsKey(r'lastPlannedFor'), 'Required key "TrainingPlanResponse[lastPlannedFor]" is missing from JSON.');
        assert(json.containsKey(r'maxHeartRate'), 'Required key "TrainingPlanResponse[maxHeartRate]" is missing from JSON.');
        assert(json.containsKey(r'maxHeartRateSource'), 'Required key "TrainingPlanResponse[maxHeartRateSource]" is missing from JSON.');
        assert(json.containsKey(r'birthYear'), 'Required key "TrainingPlanResponse[birthYear]" is missing from JSON.');
        assert(json.containsKey(r'nextEventName'), 'Required key "TrainingPlanResponse[nextEventName]" is missing from JSON.');
        assert(json.containsKey(r'nextEventDate'), 'Required key "TrainingPlanResponse[nextEventDate]" is missing from JSON.');
        assert(json.containsKey(r'firstDayOfWeek'), 'Required key "TrainingPlanResponse[firstDayOfWeek]" is missing from JSON.');
        assert(json[r'firstDayOfWeek'] != null, 'Required key "TrainingPlanResponse[firstDayOfWeek]" has a null value in JSON.');
        return true;
      }());

      return TrainingPlanResponse(
        on_: mapValueOfType<bool>(json, r'on')!,
        goal: mapValueOfType<String>(json, r'goal'),
        suggestedGoal: mapValueOfType<String>(json, r'suggestedGoal')!,
        suggestionReason: mapValueOfType<String>(json, r'suggestionReason')!,
        days: json[r'days'] is Iterable
            ? (json[r'days'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        hoursPerWeek: mapValueOfType<int>(json, r'hoursPerWeek'),
        longRideDay: mapValueOfType<String>(json, r'longRideDay'),
        lastPlannedFor: mapDateTime(json, r'lastPlannedFor', r''),
        maxHeartRate: mapValueOfType<int>(json, r'maxHeartRate'),
        maxHeartRateSource: mapValueOfType<String>(json, r'maxHeartRateSource'),
        birthYear: mapValueOfType<int>(json, r'birthYear'),
        nextEventName: mapValueOfType<String>(json, r'nextEventName'),
        nextEventDate: mapDateTime(json, r'nextEventDate', r''),
        firstDayOfWeek: mapValueOfType<String>(json, r'firstDayOfWeek')!,
      );
    }
    return null;
  }

  static List<TrainingPlanResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TrainingPlanResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TrainingPlanResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TrainingPlanResponse> mapFromJson(dynamic json) {
    final map = <String, TrainingPlanResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TrainingPlanResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TrainingPlanResponse-objects as value to a dart map
  static Map<String, List<TrainingPlanResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TrainingPlanResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TrainingPlanResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'on',
    'goal',
    'suggestedGoal',
    'suggestionReason',
    'days',
    'hoursPerWeek',
    'longRideDay',
    'lastPlannedFor',
    'maxHeartRate',
    'maxHeartRateSource',
    'birthYear',
    'nextEventName',
    'nextEventDate',
    'firstDayOfWeek',
  };
}

