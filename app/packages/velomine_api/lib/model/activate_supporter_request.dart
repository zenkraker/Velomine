//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ActivateSupporterRequest {
  /// Returns a new [ActivateSupporterRequest] instance.
  ActivateSupporterRequest({
    required this.key,
  });

  final String key;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ActivateSupporterRequest &&
    other.key == key;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (key.hashCode);

  @override
  String toString() => 'ActivateSupporterRequest[key=$key]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'key'] = this.key;
    return json;
  }

  /// Clones this instance of [ActivateSupporterRequest] and returns a new one where some of the
  /// properties have changed.
  ActivateSupporterRequest copyWith({
    String? key,
  }) => ActivateSupporterRequest(
    key: key ?? this.key,
  );

  /// Returns a new [ActivateSupporterRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ActivateSupporterRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'key'), 'Required key "ActivateSupporterRequest[key]" is missing from JSON.');
        assert(json[r'key'] != null, 'Required key "ActivateSupporterRequest[key]" has a null value in JSON.');
        return true;
      }());

      return ActivateSupporterRequest(
        key: mapValueOfType<String>(json, r'key')!,
      );
    }
    return null;
  }

  static List<ActivateSupporterRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ActivateSupporterRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ActivateSupporterRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ActivateSupporterRequest> mapFromJson(dynamic json) {
    final map = <String, ActivateSupporterRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ActivateSupporterRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ActivateSupporterRequest-objects as value to a dart map
  static Map<String, List<ActivateSupporterRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ActivateSupporterRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ActivateSupporterRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'key',
  };
}

