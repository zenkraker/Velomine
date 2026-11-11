//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ClubRideParticipantResponse {
  /// Returns a new [ClubRideParticipantResponse] instance.
  ClubRideParticipantResponse({
    required this.userId,
    required this.displayName,
  });

  final String userId;

  final String displayName;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ClubRideParticipantResponse &&
    other.userId == userId &&
    other.displayName == displayName;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (userId.hashCode) +
    (displayName.hashCode);

  @override
  String toString() => 'ClubRideParticipantResponse[userId=$userId, displayName=$displayName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'userId'] = this.userId;
      json[r'displayName'] = this.displayName;
    return json;
  }

  /// Clones this instance of [ClubRideParticipantResponse] and returns a new one where some of the
  /// properties have changed.
  ClubRideParticipantResponse copyWith({
    String? userId,
    String? displayName,
  }) => ClubRideParticipantResponse(
    userId: userId ?? this.userId,
    displayName: displayName ?? this.displayName,
  );

  /// Returns a new [ClubRideParticipantResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ClubRideParticipantResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'userId'), 'Required key "ClubRideParticipantResponse[userId]" is missing from JSON.');
        assert(json[r'userId'] != null, 'Required key "ClubRideParticipantResponse[userId]" has a null value in JSON.');
        assert(json.containsKey(r'displayName'), 'Required key "ClubRideParticipantResponse[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null, 'Required key "ClubRideParticipantResponse[displayName]" has a null value in JSON.');
        return true;
      }());

      return ClubRideParticipantResponse(
        userId: mapValueOfType<String>(json, r'userId')!,
        displayName: mapValueOfType<String>(json, r'displayName')!,
      );
    }
    return null;
  }

  static List<ClubRideParticipantResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ClubRideParticipantResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ClubRideParticipantResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ClubRideParticipantResponse> mapFromJson(dynamic json) {
    final map = <String, ClubRideParticipantResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ClubRideParticipantResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ClubRideParticipantResponse-objects as value to a dart map
  static Map<String, List<ClubRideParticipantResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ClubRideParticipantResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ClubRideParticipantResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'userId',
    'displayName',
  };
}

