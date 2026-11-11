//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class RouteDraftResponse {
  /// Returns a new [RouteDraftResponse] instance.
  RouteDraftResponse({
    required this.name,
    this.latitude = const [],
    this.longitude = const [],
    this.elevation = const [],
    required this.distanceM,
    required this.climbingM,
  });

  final String? name;

  final List<double> latitude;

  final List<double> longitude;

  final List<double>? elevation;

  final double distanceM;

  final double? climbingM;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RouteDraftResponse &&
    other.name == name &&
    _deepEquality.equals(other.latitude, latitude) &&
    _deepEquality.equals(other.longitude, longitude) &&
    _deepEquality.equals(other.elevation, elevation) &&
    other.distanceM == distanceM &&
    other.climbingM == climbingM;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (latitude.hashCode) +
    (longitude.hashCode) +
    (elevation == null ? 0 : elevation!.hashCode) +
    (distanceM.hashCode) +
    (climbingM == null ? 0 : climbingM!.hashCode);

  @override
  String toString() => 'RouteDraftResponse[name=$name, latitude=$latitude, longitude=$longitude, elevation=$elevation, distanceM=$distanceM, climbingM=$climbingM]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
      json[r'latitude'] = this.latitude;
      json[r'longitude'] = this.longitude;
    if (this.elevation != null) {
      json[r'elevation'] = this.elevation;
    } else {
      json[r'elevation'] = null;
    }
      json[r'distanceM'] = this.distanceM;
    if (this.climbingM != null) {
      json[r'climbingM'] = this.climbingM;
    } else {
      json[r'climbingM'] = null;
    }
    return json;
  }

  /// Clones this instance of [RouteDraftResponse] and returns a new one where some of the
  /// properties have changed.
  RouteDraftResponse copyWith({
    String? name,
    bool nameSetToNull = false,
    List<double>? latitude,
    List<double>? longitude,
    List<double>? elevation,
    bool elevationSetToNull = false,
    double? distanceM,
    double? climbingM,
    bool climbingMSetToNull = false,
  }) => RouteDraftResponse(
    name: nameSetToNull ? null : name ?? this.name,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    elevation: elevationSetToNull ? null : elevation ?? this.elevation,
    distanceM: distanceM ?? this.distanceM,
    climbingM: climbingMSetToNull ? null : climbingM ?? this.climbingM,
  );

  /// Returns a new [RouteDraftResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RouteDraftResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "RouteDraftResponse[name]" is missing from JSON.');
        assert(json.containsKey(r'latitude'), 'Required key "RouteDraftResponse[latitude]" is missing from JSON.');
        assert(json[r'latitude'] != null, 'Required key "RouteDraftResponse[latitude]" has a null value in JSON.');
        assert(json.containsKey(r'longitude'), 'Required key "RouteDraftResponse[longitude]" is missing from JSON.');
        assert(json[r'longitude'] != null, 'Required key "RouteDraftResponse[longitude]" has a null value in JSON.');
        assert(json.containsKey(r'elevation'), 'Required key "RouteDraftResponse[elevation]" is missing from JSON.');
        assert(json.containsKey(r'distanceM'), 'Required key "RouteDraftResponse[distanceM]" is missing from JSON.');
        assert(json[r'distanceM'] != null, 'Required key "RouteDraftResponse[distanceM]" has a null value in JSON.');
        assert(json.containsKey(r'climbingM'), 'Required key "RouteDraftResponse[climbingM]" is missing from JSON.');
        return true;
      }());

      return RouteDraftResponse(
        name: mapValueOfType<String>(json, r'name'),
        latitude: json[r'latitude'] is Iterable
            ? (json[r'latitude'] as Iterable).map((e) => (e as num).toDouble()).toList(growable: false)
            : const [],
        longitude: json[r'longitude'] is Iterable
            ? (json[r'longitude'] as Iterable).map((e) => (e as num).toDouble()).toList(growable: false)
            : const [],
        elevation: json[r'elevation'] is Iterable
            ? (json[r'elevation'] as Iterable).map((e) => (e as num).toDouble()).toList(growable: false)
            : const [],
        distanceM: mapValueOfType<double>(json, r'distanceM')!,
        climbingM: mapValueOfType<double>(json, r'climbingM'),
      );
    }
    return null;
  }

  static List<RouteDraftResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RouteDraftResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RouteDraftResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RouteDraftResponse> mapFromJson(dynamic json) {
    final map = <String, RouteDraftResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RouteDraftResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RouteDraftResponse-objects as value to a dart map
  static Map<String, List<RouteDraftResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RouteDraftResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RouteDraftResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'latitude',
    'longitude',
    'elevation',
    'distanceM',
    'climbingM',
  };
}

