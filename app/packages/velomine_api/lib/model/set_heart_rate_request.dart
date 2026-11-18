//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SetHeartRateRequest {
  /// Returns a new [SetHeartRateRequest] instance.
  SetHeartRateRequest({
    required this.bpm,
  });

  /// Minimum value: 90
  /// Maximum value: 230
  final int bpm;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SetHeartRateRequest &&
    other.bpm == bpm;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (bpm.hashCode);

  @override
  String toString() => 'SetHeartRateRequest[bpm=$bpm]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'bpm'] = this.bpm;
    return json;
  }

  /// Clones this instance of [SetHeartRateRequest] and returns a new one where some of the
  /// properties have changed.
  SetHeartRateRequest copyWith({
    int? bpm,
  }) => SetHeartRateRequest(
    bpm: bpm ?? this.bpm,
  );

  /// Returns a new [SetHeartRateRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SetHeartRateRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'bpm'), 'Required key "SetHeartRateRequest[bpm]" is missing from JSON.');
        assert(json[r'bpm'] != null, 'Required key "SetHeartRateRequest[bpm]" has a null value in JSON.');
        return true;
      }());

      return SetHeartRateRequest(
        bpm: mapValueOfType<int>(json, r'bpm')!,
      );
    }
    return null;
  }

  static List<SetHeartRateRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SetHeartRateRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SetHeartRateRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SetHeartRateRequest> mapFromJson(dynamic json) {
    final map = <String, SetHeartRateRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SetHeartRateRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SetHeartRateRequest-objects as value to a dart map
  static Map<String, List<SetHeartRateRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SetHeartRateRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SetHeartRateRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'bpm',
  };
}

