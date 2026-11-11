//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ClubRideListResponse {
  /// Returns a new [ClubRideListResponse] instance.
  ClubRideListResponse({
    this.upcoming = const [],
    this.past = const [],
  });

  final List<ClubRideSummaryResponse> upcoming;

  final List<ClubRideSummaryResponse> past;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ClubRideListResponse &&
    _deepEquality.equals(other.upcoming, upcoming) &&
    _deepEquality.equals(other.past, past);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (upcoming.hashCode) +
    (past.hashCode);

  @override
  String toString() => 'ClubRideListResponse[upcoming=$upcoming, past=$past]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'upcoming'] = this.upcoming;
      json[r'past'] = this.past;
    return json;
  }

  /// Clones this instance of [ClubRideListResponse] and returns a new one where some of the
  /// properties have changed.
  ClubRideListResponse copyWith({
    List<ClubRideSummaryResponse>? upcoming,
    List<ClubRideSummaryResponse>? past,
  }) => ClubRideListResponse(
    upcoming: upcoming ?? this.upcoming,
    past: past ?? this.past,
  );

  /// Returns a new [ClubRideListResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ClubRideListResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'upcoming'), 'Required key "ClubRideListResponse[upcoming]" is missing from JSON.');
        assert(json[r'upcoming'] != null, 'Required key "ClubRideListResponse[upcoming]" has a null value in JSON.');
        assert(json.containsKey(r'past'), 'Required key "ClubRideListResponse[past]" is missing from JSON.');
        assert(json[r'past'] != null, 'Required key "ClubRideListResponse[past]" has a null value in JSON.');
        return true;
      }());

      return ClubRideListResponse(
        upcoming: ClubRideSummaryResponse.listFromJson(json[r'upcoming']),
        past: ClubRideSummaryResponse.listFromJson(json[r'past']),
      );
    }
    return null;
  }

  static List<ClubRideListResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ClubRideListResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ClubRideListResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ClubRideListResponse> mapFromJson(dynamic json) {
    final map = <String, ClubRideListResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ClubRideListResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ClubRideListResponse-objects as value to a dart map
  static Map<String, List<ClubRideListResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ClubRideListResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ClubRideListResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'upcoming',
    'past',
  };
}

