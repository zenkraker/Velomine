//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class MeResponse {
  /// Returns a new [MeResponse] instance.
  MeResponse({
    required this.id,
    required this.email,
    required this.displayName,
    this.roles = const [],
  });

  final String id;

  final String email;

  final String displayName;

  final List<String> roles;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MeResponse &&
    other.id == id &&
    other.email == email &&
    other.displayName == displayName &&
    _deepEquality.equals(other.roles, roles);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (email.hashCode) +
    (displayName.hashCode) +
    (roles.hashCode);

  @override
  String toString() => 'MeResponse[id=$id, email=$email, displayName=$displayName, roles=$roles]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'email'] = this.email;
      json[r'displayName'] = this.displayName;
      json[r'roles'] = this.roles;
    return json;
  }

  /// Clones this instance of [MeResponse] and returns a new one where some of the
  /// properties have changed.
  MeResponse copyWith({
    String? id,
    String? email,
    String? displayName,
    List<String>? roles,
  }) => MeResponse(
    id: id ?? this.id,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    roles: roles ?? this.roles,
  );

  /// Returns a new [MeResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MeResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "MeResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "MeResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'email'), 'Required key "MeResponse[email]" is missing from JSON.');
        assert(json[r'email'] != null, 'Required key "MeResponse[email]" has a null value in JSON.');
        assert(json.containsKey(r'displayName'), 'Required key "MeResponse[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null, 'Required key "MeResponse[displayName]" has a null value in JSON.');
        assert(json.containsKey(r'roles'), 'Required key "MeResponse[roles]" is missing from JSON.');
        assert(json[r'roles'] != null, 'Required key "MeResponse[roles]" has a null value in JSON.');
        return true;
      }());

      return MeResponse(
        id: mapValueOfType<String>(json, r'id')!,
        email: mapValueOfType<String>(json, r'email')!,
        displayName: mapValueOfType<String>(json, r'displayName')!,
        roles: json[r'roles'] is Iterable
            ? (json[r'roles'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<MeResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MeResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MeResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MeResponse> mapFromJson(dynamic json) {
    final map = <String, MeResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MeResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MeResponse-objects as value to a dart map
  static Map<String, List<MeResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MeResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MeResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'email',
    'displayName',
    'roles',
  };
}

