//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class TrainingRideMatch {
  /// Returns a new [TrainingRideMatch] instance.
  TrainingRideMatch({
    required this.sessionId,
    required this.localDate,
    required this.recipe,
    required this.englishName,
    required this.italianName,
    required this.state,
  });

  final String sessionId;

  final DateTime localDate;

  final String recipe;

  final String englishName;

  final String italianName;

  final String state;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TrainingRideMatch &&
    other.sessionId == sessionId &&
    other.localDate == localDate &&
    other.recipe == recipe &&
    other.englishName == englishName &&
    other.italianName == italianName &&
    other.state == state;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (sessionId.hashCode) +
    (localDate.hashCode) +
    (recipe.hashCode) +
    (englishName.hashCode) +
    (italianName.hashCode) +
    (state.hashCode);

  @override
  String toString() => 'TrainingRideMatch[sessionId=$sessionId, localDate=$localDate, recipe=$recipe, englishName=$englishName, italianName=$italianName, state=$state]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'sessionId'] = this.sessionId;
      json[r'localDate'] = _dateFormatter.format(this.localDate);
      json[r'recipe'] = this.recipe;
      json[r'englishName'] = this.englishName;
      json[r'italianName'] = this.italianName;
      json[r'state'] = this.state;
    return json;
  }

  /// Clones this instance of [TrainingRideMatch] and returns a new one where some of the
  /// properties have changed.
  TrainingRideMatch copyWith({
    String? sessionId,
    DateTime? localDate,
    String? recipe,
    String? englishName,
    String? italianName,
    String? state,
  }) => TrainingRideMatch(
    sessionId: sessionId ?? this.sessionId,
    localDate: localDate ?? this.localDate,
    recipe: recipe ?? this.recipe,
    englishName: englishName ?? this.englishName,
    italianName: italianName ?? this.italianName,
    state: state ?? this.state,
  );

  /// Returns a new [TrainingRideMatch] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TrainingRideMatch? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'sessionId'), 'Required key "TrainingRideMatch[sessionId]" is missing from JSON.');
        assert(json[r'sessionId'] != null, 'Required key "TrainingRideMatch[sessionId]" has a null value in JSON.');
        assert(json.containsKey(r'localDate'), 'Required key "TrainingRideMatch[localDate]" is missing from JSON.');
        assert(json[r'localDate'] != null, 'Required key "TrainingRideMatch[localDate]" has a null value in JSON.');
        assert(json.containsKey(r'recipe'), 'Required key "TrainingRideMatch[recipe]" is missing from JSON.');
        assert(json[r'recipe'] != null, 'Required key "TrainingRideMatch[recipe]" has a null value in JSON.');
        assert(json.containsKey(r'englishName'), 'Required key "TrainingRideMatch[englishName]" is missing from JSON.');
        assert(json[r'englishName'] != null, 'Required key "TrainingRideMatch[englishName]" has a null value in JSON.');
        assert(json.containsKey(r'italianName'), 'Required key "TrainingRideMatch[italianName]" is missing from JSON.');
        assert(json[r'italianName'] != null, 'Required key "TrainingRideMatch[italianName]" has a null value in JSON.');
        assert(json.containsKey(r'state'), 'Required key "TrainingRideMatch[state]" is missing from JSON.');
        assert(json[r'state'] != null, 'Required key "TrainingRideMatch[state]" has a null value in JSON.');
        return true;
      }());

      return TrainingRideMatch(
        sessionId: mapValueOfType<String>(json, r'sessionId')!,
        localDate: mapDateTime(json, r'localDate', r'')!,
        recipe: mapValueOfType<String>(json, r'recipe')!,
        englishName: mapValueOfType<String>(json, r'englishName')!,
        italianName: mapValueOfType<String>(json, r'italianName')!,
        state: mapValueOfType<String>(json, r'state')!,
      );
    }
    return null;
  }

  static List<TrainingRideMatch> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TrainingRideMatch>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TrainingRideMatch.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TrainingRideMatch> mapFromJson(dynamic json) {
    final map = <String, TrainingRideMatch>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TrainingRideMatch.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TrainingRideMatch-objects as value to a dart map
  static Map<String, List<TrainingRideMatch>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TrainingRideMatch>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TrainingRideMatch.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'sessionId',
    'localDate',
    'recipe',
    'englishName',
    'italianName',
    'state',
  };
}

