//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class VerifyEmailRequest {
  /// Returns a new [VerifyEmailRequest] instance.
  VerifyEmailRequest({
    required this.email,
    required this.token,
  });

  final String email;

  final String token;

  @override
  bool operator ==(Object other) => identical(this, other) || other is VerifyEmailRequest &&
    other.email == email &&
    other.token == token;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (email.hashCode) +
    (token.hashCode);

  @override
  String toString() => 'VerifyEmailRequest[email=$email, token=$token]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'email'] = this.email;
      json[r'token'] = this.token;
    return json;
  }

  /// Clones this instance of [VerifyEmailRequest] and returns a new one where some of the
  /// properties have changed.
  VerifyEmailRequest copyWith({
    String? email,
    String? token,
  }) => VerifyEmailRequest(
    email: email ?? this.email,
    token: token ?? this.token,
  );

  /// Returns a new [VerifyEmailRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static VerifyEmailRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'email'), 'Required key "VerifyEmailRequest[email]" is missing from JSON.');
        assert(json[r'email'] != null, 'Required key "VerifyEmailRequest[email]" has a null value in JSON.');
        assert(json.containsKey(r'token'), 'Required key "VerifyEmailRequest[token]" is missing from JSON.');
        assert(json[r'token'] != null, 'Required key "VerifyEmailRequest[token]" has a null value in JSON.');
        return true;
      }());

      return VerifyEmailRequest(
        email: mapValueOfType<String>(json, r'email')!,
        token: mapValueOfType<String>(json, r'token')!,
      );
    }
    return null;
  }

  static List<VerifyEmailRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <VerifyEmailRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = VerifyEmailRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, VerifyEmailRequest> mapFromJson(dynamic json) {
    final map = <String, VerifyEmailRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = VerifyEmailRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of VerifyEmailRequest-objects as value to a dart map
  static Map<String, List<VerifyEmailRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<VerifyEmailRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = VerifyEmailRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'email',
    'token',
  };
}

