//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class TrainingSessionNotice {
  /// Returns a new [TrainingSessionNotice] instance.
  TrainingSessionNotice({
    required this.sessionId,
    required this.localDate,
    required this.minutes,
    required this.recipe,
    required this.englishName,
    required this.italianName,
    required this.state,
    required this.skipReason,
    required this.easyReason,
    required this.easyMovedTo,
  });

  final String sessionId;

  final DateTime localDate;

  final int minutes;

  final String recipe;

  final String englishName;

  final String italianName;

  final String state;

  final String? skipReason;

  final String? easyReason;

  final DateTime? easyMovedTo;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TrainingSessionNotice &&
    other.sessionId == sessionId &&
    other.localDate == localDate &&
    other.minutes == minutes &&
    other.recipe == recipe &&
    other.englishName == englishName &&
    other.italianName == italianName &&
    other.state == state &&
    other.skipReason == skipReason &&
    other.easyReason == easyReason &&
    other.easyMovedTo == easyMovedTo;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (sessionId.hashCode) +
    (localDate.hashCode) +
    (minutes.hashCode) +
    (recipe.hashCode) +
    (englishName.hashCode) +
    (italianName.hashCode) +
    (state.hashCode) +
    (skipReason == null ? 0 : skipReason!.hashCode) +
    (easyReason == null ? 0 : easyReason!.hashCode) +
    (easyMovedTo == null ? 0 : easyMovedTo!.hashCode);

  @override
  String toString() => 'TrainingSessionNotice[sessionId=$sessionId, localDate=$localDate, minutes=$minutes, recipe=$recipe, englishName=$englishName, italianName=$italianName, state=$state, skipReason=$skipReason, easyReason=$easyReason, easyMovedTo=$easyMovedTo]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'sessionId'] = this.sessionId;
      json[r'localDate'] = _dateFormatter.format(this.localDate);
      json[r'minutes'] = this.minutes;
      json[r'recipe'] = this.recipe;
      json[r'englishName'] = this.englishName;
      json[r'italianName'] = this.italianName;
      json[r'state'] = this.state;
    if (this.skipReason != null) {
      json[r'skipReason'] = this.skipReason;
    } else {
      json[r'skipReason'] = null;
    }
    if (this.easyReason != null) {
      json[r'easyReason'] = this.easyReason;
    } else {
      json[r'easyReason'] = null;
    }
    if (this.easyMovedTo != null) {
      json[r'easyMovedTo'] = _dateFormatter.format(this.easyMovedTo!);
    } else {
      json[r'easyMovedTo'] = null;
    }
    return json;
  }

  /// Clones this instance of [TrainingSessionNotice] and returns a new one where some of the
  /// properties have changed.
  TrainingSessionNotice copyWith({
    String? sessionId,
    DateTime? localDate,
    int? minutes,
    String? recipe,
    String? englishName,
    String? italianName,
    String? state,
    String? skipReason,
    bool skipReasonSetToNull = false,
    String? easyReason,
    bool easyReasonSetToNull = false,
    DateTime? easyMovedTo,
    bool easyMovedToSetToNull = false,
  }) => TrainingSessionNotice(
    sessionId: sessionId ?? this.sessionId,
    localDate: localDate ?? this.localDate,
    minutes: minutes ?? this.minutes,
    recipe: recipe ?? this.recipe,
    englishName: englishName ?? this.englishName,
    italianName: italianName ?? this.italianName,
    state: state ?? this.state,
    skipReason: skipReasonSetToNull ? null : skipReason ?? this.skipReason,
    easyReason: easyReasonSetToNull ? null : easyReason ?? this.easyReason,
    easyMovedTo: easyMovedToSetToNull ? null : easyMovedTo ?? this.easyMovedTo,
  );

  /// Returns a new [TrainingSessionNotice] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TrainingSessionNotice? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'sessionId'), 'Required key "TrainingSessionNotice[sessionId]" is missing from JSON.');
        assert(json[r'sessionId'] != null, 'Required key "TrainingSessionNotice[sessionId]" has a null value in JSON.');
        assert(json.containsKey(r'localDate'), 'Required key "TrainingSessionNotice[localDate]" is missing from JSON.');
        assert(json[r'localDate'] != null, 'Required key "TrainingSessionNotice[localDate]" has a null value in JSON.');
        assert(json.containsKey(r'minutes'), 'Required key "TrainingSessionNotice[minutes]" is missing from JSON.');
        assert(json[r'minutes'] != null, 'Required key "TrainingSessionNotice[minutes]" has a null value in JSON.');
        assert(json.containsKey(r'recipe'), 'Required key "TrainingSessionNotice[recipe]" is missing from JSON.');
        assert(json[r'recipe'] != null, 'Required key "TrainingSessionNotice[recipe]" has a null value in JSON.');
        assert(json.containsKey(r'englishName'), 'Required key "TrainingSessionNotice[englishName]" is missing from JSON.');
        assert(json[r'englishName'] != null, 'Required key "TrainingSessionNotice[englishName]" has a null value in JSON.');
        assert(json.containsKey(r'italianName'), 'Required key "TrainingSessionNotice[italianName]" is missing from JSON.');
        assert(json[r'italianName'] != null, 'Required key "TrainingSessionNotice[italianName]" has a null value in JSON.');
        assert(json.containsKey(r'state'), 'Required key "TrainingSessionNotice[state]" is missing from JSON.');
        assert(json[r'state'] != null, 'Required key "TrainingSessionNotice[state]" has a null value in JSON.');
        assert(json.containsKey(r'skipReason'), 'Required key "TrainingSessionNotice[skipReason]" is missing from JSON.');
        assert(json.containsKey(r'easyReason'), 'Required key "TrainingSessionNotice[easyReason]" is missing from JSON.');
        assert(json.containsKey(r'easyMovedTo'), 'Required key "TrainingSessionNotice[easyMovedTo]" is missing from JSON.');
        return true;
      }());

      return TrainingSessionNotice(
        sessionId: mapValueOfType<String>(json, r'sessionId')!,
        localDate: mapDateTime(json, r'localDate', r'')!,
        minutes: mapValueOfType<int>(json, r'minutes')!,
        recipe: mapValueOfType<String>(json, r'recipe')!,
        englishName: mapValueOfType<String>(json, r'englishName')!,
        italianName: mapValueOfType<String>(json, r'italianName')!,
        state: mapValueOfType<String>(json, r'state')!,
        skipReason: mapValueOfType<String>(json, r'skipReason'),
        easyReason: mapValueOfType<String>(json, r'easyReason'),
        easyMovedTo: mapDateTime(json, r'easyMovedTo', r''),
      );
    }
    return null;
  }

  static List<TrainingSessionNotice> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TrainingSessionNotice>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TrainingSessionNotice.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TrainingSessionNotice> mapFromJson(dynamic json) {
    final map = <String, TrainingSessionNotice>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TrainingSessionNotice.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TrainingSessionNotice-objects as value to a dart map
  static Map<String, List<TrainingSessionNotice>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TrainingSessionNotice>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TrainingSessionNotice.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'sessionId',
    'localDate',
    'minutes',
    'recipe',
    'englishName',
    'italianName',
    'state',
    'skipReason',
    'easyReason',
    'easyMovedTo',
  };
}

