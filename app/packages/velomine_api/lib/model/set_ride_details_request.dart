//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SetRideDetailsRequest {
  /// Returns a new [SetRideDetailsRequest] instance.
  SetRideDetailsRequest({
    this.title = const Optional.absent(),
    this.description = const Optional.absent(),
    this.version = const Optional.absent(),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> title;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> description;

  /// Minimum value: 0
  /// Maximum value: 4294967295
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> version;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SetRideDetailsRequest &&
    other.title == title &&
    other.description == description &&
    other.version == version;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (title == null ? 0 : title!.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (version == null ? 0 : version!.hashCode);

  @override
  String toString() => 'SetRideDetailsRequest[title=$title, description=$description, version=$version]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.title.isPresent) {
      final value = this.title.value;
      json[r'title'] = value;
    }
    if (this.description.isPresent) {
      final value = this.description.value;
      json[r'description'] = value;
    }
    if (this.version.isPresent) {
      final value = this.version.value;
      json[r'version'] = value;
    }
    return json;
  }

  /// Clones this instance of [SetRideDetailsRequest] and returns a new one where some of the
  /// properties have changed.
  SetRideDetailsRequest copyWith({
    Optional<String?>? title,
    Optional<String?>? description,
    Optional<int?>? version,
  }) => SetRideDetailsRequest(
    title: title ?? this.title,
    description: description ?? this.description,
    version: version ?? this.version,
  );

  /// Returns a new [SetRideDetailsRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SetRideDetailsRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return SetRideDetailsRequest(
        title: json.containsKey(r'title') ? Optional.present(mapValueOfType<String>(json, r'title')) : const Optional.absent(),
        description: json.containsKey(r'description') ? Optional.present(mapValueOfType<String>(json, r'description')) : const Optional.absent(),
        version: json.containsKey(r'version') ? Optional.present(mapValueOfType<int>(json, r'version')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<SetRideDetailsRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SetRideDetailsRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SetRideDetailsRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SetRideDetailsRequest> mapFromJson(dynamic json) {
    final map = <String, SetRideDetailsRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SetRideDetailsRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SetRideDetailsRequest-objects as value to a dart map
  static Map<String, List<SetRideDetailsRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SetRideDetailsRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SetRideDetailsRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

