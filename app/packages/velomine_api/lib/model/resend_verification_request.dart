//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ResendVerificationRequest {
  /// Returns a new [ResendVerificationRequest] instance.
  ResendVerificationRequest({
    required this.email,
  });

  final String email;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ResendVerificationRequest &&
    other.email == email;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (email.hashCode);

  @override
  String toString() => 'ResendVerificationRequest[email=$email]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'email'] = this.email;
    return json;
  }

  /// Clones this instance of [ResendVerificationRequest] and returns a new one where some of the
  /// properties have changed.
  ResendVerificationRequest copyWith({
    String? email,
  }) => ResendVerificationRequest(
    email: email ?? this.email,
  );

  /// Returns a new [ResendVerificationRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ResendVerificationRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'email'), 'Required key "ResendVerificationRequest[email]" is missing from JSON.');
        assert(json[r'email'] != null, 'Required key "ResendVerificationRequest[email]" has a null value in JSON.');
        return true;
      }());

      return ResendVerificationRequest(
        email: mapValueOfType<String>(json, r'email')!,
      );
    }
    return null;
  }

  static List<ResendVerificationRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ResendVerificationRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ResendVerificationRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ResendVerificationRequest> mapFromJson(dynamic json) {
    final map = <String, ResendVerificationRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ResendVerificationRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ResendVerificationRequest-objects as value to a dart map
  static Map<String, List<ResendVerificationRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ResendVerificationRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ResendVerificationRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'email',
  };
}

