//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SaveCheckInRequest {
  /// Returns a new [SaveCheckInRequest] instance.
  SaveCheckInRequest({
    required this.fatigue,
    required this.soreness,
    required this.mood,
    required this.stress,
    required this.motivation,
  });

  /// Minimum value: 1
  /// Maximum value: 5
  final int fatigue;

  /// Minimum value: 1
  /// Maximum value: 5
  final int soreness;

  /// Minimum value: 1
  /// Maximum value: 5
  final int mood;

  /// Minimum value: 1
  /// Maximum value: 5
  final int stress;

  /// Minimum value: 1
  /// Maximum value: 5
  final int motivation;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SaveCheckInRequest &&
    other.fatigue == fatigue &&
    other.soreness == soreness &&
    other.mood == mood &&
    other.stress == stress &&
    other.motivation == motivation;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (fatigue.hashCode) +
    (soreness.hashCode) +
    (mood.hashCode) +
    (stress.hashCode) +
    (motivation.hashCode);

  @override
  String toString() => 'SaveCheckInRequest[fatigue=$fatigue, soreness=$soreness, mood=$mood, stress=$stress, motivation=$motivation]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'fatigue'] = this.fatigue;
      json[r'soreness'] = this.soreness;
      json[r'mood'] = this.mood;
      json[r'stress'] = this.stress;
      json[r'motivation'] = this.motivation;
    return json;
  }

  /// Clones this instance of [SaveCheckInRequest] and returns a new one where some of the
  /// properties have changed.
  SaveCheckInRequest copyWith({
    int? fatigue,
    int? soreness,
    int? mood,
    int? stress,
    int? motivation,
  }) => SaveCheckInRequest(
    fatigue: fatigue ?? this.fatigue,
    soreness: soreness ?? this.soreness,
    mood: mood ?? this.mood,
    stress: stress ?? this.stress,
    motivation: motivation ?? this.motivation,
  );

  /// Returns a new [SaveCheckInRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SaveCheckInRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'fatigue'), 'Required key "SaveCheckInRequest[fatigue]" is missing from JSON.');
        assert(json[r'fatigue'] != null, 'Required key "SaveCheckInRequest[fatigue]" has a null value in JSON.');
        assert(json.containsKey(r'soreness'), 'Required key "SaveCheckInRequest[soreness]" is missing from JSON.');
        assert(json[r'soreness'] != null, 'Required key "SaveCheckInRequest[soreness]" has a null value in JSON.');
        assert(json.containsKey(r'mood'), 'Required key "SaveCheckInRequest[mood]" is missing from JSON.');
        assert(json[r'mood'] != null, 'Required key "SaveCheckInRequest[mood]" has a null value in JSON.');
        assert(json.containsKey(r'stress'), 'Required key "SaveCheckInRequest[stress]" is missing from JSON.');
        assert(json[r'stress'] != null, 'Required key "SaveCheckInRequest[stress]" has a null value in JSON.');
        assert(json.containsKey(r'motivation'), 'Required key "SaveCheckInRequest[motivation]" is missing from JSON.');
        assert(json[r'motivation'] != null, 'Required key "SaveCheckInRequest[motivation]" has a null value in JSON.');
        return true;
      }());

      return SaveCheckInRequest(
        fatigue: mapValueOfType<int>(json, r'fatigue')!,
        soreness: mapValueOfType<int>(json, r'soreness')!,
        mood: mapValueOfType<int>(json, r'mood')!,
        stress: mapValueOfType<int>(json, r'stress')!,
        motivation: mapValueOfType<int>(json, r'motivation')!,
      );
    }
    return null;
  }

  static List<SaveCheckInRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SaveCheckInRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SaveCheckInRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SaveCheckInRequest> mapFromJson(dynamic json) {
    final map = <String, SaveCheckInRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SaveCheckInRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SaveCheckInRequest-objects as value to a dart map
  static Map<String, List<SaveCheckInRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SaveCheckInRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SaveCheckInRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'fatigue',
    'soreness',
    'mood',
    'stress',
    'motivation',
  };
}

