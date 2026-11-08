//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class CoachWellbeingResponse {
  /// Returns a new [CoachWellbeingResponse] instance.
  CoachWellbeingResponse({
    this.checkIns = const [],
    this.rides = const [],
  });

  final List<CheckInResponse> checkIns;

  final List<CoachRpeResponse> rides;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CoachWellbeingResponse &&
    _deepEquality.equals(other.checkIns, checkIns) &&
    _deepEquality.equals(other.rides, rides);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (checkIns.hashCode) +
    (rides.hashCode);

  @override
  String toString() => 'CoachWellbeingResponse[checkIns=$checkIns, rides=$rides]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'checkIns'] = this.checkIns;
      json[r'rides'] = this.rides;
    return json;
  }

  /// Clones this instance of [CoachWellbeingResponse] and returns a new one where some of the
  /// properties have changed.
  CoachWellbeingResponse copyWith({
    List<CheckInResponse>? checkIns,
    List<CoachRpeResponse>? rides,
  }) => CoachWellbeingResponse(
    checkIns: checkIns ?? this.checkIns,
    rides: rides ?? this.rides,
  );

  /// Returns a new [CoachWellbeingResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CoachWellbeingResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'checkIns'), 'Required key "CoachWellbeingResponse[checkIns]" is missing from JSON.');
        assert(json[r'checkIns'] != null, 'Required key "CoachWellbeingResponse[checkIns]" has a null value in JSON.');
        assert(json.containsKey(r'rides'), 'Required key "CoachWellbeingResponse[rides]" is missing from JSON.');
        assert(json[r'rides'] != null, 'Required key "CoachWellbeingResponse[rides]" has a null value in JSON.');
        return true;
      }());

      return CoachWellbeingResponse(
        checkIns: CheckInResponse.listFromJson(json[r'checkIns']),
        rides: CoachRpeResponse.listFromJson(json[r'rides']),
      );
    }
    return null;
  }

  static List<CoachWellbeingResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CoachWellbeingResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CoachWellbeingResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CoachWellbeingResponse> mapFromJson(dynamic json) {
    final map = <String, CoachWellbeingResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CoachWellbeingResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CoachWellbeingResponse-objects as value to a dart map
  static Map<String, List<CoachWellbeingResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CoachWellbeingResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CoachWellbeingResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'checkIns',
    'rides',
  };
}

