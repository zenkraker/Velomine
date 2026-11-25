//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class CoachPlanSession {
  /// Returns a new [CoachPlanSession] instance.
  CoachPlanSession({
    required this.localDate,
    required this.englishName,
    required this.italianName,
    required this.minutes,
    required this.state,
    required this.skipReason,
    required this.riddenMinutes,
  });

  final DateTime localDate;

  final String englishName;

  final String italianName;

  final int minutes;

  final String state;

  final String? skipReason;

  final int? riddenMinutes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CoachPlanSession &&
    other.localDate == localDate &&
    other.englishName == englishName &&
    other.italianName == italianName &&
    other.minutes == minutes &&
    other.state == state &&
    other.skipReason == skipReason &&
    other.riddenMinutes == riddenMinutes;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (localDate.hashCode) +
    (englishName.hashCode) +
    (italianName.hashCode) +
    (minutes.hashCode) +
    (state.hashCode) +
    (skipReason == null ? 0 : skipReason!.hashCode) +
    (riddenMinutes == null ? 0 : riddenMinutes!.hashCode);

  @override
  String toString() => 'CoachPlanSession[localDate=$localDate, englishName=$englishName, italianName=$italianName, minutes=$minutes, state=$state, skipReason=$skipReason, riddenMinutes=$riddenMinutes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'localDate'] = _dateFormatter.format(this.localDate);
      json[r'englishName'] = this.englishName;
      json[r'italianName'] = this.italianName;
      json[r'minutes'] = this.minutes;
      json[r'state'] = this.state;
    if (this.skipReason != null) {
      json[r'skipReason'] = this.skipReason;
    } else {
      json[r'skipReason'] = null;
    }
    if (this.riddenMinutes != null) {
      json[r'riddenMinutes'] = this.riddenMinutes;
    } else {
      json[r'riddenMinutes'] = null;
    }
    return json;
  }

  /// Clones this instance of [CoachPlanSession] and returns a new one where some of the
  /// properties have changed.
  CoachPlanSession copyWith({
    DateTime? localDate,
    String? englishName,
    String? italianName,
    int? minutes,
    String? state,
    String? skipReason,
    bool skipReasonSetToNull = false,
    int? riddenMinutes,
    bool riddenMinutesSetToNull = false,
  }) => CoachPlanSession(
    localDate: localDate ?? this.localDate,
    englishName: englishName ?? this.englishName,
    italianName: italianName ?? this.italianName,
    minutes: minutes ?? this.minutes,
    state: state ?? this.state,
    skipReason: skipReasonSetToNull ? null : skipReason ?? this.skipReason,
    riddenMinutes: riddenMinutesSetToNull ? null : riddenMinutes ?? this.riddenMinutes,
  );

  /// Returns a new [CoachPlanSession] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CoachPlanSession? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'localDate'), 'Required key "CoachPlanSession[localDate]" is missing from JSON.');
        assert(json[r'localDate'] != null, 'Required key "CoachPlanSession[localDate]" has a null value in JSON.');
        assert(json.containsKey(r'englishName'), 'Required key "CoachPlanSession[englishName]" is missing from JSON.');
        assert(json[r'englishName'] != null, 'Required key "CoachPlanSession[englishName]" has a null value in JSON.');
        assert(json.containsKey(r'italianName'), 'Required key "CoachPlanSession[italianName]" is missing from JSON.');
        assert(json[r'italianName'] != null, 'Required key "CoachPlanSession[italianName]" has a null value in JSON.');
        assert(json.containsKey(r'minutes'), 'Required key "CoachPlanSession[minutes]" is missing from JSON.');
        assert(json[r'minutes'] != null, 'Required key "CoachPlanSession[minutes]" has a null value in JSON.');
        assert(json.containsKey(r'state'), 'Required key "CoachPlanSession[state]" is missing from JSON.');
        assert(json[r'state'] != null, 'Required key "CoachPlanSession[state]" has a null value in JSON.');
        assert(json.containsKey(r'skipReason'), 'Required key "CoachPlanSession[skipReason]" is missing from JSON.');
        assert(json.containsKey(r'riddenMinutes'), 'Required key "CoachPlanSession[riddenMinutes]" is missing from JSON.');
        return true;
      }());

      return CoachPlanSession(
        localDate: mapDateTime(json, r'localDate', r'')!,
        englishName: mapValueOfType<String>(json, r'englishName')!,
        italianName: mapValueOfType<String>(json, r'italianName')!,
        minutes: mapValueOfType<int>(json, r'minutes')!,
        state: mapValueOfType<String>(json, r'state')!,
        skipReason: mapValueOfType<String>(json, r'skipReason'),
        riddenMinutes: mapValueOfType<int>(json, r'riddenMinutes'),
      );
    }
    return null;
  }

  static List<CoachPlanSession> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CoachPlanSession>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CoachPlanSession.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CoachPlanSession> mapFromJson(dynamic json) {
    final map = <String, CoachPlanSession>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CoachPlanSession.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CoachPlanSession-objects as value to a dart map
  static Map<String, List<CoachPlanSession>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CoachPlanSession>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CoachPlanSession.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'localDate',
    'englishName',
    'italianName',
    'minutes',
    'state',
    'skipReason',
    'riddenMinutes',
  };
}

