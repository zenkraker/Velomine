//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class TrainingNote {
  /// Returns a new [TrainingNote] instance.
  TrainingNote({
    required this.code,
    required this.english,
    required this.italian,
  });

  final String code;

  final String english;

  final String italian;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TrainingNote &&
    other.code == code &&
    other.english == english &&
    other.italian == italian;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (code.hashCode) +
    (english.hashCode) +
    (italian.hashCode);

  @override
  String toString() => 'TrainingNote[code=$code, english=$english, italian=$italian]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'code'] = this.code;
      json[r'english'] = this.english;
      json[r'italian'] = this.italian;
    return json;
  }

  /// Clones this instance of [TrainingNote] and returns a new one where some of the
  /// properties have changed.
  TrainingNote copyWith({
    String? code,
    String? english,
    String? italian,
  }) => TrainingNote(
    code: code ?? this.code,
    english: english ?? this.english,
    italian: italian ?? this.italian,
  );

  /// Returns a new [TrainingNote] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TrainingNote? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'code'), 'Required key "TrainingNote[code]" is missing from JSON.');
        assert(json[r'code'] != null, 'Required key "TrainingNote[code]" has a null value in JSON.');
        assert(json.containsKey(r'english'), 'Required key "TrainingNote[english]" is missing from JSON.');
        assert(json[r'english'] != null, 'Required key "TrainingNote[english]" has a null value in JSON.');
        assert(json.containsKey(r'italian'), 'Required key "TrainingNote[italian]" is missing from JSON.');
        assert(json[r'italian'] != null, 'Required key "TrainingNote[italian]" has a null value in JSON.');
        return true;
      }());

      return TrainingNote(
        code: mapValueOfType<String>(json, r'code')!,
        english: mapValueOfType<String>(json, r'english')!,
        italian: mapValueOfType<String>(json, r'italian')!,
      );
    }
    return null;
  }

  static List<TrainingNote> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TrainingNote>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TrainingNote.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TrainingNote> mapFromJson(dynamic json) {
    final map = <String, TrainingNote>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TrainingNote.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TrainingNote-objects as value to a dart map
  static Map<String, List<TrainingNote>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TrainingNote>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TrainingNote.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'code',
    'english',
    'italian',
  };
}

