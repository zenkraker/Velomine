//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ProblemDetailsErrorsInner {
  /// Returns a new [ProblemDetailsErrorsInner] instance.
  ProblemDetailsErrorsInner({
    this.name = const Optional.present('Error or field name'),
    this.reason = const Optional.present('Error reason'),
    this.code = const Optional.absent(),
    this.severity = const Optional.absent(),
  });

  /// the name of the error or property of the dto that caused the error
  final Optional<String?> name;

  /// the reason for the error
  final Optional<String?> reason;

  /// the code of the error
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> code;

  /// the severity of the error
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> severity;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ProblemDetailsErrorsInner &&
    other.name == name &&
    other.reason == reason &&
    other.code == code &&
    other.severity == severity;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (reason.hashCode) +
    (code == null ? 0 : code!.hashCode) +
    (severity == null ? 0 : severity!.hashCode);

  @override
  String toString() => 'ProblemDetailsErrorsInner[name=$name, reason=$reason, code=$code, severity=$severity]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name.isPresent) {
      final value = this.name.value;
      json[r'name'] = value;
    }
    if (this.reason.isPresent) {
      final value = this.reason.value;
      json[r'reason'] = value;
    }
    if (this.code.isPresent) {
      final value = this.code.value;
      json[r'code'] = value;
    }
    if (this.severity.isPresent) {
      final value = this.severity.value;
      json[r'severity'] = value;
    }
    return json;
  }

  /// Clones this instance of [ProblemDetailsErrorsInner] and returns a new one where some of the
  /// properties have changed.
  ProblemDetailsErrorsInner copyWith({
    Optional<String?>? name,
    Optional<String?>? reason,
    Optional<String?>? code,
    Optional<String?>? severity,
  }) => ProblemDetailsErrorsInner(
    name: name ?? this.name,
    reason: reason ?? this.reason,
    code: code ?? this.code,
    severity: severity ?? this.severity,
  );

  /// Returns a new [ProblemDetailsErrorsInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProblemDetailsErrorsInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return ProblemDetailsErrorsInner(
        name: json.containsKey(r'name') ? Optional.present(mapValueOfType<String>(json, r'name')) : const Optional.absent(),
        reason: json.containsKey(r'reason') ? Optional.present(mapValueOfType<String>(json, r'reason')) : const Optional.absent(),
        code: json.containsKey(r'code') ? Optional.present(mapValueOfType<String>(json, r'code')) : const Optional.absent(),
        severity: json.containsKey(r'severity') ? Optional.present(mapValueOfType<String>(json, r'severity')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<ProblemDetailsErrorsInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ProblemDetailsErrorsInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProblemDetailsErrorsInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProblemDetailsErrorsInner> mapFromJson(dynamic json) {
    final map = <String, ProblemDetailsErrorsInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProblemDetailsErrorsInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProblemDetailsErrorsInner-objects as value to a dart map
  static Map<String, List<ProblemDetailsErrorsInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ProblemDetailsErrorsInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProblemDetailsErrorsInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

