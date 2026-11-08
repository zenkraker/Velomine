//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class UpdateClubRequest {
  /// Returns a new [UpdateClubRequest] instance.
  UpdateClubRequest({
    required this.name,
    required this.isActive,
  });

  final String name;

  final bool isActive;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UpdateClubRequest &&
    other.name == name &&
    other.isActive == isActive;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (isActive.hashCode);

  @override
  String toString() => 'UpdateClubRequest[name=$name, isActive=$isActive]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'isActive'] = this.isActive;
    return json;
  }

  /// Clones this instance of [UpdateClubRequest] and returns a new one where some of the
  /// properties have changed.
  UpdateClubRequest copyWith({
    String? name,
    bool? isActive,
  }) => UpdateClubRequest(
    name: name ?? this.name,
    isActive: isActive ?? this.isActive,
  );

  /// Returns a new [UpdateClubRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateClubRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "UpdateClubRequest[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "UpdateClubRequest[name]" has a null value in JSON.');
        assert(json.containsKey(r'isActive'), 'Required key "UpdateClubRequest[isActive]" is missing from JSON.');
        assert(json[r'isActive'] != null, 'Required key "UpdateClubRequest[isActive]" has a null value in JSON.');
        return true;
      }());

      return UpdateClubRequest(
        name: mapValueOfType<String>(json, r'name')!,
        isActive: mapValueOfType<bool>(json, r'isActive')!,
      );
    }
    return null;
  }

  static List<UpdateClubRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UpdateClubRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateClubRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateClubRequest> mapFromJson(dynamic json) {
    final map = <String, UpdateClubRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateClubRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateClubRequest-objects as value to a dart map
  static Map<String, List<UpdateClubRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UpdateClubRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateClubRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'isActive',
  };
}

