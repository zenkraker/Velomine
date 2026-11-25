//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class TrainingWeeksResponse {
  /// Returns a new [TrainingWeeksResponse] instance.
  TrainingWeeksResponse({
    this.weeks = const [],
  });

  final List<TrainingWeek> weeks;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TrainingWeeksResponse &&
    _deepEquality.equals(other.weeks, weeks);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (weeks.hashCode);

  @override
  String toString() => 'TrainingWeeksResponse[weeks=$weeks]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'weeks'] = this.weeks;
    return json;
  }

  /// Clones this instance of [TrainingWeeksResponse] and returns a new one where some of the
  /// properties have changed.
  TrainingWeeksResponse copyWith({
    List<TrainingWeek>? weeks,
  }) => TrainingWeeksResponse(
    weeks: weeks ?? this.weeks,
  );

  /// Returns a new [TrainingWeeksResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TrainingWeeksResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'weeks'), 'Required key "TrainingWeeksResponse[weeks]" is missing from JSON.');
        assert(json[r'weeks'] != null, 'Required key "TrainingWeeksResponse[weeks]" has a null value in JSON.');
        return true;
      }());

      return TrainingWeeksResponse(
        weeks: TrainingWeek.listFromJson(json[r'weeks']),
      );
    }
    return null;
  }

  static List<TrainingWeeksResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TrainingWeeksResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TrainingWeeksResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TrainingWeeksResponse> mapFromJson(dynamic json) {
    final map = <String, TrainingWeeksResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TrainingWeeksResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TrainingWeeksResponse-objects as value to a dart map
  static Map<String, List<TrainingWeeksResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TrainingWeeksResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TrainingWeeksResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'weeks',
  };
}

