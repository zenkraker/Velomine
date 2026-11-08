//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class CheckInResponse {
  /// Returns a new [CheckInResponse] instance.
  CheckInResponse({
    required this.date,
    required this.fatigue,
    required this.soreness,
    required this.mood,
    required this.stress,
    required this.motivation,
  });

  final DateTime date;

  final int fatigue;

  final int soreness;

  final int mood;

  final int stress;

  final int motivation;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CheckInResponse &&
    other.date == date &&
    other.fatigue == fatigue &&
    other.soreness == soreness &&
    other.mood == mood &&
    other.stress == stress &&
    other.motivation == motivation;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (date.hashCode) +
    (fatigue.hashCode) +
    (soreness.hashCode) +
    (mood.hashCode) +
    (stress.hashCode) +
    (motivation.hashCode);

  @override
  String toString() => 'CheckInResponse[date=$date, fatigue=$fatigue, soreness=$soreness, mood=$mood, stress=$stress, motivation=$motivation]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'date'] = _dateFormatter.format(this.date);
      json[r'fatigue'] = this.fatigue;
      json[r'soreness'] = this.soreness;
      json[r'mood'] = this.mood;
      json[r'stress'] = this.stress;
      json[r'motivation'] = this.motivation;
    return json;
  }

  /// Clones this instance of [CheckInResponse] and returns a new one where some of the
  /// properties have changed.
  CheckInResponse copyWith({
    DateTime? date,
    int? fatigue,
    int? soreness,
    int? mood,
    int? stress,
    int? motivation,
  }) => CheckInResponse(
    date: date ?? this.date,
    fatigue: fatigue ?? this.fatigue,
    soreness: soreness ?? this.soreness,
    mood: mood ?? this.mood,
    stress: stress ?? this.stress,
    motivation: motivation ?? this.motivation,
  );

  /// Returns a new [CheckInResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CheckInResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'date'), 'Required key "CheckInResponse[date]" is missing from JSON.');
        assert(json[r'date'] != null, 'Required key "CheckInResponse[date]" has a null value in JSON.');
        assert(json.containsKey(r'fatigue'), 'Required key "CheckInResponse[fatigue]" is missing from JSON.');
        assert(json[r'fatigue'] != null, 'Required key "CheckInResponse[fatigue]" has a null value in JSON.');
        assert(json.containsKey(r'soreness'), 'Required key "CheckInResponse[soreness]" is missing from JSON.');
        assert(json[r'soreness'] != null, 'Required key "CheckInResponse[soreness]" has a null value in JSON.');
        assert(json.containsKey(r'mood'), 'Required key "CheckInResponse[mood]" is missing from JSON.');
        assert(json[r'mood'] != null, 'Required key "CheckInResponse[mood]" has a null value in JSON.');
        assert(json.containsKey(r'stress'), 'Required key "CheckInResponse[stress]" is missing from JSON.');
        assert(json[r'stress'] != null, 'Required key "CheckInResponse[stress]" has a null value in JSON.');
        assert(json.containsKey(r'motivation'), 'Required key "CheckInResponse[motivation]" is missing from JSON.');
        assert(json[r'motivation'] != null, 'Required key "CheckInResponse[motivation]" has a null value in JSON.');
        return true;
      }());

      return CheckInResponse(
        date: mapDateTime(json, r'date', r'')!,
        fatigue: mapValueOfType<int>(json, r'fatigue')!,
        soreness: mapValueOfType<int>(json, r'soreness')!,
        mood: mapValueOfType<int>(json, r'mood')!,
        stress: mapValueOfType<int>(json, r'stress')!,
        motivation: mapValueOfType<int>(json, r'motivation')!,
      );
    }
    return null;
  }

  static List<CheckInResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CheckInResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CheckInResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CheckInResponse> mapFromJson(dynamic json) {
    final map = <String, CheckInResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CheckInResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CheckInResponse-objects as value to a dart map
  static Map<String, List<CheckInResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CheckInResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CheckInResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'date',
    'fatigue',
    'soreness',
    'mood',
    'stress',
    'motivation',
  };
}

