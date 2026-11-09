//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SetClubLocationRequest {
  /// Returns a new [SetClubLocationRequest] instance.
  SetClubLocationRequest({
    this.latitude = const Optional.absent(),
    this.longitude = const Optional.absent(),
    required this.isDiscoverable,
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

  final bool isDiscoverable;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SetClubLocationRequest &&
    other.latitude == latitude &&
    other.longitude == longitude &&
    other.isDiscoverable == isDiscoverable;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (latitude == null ? 0 : latitude!.hashCode) +
    (longitude == null ? 0 : longitude!.hashCode) +
    (isDiscoverable.hashCode);

  @override
  String toString() => 'SetClubLocationRequest[latitude=$latitude, longitude=$longitude, isDiscoverable=$isDiscoverable]';

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
      json[r'isDiscoverable'] = this.isDiscoverable;
    return json;
  }

  /// Clones this instance of [SetClubLocationRequest] and returns a new one where some of the
  /// properties have changed.
  SetClubLocationRequest copyWith({
    Optional<double?>? latitude,
    Optional<double?>? longitude,
    bool? isDiscoverable,
  }) => SetClubLocationRequest(
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    isDiscoverable: isDiscoverable ?? this.isDiscoverable,
  );

  /// Returns a new [SetClubLocationRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SetClubLocationRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'isDiscoverable'), 'Required key "SetClubLocationRequest[isDiscoverable]" is missing from JSON.');
        assert(json[r'isDiscoverable'] != null, 'Required key "SetClubLocationRequest[isDiscoverable]" has a null value in JSON.');
        return true;
      }());

      return SetClubLocationRequest(
        latitude: json.containsKey(r'latitude') ? Optional.present(mapValueOfType<double>(json, r'latitude')) : const Optional.absent(),
        longitude: json.containsKey(r'longitude') ? Optional.present(mapValueOfType<double>(json, r'longitude')) : const Optional.absent(),
        isDiscoverable: mapValueOfType<bool>(json, r'isDiscoverable')!,
      );
    }
    return null;
  }

  static List<SetClubLocationRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SetClubLocationRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SetClubLocationRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SetClubLocationRequest> mapFromJson(dynamic json) {
    final map = <String, SetClubLocationRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SetClubLocationRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SetClubLocationRequest-objects as value to a dart map
  static Map<String, List<SetClubLocationRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SetClubLocationRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SetClubLocationRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'isDiscoverable',
  };
}

