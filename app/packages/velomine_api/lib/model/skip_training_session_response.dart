//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SkipTrainingSessionResponse {
  /// Returns a new [SkipTrainingSessionResponse] instance.
  SkipTrainingSessionResponse({
    required this.askRestOfWeek,
    required this.week,
  });

  final bool askRestOfWeek;

  final TrainingWeeksResponse week;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SkipTrainingSessionResponse &&
    other.askRestOfWeek == askRestOfWeek &&
    other.week == week;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (askRestOfWeek.hashCode) +
    (week.hashCode);

  @override
  String toString() => 'SkipTrainingSessionResponse[askRestOfWeek=$askRestOfWeek, week=$week]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'askRestOfWeek'] = this.askRestOfWeek;
      json[r'week'] = this.week;
    return json;
  }

  /// Clones this instance of [SkipTrainingSessionResponse] and returns a new one where some of the
  /// properties have changed.
  SkipTrainingSessionResponse copyWith({
    bool? askRestOfWeek,
    TrainingWeeksResponse? week,
  }) => SkipTrainingSessionResponse(
    askRestOfWeek: askRestOfWeek ?? this.askRestOfWeek,
    week: week ?? this.week,
  );

  /// Returns a new [SkipTrainingSessionResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SkipTrainingSessionResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'askRestOfWeek'), 'Required key "SkipTrainingSessionResponse[askRestOfWeek]" is missing from JSON.');
        assert(json[r'askRestOfWeek'] != null, 'Required key "SkipTrainingSessionResponse[askRestOfWeek]" has a null value in JSON.');
        assert(json.containsKey(r'week'), 'Required key "SkipTrainingSessionResponse[week]" is missing from JSON.');
        assert(json[r'week'] != null, 'Required key "SkipTrainingSessionResponse[week]" has a null value in JSON.');
        return true;
      }());

      return SkipTrainingSessionResponse(
        askRestOfWeek: mapValueOfType<bool>(json, r'askRestOfWeek')!,
        week: TrainingWeeksResponse.fromJson(json[r'week'])!,
      );
    }
    return null;
  }

  static List<SkipTrainingSessionResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SkipTrainingSessionResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SkipTrainingSessionResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SkipTrainingSessionResponse> mapFromJson(dynamic json) {
    final map = <String, SkipTrainingSessionResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SkipTrainingSessionResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SkipTrainingSessionResponse-objects as value to a dart map
  static Map<String, List<SkipTrainingSessionResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SkipTrainingSessionResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SkipTrainingSessionResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'askRestOfWeek',
    'week',
  };
}

