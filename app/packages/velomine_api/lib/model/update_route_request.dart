//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class UpdateRouteRequest {
  /// Returns a new [UpdateRouteRequest] instance.
  UpdateRouteRequest({
    required this.name,
    this.description = const Optional.absent(),
    required this.surface,
  });

  final String name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> description;

  final String surface;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UpdateRouteRequest &&
    other.name == name &&
    other.description == description &&
    other.surface == surface;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (surface.hashCode);

  @override
  String toString() => 'UpdateRouteRequest[name=$name, description=$description, surface=$surface]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
    if (this.description.isPresent) {
      final value = this.description.value;
      json[r'description'] = value;
    }
      json[r'surface'] = this.surface;
    return json;
  }

  /// Clones this instance of [UpdateRouteRequest] and returns a new one where some of the
  /// properties have changed.
  UpdateRouteRequest copyWith({
    String? name,
    Optional<String?>? description,
    String? surface,
  }) => UpdateRouteRequest(
    name: name ?? this.name,
    description: description ?? this.description,
    surface: surface ?? this.surface,
  );

  /// Returns a new [UpdateRouteRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateRouteRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "UpdateRouteRequest[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "UpdateRouteRequest[name]" has a null value in JSON.');
        assert(json.containsKey(r'surface'), 'Required key "UpdateRouteRequest[surface]" is missing from JSON.');
        assert(json[r'surface'] != null, 'Required key "UpdateRouteRequest[surface]" has a null value in JSON.');
        return true;
      }());

      return UpdateRouteRequest(
        name: mapValueOfType<String>(json, r'name')!,
        description: json.containsKey(r'description') ? Optional.present(mapValueOfType<String>(json, r'description')) : const Optional.absent(),
        surface: mapValueOfType<String>(json, r'surface')!,
      );
    }
    return null;
  }

  static List<UpdateRouteRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UpdateRouteRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateRouteRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateRouteRequest> mapFromJson(dynamic json) {
    final map = <String, UpdateRouteRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateRouteRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateRouteRequest-objects as value to a dart map
  static Map<String, List<UpdateRouteRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UpdateRouteRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateRouteRequest.listFromJson(entry.value, growable: growable,);
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

