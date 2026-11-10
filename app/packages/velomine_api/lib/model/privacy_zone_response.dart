//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class PrivacyZoneResponse {
  /// Returns a new [PrivacyZoneResponse] instance.
  PrivacyZoneResponse({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusM,
  });

  final String id;

  final String name;

  final double latitude;

  final double longitude;

  final int radiusM;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PrivacyZoneResponse &&
    other.id == id &&
    other.name == name &&
    other.latitude == latitude &&
    other.longitude == longitude &&
    other.radiusM == radiusM;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (latitude.hashCode) +
    (longitude.hashCode) +
    (radiusM.hashCode);

  @override
  String toString() => 'PrivacyZoneResponse[id=$id, name=$name, latitude=$latitude, longitude=$longitude, radiusM=$radiusM]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'latitude'] = this.latitude;
      json[r'longitude'] = this.longitude;
      json[r'radiusM'] = this.radiusM;
    return json;
  }

  /// Clones this instance of [PrivacyZoneResponse] and returns a new one where some of the
  /// properties have changed.
  PrivacyZoneResponse copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    int? radiusM,
  }) => PrivacyZoneResponse(
    id: id ?? this.id,
    name: name ?? this.name,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radiusM: radiusM ?? this.radiusM,
  );

  /// Returns a new [PrivacyZoneResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PrivacyZoneResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "PrivacyZoneResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "PrivacyZoneResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "PrivacyZoneResponse[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "PrivacyZoneResponse[name]" has a null value in JSON.');
        assert(json.containsKey(r'latitude'), 'Required key "PrivacyZoneResponse[latitude]" is missing from JSON.');
        assert(json[r'latitude'] != null, 'Required key "PrivacyZoneResponse[latitude]" has a null value in JSON.');
        assert(json.containsKey(r'longitude'), 'Required key "PrivacyZoneResponse[longitude]" is missing from JSON.');
        assert(json[r'longitude'] != null, 'Required key "PrivacyZoneResponse[longitude]" has a null value in JSON.');
        assert(json.containsKey(r'radiusM'), 'Required key "PrivacyZoneResponse[radiusM]" is missing from JSON.');
        assert(json[r'radiusM'] != null, 'Required key "PrivacyZoneResponse[radiusM]" has a null value in JSON.');
        return true;
      }());

      return PrivacyZoneResponse(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        latitude: mapValueOfType<double>(json, r'latitude')!,
        longitude: mapValueOfType<double>(json, r'longitude')!,
        radiusM: mapValueOfType<int>(json, r'radiusM')!,
      );
    }
    return null;
  }

  static List<PrivacyZoneResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PrivacyZoneResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PrivacyZoneResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PrivacyZoneResponse> mapFromJson(dynamic json) {
    final map = <String, PrivacyZoneResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PrivacyZoneResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PrivacyZoneResponse-objects as value to a dart map
  static Map<String, List<PrivacyZoneResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PrivacyZoneResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PrivacyZoneResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'latitude',
    'longitude',
    'radiusM',
  };
}

