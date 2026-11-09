//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class JoinRequestsResponse {
  /// Returns a new [JoinRequestsResponse] instance.
  JoinRequestsResponse({
    this.requests = const [],
  });

  final List<JoinRequestResponse> requests;

  @override
  bool operator ==(Object other) => identical(this, other) || other is JoinRequestsResponse &&
    _deepEquality.equals(other.requests, requests);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (requests.hashCode);

  @override
  String toString() => 'JoinRequestsResponse[requests=$requests]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'requests'] = this.requests;
    return json;
  }

  /// Clones this instance of [JoinRequestsResponse] and returns a new one where some of the
  /// properties have changed.
  JoinRequestsResponse copyWith({
    List<JoinRequestResponse>? requests,
  }) => JoinRequestsResponse(
    requests: requests ?? this.requests,
  );

  /// Returns a new [JoinRequestsResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static JoinRequestsResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'requests'), 'Required key "JoinRequestsResponse[requests]" is missing from JSON.');
        assert(json[r'requests'] != null, 'Required key "JoinRequestsResponse[requests]" has a null value in JSON.');
        return true;
      }());

      return JoinRequestsResponse(
        requests: JoinRequestResponse.listFromJson(json[r'requests']),
      );
    }
    return null;
  }

  static List<JoinRequestsResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <JoinRequestsResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = JoinRequestsResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, JoinRequestsResponse> mapFromJson(dynamic json) {
    final map = <String, JoinRequestsResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = JoinRequestsResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of JoinRequestsResponse-objects as value to a dart map
  static Map<String, List<JoinRequestsResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<JoinRequestsResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = JoinRequestsResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'requests',
  };
}

