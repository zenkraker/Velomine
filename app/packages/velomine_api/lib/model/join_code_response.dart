//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class JoinCodeResponse {
  /// Returns a new [JoinCodeResponse] instance.
  JoinCodeResponse({
    required this.joinCode,
  });

  final String joinCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is JoinCodeResponse &&
    other.joinCode == joinCode;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (joinCode.hashCode);

  @override
  String toString() => 'JoinCodeResponse[joinCode=$joinCode]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'joinCode'] = this.joinCode;
    return json;
  }

  /// Clones this instance of [JoinCodeResponse] and returns a new one where some of the
  /// properties have changed.
  JoinCodeResponse copyWith({
    String? joinCode,
  }) => JoinCodeResponse(
    joinCode: joinCode ?? this.joinCode,
  );

  /// Returns a new [JoinCodeResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static JoinCodeResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'joinCode'), 'Required key "JoinCodeResponse[joinCode]" is missing from JSON.');
        assert(json[r'joinCode'] != null, 'Required key "JoinCodeResponse[joinCode]" has a null value in JSON.');
        return true;
      }());

      return JoinCodeResponse(
        joinCode: mapValueOfType<String>(json, r'joinCode')!,
      );
    }
    return null;
  }

  static List<JoinCodeResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <JoinCodeResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = JoinCodeResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, JoinCodeResponse> mapFromJson(dynamic json) {
    final map = <String, JoinCodeResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = JoinCodeResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of JoinCodeResponse-objects as value to a dart map
  static Map<String, List<JoinCodeResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<JoinCodeResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = JoinCodeResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'joinCode',
  };
}

