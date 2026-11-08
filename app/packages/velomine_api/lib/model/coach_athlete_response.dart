//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class CoachAthleteResponse {
  /// Returns a new [CoachAthleteResponse] instance.
  CoachAthleteResponse({
    required this.userId,
    required this.displayName,
    required this.sharesRides,
    required this.sharesAnalytics,
    required this.sharesRoutes,
    required this.lastRideAt,
    required this.rides,
    required this.distanceM,
    required this.tss7,
    required this.tss42,
  });

  final String userId;

  final String displayName;

  final bool sharesRides;

  final bool sharesAnalytics;

  final bool sharesRoutes;

  final DateTime? lastRideAt;

  final int? rides;

  final double? distanceM;

  final double? tss7;

  final double? tss42;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CoachAthleteResponse &&
    other.userId == userId &&
    other.displayName == displayName &&
    other.sharesRides == sharesRides &&
    other.sharesAnalytics == sharesAnalytics &&
    other.sharesRoutes == sharesRoutes &&
    other.lastRideAt == lastRideAt &&
    other.rides == rides &&
    other.distanceM == distanceM &&
    other.tss7 == tss7 &&
    other.tss42 == tss42;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (userId.hashCode) +
    (displayName.hashCode) +
    (sharesRides.hashCode) +
    (sharesAnalytics.hashCode) +
    (sharesRoutes.hashCode) +
    (lastRideAt == null ? 0 : lastRideAt!.hashCode) +
    (rides == null ? 0 : rides!.hashCode) +
    (distanceM == null ? 0 : distanceM!.hashCode) +
    (tss7 == null ? 0 : tss7!.hashCode) +
    (tss42 == null ? 0 : tss42!.hashCode);

  @override
  String toString() => 'CoachAthleteResponse[userId=$userId, displayName=$displayName, sharesRides=$sharesRides, sharesAnalytics=$sharesAnalytics, sharesRoutes=$sharesRoutes, lastRideAt=$lastRideAt, rides=$rides, distanceM=$distanceM, tss7=$tss7, tss42=$tss42]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'userId'] = this.userId;
      json[r'displayName'] = this.displayName;
      json[r'sharesRides'] = this.sharesRides;
      json[r'sharesAnalytics'] = this.sharesAnalytics;
      json[r'sharesRoutes'] = this.sharesRoutes;
    if (this.lastRideAt != null) {
      json[r'lastRideAt'] = this.lastRideAt!.toUtc().toIso8601String();
    } else {
      json[r'lastRideAt'] = null;
    }
    if (this.rides != null) {
      json[r'rides'] = this.rides;
    } else {
      json[r'rides'] = null;
    }
    if (this.distanceM != null) {
      json[r'distanceM'] = this.distanceM;
    } else {
      json[r'distanceM'] = null;
    }
    if (this.tss7 != null) {
      json[r'tss7'] = this.tss7;
    } else {
      json[r'tss7'] = null;
    }
    if (this.tss42 != null) {
      json[r'tss42'] = this.tss42;
    } else {
      json[r'tss42'] = null;
    }
    return json;
  }

  /// Clones this instance of [CoachAthleteResponse] and returns a new one where some of the
  /// properties have changed.
  CoachAthleteResponse copyWith({
    String? userId,
    String? displayName,
    bool? sharesRides,
    bool? sharesAnalytics,
    bool? sharesRoutes,
    DateTime? lastRideAt,
    bool lastRideAtSetToNull = false,
    int? rides,
    bool ridesSetToNull = false,
    double? distanceM,
    bool distanceMSetToNull = false,
    double? tss7,
    bool tss7SetToNull = false,
    double? tss42,
    bool tss42SetToNull = false,
  }) => CoachAthleteResponse(
    userId: userId ?? this.userId,
    displayName: displayName ?? this.displayName,
    sharesRides: sharesRides ?? this.sharesRides,
    sharesAnalytics: sharesAnalytics ?? this.sharesAnalytics,
    sharesRoutes: sharesRoutes ?? this.sharesRoutes,
    lastRideAt: lastRideAtSetToNull ? null : lastRideAt ?? this.lastRideAt,
    rides: ridesSetToNull ? null : rides ?? this.rides,
    distanceM: distanceMSetToNull ? null : distanceM ?? this.distanceM,
    tss7: tss7SetToNull ? null : tss7 ?? this.tss7,
    tss42: tss42SetToNull ? null : tss42 ?? this.tss42,
  );

  /// Returns a new [CoachAthleteResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CoachAthleteResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'userId'), 'Required key "CoachAthleteResponse[userId]" is missing from JSON.');
        assert(json[r'userId'] != null, 'Required key "CoachAthleteResponse[userId]" has a null value in JSON.');
        assert(json.containsKey(r'displayName'), 'Required key "CoachAthleteResponse[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null, 'Required key "CoachAthleteResponse[displayName]" has a null value in JSON.');
        assert(json.containsKey(r'sharesRides'), 'Required key "CoachAthleteResponse[sharesRides]" is missing from JSON.');
        assert(json[r'sharesRides'] != null, 'Required key "CoachAthleteResponse[sharesRides]" has a null value in JSON.');
        assert(json.containsKey(r'sharesAnalytics'), 'Required key "CoachAthleteResponse[sharesAnalytics]" is missing from JSON.');
        assert(json[r'sharesAnalytics'] != null, 'Required key "CoachAthleteResponse[sharesAnalytics]" has a null value in JSON.');
        assert(json.containsKey(r'sharesRoutes'), 'Required key "CoachAthleteResponse[sharesRoutes]" is missing from JSON.');
        assert(json[r'sharesRoutes'] != null, 'Required key "CoachAthleteResponse[sharesRoutes]" has a null value in JSON.');
        assert(json.containsKey(r'lastRideAt'), 'Required key "CoachAthleteResponse[lastRideAt]" is missing from JSON.');
        assert(json.containsKey(r'rides'), 'Required key "CoachAthleteResponse[rides]" is missing from JSON.');
        assert(json.containsKey(r'distanceM'), 'Required key "CoachAthleteResponse[distanceM]" is missing from JSON.');
        assert(json.containsKey(r'tss7'), 'Required key "CoachAthleteResponse[tss7]" is missing from JSON.');
        assert(json.containsKey(r'tss42'), 'Required key "CoachAthleteResponse[tss42]" is missing from JSON.');
        return true;
      }());

      return CoachAthleteResponse(
        userId: mapValueOfType<String>(json, r'userId')!,
        displayName: mapValueOfType<String>(json, r'displayName')!,
        sharesRides: mapValueOfType<bool>(json, r'sharesRides')!,
        sharesAnalytics: mapValueOfType<bool>(json, r'sharesAnalytics')!,
        sharesRoutes: mapValueOfType<bool>(json, r'sharesRoutes')!,
        lastRideAt: mapDateTime(json, r'lastRideAt', r''),
        rides: mapValueOfType<int>(json, r'rides'),
        distanceM: mapValueOfType<double>(json, r'distanceM'),
        tss7: mapValueOfType<double>(json, r'tss7'),
        tss42: mapValueOfType<double>(json, r'tss42'),
      );
    }
    return null;
  }

  static List<CoachAthleteResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CoachAthleteResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CoachAthleteResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CoachAthleteResponse> mapFromJson(dynamic json) {
    final map = <String, CoachAthleteResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CoachAthleteResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CoachAthleteResponse-objects as value to a dart map
  static Map<String, List<CoachAthleteResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CoachAthleteResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CoachAthleteResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'userId',
    'displayName',
    'sharesRides',
    'sharesAnalytics',
    'sharesRoutes',
    'lastRideAt',
    'rides',
    'distanceM',
    'tss7',
    'tss42',
  };
}

