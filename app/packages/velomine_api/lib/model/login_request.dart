//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class LoginRequest {
  /// Returns a new [LoginRequest] instance.
  LoginRequest({
    required this.email,
    required this.password,
    this.useCookies = const Optional.present(false),
    this.rememberMe = const Optional.present(true),
    this.deviceLabel = const Optional.absent(),
  });

  final String email;

  final String password;

  final Optional<bool?> useCookies;

  final Optional<bool?> rememberMe;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> deviceLabel;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LoginRequest &&
    other.email == email &&
    other.password == password &&
    other.useCookies == useCookies &&
    other.rememberMe == rememberMe &&
    other.deviceLabel == deviceLabel;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (email.hashCode) +
    (password.hashCode) +
    (useCookies.hashCode) +
    (rememberMe.hashCode) +
    (deviceLabel == null ? 0 : deviceLabel!.hashCode);

  @override
  String toString() => 'LoginRequest[email=$email, password=$password, useCookies=$useCookies, rememberMe=$rememberMe, deviceLabel=$deviceLabel]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'email'] = this.email;
      json[r'password'] = this.password;
    if (this.useCookies.isPresent) {
      final value = this.useCookies.value;
      json[r'useCookies'] = value;
    }
    if (this.rememberMe.isPresent) {
      final value = this.rememberMe.value;
      json[r'rememberMe'] = value;
    }
    if (this.deviceLabel.isPresent) {
      final value = this.deviceLabel.value;
      json[r'deviceLabel'] = value;
    }
    return json;
  }

  /// Clones this instance of [LoginRequest] and returns a new one where some of the
  /// properties have changed.
  LoginRequest copyWith({
    String? email,
    String? password,
    Optional<bool?>? useCookies,
    Optional<bool?>? rememberMe,
    Optional<String?>? deviceLabel,
  }) => LoginRequest(
    email: email ?? this.email,
    password: password ?? this.password,
    useCookies: useCookies ?? this.useCookies,
    rememberMe: rememberMe ?? this.rememberMe,
    deviceLabel: deviceLabel ?? this.deviceLabel,
  );

  /// Returns a new [LoginRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LoginRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'email'), 'Required key "LoginRequest[email]" is missing from JSON.');
        assert(json[r'email'] != null, 'Required key "LoginRequest[email]" has a null value in JSON.');
        assert(json.containsKey(r'password'), 'Required key "LoginRequest[password]" is missing from JSON.');
        assert(json[r'password'] != null, 'Required key "LoginRequest[password]" has a null value in JSON.');
        return true;
      }());

      return LoginRequest(
        email: mapValueOfType<String>(json, r'email')!,
        password: mapValueOfType<String>(json, r'password')!,
        useCookies: json.containsKey(r'useCookies') ? Optional.present(mapValueOfType<bool>(json, r'useCookies')) : const Optional.absent(),
        rememberMe: json.containsKey(r'rememberMe') ? Optional.present(mapValueOfType<bool>(json, r'rememberMe')) : const Optional.absent(),
        deviceLabel: json.containsKey(r'deviceLabel') ? Optional.present(mapValueOfType<String>(json, r'deviceLabel')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<LoginRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LoginRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LoginRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LoginRequest> mapFromJson(dynamic json) {
    final map = <String, LoginRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LoginRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LoginRequest-objects as value to a dart map
  static Map<String, List<LoginRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LoginRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LoginRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'email',
    'password',
  };
}

