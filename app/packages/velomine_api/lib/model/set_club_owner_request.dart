//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SetClubOwnerRequest {
  /// Returns a new [SetClubOwnerRequest] instance.
  SetClubOwnerRequest({
    required this.userId,
  });

  final String userId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SetClubOwnerRequest &&
    other.userId == userId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (userId.hashCode);

  @override
  String toString() => 'SetClubOwnerRequest[userId=$userId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'userId'] = this.userId;
    return json;
  }

  /// Clones this instance of [SetClubOwnerRequest] and returns a new one where some of the
  /// properties have changed.
  SetClubOwnerRequest copyWith({
    String? userId,
  }) => SetClubOwnerRequest(
    userId: userId ?? this.userId,
  );

  /// Returns a new [SetClubOwnerRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SetClubOwnerRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'userId'), 'Required key "SetClubOwnerRequest[userId]" is missing from JSON.');
        assert(json[r'userId'] != null, 'Required key "SetClubOwnerRequest[userId]" has a null value in JSON.');
        return true;
      }());

      return SetClubOwnerRequest(
        userId: mapValueOfType<String>(json, r'userId')!,
      );
    }
    return null;
  }

  static List<SetClubOwnerRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SetClubOwnerRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SetClubOwnerRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SetClubOwnerRequest> mapFromJson(dynamic json) {
    final map = <String, SetClubOwnerRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SetClubOwnerRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SetClubOwnerRequest-objects as value to a dart map
  static Map<String, List<SetClubOwnerRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SetClubOwnerRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SetClubOwnerRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'userId',
  };
}

