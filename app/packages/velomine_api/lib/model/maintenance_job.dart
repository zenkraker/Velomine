//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class MaintenanceJob {
  /// Returns a new [MaintenanceJob] instance.
  MaintenanceJob({
    required this.id,
    required this.intervalDistanceM,
    required this.intervalHours,
    required this.intervalMonths,
  });

  final String id;

  final double? intervalDistanceM;

  final double? intervalHours;

  final int? intervalMonths;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MaintenanceJob &&
    other.id == id &&
    other.intervalDistanceM == intervalDistanceM &&
    other.intervalHours == intervalHours &&
    other.intervalMonths == intervalMonths;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (intervalDistanceM == null ? 0 : intervalDistanceM!.hashCode) +
    (intervalHours == null ? 0 : intervalHours!.hashCode) +
    (intervalMonths == null ? 0 : intervalMonths!.hashCode);

  @override
  String toString() => 'MaintenanceJob[id=$id, intervalDistanceM=$intervalDistanceM, intervalHours=$intervalHours, intervalMonths=$intervalMonths]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
    if (this.intervalDistanceM != null) {
      json[r'intervalDistanceM'] = this.intervalDistanceM;
    } else {
      json[r'intervalDistanceM'] = null;
    }
    if (this.intervalHours != null) {
      json[r'intervalHours'] = this.intervalHours;
    } else {
      json[r'intervalHours'] = null;
    }
    if (this.intervalMonths != null) {
      json[r'intervalMonths'] = this.intervalMonths;
    } else {
      json[r'intervalMonths'] = null;
    }
    return json;
  }

  /// Clones this instance of [MaintenanceJob] and returns a new one where some of the
  /// properties have changed.
  MaintenanceJob copyWith({
    String? id,
    double? intervalDistanceM,
    bool intervalDistanceMSetToNull = false,
    double? intervalHours,
    bool intervalHoursSetToNull = false,
    int? intervalMonths,
    bool intervalMonthsSetToNull = false,
  }) => MaintenanceJob(
    id: id ?? this.id,
    intervalDistanceM: intervalDistanceMSetToNull ? null : intervalDistanceM ?? this.intervalDistanceM,
    intervalHours: intervalHoursSetToNull ? null : intervalHours ?? this.intervalHours,
    intervalMonths: intervalMonthsSetToNull ? null : intervalMonths ?? this.intervalMonths,
  );

  /// Returns a new [MaintenanceJob] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MaintenanceJob? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "MaintenanceJob[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "MaintenanceJob[id]" has a null value in JSON.');
        assert(json.containsKey(r'intervalDistanceM'), 'Required key "MaintenanceJob[intervalDistanceM]" is missing from JSON.');
        assert(json.containsKey(r'intervalHours'), 'Required key "MaintenanceJob[intervalHours]" is missing from JSON.');
        assert(json.containsKey(r'intervalMonths'), 'Required key "MaintenanceJob[intervalMonths]" is missing from JSON.');
        return true;
      }());

      return MaintenanceJob(
        id: mapValueOfType<String>(json, r'id')!,
        intervalDistanceM: mapValueOfType<double>(json, r'intervalDistanceM'),
        intervalHours: mapValueOfType<double>(json, r'intervalHours'),
        intervalMonths: mapValueOfType<int>(json, r'intervalMonths'),
      );
    }
    return null;
  }

  static List<MaintenanceJob> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MaintenanceJob>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MaintenanceJob.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MaintenanceJob> mapFromJson(dynamic json) {
    final map = <String, MaintenanceJob>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MaintenanceJob.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MaintenanceJob-objects as value to a dart map
  static Map<String, List<MaintenanceJob>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MaintenanceJob>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MaintenanceJob.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'intervalDistanceM',
    'intervalHours',
    'intervalMonths',
  };
}

