//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class UpdateProfileRequest {
  /// Returns a new [UpdateProfileRequest] instance.
  UpdateProfileRequest({
    required this.displayName,
    required this.ftpW,
    required this.weightKg,
    required this.maxHeartRate,
    required this.timeZone,
    required this.firstDayOfWeek,
  });

  final String displayName;

  /// Minimum value: 30
  /// Maximum value: 1000
  final int? ftpW;

  /// Minimum value: 20
  /// Maximum value: 300
  final double? weightKg;

  /// Minimum value: 100
  /// Maximum value: 240
  final int? maxHeartRate;

  final String? timeZone;

  final String firstDayOfWeek;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UpdateProfileRequest &&
    other.displayName == displayName &&
    other.ftpW == ftpW &&
    other.weightKg == weightKg &&
    other.maxHeartRate == maxHeartRate &&
    other.timeZone == timeZone &&
    other.firstDayOfWeek == firstDayOfWeek;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (displayName.hashCode) +
    (ftpW == null ? 0 : ftpW!.hashCode) +
    (weightKg == null ? 0 : weightKg!.hashCode) +
    (maxHeartRate == null ? 0 : maxHeartRate!.hashCode) +
    (timeZone == null ? 0 : timeZone!.hashCode) +
    (firstDayOfWeek.hashCode);

  @override
  String toString() => 'UpdateProfileRequest[displayName=$displayName, ftpW=$ftpW, weightKg=$weightKg, maxHeartRate=$maxHeartRate, timeZone=$timeZone, firstDayOfWeek=$firstDayOfWeek]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'displayName'] = this.displayName;
    if (this.ftpW != null) {
      json[r'ftpW'] = this.ftpW;
    } else {
      json[r'ftpW'] = null;
    }
    if (this.weightKg != null) {
      json[r'weightKg'] = this.weightKg;
    } else {
      json[r'weightKg'] = null;
    }
    if (this.maxHeartRate != null) {
      json[r'maxHeartRate'] = this.maxHeartRate;
    } else {
      json[r'maxHeartRate'] = null;
    }
    if (this.timeZone != null) {
      json[r'timeZone'] = this.timeZone;
    } else {
      json[r'timeZone'] = null;
    }
      json[r'firstDayOfWeek'] = this.firstDayOfWeek;
    return json;
  }

  /// Clones this instance of [UpdateProfileRequest] and returns a new one where some of the
  /// properties have changed.
  UpdateProfileRequest copyWith({
    String? displayName,
    int? ftpW,
    bool ftpWSetToNull = false,
    double? weightKg,
    bool weightKgSetToNull = false,
    int? maxHeartRate,
    bool maxHeartRateSetToNull = false,
    String? timeZone,
    bool timeZoneSetToNull = false,
    String? firstDayOfWeek,
  }) => UpdateProfileRequest(
    displayName: displayName ?? this.displayName,
    ftpW: ftpWSetToNull ? null : ftpW ?? this.ftpW,
    weightKg: weightKgSetToNull ? null : weightKg ?? this.weightKg,
    maxHeartRate: maxHeartRateSetToNull ? null : maxHeartRate ?? this.maxHeartRate,
    timeZone: timeZoneSetToNull ? null : timeZone ?? this.timeZone,
    firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
  );

  /// Returns a new [UpdateProfileRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateProfileRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'displayName'), 'Required key "UpdateProfileRequest[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null, 'Required key "UpdateProfileRequest[displayName]" has a null value in JSON.');
        assert(json.containsKey(r'ftpW'), 'Required key "UpdateProfileRequest[ftpW]" is missing from JSON.');
        assert(json.containsKey(r'weightKg'), 'Required key "UpdateProfileRequest[weightKg]" is missing from JSON.');
        assert(json.containsKey(r'maxHeartRate'), 'Required key "UpdateProfileRequest[maxHeartRate]" is missing from JSON.');
        assert(json.containsKey(r'timeZone'), 'Required key "UpdateProfileRequest[timeZone]" is missing from JSON.');
        assert(json.containsKey(r'firstDayOfWeek'), 'Required key "UpdateProfileRequest[firstDayOfWeek]" is missing from JSON.');
        assert(json[r'firstDayOfWeek'] != null, 'Required key "UpdateProfileRequest[firstDayOfWeek]" has a null value in JSON.');
        return true;
      }());

      return UpdateProfileRequest(
        displayName: mapValueOfType<String>(json, r'displayName')!,
        ftpW: mapValueOfType<int>(json, r'ftpW'),
        weightKg: mapValueOfType<double>(json, r'weightKg'),
        maxHeartRate: mapValueOfType<int>(json, r'maxHeartRate'),
        timeZone: mapValueOfType<String>(json, r'timeZone'),
        firstDayOfWeek: mapValueOfType<String>(json, r'firstDayOfWeek')!,
      );
    }
    return null;
  }

  static List<UpdateProfileRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UpdateProfileRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateProfileRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateProfileRequest> mapFromJson(dynamic json) {
    final map = <String, UpdateProfileRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateProfileRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateProfileRequest-objects as value to a dart map
  static Map<String, List<UpdateProfileRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UpdateProfileRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateProfileRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'displayName',
    'ftpW',
    'weightKg',
    'maxHeartRate',
    'timeZone',
    'firstDayOfWeek',
  };
}

