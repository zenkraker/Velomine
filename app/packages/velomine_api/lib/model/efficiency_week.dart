//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class EfficiencyWeek {
  /// Returns a new [EfficiencyWeek] instance.
  EfficiencyWeek({
    required this.weekStart,
    required this.efficiencyFactor,
    required this.rides,
  });

  final DateTime weekStart;

  final double efficiencyFactor;

  final int rides;

  @override
  bool operator ==(Object other) => identical(this, other) || other is EfficiencyWeek &&
    other.weekStart == weekStart &&
    other.efficiencyFactor == efficiencyFactor &&
    other.rides == rides;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (weekStart.hashCode) +
    (efficiencyFactor.hashCode) +
    (rides.hashCode);

  @override
  String toString() => 'EfficiencyWeek[weekStart=$weekStart, efficiencyFactor=$efficiencyFactor, rides=$rides]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'weekStart'] = _dateFormatter.format(this.weekStart);
      json[r'efficiencyFactor'] = this.efficiencyFactor;
      json[r'rides'] = this.rides;
    return json;
  }

  /// Clones this instance of [EfficiencyWeek] and returns a new one where some of the
  /// properties have changed.
  EfficiencyWeek copyWith({
    DateTime? weekStart,
    double? efficiencyFactor,
    int? rides,
  }) => EfficiencyWeek(
    weekStart: weekStart ?? this.weekStart,
    efficiencyFactor: efficiencyFactor ?? this.efficiencyFactor,
    rides: rides ?? this.rides,
  );

  /// Returns a new [EfficiencyWeek] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static EfficiencyWeek? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'weekStart'), 'Required key "EfficiencyWeek[weekStart]" is missing from JSON.');
        assert(json[r'weekStart'] != null, 'Required key "EfficiencyWeek[weekStart]" has a null value in JSON.');
        assert(json.containsKey(r'efficiencyFactor'), 'Required key "EfficiencyWeek[efficiencyFactor]" is missing from JSON.');
        assert(json[r'efficiencyFactor'] != null, 'Required key "EfficiencyWeek[efficiencyFactor]" has a null value in JSON.');
        assert(json.containsKey(r'rides'), 'Required key "EfficiencyWeek[rides]" is missing from JSON.');
        assert(json[r'rides'] != null, 'Required key "EfficiencyWeek[rides]" has a null value in JSON.');
        return true;
      }());

      return EfficiencyWeek(
        weekStart: mapDateTime(json, r'weekStart', r'')!,
        efficiencyFactor: mapValueOfType<double>(json, r'efficiencyFactor')!,
        rides: mapValueOfType<int>(json, r'rides')!,
      );
    }
    return null;
  }

  static List<EfficiencyWeek> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <EfficiencyWeek>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = EfficiencyWeek.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, EfficiencyWeek> mapFromJson(dynamic json) {
    final map = <String, EfficiencyWeek>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = EfficiencyWeek.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of EfficiencyWeek-objects as value to a dart map
  static Map<String, List<EfficiencyWeek>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<EfficiencyWeek>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = EfficiencyWeek.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'weekStart',
    'efficiencyFactor',
    'rides',
  };
}

