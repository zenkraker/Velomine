//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class CheckInsResponse {
  /// Returns a new [CheckInsResponse] instance.
  CheckInsResponse({
    this.checkIns = const [],
  });

  final List<CheckInResponse> checkIns;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CheckInsResponse &&
    _deepEquality.equals(other.checkIns, checkIns);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (checkIns.hashCode);

  @override
  String toString() => 'CheckInsResponse[checkIns=$checkIns]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'checkIns'] = this.checkIns;
    return json;
  }

  /// Clones this instance of [CheckInsResponse] and returns a new one where some of the
  /// properties have changed.
  CheckInsResponse copyWith({
    List<CheckInResponse>? checkIns,
  }) => CheckInsResponse(
    checkIns: checkIns ?? this.checkIns,
  );

  /// Returns a new [CheckInsResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CheckInsResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'checkIns'), 'Required key "CheckInsResponse[checkIns]" is missing from JSON.');
        assert(json[r'checkIns'] != null, 'Required key "CheckInsResponse[checkIns]" has a null value in JSON.');
        return true;
      }());

      return CheckInsResponse(
        checkIns: CheckInResponse.listFromJson(json[r'checkIns']),
      );
    }
    return null;
  }

  static List<CheckInsResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CheckInsResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CheckInsResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CheckInsResponse> mapFromJson(dynamic json) {
    final map = <String, CheckInsResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CheckInsResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CheckInsResponse-objects as value to a dart map
  static Map<String, List<CheckInsResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CheckInsResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CheckInsResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'checkIns',
  };
}

