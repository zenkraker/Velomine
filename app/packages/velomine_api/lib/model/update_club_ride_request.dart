//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class UpdateClubRideRequest {
  /// Returns a new [UpdateClubRideRequest] instance.
  UpdateClubRideRequest({
    required this.title,
    required this.startsAt,
    required this.utcOffsetMinutes,
    required this.meetingName,
    required this.latitude,
    required this.longitude,
    this.routeId = const Optional.absent(),
    required this.pace,
    this.noDrop = const Optional.absent(),
    this.notes = const Optional.absent(),
    this.maxRiders = const Optional.absent(),
  });

  final String title;

  final DateTime startsAt;

  /// Minimum value: -840
  /// Maximum value: 840
  final int utcOffsetMinutes;

  final String meetingName;

  /// Minimum value: -90
  /// Maximum value: 90
  final double latitude;

  /// Minimum value: -180
  /// Maximum value: 180
  final double longitude;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> routeId;

  final String pace;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> noDrop;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> notes;

  /// Minimum value: 1
  /// Maximum value: 500
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> maxRiders;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UpdateClubRideRequest &&
    other.title == title &&
    other.startsAt == startsAt &&
    other.utcOffsetMinutes == utcOffsetMinutes &&
    other.meetingName == meetingName &&
    other.latitude == latitude &&
    other.longitude == longitude &&
    other.routeId == routeId &&
    other.pace == pace &&
    other.noDrop == noDrop &&
    other.notes == notes &&
    other.maxRiders == maxRiders;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (title.hashCode) +
    (startsAt.hashCode) +
    (utcOffsetMinutes.hashCode) +
    (meetingName.hashCode) +
    (latitude.hashCode) +
    (longitude.hashCode) +
    (routeId == null ? 0 : routeId!.hashCode) +
    (pace.hashCode) +
    (noDrop == null ? 0 : noDrop!.hashCode) +
    (notes == null ? 0 : notes!.hashCode) +
    (maxRiders == null ? 0 : maxRiders!.hashCode);

  @override
  String toString() => 'UpdateClubRideRequest[title=$title, startsAt=$startsAt, utcOffsetMinutes=$utcOffsetMinutes, meetingName=$meetingName, latitude=$latitude, longitude=$longitude, routeId=$routeId, pace=$pace, noDrop=$noDrop, notes=$notes, maxRiders=$maxRiders]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'title'] = this.title;
      json[r'startsAt'] = this.startsAt.toUtc().toIso8601String();
      json[r'utcOffsetMinutes'] = this.utcOffsetMinutes;
      json[r'meetingName'] = this.meetingName;
      json[r'latitude'] = this.latitude;
      json[r'longitude'] = this.longitude;
    if (this.routeId.isPresent) {
      final value = this.routeId.value;
      json[r'routeId'] = value;
    }
      json[r'pace'] = this.pace;
    if (this.noDrop.isPresent) {
      final value = this.noDrop.value;
      json[r'noDrop'] = value;
    }
    if (this.notes.isPresent) {
      final value = this.notes.value;
      json[r'notes'] = value;
    }
    if (this.maxRiders.isPresent) {
      final value = this.maxRiders.value;
      json[r'maxRiders'] = value;
    }
    return json;
  }

  /// Clones this instance of [UpdateClubRideRequest] and returns a new one where some of the
  /// properties have changed.
  UpdateClubRideRequest copyWith({
    String? title,
    DateTime? startsAt,
    int? utcOffsetMinutes,
    String? meetingName,
    double? latitude,
    double? longitude,
    Optional<String?>? routeId,
    String? pace,
    Optional<bool?>? noDrop,
    Optional<String?>? notes,
    Optional<int?>? maxRiders,
  }) => UpdateClubRideRequest(
    title: title ?? this.title,
    startsAt: startsAt ?? this.startsAt,
    utcOffsetMinutes: utcOffsetMinutes ?? this.utcOffsetMinutes,
    meetingName: meetingName ?? this.meetingName,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    routeId: routeId ?? this.routeId,
    pace: pace ?? this.pace,
    noDrop: noDrop ?? this.noDrop,
    notes: notes ?? this.notes,
    maxRiders: maxRiders ?? this.maxRiders,
  );

  /// Returns a new [UpdateClubRideRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateClubRideRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'title'), 'Required key "UpdateClubRideRequest[title]" is missing from JSON.');
        assert(json[r'title'] != null, 'Required key "UpdateClubRideRequest[title]" has a null value in JSON.');
        assert(json.containsKey(r'startsAt'), 'Required key "UpdateClubRideRequest[startsAt]" is missing from JSON.');
        assert(json[r'startsAt'] != null, 'Required key "UpdateClubRideRequest[startsAt]" has a null value in JSON.');
        assert(json.containsKey(r'utcOffsetMinutes'), 'Required key "UpdateClubRideRequest[utcOffsetMinutes]" is missing from JSON.');
        assert(json[r'utcOffsetMinutes'] != null, 'Required key "UpdateClubRideRequest[utcOffsetMinutes]" has a null value in JSON.');
        assert(json.containsKey(r'meetingName'), 'Required key "UpdateClubRideRequest[meetingName]" is missing from JSON.');
        assert(json[r'meetingName'] != null, 'Required key "UpdateClubRideRequest[meetingName]" has a null value in JSON.');
        assert(json.containsKey(r'latitude'), 'Required key "UpdateClubRideRequest[latitude]" is missing from JSON.');
        assert(json[r'latitude'] != null, 'Required key "UpdateClubRideRequest[latitude]" has a null value in JSON.');
        assert(json.containsKey(r'longitude'), 'Required key "UpdateClubRideRequest[longitude]" is missing from JSON.');
        assert(json[r'longitude'] != null, 'Required key "UpdateClubRideRequest[longitude]" has a null value in JSON.');
        assert(json.containsKey(r'pace'), 'Required key "UpdateClubRideRequest[pace]" is missing from JSON.');
        assert(json[r'pace'] != null, 'Required key "UpdateClubRideRequest[pace]" has a null value in JSON.');
        return true;
      }());

      return UpdateClubRideRequest(
        title: mapValueOfType<String>(json, r'title')!,
        startsAt: mapDateTime(json, r'startsAt', r'')!,
        utcOffsetMinutes: mapValueOfType<int>(json, r'utcOffsetMinutes')!,
        meetingName: mapValueOfType<String>(json, r'meetingName')!,
        latitude: mapValueOfType<double>(json, r'latitude')!,
        longitude: mapValueOfType<double>(json, r'longitude')!,
        routeId: json.containsKey(r'routeId') ? Optional.present(mapValueOfType<String>(json, r'routeId')) : const Optional.absent(),
        pace: mapValueOfType<String>(json, r'pace')!,
        noDrop: json.containsKey(r'noDrop') ? Optional.present(mapValueOfType<bool>(json, r'noDrop')) : const Optional.absent(),
        notes: json.containsKey(r'notes') ? Optional.present(mapValueOfType<String>(json, r'notes')) : const Optional.absent(),
        maxRiders: json.containsKey(r'maxRiders') ? Optional.present(json[r'maxRiders'] == null ? null : int.parse('${json[r'maxRiders']}')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<UpdateClubRideRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UpdateClubRideRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateClubRideRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateClubRideRequest> mapFromJson(dynamic json) {
    final map = <String, UpdateClubRideRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateClubRideRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateClubRideRequest-objects as value to a dart map
  static Map<String, List<UpdateClubRideRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UpdateClubRideRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateClubRideRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'title',
    'startsAt',
    'utcOffsetMinutes',
    'meetingName',
    'latitude',
    'longitude',
    'pace',
  };
}

