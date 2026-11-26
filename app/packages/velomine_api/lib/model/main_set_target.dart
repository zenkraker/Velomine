//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class MainSetTarget {
  /// Returns a new [MainSetTarget] instance.
  MainSetTarget({
    required this.signal,
    required this.target,
    required this.average,
  });

  final String signal;

  final int target;

  final int? average;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MainSetTarget &&
    other.signal == signal &&
    other.target == target &&
    other.average == average;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (signal.hashCode) +
    (target.hashCode) +
    (average == null ? 0 : average!.hashCode);

  @override
  String toString() => 'MainSetTarget[signal=$signal, target=$target, average=$average]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'signal'] = this.signal;
      json[r'target'] = this.target;
    if (this.average != null) {
      json[r'average'] = this.average;
    } else {
      json[r'average'] = null;
    }
    return json;
  }

  /// Clones this instance of [MainSetTarget] and returns a new one where some of the
  /// properties have changed.
  MainSetTarget copyWith({
    String? signal,
    int? target,
    int? average,
    bool averageSetToNull = false,
  }) => MainSetTarget(
    signal: signal ?? this.signal,
    target: target ?? this.target,
    average: averageSetToNull ? null : average ?? this.average,
  );

  /// Returns a new [MainSetTarget] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MainSetTarget? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'signal'), 'Required key "MainSetTarget[signal]" is missing from JSON.');
        assert(json[r'signal'] != null, 'Required key "MainSetTarget[signal]" has a null value in JSON.');
        assert(json.containsKey(r'target'), 'Required key "MainSetTarget[target]" is missing from JSON.');
        assert(json[r'target'] != null, 'Required key "MainSetTarget[target]" has a null value in JSON.');
        assert(json.containsKey(r'average'), 'Required key "MainSetTarget[average]" is missing from JSON.');
        return true;
      }());

      return MainSetTarget(
        signal: mapValueOfType<String>(json, r'signal')!,
        target: mapValueOfType<int>(json, r'target')!,
        average: mapValueOfType<int>(json, r'average'),
      );
    }
    return null;
  }

  static List<MainSetTarget> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MainSetTarget>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MainSetTarget.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MainSetTarget> mapFromJson(dynamic json) {
    final map = <String, MainSetTarget>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MainSetTarget.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MainSetTarget-objects as value to a dart map
  static Map<String, List<MainSetTarget>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MainSetTarget>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MainSetTarget.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'signal',
    'target',
    'average',
  };
}

