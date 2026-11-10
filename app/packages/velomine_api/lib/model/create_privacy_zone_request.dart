//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class CreatePrivacyZoneRequest {
  /// Returns a new [CreatePrivacyZoneRequest] instance.
  CreatePrivacyZoneRequest({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusM,
  });

  final String name;

  /// Minimum value: -90
  /// Maximum value: 90
  final double latitude;

  /// Minimum value: -180
  /// Maximum value: 180
  final double longitude;

  /// Minimum value: 200
  /// Maximum value: 1609
  final int radiusM;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreatePrivacyZoneRequest &&
    other.name == name &&
    other.latitude == latitude &&
    other.longitude == longitude &&
    other.radiusM == radiusM;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (latitude.hashCode) +
    (longitude.hashCode) +
    (radiusM.hashCode);

  @override
  String toString() => 'CreatePrivacyZoneRequest[name=$name, latitude=$latitude, longitude=$longitude, radiusM=$radiusM]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'latitude'] = this.latitude;
      json[r'longitude'] = this.longitude;
      json[r'radiusM'] = this.radiusM;
    return json;
  }

  /// Clones this instance of [CreatePrivacyZoneRequest] and returns a new one where some of the
  /// properties have changed.
  CreatePrivacyZoneRequest copyWith({
    String? name,
    double? latitude,
    double? longitude,
    int? radiusM,
  }) => CreatePrivacyZoneRequest(
    name: name ?? this.name,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radiusM: radiusM ?? this.radiusM,
  );

  /// Returns a new [CreatePrivacyZoneRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreatePrivacyZoneRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "CreatePrivacyZoneRequest[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "CreatePrivacyZoneRequest[name]" has a null value in JSON.');
        assert(json.containsKey(r'latitude'), 'Required key "CreatePrivacyZoneRequest[latitude]" is missing from JSON.');
        assert(json[r'latitude'] != null, 'Required key "CreatePrivacyZoneRequest[latitude]" has a null value in JSON.');
        assert(json.containsKey(r'longitude'), 'Required key "CreatePrivacyZoneRequest[longitude]" is missing from JSON.');
        assert(json[r'longitude'] != null, 'Required key "CreatePrivacyZoneRequest[longitude]" has a null value in JSON.');
        assert(json.containsKey(r'radiusM'), 'Required key "CreatePrivacyZoneRequest[radiusM]" is missing from JSON.');
        assert(json[r'radiusM'] != null, 'Required key "CreatePrivacyZoneRequest[radiusM]" has a null value in JSON.');
        return true;
      }());

      return CreatePrivacyZoneRequest(
        name: mapValueOfType<String>(json, r'name')!,
        latitude: mapValueOfType<double>(json, r'latitude')!,
        longitude: mapValueOfType<double>(json, r'longitude')!,
        radiusM: mapValueOfType<int>(json, r'radiusM')!,
      );
    }
    return null;
  }

  static List<CreatePrivacyZoneRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreatePrivacyZoneRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreatePrivacyZoneRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreatePrivacyZoneRequest> mapFromJson(dynamic json) {
    final map = <String, CreatePrivacyZoneRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreatePrivacyZoneRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreatePrivacyZoneRequest-objects as value to a dart map
  static Map<String, List<CreatePrivacyZoneRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreatePrivacyZoneRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreatePrivacyZoneRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'latitude',
    'longitude',
    'radiusM',
  };
}

