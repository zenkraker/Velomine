//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SetMyLanguageRequest {
  /// Returns a new [SetMyLanguageRequest] instance.
  SetMyLanguageRequest({
    this.language = const Optional.absent(),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> language;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SetMyLanguageRequest &&
    other.language == language;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (language == null ? 0 : language!.hashCode);

  @override
  String toString() => 'SetMyLanguageRequest[language=$language]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.language.isPresent) {
      final value = this.language.value;
      json[r'language'] = value;
    }
    return json;
  }

  /// Clones this instance of [SetMyLanguageRequest] and returns a new one where some of the
  /// properties have changed.
  SetMyLanguageRequest copyWith({
    Optional<String?>? language,
  }) => SetMyLanguageRequest(
    language: language ?? this.language,
  );

  /// Returns a new [SetMyLanguageRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SetMyLanguageRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return SetMyLanguageRequest(
        language: json.containsKey(r'language') ? Optional.present(mapValueOfType<String>(json, r'language')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<SetMyLanguageRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SetMyLanguageRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SetMyLanguageRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SetMyLanguageRequest> mapFromJson(dynamic json) {
    final map = <String, SetMyLanguageRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SetMyLanguageRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SetMyLanguageRequest-objects as value to a dart map
  static Map<String, List<SetMyLanguageRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SetMyLanguageRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SetMyLanguageRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

