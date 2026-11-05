//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class PeriodTotals {
  /// Returns a new [PeriodTotals] instance.
  PeriodTotals({
    required this.start,
    required this.end,
    required this.rides,
    required this.distanceM,
    required this.movingS,
    required this.elevationGainM,
  });

  final DateTime start;

  final DateTime end;

  final int rides;

  final double distanceM;

  final double movingS;

  final double elevationGainM;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PeriodTotals &&
    other.start == start &&
    other.end == end &&
    other.rides == rides &&
    other.distanceM == distanceM &&
    other.movingS == movingS &&
    other.elevationGainM == elevationGainM;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (start.hashCode) +
    (end.hashCode) +
    (rides.hashCode) +
    (distanceM.hashCode) +
    (movingS.hashCode) +
    (elevationGainM.hashCode);

  @override
  String toString() => 'PeriodTotals[start=$start, end=$end, rides=$rides, distanceM=$distanceM, movingS=$movingS, elevationGainM=$elevationGainM]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'start'] = _dateFormatter.format(this.start);
      json[r'end'] = _dateFormatter.format(this.end);
      json[r'rides'] = this.rides;
      json[r'distanceM'] = this.distanceM;
      json[r'movingS'] = this.movingS;
      json[r'elevationGainM'] = this.elevationGainM;
    return json;
  }

  /// Clones this instance of [PeriodTotals] and returns a new one where some of the
  /// properties have changed.
  PeriodTotals copyWith({
    DateTime? start,
    DateTime? end,
    int? rides,
    double? distanceM,
    double? movingS,
    double? elevationGainM,
  }) => PeriodTotals(
    start: start ?? this.start,
    end: end ?? this.end,
    rides: rides ?? this.rides,
    distanceM: distanceM ?? this.distanceM,
    movingS: movingS ?? this.movingS,
    elevationGainM: elevationGainM ?? this.elevationGainM,
  );

  /// Returns a new [PeriodTotals] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PeriodTotals? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'start'), 'Required key "PeriodTotals[start]" is missing from JSON.');
        assert(json[r'start'] != null, 'Required key "PeriodTotals[start]" has a null value in JSON.');
        assert(json.containsKey(r'end'), 'Required key "PeriodTotals[end]" is missing from JSON.');
        assert(json[r'end'] != null, 'Required key "PeriodTotals[end]" has a null value in JSON.');
        assert(json.containsKey(r'rides'), 'Required key "PeriodTotals[rides]" is missing from JSON.');
        assert(json[r'rides'] != null, 'Required key "PeriodTotals[rides]" has a null value in JSON.');
        assert(json.containsKey(r'distanceM'), 'Required key "PeriodTotals[distanceM]" is missing from JSON.');
        assert(json[r'distanceM'] != null, 'Required key "PeriodTotals[distanceM]" has a null value in JSON.');
        assert(json.containsKey(r'movingS'), 'Required key "PeriodTotals[movingS]" is missing from JSON.');
        assert(json[r'movingS'] != null, 'Required key "PeriodTotals[movingS]" has a null value in JSON.');
        assert(json.containsKey(r'elevationGainM'), 'Required key "PeriodTotals[elevationGainM]" is missing from JSON.');
        assert(json[r'elevationGainM'] != null, 'Required key "PeriodTotals[elevationGainM]" has a null value in JSON.');
        return true;
      }());

      return PeriodTotals(
        start: mapDateTime(json, r'start', r'')!,
        end: mapDateTime(json, r'end', r'')!,
        rides: mapValueOfType<int>(json, r'rides')!,
        distanceM: mapValueOfType<double>(json, r'distanceM')!,
        movingS: mapValueOfType<double>(json, r'movingS')!,
        elevationGainM: mapValueOfType<double>(json, r'elevationGainM')!,
      );
    }
    return null;
  }

  static List<PeriodTotals> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PeriodTotals>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PeriodTotals.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PeriodTotals> mapFromJson(dynamic json) {
    final map = <String, PeriodTotals>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PeriodTotals.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PeriodTotals-objects as value to a dart map
  static Map<String, List<PeriodTotals>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PeriodTotals>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PeriodTotals.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'start',
    'end',
    'rides',
    'distanceM',
    'movingS',
    'elevationGainM',
  };
}

