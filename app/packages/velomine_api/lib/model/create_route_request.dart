//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class CreateRouteRequest {
  /// Returns a new [CreateRouteRequest] instance.
  CreateRouteRequest({
    this.rideId = const Optional.absent(),
    required this.name,
    this.description = const Optional.absent(),
    required this.surface,
    this.latitude = const Optional.present(const []),
    this.longitude = const Optional.present(const []),
    this.elevation = const Optional.present(const []),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> rideId;

  final String name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> description;

  final String surface;

  final Optional<List<double>?> latitude;

  final Optional<List<double>?> longitude;

  final Optional<List<double>?> elevation;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreateRouteRequest &&
    other.rideId == rideId &&
    other.name == name &&
    other.description == description &&
    other.surface == surface &&
    _deepEquality.equals(other.latitude, latitude) &&
    _deepEquality.equals(other.longitude, longitude) &&
    _deepEquality.equals(other.elevation, elevation);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (rideId == null ? 0 : rideId!.hashCode) +
    (name.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (surface.hashCode) +
    (latitude.hashCode) +
    (longitude.hashCode) +
    (elevation.hashCode);

  @override
  String toString() => 'CreateRouteRequest[rideId=$rideId, name=$name, description=$description, surface=$surface, latitude=$latitude, longitude=$longitude, elevation=$elevation]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.rideId.isPresent) {
      final value = this.rideId.value;
      json[r'rideId'] = value;
    }
      json[r'name'] = this.name;
    if (this.description.isPresent) {
      final value = this.description.value;
      json[r'description'] = value;
    }
      json[r'surface'] = this.surface;
    if (this.latitude.isPresent) {
      final value = this.latitude.value;
      json[r'latitude'] = value;
    }
    if (this.longitude.isPresent) {
      final value = this.longitude.value;
      json[r'longitude'] = value;
    }
    if (this.elevation.isPresent) {
      final value = this.elevation.value;
      json[r'elevation'] = value;
    }
    return json;
  }

  /// Clones this instance of [CreateRouteRequest] and returns a new one where some of the
  /// properties have changed.
  CreateRouteRequest copyWith({
    Optional<String?>? rideId,
    String? name,
    Optional<String?>? description,
    String? surface,
    Optional<List<double>?>? latitude,
    Optional<List<double>?>? longitude,
    Optional<List<double>?>? elevation,
  }) => CreateRouteRequest(
    rideId: rideId ?? this.rideId,
    name: name ?? this.name,
    description: description ?? this.description,
    surface: surface ?? this.surface,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    elevation: elevation ?? this.elevation,
  );

  /// Returns a new [CreateRouteRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateRouteRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "CreateRouteRequest[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "CreateRouteRequest[name]" has a null value in JSON.');
        assert(json.containsKey(r'surface'), 'Required key "CreateRouteRequest[surface]" is missing from JSON.');
        assert(json[r'surface'] != null, 'Required key "CreateRouteRequest[surface]" has a null value in JSON.');
        return true;
      }());

      return CreateRouteRequest(
        rideId: json.containsKey(r'rideId') ? Optional.present(mapValueOfType<String>(json, r'rideId')) : const Optional.absent(),
        name: mapValueOfType<String>(json, r'name')!,
        description: json.containsKey(r'description') ? Optional.present(mapValueOfType<String>(json, r'description')) : const Optional.absent(),
        surface: mapValueOfType<String>(json, r'surface')!,
        latitude: json.containsKey(r'latitude') ? Optional.present(json[r'latitude'] is Iterable
            ? (json[r'latitude'] as Iterable).cast<double>().toList(growable: false)
            : const []) : const Optional.absent(),
        longitude: json.containsKey(r'longitude') ? Optional.present(json[r'longitude'] is Iterable
            ? (json[r'longitude'] as Iterable).cast<double>().toList(growable: false)
            : const []) : const Optional.absent(),
        elevation: json.containsKey(r'elevation') ? Optional.present(json[r'elevation'] is Iterable
            ? (json[r'elevation'] as Iterable).cast<double>().toList(growable: false)
            : const []) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<CreateRouteRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateRouteRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateRouteRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateRouteRequest> mapFromJson(dynamic json) {
    final map = <String, CreateRouteRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateRouteRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateRouteRequest-objects as value to a dart map
  static Map<String, List<CreateRouteRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreateRouteRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateRouteRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'surface',
  };
}

