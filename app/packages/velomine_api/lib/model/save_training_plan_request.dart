//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SaveTrainingPlanRequest {
  /// Returns a new [SaveTrainingPlanRequest] instance.
  SaveTrainingPlanRequest({
    required this.goal,
    this.days = const [],
    required this.hoursPerWeek,
    required this.longRideDay,
    required this.maxHeartRateKnown,
    required this.maxHeartRate,
    required this.birthYear,
    required this.timeZone,
    this.utcOffsetMinutes = const Optional.absent(),
  });

  final String goal;

  final List<String> days;

  /// Minimum value: 1
  /// Maximum value: 30
  final int hoursPerWeek;

  final String? longRideDay;

  final bool maxHeartRateKnown;

  /// Minimum value: 120
  /// Maximum value: 230
  final int? maxHeartRate;

  /// Minimum value: 1900
  /// Maximum value: 2016
  final int? birthYear;

  final String? timeZone;

  /// Minimum value: -840
  /// Maximum value: 840
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> utcOffsetMinutes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SaveTrainingPlanRequest &&
    other.goal == goal &&
    _deepEquality.equals(other.days, days) &&
    other.hoursPerWeek == hoursPerWeek &&
    other.longRideDay == longRideDay &&
    other.maxHeartRateKnown == maxHeartRateKnown &&
    other.maxHeartRate == maxHeartRate &&
    other.birthYear == birthYear &&
    other.timeZone == timeZone &&
    other.utcOffsetMinutes == utcOffsetMinutes;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (goal.hashCode) +
    (days.hashCode) +
    (hoursPerWeek.hashCode) +
    (longRideDay == null ? 0 : longRideDay!.hashCode) +
    (maxHeartRateKnown.hashCode) +
    (maxHeartRate == null ? 0 : maxHeartRate!.hashCode) +
    (birthYear == null ? 0 : birthYear!.hashCode) +
    (timeZone == null ? 0 : timeZone!.hashCode) +
    (utcOffsetMinutes == null ? 0 : utcOffsetMinutes!.hashCode);

  @override
  String toString() => 'SaveTrainingPlanRequest[goal=$goal, days=$days, hoursPerWeek=$hoursPerWeek, longRideDay=$longRideDay, maxHeartRateKnown=$maxHeartRateKnown, maxHeartRate=$maxHeartRate, birthYear=$birthYear, timeZone=$timeZone, utcOffsetMinutes=$utcOffsetMinutes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'goal'] = this.goal;
      json[r'days'] = this.days;
      json[r'hoursPerWeek'] = this.hoursPerWeek;
    if (this.longRideDay != null) {
      json[r'longRideDay'] = this.longRideDay;
    } else {
      json[r'longRideDay'] = null;
    }
      json[r'maxHeartRateKnown'] = this.maxHeartRateKnown;
    if (this.maxHeartRate != null) {
      json[r'maxHeartRate'] = this.maxHeartRate;
    } else {
      json[r'maxHeartRate'] = null;
    }
    if (this.birthYear != null) {
      json[r'birthYear'] = this.birthYear;
    } else {
      json[r'birthYear'] = null;
    }
    if (this.timeZone != null) {
      json[r'timeZone'] = this.timeZone;
    } else {
      json[r'timeZone'] = null;
    }
    if (this.utcOffsetMinutes.isPresent) {
      final value = this.utcOffsetMinutes.value;
      json[r'utcOffsetMinutes'] = value;
    }
    return json;
  }

  /// Clones this instance of [SaveTrainingPlanRequest] and returns a new one where some of the
  /// properties have changed.
  SaveTrainingPlanRequest copyWith({
    String? goal,
    List<String>? days,
    int? hoursPerWeek,
    String? longRideDay,
    bool longRideDaySetToNull = false,
    bool? maxHeartRateKnown,
    int? maxHeartRate,
    bool maxHeartRateSetToNull = false,
    int? birthYear,
    bool birthYearSetToNull = false,
    String? timeZone,
    bool timeZoneSetToNull = false,
    Optional<int?>? utcOffsetMinutes,
  }) => SaveTrainingPlanRequest(
    goal: goal ?? this.goal,
    days: days ?? this.days,
    hoursPerWeek: hoursPerWeek ?? this.hoursPerWeek,
    longRideDay: longRideDaySetToNull ? null : longRideDay ?? this.longRideDay,
    maxHeartRateKnown: maxHeartRateKnown ?? this.maxHeartRateKnown,
    maxHeartRate: maxHeartRateSetToNull ? null : maxHeartRate ?? this.maxHeartRate,
    birthYear: birthYearSetToNull ? null : birthYear ?? this.birthYear,
    timeZone: timeZoneSetToNull ? null : timeZone ?? this.timeZone,
    utcOffsetMinutes: utcOffsetMinutes ?? this.utcOffsetMinutes,
  );

  /// Returns a new [SaveTrainingPlanRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SaveTrainingPlanRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'goal'), 'Required key "SaveTrainingPlanRequest[goal]" is missing from JSON.');
        assert(json[r'goal'] != null, 'Required key "SaveTrainingPlanRequest[goal]" has a null value in JSON.');
        assert(json.containsKey(r'days'), 'Required key "SaveTrainingPlanRequest[days]" is missing from JSON.');
        assert(json[r'days'] != null, 'Required key "SaveTrainingPlanRequest[days]" has a null value in JSON.');
        assert(json.containsKey(r'hoursPerWeek'), 'Required key "SaveTrainingPlanRequest[hoursPerWeek]" is missing from JSON.');
        assert(json[r'hoursPerWeek'] != null, 'Required key "SaveTrainingPlanRequest[hoursPerWeek]" has a null value in JSON.');
        assert(json.containsKey(r'longRideDay'), 'Required key "SaveTrainingPlanRequest[longRideDay]" is missing from JSON.');
        assert(json.containsKey(r'maxHeartRateKnown'), 'Required key "SaveTrainingPlanRequest[maxHeartRateKnown]" is missing from JSON.');
        assert(json[r'maxHeartRateKnown'] != null, 'Required key "SaveTrainingPlanRequest[maxHeartRateKnown]" has a null value in JSON.');
        assert(json.containsKey(r'maxHeartRate'), 'Required key "SaveTrainingPlanRequest[maxHeartRate]" is missing from JSON.');
        assert(json.containsKey(r'birthYear'), 'Required key "SaveTrainingPlanRequest[birthYear]" is missing from JSON.');
        assert(json.containsKey(r'timeZone'), 'Required key "SaveTrainingPlanRequest[timeZone]" is missing from JSON.');
        return true;
      }());

      return SaveTrainingPlanRequest(
        goal: mapValueOfType<String>(json, r'goal')!,
        days: json[r'days'] is Iterable
            ? (json[r'days'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        hoursPerWeek: mapValueOfType<int>(json, r'hoursPerWeek')!,
        longRideDay: mapValueOfType<String>(json, r'longRideDay'),
        maxHeartRateKnown: mapValueOfType<bool>(json, r'maxHeartRateKnown')!,
        maxHeartRate: mapValueOfType<int>(json, r'maxHeartRate'),
        birthYear: mapValueOfType<int>(json, r'birthYear'),
        timeZone: mapValueOfType<String>(json, r'timeZone'),
        utcOffsetMinutes: json.containsKey(r'utcOffsetMinutes') ? Optional.present(json[r'utcOffsetMinutes'] == null ? null : int.parse('${json[r'utcOffsetMinutes']}')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<SaveTrainingPlanRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SaveTrainingPlanRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SaveTrainingPlanRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SaveTrainingPlanRequest> mapFromJson(dynamic json) {
    final map = <String, SaveTrainingPlanRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SaveTrainingPlanRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SaveTrainingPlanRequest-objects as value to a dart map
  static Map<String, List<SaveTrainingPlanRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SaveTrainingPlanRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SaveTrainingPlanRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'goal',
    'days',
    'hoursPerWeek',
    'longRideDay',
    'maxHeartRateKnown',
    'maxHeartRate',
    'birthYear',
    'timeZone',
  };
}

