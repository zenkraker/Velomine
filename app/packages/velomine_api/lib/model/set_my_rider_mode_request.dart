//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SetMyRiderModeRequest {
  /// Returns a new [SetMyRiderModeRequest] instance.
  SetMyRiderModeRequest({
    required this.riderMode,
  });

  final String riderMode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SetMyRiderModeRequest &&
    other.riderMode == riderMode;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (riderMode.hashCode);

  @override
  String toString() => 'SetMyRiderModeRequest[riderMode=$riderMode]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'riderMode'] = this.riderMode;
    return json;
  }

  /// Clones this instance of [SetMyRiderModeRequest] and returns a new one where some of the
  /// properties have changed.
  SetMyRiderModeRequest copyWith({
    String? riderMode,
  }) => SetMyRiderModeRequest(
    riderMode: riderMode ?? this.riderMode,
  );

  /// Returns a new [SetMyRiderModeRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SetMyRiderModeRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'riderMode'), 'Required key "SetMyRiderModeRequest[riderMode]" is missing from JSON.');
        assert(json[r'riderMode'] != null, 'Required key "SetMyRiderModeRequest[riderMode]" has a null value in JSON.');
        return true;
      }());

      return SetMyRiderModeRequest(
        riderMode: mapValueOfType<String>(json, r'riderMode')!,
      );
    }
    return null;
  }

  static List<SetMyRiderModeRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SetMyRiderModeRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SetMyRiderModeRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SetMyRiderModeRequest> mapFromJson(dynamic json) {
    final map = <String, SetMyRiderModeRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SetMyRiderModeRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SetMyRiderModeRequest-objects as value to a dart map
  static Map<String, List<SetMyRiderModeRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SetMyRiderModeRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SetMyRiderModeRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'riderMode',
  };
}

