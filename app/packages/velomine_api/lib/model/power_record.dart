//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class PowerRecord {
  /// Returns a new [PowerRecord] instance.
  PowerRecord({
    required this.durationS,
    required this.watts,
    required this.kind,
  });

  final int durationS;

  final int watts;

  final String kind;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PowerRecord &&
    other.durationS == durationS &&
    other.watts == watts &&
    other.kind == kind;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (durationS.hashCode) +
    (watts.hashCode) +
    (kind.hashCode);

  @override
  String toString() => 'PowerRecord[durationS=$durationS, watts=$watts, kind=$kind]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'durationS'] = this.durationS;
      json[r'watts'] = this.watts;
      json[r'kind'] = this.kind;
    return json;
  }

  /// Clones this instance of [PowerRecord] and returns a new one where some of the
  /// properties have changed.
  PowerRecord copyWith({
    int? durationS,
    int? watts,
    String? kind,
  }) => PowerRecord(
    durationS: durationS ?? this.durationS,
    watts: watts ?? this.watts,
    kind: kind ?? this.kind,
  );

  /// Returns a new [PowerRecord] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PowerRecord? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'durationS'), 'Required key "PowerRecord[durationS]" is missing from JSON.');
        assert(json[r'durationS'] != null, 'Required key "PowerRecord[durationS]" has a null value in JSON.');
        assert(json.containsKey(r'watts'), 'Required key "PowerRecord[watts]" is missing from JSON.');
        assert(json[r'watts'] != null, 'Required key "PowerRecord[watts]" has a null value in JSON.');
        assert(json.containsKey(r'kind'), 'Required key "PowerRecord[kind]" is missing from JSON.');
        assert(json[r'kind'] != null, 'Required key "PowerRecord[kind]" has a null value in JSON.');
        return true;
      }());

      return PowerRecord(
        durationS: mapValueOfType<int>(json, r'durationS')!,
        watts: mapValueOfType<int>(json, r'watts')!,
        kind: mapValueOfType<String>(json, r'kind')!,
      );
    }
    return null;
  }

  static List<PowerRecord> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PowerRecord>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PowerRecord.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PowerRecord> mapFromJson(dynamic json) {
    final map = <String, PowerRecord>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PowerRecord.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PowerRecord-objects as value to a dart map
  static Map<String, List<PowerRecord>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PowerRecord>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PowerRecord.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'durationS',
    'watts',
    'kind',
  };
}

