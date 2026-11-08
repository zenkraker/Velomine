//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ReadinessFactor {
  /// Returns a new [ReadinessFactor] instance.
  ReadinessFactor({
    required this.key,
    required this.value,
    required this.effect,
  });

  final String key;

  final double value;

  final double effect;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ReadinessFactor &&
    other.key == key &&
    other.value == value &&
    other.effect == effect;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (key.hashCode) +
    (value.hashCode) +
    (effect.hashCode);

  @override
  String toString() => 'ReadinessFactor[key=$key, value=$value, effect=$effect]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'key'] = this.key;
      json[r'value'] = this.value;
      json[r'effect'] = this.effect;
    return json;
  }

  /// Clones this instance of [ReadinessFactor] and returns a new one where some of the
  /// properties have changed.
  ReadinessFactor copyWith({
    String? key,
    double? value,
    double? effect,
  }) => ReadinessFactor(
    key: key ?? this.key,
    value: value ?? this.value,
    effect: effect ?? this.effect,
  );

  /// Returns a new [ReadinessFactor] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ReadinessFactor? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'key'), 'Required key "ReadinessFactor[key]" is missing from JSON.');
        assert(json[r'key'] != null, 'Required key "ReadinessFactor[key]" has a null value in JSON.');
        assert(json.containsKey(r'value'), 'Required key "ReadinessFactor[value]" is missing from JSON.');
        assert(json[r'value'] != null, 'Required key "ReadinessFactor[value]" has a null value in JSON.');
        assert(json.containsKey(r'effect'), 'Required key "ReadinessFactor[effect]" is missing from JSON.');
        assert(json[r'effect'] != null, 'Required key "ReadinessFactor[effect]" has a null value in JSON.');
        return true;
      }());

      return ReadinessFactor(
        key: mapValueOfType<String>(json, r'key')!,
        value: mapValueOfType<double>(json, r'value')!,
        effect: mapValueOfType<double>(json, r'effect')!,
      );
    }
    return null;
  }

  static List<ReadinessFactor> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ReadinessFactor>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ReadinessFactor.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ReadinessFactor> mapFromJson(dynamic json) {
    final map = <String, ReadinessFactor>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ReadinessFactor.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ReadinessFactor-objects as value to a dart map
  static Map<String, List<ReadinessFactor>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ReadinessFactor>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ReadinessFactor.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'key',
    'value',
    'effect',
  };
}

