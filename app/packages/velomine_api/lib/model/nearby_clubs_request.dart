//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class NearbyClubsRequest {
  /// Returns a new [NearbyClubsRequest] instance.
  NearbyClubsRequest({
    this.latitude = const Optional.absent(),
    this.longitude = const Optional.absent(),
    this.radiusKm = const Optional.absent(),
  });

  /// Minimum value: -90
  /// Maximum value: 90
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<double?> latitude;

  /// Minimum value: -180
  /// Maximum value: 180
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<double?> longitude;

  /// Minimum value: 1
  /// Maximum value: 200
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> radiusKm;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NearbyClubsRequest &&
    other.latitude == latitude &&
    other.longitude == longitude &&
    other.radiusKm == radiusKm;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (latitude == null ? 0 : latitude!.hashCode) +
    (longitude == null ? 0 : longitude!.hashCode) +
    (radiusKm == null ? 0 : radiusKm!.hashCode);

  @override
  String toString() => 'NearbyClubsRequest[latitude=$latitude, longitude=$longitude, radiusKm=$radiusKm]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.latitude.isPresent) {
      final value = this.latitude.value;
      json[r'latitude'] = value;
    }
    if (this.longitude.isPresent) {
      final value = this.longitude.value;
      json[r'longitude'] = value;
    }
    if (this.radiusKm.isPresent) {
      final value = this.radiusKm.value;
      json[r'radiusKm'] = value;
    }
    return json;
  }

  /// Clones this instance of [NearbyClubsRequest] and returns a new one where some of the
  /// properties have changed.
  NearbyClubsRequest copyWith({
    Optional<double?>? latitude,
    Optional<double?>? longitude,
    Optional<int?>? radiusKm,
  }) => NearbyClubsRequest(
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radiusKm: radiusKm ?? this.radiusKm,
  );

  /// Returns a new [NearbyClubsRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NearbyClubsRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return NearbyClubsRequest(
        latitude: json.containsKey(r'latitude') ? Optional.present(mapValueOfType<double>(json, r'latitude')) : const Optional.absent(),
        longitude: json.containsKey(r'longitude') ? Optional.present(mapValueOfType<double>(json, r'longitude')) : const Optional.absent(),
        radiusKm: json.containsKey(r'radiusKm') ? Optional.present(json[r'radiusKm'] == null ? null : int.parse('${json[r'radiusKm']}')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<NearbyClubsRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NearbyClubsRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NearbyClubsRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NearbyClubsRequest> mapFromJson(dynamic json) {
    final map = <String, NearbyClubsRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NearbyClubsRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NearbyClubsRequest-objects as value to a dart map
  static Map<String, List<NearbyClubsRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NearbyClubsRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NearbyClubsRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

