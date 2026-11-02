//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class RegisterRequest {
  /// Returns a new [RegisterRequest] instance.
  RegisterRequest({
    required this.email,
    required this.password,
    required this.displayName,
  });

  final String email;

  final String password;

  final String displayName;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RegisterRequest &&
    other.email == email &&
    other.password == password &&
    other.displayName == displayName;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (email.hashCode) +
    (password.hashCode) +
    (displayName.hashCode);

  @override
  String toString() => 'RegisterRequest[email=$email, password=$password, displayName=$displayName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'email'] = this.email;
      json[r'password'] = this.password;
      json[r'displayName'] = this.displayName;
    return json;
  }

  /// Clones this instance of [RegisterRequest] and returns a new one where some of the
  /// properties have changed.
  RegisterRequest copyWith({
    String? email,
    String? password,
    String? displayName,
  }) => RegisterRequest(
    email: email ?? this.email,
    password: password ?? this.password,
    displayName: displayName ?? this.displayName,
  );

  /// Returns a new [RegisterRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RegisterRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'email'), 'Required key "RegisterRequest[email]" is missing from JSON.');
        assert(json[r'email'] != null, 'Required key "RegisterRequest[email]" has a null value in JSON.');
        assert(json.containsKey(r'password'), 'Required key "RegisterRequest[password]" is missing from JSON.');
        assert(json[r'password'] != null, 'Required key "RegisterRequest[password]" has a null value in JSON.');
        assert(json.containsKey(r'displayName'), 'Required key "RegisterRequest[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null, 'Required key "RegisterRequest[displayName]" has a null value in JSON.');
        return true;
      }());

      return RegisterRequest(
        email: mapValueOfType<String>(json, r'email')!,
        password: mapValueOfType<String>(json, r'password')!,
        displayName: mapValueOfType<String>(json, r'displayName')!,
      );
    }
    return null;
  }

  static List<RegisterRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RegisterRequest> mapFromJson(dynamic json) {
    final map = <String, RegisterRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RegisterRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RegisterRequest-objects as value to a dart map
  static Map<String, List<RegisterRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RegisterRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RegisterRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'email',
    'password',
    'displayName',
  };
}

