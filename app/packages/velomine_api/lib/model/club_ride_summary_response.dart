//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ClubRideSummaryResponse {
  /// Returns a new [ClubRideSummaryResponse] instance.
  ClubRideSummaryResponse({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.utcOffsetMinutes,
    required this.meetingName,
    required this.pace,
    required this.noDrop,
    required this.routeId,
    required this.routeName,
    required this.routeDistanceM,
    required this.signUpCount,
    required this.maxRiders,
    required this.isFull,
    required this.isSignedUp,
    required this.isCancelled,
    required this.createdByName,
  });

  final String id;

  final String title;

  final DateTime startsAt;

  final DateTime endsAt;

  final int utcOffsetMinutes;

  final String meetingName;

  final String pace;

  final bool noDrop;

  final String? routeId;

  final String? routeName;

  final double? routeDistanceM;

  final int signUpCount;

  final int? maxRiders;

  final bool isFull;

  final bool isSignedUp;

  final bool isCancelled;

  final String? createdByName;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ClubRideSummaryResponse &&
    other.id == id &&
    other.title == title &&
    other.startsAt == startsAt &&
    other.endsAt == endsAt &&
    other.utcOffsetMinutes == utcOffsetMinutes &&
    other.meetingName == meetingName &&
    other.pace == pace &&
    other.noDrop == noDrop &&
    other.routeId == routeId &&
    other.routeName == routeName &&
    other.routeDistanceM == routeDistanceM &&
    other.signUpCount == signUpCount &&
    other.maxRiders == maxRiders &&
    other.isFull == isFull &&
    other.isSignedUp == isSignedUp &&
    other.isCancelled == isCancelled &&
    other.createdByName == createdByName;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (title.hashCode) +
    (startsAt.hashCode) +
    (endsAt.hashCode) +
    (utcOffsetMinutes.hashCode) +
    (meetingName.hashCode) +
    (pace.hashCode) +
    (noDrop.hashCode) +
    (routeId == null ? 0 : routeId!.hashCode) +
    (routeName == null ? 0 : routeName!.hashCode) +
    (routeDistanceM == null ? 0 : routeDistanceM!.hashCode) +
    (signUpCount.hashCode) +
    (maxRiders == null ? 0 : maxRiders!.hashCode) +
    (isFull.hashCode) +
    (isSignedUp.hashCode) +
    (isCancelled.hashCode) +
    (createdByName == null ? 0 : createdByName!.hashCode);

  @override
  String toString() => 'ClubRideSummaryResponse[id=$id, title=$title, startsAt=$startsAt, endsAt=$endsAt, utcOffsetMinutes=$utcOffsetMinutes, meetingName=$meetingName, pace=$pace, noDrop=$noDrop, routeId=$routeId, routeName=$routeName, routeDistanceM=$routeDistanceM, signUpCount=$signUpCount, maxRiders=$maxRiders, isFull=$isFull, isSignedUp=$isSignedUp, isCancelled=$isCancelled, createdByName=$createdByName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'title'] = this.title;
      json[r'startsAt'] = this.startsAt.toUtc().toIso8601String();
      json[r'endsAt'] = this.endsAt.toUtc().toIso8601String();
      json[r'utcOffsetMinutes'] = this.utcOffsetMinutes;
      json[r'meetingName'] = this.meetingName;
      json[r'pace'] = this.pace;
      json[r'noDrop'] = this.noDrop;
    if (this.routeId != null) {
      json[r'routeId'] = this.routeId;
    } else {
      json[r'routeId'] = null;
    }
    if (this.routeName != null) {
      json[r'routeName'] = this.routeName;
    } else {
      json[r'routeName'] = null;
    }
    if (this.routeDistanceM != null) {
      json[r'routeDistanceM'] = this.routeDistanceM;
    } else {
      json[r'routeDistanceM'] = null;
    }
      json[r'signUpCount'] = this.signUpCount;
    if (this.maxRiders != null) {
      json[r'maxRiders'] = this.maxRiders;
    } else {
      json[r'maxRiders'] = null;
    }
      json[r'isFull'] = this.isFull;
      json[r'isSignedUp'] = this.isSignedUp;
      json[r'isCancelled'] = this.isCancelled;
    if (this.createdByName != null) {
      json[r'createdByName'] = this.createdByName;
    } else {
      json[r'createdByName'] = null;
    }
    return json;
  }

  /// Clones this instance of [ClubRideSummaryResponse] and returns a new one where some of the
  /// properties have changed.
  ClubRideSummaryResponse copyWith({
    String? id,
    String? title,
    DateTime? startsAt,
    DateTime? endsAt,
    int? utcOffsetMinutes,
    String? meetingName,
    String? pace,
    bool? noDrop,
    String? routeId,
    bool routeIdSetToNull = false,
    String? routeName,
    bool routeNameSetToNull = false,
    double? routeDistanceM,
    bool routeDistanceMSetToNull = false,
    int? signUpCount,
    int? maxRiders,
    bool maxRidersSetToNull = false,
    bool? isFull,
    bool? isSignedUp,
    bool? isCancelled,
    String? createdByName,
    bool createdByNameSetToNull = false,
  }) => ClubRideSummaryResponse(
    id: id ?? this.id,
    title: title ?? this.title,
    startsAt: startsAt ?? this.startsAt,
    endsAt: endsAt ?? this.endsAt,
    utcOffsetMinutes: utcOffsetMinutes ?? this.utcOffsetMinutes,
    meetingName: meetingName ?? this.meetingName,
    pace: pace ?? this.pace,
    noDrop: noDrop ?? this.noDrop,
    routeId: routeIdSetToNull ? null : routeId ?? this.routeId,
    routeName: routeNameSetToNull ? null : routeName ?? this.routeName,
    routeDistanceM: routeDistanceMSetToNull ? null : routeDistanceM ?? this.routeDistanceM,
    signUpCount: signUpCount ?? this.signUpCount,
    maxRiders: maxRidersSetToNull ? null : maxRiders ?? this.maxRiders,
    isFull: isFull ?? this.isFull,
    isSignedUp: isSignedUp ?? this.isSignedUp,
    isCancelled: isCancelled ?? this.isCancelled,
    createdByName: createdByNameSetToNull ? null : createdByName ?? this.createdByName,
  );

  /// Returns a new [ClubRideSummaryResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ClubRideSummaryResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "ClubRideSummaryResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "ClubRideSummaryResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'title'), 'Required key "ClubRideSummaryResponse[title]" is missing from JSON.');
        assert(json[r'title'] != null, 'Required key "ClubRideSummaryResponse[title]" has a null value in JSON.');
        assert(json.containsKey(r'startsAt'), 'Required key "ClubRideSummaryResponse[startsAt]" is missing from JSON.');
        assert(json[r'startsAt'] != null, 'Required key "ClubRideSummaryResponse[startsAt]" has a null value in JSON.');
        assert(json.containsKey(r'endsAt'), 'Required key "ClubRideSummaryResponse[endsAt]" is missing from JSON.');
        assert(json[r'endsAt'] != null, 'Required key "ClubRideSummaryResponse[endsAt]" has a null value in JSON.');
        assert(json.containsKey(r'utcOffsetMinutes'), 'Required key "ClubRideSummaryResponse[utcOffsetMinutes]" is missing from JSON.');
        assert(json[r'utcOffsetMinutes'] != null, 'Required key "ClubRideSummaryResponse[utcOffsetMinutes]" has a null value in JSON.');
        assert(json.containsKey(r'meetingName'), 'Required key "ClubRideSummaryResponse[meetingName]" is missing from JSON.');
        assert(json[r'meetingName'] != null, 'Required key "ClubRideSummaryResponse[meetingName]" has a null value in JSON.');
        assert(json.containsKey(r'pace'), 'Required key "ClubRideSummaryResponse[pace]" is missing from JSON.');
        assert(json[r'pace'] != null, 'Required key "ClubRideSummaryResponse[pace]" has a null value in JSON.');
        assert(json.containsKey(r'noDrop'), 'Required key "ClubRideSummaryResponse[noDrop]" is missing from JSON.');
        assert(json[r'noDrop'] != null, 'Required key "ClubRideSummaryResponse[noDrop]" has a null value in JSON.');
        assert(json.containsKey(r'routeId'), 'Required key "ClubRideSummaryResponse[routeId]" is missing from JSON.');
        assert(json.containsKey(r'routeName'), 'Required key "ClubRideSummaryResponse[routeName]" is missing from JSON.');
        assert(json.containsKey(r'routeDistanceM'), 'Required key "ClubRideSummaryResponse[routeDistanceM]" is missing from JSON.');
        assert(json.containsKey(r'signUpCount'), 'Required key "ClubRideSummaryResponse[signUpCount]" is missing from JSON.');
        assert(json[r'signUpCount'] != null, 'Required key "ClubRideSummaryResponse[signUpCount]" has a null value in JSON.');
        assert(json.containsKey(r'maxRiders'), 'Required key "ClubRideSummaryResponse[maxRiders]" is missing from JSON.');
        assert(json.containsKey(r'isFull'), 'Required key "ClubRideSummaryResponse[isFull]" is missing from JSON.');
        assert(json[r'isFull'] != null, 'Required key "ClubRideSummaryResponse[isFull]" has a null value in JSON.');
        assert(json.containsKey(r'isSignedUp'), 'Required key "ClubRideSummaryResponse[isSignedUp]" is missing from JSON.');
        assert(json[r'isSignedUp'] != null, 'Required key "ClubRideSummaryResponse[isSignedUp]" has a null value in JSON.');
        assert(json.containsKey(r'isCancelled'), 'Required key "ClubRideSummaryResponse[isCancelled]" is missing from JSON.');
        assert(json[r'isCancelled'] != null, 'Required key "ClubRideSummaryResponse[isCancelled]" has a null value in JSON.');
        assert(json.containsKey(r'createdByName'), 'Required key "ClubRideSummaryResponse[createdByName]" is missing from JSON.');
        return true;
      }());

      return ClubRideSummaryResponse(
        id: mapValueOfType<String>(json, r'id')!,
        title: mapValueOfType<String>(json, r'title')!,
        startsAt: mapDateTime(json, r'startsAt', r'')!,
        endsAt: mapDateTime(json, r'endsAt', r'')!,
        utcOffsetMinutes: mapValueOfType<int>(json, r'utcOffsetMinutes')!,
        meetingName: mapValueOfType<String>(json, r'meetingName')!,
        pace: mapValueOfType<String>(json, r'pace')!,
        noDrop: mapValueOfType<bool>(json, r'noDrop')!,
        routeId: mapValueOfType<String>(json, r'routeId'),
        routeName: mapValueOfType<String>(json, r'routeName'),
        routeDistanceM: mapValueOfType<double>(json, r'routeDistanceM'),
        signUpCount: mapValueOfType<int>(json, r'signUpCount')!,
        maxRiders: mapValueOfType<int>(json, r'maxRiders'),
        isFull: mapValueOfType<bool>(json, r'isFull')!,
        isSignedUp: mapValueOfType<bool>(json, r'isSignedUp')!,
        isCancelled: mapValueOfType<bool>(json, r'isCancelled')!,
        createdByName: mapValueOfType<String>(json, r'createdByName'),
      );
    }
    return null;
  }

  static List<ClubRideSummaryResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ClubRideSummaryResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ClubRideSummaryResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ClubRideSummaryResponse> mapFromJson(dynamic json) {
    final map = <String, ClubRideSummaryResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ClubRideSummaryResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ClubRideSummaryResponse-objects as value to a dart map
  static Map<String, List<ClubRideSummaryResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ClubRideSummaryResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ClubRideSummaryResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'title',
    'startsAt',
    'endsAt',
    'utcOffsetMinutes',
    'meetingName',
    'pace',
    'noDrop',
    'routeId',
    'routeName',
    'routeDistanceM',
    'signUpCount',
    'maxRiders',
    'isFull',
    'isSignedUp',
    'isCancelled',
    'createdByName',
  };
}

