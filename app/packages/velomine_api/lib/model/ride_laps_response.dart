//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class RideLapsResponse {
  /// Returns a new [RideLapsResponse] instance.
  RideLapsResponse({
    this.laps = const [],
  });

  final List<LapResponse> laps;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RideLapsResponse &&
    _deepEquality.equals(other.laps, laps);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (laps.hashCode);

  @override
  String toString() => 'RideLapsResponse[laps=$laps]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'laps'] = this.laps;
    return json;
  }

  /// Clones this instance of [RideLapsResponse] and returns a new one where some of the
  /// properties have changed.
  RideLapsResponse copyWith({
    List<LapResponse>? laps,
  }) => RideLapsResponse(
    laps: laps ?? this.laps,
  );

  /// Returns a new [RideLapsResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RideLapsResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'laps'), 'Required key "RideLapsResponse[laps]" is missing from JSON.');
        assert(json[r'laps'] != null, 'Required key "RideLapsResponse[laps]" has a null value in JSON.');
        return true;
      }());

      return RideLapsResponse(
        laps: LapResponse.listFromJson(json[r'laps']),
      );
    }
    return null;
  }

  static List<RideLapsResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RideLapsResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RideLapsResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RideLapsResponse> mapFromJson(dynamic json) {
    final map = <String, RideLapsResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RideLapsResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RideLapsResponse-objects as value to a dart map
  static Map<String, List<RideLapsResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RideLapsResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RideLapsResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'laps',
  };
}

