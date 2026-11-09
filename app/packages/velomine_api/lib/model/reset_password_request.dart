//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ResetPasswordRequest {
  /// Returns a new [ResetPasswordRequest] instance.
  ResetPasswordRequest({
    required this.email,
    required this.token,
    required this.newPassword,
  });

  final String email;

  final String token;

  final String newPassword;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ResetPasswordRequest &&
    other.email == email &&
    other.token == token &&
    other.newPassword == newPassword;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (email.hashCode) +
    (token.hashCode) +
    (newPassword.hashCode);

  @override
  String toString() => 'ResetPasswordRequest[email=$email, token=$token, newPassword=$newPassword]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'email'] = this.email;
      json[r'token'] = this.token;
      json[r'newPassword'] = this.newPassword;
    return json;
  }

  /// Clones this instance of [ResetPasswordRequest] and returns a new one where some of the
  /// properties have changed.
  ResetPasswordRequest copyWith({
    String? email,
    String? token,
    String? newPassword,
  }) => ResetPasswordRequest(
    email: email ?? this.email,
    token: token ?? this.token,
    newPassword: newPassword ?? this.newPassword,
  );

  /// Returns a new [ResetPasswordRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ResetPasswordRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'email'), 'Required key "ResetPasswordRequest[email]" is missing from JSON.');
        assert(json[r'email'] != null, 'Required key "ResetPasswordRequest[email]" has a null value in JSON.');
        assert(json.containsKey(r'token'), 'Required key "ResetPasswordRequest[token]" is missing from JSON.');
        assert(json[r'token'] != null, 'Required key "ResetPasswordRequest[token]" has a null value in JSON.');
        assert(json.containsKey(r'newPassword'), 'Required key "ResetPasswordRequest[newPassword]" is missing from JSON.');
        assert(json[r'newPassword'] != null, 'Required key "ResetPasswordRequest[newPassword]" has a null value in JSON.');
        return true;
      }());

      return ResetPasswordRequest(
        email: mapValueOfType<String>(json, r'email')!,
        token: mapValueOfType<String>(json, r'token')!,
        newPassword: mapValueOfType<String>(json, r'newPassword')!,
      );
    }
    return null;
  }

  static List<ResetPasswordRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ResetPasswordRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ResetPasswordRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ResetPasswordRequest> mapFromJson(dynamic json) {
    final map = <String, ResetPasswordRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ResetPasswordRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ResetPasswordRequest-objects as value to a dart map
  static Map<String, List<ResetPasswordRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ResetPasswordRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ResetPasswordRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'email',
    'token',
    'newPassword',
  };
}

