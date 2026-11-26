//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SkipTrainingSessionRequest {
  /// Returns a new [SkipTrainingSessionRequest] instance.
  SkipTrainingSessionRequest({
    this.reason = const Optional.absent(),
    this.restOfWeek = const Optional.absent(),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> reason;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> restOfWeek;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SkipTrainingSessionRequest &&
    other.reason == reason &&
    other.restOfWeek == restOfWeek;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (reason == null ? 0 : reason!.hashCode) +
    (restOfWeek == null ? 0 : restOfWeek!.hashCode);

  @override
  String toString() => 'SkipTrainingSessionRequest[reason=$reason, restOfWeek=$restOfWeek]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.reason.isPresent) {
      final value = this.reason.value;
      json[r'reason'] = value;
    }
    if (this.restOfWeek.isPresent) {
      final value = this.restOfWeek.value;
      json[r'restOfWeek'] = value;
    }
    return json;
  }

  /// Clones this instance of [SkipTrainingSessionRequest] and returns a new one where some of the
  /// properties have changed.
  SkipTrainingSessionRequest copyWith({
    Optional<String?>? reason,
    Optional<bool?>? restOfWeek,
  }) => SkipTrainingSessionRequest(
    reason: reason ?? this.reason,
    restOfWeek: restOfWeek ?? this.restOfWeek,
  );

  /// Returns a new [SkipTrainingSessionRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SkipTrainingSessionRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return SkipTrainingSessionRequest(
        reason: json.containsKey(r'reason') ? Optional.present(mapValueOfType<String>(json, r'reason')) : const Optional.absent(),
        restOfWeek: json.containsKey(r'restOfWeek') ? Optional.present(mapValueOfType<bool>(json, r'restOfWeek')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<SkipTrainingSessionRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SkipTrainingSessionRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SkipTrainingSessionRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SkipTrainingSessionRequest> mapFromJson(dynamic json) {
    final map = <String, SkipTrainingSessionRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SkipTrainingSessionRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SkipTrainingSessionRequest-objects as value to a dart map
  static Map<String, List<SkipTrainingSessionRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SkipTrainingSessionRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SkipTrainingSessionRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

