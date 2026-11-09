//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SetRideTypeRequest {
  /// Returns a new [SetRideTypeRequest] instance.
  SetRideTypeRequest({
    this.discipline = const Optional.absent(),
    this.assist = const Optional.absent(),
    this.environment = const Optional.absent(),
    this.commute = const Optional.absent(),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> discipline;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> assist;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> environment;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> commute;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SetRideTypeRequest &&
    other.discipline == discipline &&
    other.assist == assist &&
    other.environment == environment &&
    other.commute == commute;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (discipline == null ? 0 : discipline!.hashCode) +
    (assist == null ? 0 : assist!.hashCode) +
    (environment == null ? 0 : environment!.hashCode) +
    (commute == null ? 0 : commute!.hashCode);

  @override
  String toString() => 'SetRideTypeRequest[discipline=$discipline, assist=$assist, environment=$environment, commute=$commute]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.discipline.isPresent) {
      final value = this.discipline.value;
      json[r'discipline'] = value;
    }
    if (this.assist.isPresent) {
      final value = this.assist.value;
      json[r'assist'] = value;
    }
    if (this.environment.isPresent) {
      final value = this.environment.value;
      json[r'environment'] = value;
    }
    if (this.commute.isPresent) {
      final value = this.commute.value;
      json[r'commute'] = value;
    }
    return json;
  }

  /// Clones this instance of [SetRideTypeRequest] and returns a new one where some of the
  /// properties have changed.
  SetRideTypeRequest copyWith({
    Optional<String?>? discipline,
    Optional<String?>? assist,
    Optional<String?>? environment,
    Optional<bool?>? commute,
  }) => SetRideTypeRequest(
    discipline: discipline ?? this.discipline,
    assist: assist ?? this.assist,
    environment: environment ?? this.environment,
    commute: commute ?? this.commute,
  );

  /// Returns a new [SetRideTypeRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SetRideTypeRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return SetRideTypeRequest(
        discipline: json.containsKey(r'discipline') ? Optional.present(mapValueOfType<String>(json, r'discipline')) : const Optional.absent(),
        assist: json.containsKey(r'assist') ? Optional.present(mapValueOfType<String>(json, r'assist')) : const Optional.absent(),
        environment: json.containsKey(r'environment') ? Optional.present(mapValueOfType<String>(json, r'environment')) : const Optional.absent(),
        commute: json.containsKey(r'commute') ? Optional.present(mapValueOfType<bool>(json, r'commute')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<SetRideTypeRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SetRideTypeRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SetRideTypeRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SetRideTypeRequest> mapFromJson(dynamic json) {
    final map = <String, SetRideTypeRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SetRideTypeRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SetRideTypeRequest-objects as value to a dart map
  static Map<String, List<SetRideTypeRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SetRideTypeRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SetRideTypeRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

