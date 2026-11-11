//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ClubRideDetailResponse {
  /// Returns a new [ClubRideDetailResponse] instance.
  ClubRideDetailResponse({
    required this.ride,
    required this.meetingLatitude,
    required this.meetingLongitude,
    required this.notes,
    required this.canPlan,
    this.participants = const [],
  });

  final ClubRideSummaryResponse ride;

  final double meetingLatitude;

  final double meetingLongitude;

  final String? notes;

  final bool canPlan;

  final List<ClubRideParticipantResponse> participants;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ClubRideDetailResponse &&
    other.ride == ride &&
    other.meetingLatitude == meetingLatitude &&
    other.meetingLongitude == meetingLongitude &&
    other.notes == notes &&
    other.canPlan == canPlan &&
    _deepEquality.equals(other.participants, participants);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (ride.hashCode) +
    (meetingLatitude.hashCode) +
    (meetingLongitude.hashCode) +
    (notes == null ? 0 : notes!.hashCode) +
    (canPlan.hashCode) +
    (participants.hashCode);

  @override
  String toString() => 'ClubRideDetailResponse[ride=$ride, meetingLatitude=$meetingLatitude, meetingLongitude=$meetingLongitude, notes=$notes, canPlan=$canPlan, participants=$participants]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'ride'] = this.ride;
      json[r'meetingLatitude'] = this.meetingLatitude;
      json[r'meetingLongitude'] = this.meetingLongitude;
    if (this.notes != null) {
      json[r'notes'] = this.notes;
    } else {
      json[r'notes'] = null;
    }
      json[r'canPlan'] = this.canPlan;
      json[r'participants'] = this.participants;
    return json;
  }

  /// Clones this instance of [ClubRideDetailResponse] and returns a new one where some of the
  /// properties have changed.
  ClubRideDetailResponse copyWith({
    ClubRideSummaryResponse? ride,
    double? meetingLatitude,
    double? meetingLongitude,
    String? notes,
    bool notesSetToNull = false,
    bool? canPlan,
    List<ClubRideParticipantResponse>? participants,
  }) => ClubRideDetailResponse(
    ride: ride ?? this.ride,
    meetingLatitude: meetingLatitude ?? this.meetingLatitude,
    meetingLongitude: meetingLongitude ?? this.meetingLongitude,
    notes: notesSetToNull ? null : notes ?? this.notes,
    canPlan: canPlan ?? this.canPlan,
    participants: participants ?? this.participants,
  );

  /// Returns a new [ClubRideDetailResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ClubRideDetailResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'ride'), 'Required key "ClubRideDetailResponse[ride]" is missing from JSON.');
        assert(json[r'ride'] != null, 'Required key "ClubRideDetailResponse[ride]" has a null value in JSON.');
        assert(json.containsKey(r'meetingLatitude'), 'Required key "ClubRideDetailResponse[meetingLatitude]" is missing from JSON.');
        assert(json[r'meetingLatitude'] != null, 'Required key "ClubRideDetailResponse[meetingLatitude]" has a null value in JSON.');
        assert(json.containsKey(r'meetingLongitude'), 'Required key "ClubRideDetailResponse[meetingLongitude]" is missing from JSON.');
        assert(json[r'meetingLongitude'] != null, 'Required key "ClubRideDetailResponse[meetingLongitude]" has a null value in JSON.');
        assert(json.containsKey(r'notes'), 'Required key "ClubRideDetailResponse[notes]" is missing from JSON.');
        assert(json.containsKey(r'canPlan'), 'Required key "ClubRideDetailResponse[canPlan]" is missing from JSON.');
        assert(json[r'canPlan'] != null, 'Required key "ClubRideDetailResponse[canPlan]" has a null value in JSON.');
        assert(json.containsKey(r'participants'), 'Required key "ClubRideDetailResponse[participants]" is missing from JSON.');
        assert(json[r'participants'] != null, 'Required key "ClubRideDetailResponse[participants]" has a null value in JSON.');
        return true;
      }());

      return ClubRideDetailResponse(
        ride: ClubRideSummaryResponse.fromJson(json[r'ride'])!,
        meetingLatitude: mapValueOfType<double>(json, r'meetingLatitude')!,
        meetingLongitude: mapValueOfType<double>(json, r'meetingLongitude')!,
        notes: mapValueOfType<String>(json, r'notes'),
        canPlan: mapValueOfType<bool>(json, r'canPlan')!,
        participants: ClubRideParticipantResponse.listFromJson(json[r'participants']),
      );
    }
    return null;
  }

  static List<ClubRideDetailResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ClubRideDetailResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ClubRideDetailResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ClubRideDetailResponse> mapFromJson(dynamic json) {
    final map = <String, ClubRideDetailResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ClubRideDetailResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ClubRideDetailResponse-objects as value to a dart map
  static Map<String, List<ClubRideDetailResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ClubRideDetailResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ClubRideDetailResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'ride',
    'meetingLatitude',
    'meetingLongitude',
    'notes',
    'canPlan',
    'participants',
  };
}

