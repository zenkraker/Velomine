//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class PowerCurvePoint {
  /// Returns a new [PowerCurvePoint] instance.
  PowerCurvePoint({
    required this.seconds,
    required this.watts,
  });

  final int seconds;

  final int watts;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PowerCurvePoint &&
    other.seconds == seconds &&
    other.watts == watts;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (seconds.hashCode) +
    (watts.hashCode);

  @override
  String toString() => 'PowerCurvePoint[seconds=$seconds, watts=$watts]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'seconds'] = this.seconds;
      json[r'watts'] = this.watts;
    return json;
  }

  /// Clones this instance of [PowerCurvePoint] and returns a new one where some of the
  /// properties have changed.
  PowerCurvePoint copyWith({
    int? seconds,
    int? watts,
  }) => PowerCurvePoint(
    seconds: seconds ?? this.seconds,
    watts: watts ?? this.watts,
  );

  /// Returns a new [PowerCurvePoint] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PowerCurvePoint? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'seconds'), 'Required key "PowerCurvePoint[seconds]" is missing from JSON.');
        assert(json[r'seconds'] != null, 'Required key "PowerCurvePoint[seconds]" has a null value in JSON.');
        assert(json.containsKey(r'watts'), 'Required key "PowerCurvePoint[watts]" is missing from JSON.');
        assert(json[r'watts'] != null, 'Required key "PowerCurvePoint[watts]" has a null value in JSON.');
        return true;
      }());

      return PowerCurvePoint(
        seconds: mapValueOfType<int>(json, r'seconds')!,
        watts: mapValueOfType<int>(json, r'watts')!,
      );
    }
    return null;
  }

  static List<PowerCurvePoint> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PowerCurvePoint>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PowerCurvePoint.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PowerCurvePoint> mapFromJson(dynamic json) {
    final map = <String, PowerCurvePoint>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PowerCurvePoint.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PowerCurvePoint-objects as value to a dart map
  static Map<String, List<PowerCurvePoint>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PowerCurvePoint>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PowerCurvePoint.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'seconds',
    'watts',
  };
}

