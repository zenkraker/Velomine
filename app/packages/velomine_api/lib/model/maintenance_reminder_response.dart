//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class MaintenanceReminderResponse {
  /// Returns a new [MaintenanceReminderResponse] instance.
  MaintenanceReminderResponse({
    required this.id,
    required this.name,
    required this.intervalDistanceM,
    required this.intervalHours,
    required this.intervalMonths,
    required this.lastDoneOn,
    required this.isPaused,
    required this.usedDistanceM,
    required this.usedHours,
    required this.usedMonths,
    required this.percent,
    required this.status,
  });

  final String id;

  final String name;

  final double? intervalDistanceM;

  final double? intervalHours;

  final int? intervalMonths;

  final DateTime lastDoneOn;

  final bool isPaused;

  final double usedDistanceM;

  final double usedHours;

  final double usedMonths;

  final int? percent;

  final String status;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MaintenanceReminderResponse &&
    other.id == id &&
    other.name == name &&
    other.intervalDistanceM == intervalDistanceM &&
    other.intervalHours == intervalHours &&
    other.intervalMonths == intervalMonths &&
    other.lastDoneOn == lastDoneOn &&
    other.isPaused == isPaused &&
    other.usedDistanceM == usedDistanceM &&
    other.usedHours == usedHours &&
    other.usedMonths == usedMonths &&
    other.percent == percent &&
    other.status == status;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (intervalDistanceM == null ? 0 : intervalDistanceM!.hashCode) +
    (intervalHours == null ? 0 : intervalHours!.hashCode) +
    (intervalMonths == null ? 0 : intervalMonths!.hashCode) +
    (lastDoneOn.hashCode) +
    (isPaused.hashCode) +
    (usedDistanceM.hashCode) +
    (usedHours.hashCode) +
    (usedMonths.hashCode) +
    (percent == null ? 0 : percent!.hashCode) +
    (status.hashCode);

  @override
  String toString() => 'MaintenanceReminderResponse[id=$id, name=$name, intervalDistanceM=$intervalDistanceM, intervalHours=$intervalHours, intervalMonths=$intervalMonths, lastDoneOn=$lastDoneOn, isPaused=$isPaused, usedDistanceM=$usedDistanceM, usedHours=$usedHours, usedMonths=$usedMonths, percent=$percent, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
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
      json[r'lastDoneOn'] = _dateFormatter.format(this.lastDoneOn);
      json[r'isPaused'] = this.isPaused;
      json[r'usedDistanceM'] = this.usedDistanceM;
      json[r'usedHours'] = this.usedHours;
      json[r'usedMonths'] = this.usedMonths;
    if (this.percent != null) {
      json[r'percent'] = this.percent;
    } else {
      json[r'percent'] = null;
    }
      json[r'status'] = this.status;
    return json;
  }

  /// Clones this instance of [MaintenanceReminderResponse] and returns a new one where some of the
  /// properties have changed.
  MaintenanceReminderResponse copyWith({
    String? id,
    String? name,
    double? intervalDistanceM,
    bool intervalDistanceMSetToNull = false,
    double? intervalHours,
    bool intervalHoursSetToNull = false,
    int? intervalMonths,
    bool intervalMonthsSetToNull = false,
    DateTime? lastDoneOn,
    bool? isPaused,
    double? usedDistanceM,
    double? usedHours,
    double? usedMonths,
    int? percent,
    bool percentSetToNull = false,
    String? status,
  }) => MaintenanceReminderResponse(
    id: id ?? this.id,
    name: name ?? this.name,
    intervalDistanceM: intervalDistanceMSetToNull ? null : intervalDistanceM ?? this.intervalDistanceM,
    intervalHours: intervalHoursSetToNull ? null : intervalHours ?? this.intervalHours,
    intervalMonths: intervalMonthsSetToNull ? null : intervalMonths ?? this.intervalMonths,
    lastDoneOn: lastDoneOn ?? this.lastDoneOn,
    isPaused: isPaused ?? this.isPaused,
    usedDistanceM: usedDistanceM ?? this.usedDistanceM,
    usedHours: usedHours ?? this.usedHours,
    usedMonths: usedMonths ?? this.usedMonths,
    percent: percentSetToNull ? null : percent ?? this.percent,
    status: status ?? this.status,
  );

  /// Returns a new [MaintenanceReminderResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MaintenanceReminderResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "MaintenanceReminderResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "MaintenanceReminderResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "MaintenanceReminderResponse[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "MaintenanceReminderResponse[name]" has a null value in JSON.');
        assert(json.containsKey(r'intervalDistanceM'), 'Required key "MaintenanceReminderResponse[intervalDistanceM]" is missing from JSON.');
        assert(json.containsKey(r'intervalHours'), 'Required key "MaintenanceReminderResponse[intervalHours]" is missing from JSON.');
        assert(json.containsKey(r'intervalMonths'), 'Required key "MaintenanceReminderResponse[intervalMonths]" is missing from JSON.');
        assert(json.containsKey(r'lastDoneOn'), 'Required key "MaintenanceReminderResponse[lastDoneOn]" is missing from JSON.');
        assert(json[r'lastDoneOn'] != null, 'Required key "MaintenanceReminderResponse[lastDoneOn]" has a null value in JSON.');
        assert(json.containsKey(r'isPaused'), 'Required key "MaintenanceReminderResponse[isPaused]" is missing from JSON.');
        assert(json[r'isPaused'] != null, 'Required key "MaintenanceReminderResponse[isPaused]" has a null value in JSON.');
        assert(json.containsKey(r'usedDistanceM'), 'Required key "MaintenanceReminderResponse[usedDistanceM]" is missing from JSON.');
        assert(json[r'usedDistanceM'] != null, 'Required key "MaintenanceReminderResponse[usedDistanceM]" has a null value in JSON.');
        assert(json.containsKey(r'usedHours'), 'Required key "MaintenanceReminderResponse[usedHours]" is missing from JSON.');
        assert(json[r'usedHours'] != null, 'Required key "MaintenanceReminderResponse[usedHours]" has a null value in JSON.');
        assert(json.containsKey(r'usedMonths'), 'Required key "MaintenanceReminderResponse[usedMonths]" is missing from JSON.');
        assert(json[r'usedMonths'] != null, 'Required key "MaintenanceReminderResponse[usedMonths]" has a null value in JSON.');
        assert(json.containsKey(r'percent'), 'Required key "MaintenanceReminderResponse[percent]" is missing from JSON.');
        assert(json.containsKey(r'status'), 'Required key "MaintenanceReminderResponse[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "MaintenanceReminderResponse[status]" has a null value in JSON.');
        return true;
      }());

      return MaintenanceReminderResponse(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        intervalDistanceM: mapValueOfType<double>(json, r'intervalDistanceM'),
        intervalHours: mapValueOfType<double>(json, r'intervalHours'),
        intervalMonths: mapValueOfType<int>(json, r'intervalMonths'),
        lastDoneOn: mapDateTime(json, r'lastDoneOn', r'')!,
        isPaused: mapValueOfType<bool>(json, r'isPaused')!,
        usedDistanceM: mapValueOfType<double>(json, r'usedDistanceM')!,
        usedHours: mapValueOfType<double>(json, r'usedHours')!,
        usedMonths: mapValueOfType<double>(json, r'usedMonths')!,
        percent: mapValueOfType<int>(json, r'percent'),
        status: mapValueOfType<String>(json, r'status')!,
      );
    }
    return null;
  }

  static List<MaintenanceReminderResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MaintenanceReminderResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MaintenanceReminderResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MaintenanceReminderResponse> mapFromJson(dynamic json) {
    final map = <String, MaintenanceReminderResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MaintenanceReminderResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MaintenanceReminderResponse-objects as value to a dart map
  static Map<String, List<MaintenanceReminderResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MaintenanceReminderResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MaintenanceReminderResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'intervalDistanceM',
    'intervalHours',
    'intervalMonths',
    'lastDoneOn',
    'isPaused',
    'usedDistanceM',
    'usedHours',
    'usedMonths',
    'percent',
    'status',
  };
}

