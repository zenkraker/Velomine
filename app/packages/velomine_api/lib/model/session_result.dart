//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SessionResult {
  /// Returns a new [SessionResult] instance.
  SessionResult({
    required this.score,
    required this.plannedMinutes,
    required this.doneMinutes,
    required this.plannedEffort,
    required this.doneEffort,
    required this.mainSetShare,
    required this.mainSet,
  });

  final int score;

  final int plannedMinutes;

  final double doneMinutes;

  final double plannedEffort;

  final double? doneEffort;

  final double? mainSetShare;

  final MainSetTarget? mainSet;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SessionResult &&
    other.score == score &&
    other.plannedMinutes == plannedMinutes &&
    other.doneMinutes == doneMinutes &&
    other.plannedEffort == plannedEffort &&
    other.doneEffort == doneEffort &&
    other.mainSetShare == mainSetShare &&
    other.mainSet == mainSet;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (score.hashCode) +
    (plannedMinutes.hashCode) +
    (doneMinutes.hashCode) +
    (plannedEffort.hashCode) +
    (doneEffort == null ? 0 : doneEffort!.hashCode) +
    (mainSetShare == null ? 0 : mainSetShare!.hashCode) +
    (mainSet == null ? 0 : mainSet!.hashCode);

  @override
  String toString() => 'SessionResult[score=$score, plannedMinutes=$plannedMinutes, doneMinutes=$doneMinutes, plannedEffort=$plannedEffort, doneEffort=$doneEffort, mainSetShare=$mainSetShare, mainSet=$mainSet]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'score'] = this.score;
      json[r'plannedMinutes'] = this.plannedMinutes;
      json[r'doneMinutes'] = this.doneMinutes;
      json[r'plannedEffort'] = this.plannedEffort;
    if (this.doneEffort != null) {
      json[r'doneEffort'] = this.doneEffort;
    } else {
      json[r'doneEffort'] = null;
    }
    if (this.mainSetShare != null) {
      json[r'mainSetShare'] = this.mainSetShare;
    } else {
      json[r'mainSetShare'] = null;
    }
    if (this.mainSet != null) {
      json[r'mainSet'] = this.mainSet;
    } else {
      json[r'mainSet'] = null;
    }
    return json;
  }

  /// Clones this instance of [SessionResult] and returns a new one where some of the
  /// properties have changed.
  SessionResult copyWith({
    int? score,
    int? plannedMinutes,
    double? doneMinutes,
    double? plannedEffort,
    double? doneEffort,
    bool doneEffortSetToNull = false,
    double? mainSetShare,
    bool mainSetShareSetToNull = false,
    MainSetTarget? mainSet,
    bool mainSetSetToNull = false,
  }) => SessionResult(
    score: score ?? this.score,
    plannedMinutes: plannedMinutes ?? this.plannedMinutes,
    doneMinutes: doneMinutes ?? this.doneMinutes,
    plannedEffort: plannedEffort ?? this.plannedEffort,
    doneEffort: doneEffortSetToNull ? null : doneEffort ?? this.doneEffort,
    mainSetShare: mainSetShareSetToNull ? null : mainSetShare ?? this.mainSetShare,
    mainSet: mainSetSetToNull ? null : mainSet ?? this.mainSet,
  );

  /// Returns a new [SessionResult] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SessionResult? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'score'), 'Required key "SessionResult[score]" is missing from JSON.');
        assert(json[r'score'] != null, 'Required key "SessionResult[score]" has a null value in JSON.');
        assert(json.containsKey(r'plannedMinutes'), 'Required key "SessionResult[plannedMinutes]" is missing from JSON.');
        assert(json[r'plannedMinutes'] != null, 'Required key "SessionResult[plannedMinutes]" has a null value in JSON.');
        assert(json.containsKey(r'doneMinutes'), 'Required key "SessionResult[doneMinutes]" is missing from JSON.');
        assert(json[r'doneMinutes'] != null, 'Required key "SessionResult[doneMinutes]" has a null value in JSON.');
        assert(json.containsKey(r'plannedEffort'), 'Required key "SessionResult[plannedEffort]" is missing from JSON.');
        assert(json[r'plannedEffort'] != null, 'Required key "SessionResult[plannedEffort]" has a null value in JSON.');
        assert(json.containsKey(r'doneEffort'), 'Required key "SessionResult[doneEffort]" is missing from JSON.');
        assert(json.containsKey(r'mainSetShare'), 'Required key "SessionResult[mainSetShare]" is missing from JSON.');
        assert(json.containsKey(r'mainSet'), 'Required key "SessionResult[mainSet]" is missing from JSON.');
        return true;
      }());

      return SessionResult(
        score: mapValueOfType<int>(json, r'score')!,
        plannedMinutes: mapValueOfType<int>(json, r'plannedMinutes')!,
        doneMinutes: mapValueOfType<double>(json, r'doneMinutes')!,
        plannedEffort: mapValueOfType<double>(json, r'plannedEffort')!,
        doneEffort: mapValueOfType<double>(json, r'doneEffort'),
        mainSetShare: mapValueOfType<double>(json, r'mainSetShare'),
        mainSet: MainSetTarget.fromJson(json[r'mainSet']),
      );
    }
    return null;
  }

  static List<SessionResult> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SessionResult>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SessionResult.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SessionResult> mapFromJson(dynamic json) {
    final map = <String, SessionResult>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SessionResult.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SessionResult-objects as value to a dart map
  static Map<String, List<SessionResult>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SessionResult>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SessionResult.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'score',
    'plannedMinutes',
    'doneMinutes',
    'plannedEffort',
    'doneEffort',
    'mainSetShare',
    'mainSet',
  };
}

