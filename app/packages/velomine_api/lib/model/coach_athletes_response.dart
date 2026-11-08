//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class CoachAthletesResponse {
  /// Returns a new [CoachAthletesResponse] instance.
  CoachAthletesResponse({
    this.athletes = const [],
  });

  final List<CoachAthleteResponse> athletes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CoachAthletesResponse &&
    _deepEquality.equals(other.athletes, athletes);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (athletes.hashCode);

  @override
  String toString() => 'CoachAthletesResponse[athletes=$athletes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'athletes'] = this.athletes;
    return json;
  }

  /// Clones this instance of [CoachAthletesResponse] and returns a new one where some of the
  /// properties have changed.
  CoachAthletesResponse copyWith({
    List<CoachAthleteResponse>? athletes,
  }) => CoachAthletesResponse(
    athletes: athletes ?? this.athletes,
  );

  /// Returns a new [CoachAthletesResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CoachAthletesResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'athletes'), 'Required key "CoachAthletesResponse[athletes]" is missing from JSON.');
        assert(json[r'athletes'] != null, 'Required key "CoachAthletesResponse[athletes]" has a null value in JSON.');
        return true;
      }());

      return CoachAthletesResponse(
        athletes: CoachAthleteResponse.listFromJson(json[r'athletes']),
      );
    }
    return null;
  }

  static List<CoachAthletesResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CoachAthletesResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CoachAthletesResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CoachAthletesResponse> mapFromJson(dynamic json) {
    final map = <String, CoachAthletesResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CoachAthletesResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CoachAthletesResponse-objects as value to a dart map
  static Map<String, List<CoachAthletesResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CoachAthletesResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CoachAthletesResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'athletes',
  };
}

