//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class DeleteMyAccountRequest {
  /// Returns a new [DeleteMyAccountRequest] instance.
  DeleteMyAccountRequest({
    required this.password,
    required this.confirmEmail,
  });

  final String? password;

  final String? confirmEmail;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DeleteMyAccountRequest &&
    other.password == password &&
    other.confirmEmail == confirmEmail;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (password == null ? 0 : password!.hashCode) +
    (confirmEmail == null ? 0 : confirmEmail!.hashCode);

  @override
  String toString() => 'DeleteMyAccountRequest[password=$password, confirmEmail=$confirmEmail]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.password != null) {
      json[r'password'] = this.password;
    } else {
      json[r'password'] = null;
    }
    if (this.confirmEmail != null) {
      json[r'confirmEmail'] = this.confirmEmail;
    } else {
      json[r'confirmEmail'] = null;
    }
    return json;
  }

  /// Clones this instance of [DeleteMyAccountRequest] and returns a new one where some of the
  /// properties have changed.
  DeleteMyAccountRequest copyWith({
    String? password,
    bool passwordSetToNull = false,
    String? confirmEmail,
    bool confirmEmailSetToNull = false,
  }) => DeleteMyAccountRequest(
    password: passwordSetToNull ? null : password ?? this.password,
    confirmEmail: confirmEmailSetToNull ? null : confirmEmail ?? this.confirmEmail,
  );

  /// Returns a new [DeleteMyAccountRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DeleteMyAccountRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'password'), 'Required key "DeleteMyAccountRequest[password]" is missing from JSON.');
        assert(json.containsKey(r'confirmEmail'), 'Required key "DeleteMyAccountRequest[confirmEmail]" is missing from JSON.');
        return true;
      }());

      return DeleteMyAccountRequest(
        password: mapValueOfType<String>(json, r'password'),
        confirmEmail: mapValueOfType<String>(json, r'confirmEmail'),
      );
    }
    return null;
  }

  static List<DeleteMyAccountRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DeleteMyAccountRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DeleteMyAccountRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DeleteMyAccountRequest> mapFromJson(dynamic json) {
    final map = <String, DeleteMyAccountRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DeleteMyAccountRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DeleteMyAccountRequest-objects as value to a dart map
  static Map<String, List<DeleteMyAccountRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DeleteMyAccountRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DeleteMyAccountRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'password',
    'confirmEmail',
  };
}

