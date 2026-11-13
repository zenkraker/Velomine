//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ProfileResponse {
  /// Returns a new [ProfileResponse] instance.
  ProfileResponse({
    required this.displayName,
    required this.ftpW,
    required this.weightKg,
    required this.birthYear,
    required this.maxHeartRate,
    required this.timeZone,
    required this.firstDayOfWeek,
    required this.emailNotifications,
    required this.hasPassword,
    required this.emailAccountNotifications,
    required this.emailTrainingNotifications,
    required this.soloTrialEndsAt,
  });

  final String displayName;

  final int? ftpW;

  final double? weightKg;

  final int? birthYear;

  final int? maxHeartRate;

  final String? timeZone;

  final String firstDayOfWeek;

  final bool emailNotifications;

  final bool hasPassword;

  final bool emailAccountNotifications;

  final bool emailTrainingNotifications;

  final DateTime? soloTrialEndsAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ProfileResponse &&
    other.displayName == displayName &&
    other.ftpW == ftpW &&
    other.weightKg == weightKg &&
    other.birthYear == birthYear &&
    other.maxHeartRate == maxHeartRate &&
    other.timeZone == timeZone &&
    other.firstDayOfWeek == firstDayOfWeek &&
    other.emailNotifications == emailNotifications &&
    other.hasPassword == hasPassword &&
    other.emailAccountNotifications == emailAccountNotifications &&
    other.emailTrainingNotifications == emailTrainingNotifications &&
    other.soloTrialEndsAt == soloTrialEndsAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (displayName.hashCode) +
    (ftpW == null ? 0 : ftpW!.hashCode) +
    (weightKg == null ? 0 : weightKg!.hashCode) +
    (birthYear == null ? 0 : birthYear!.hashCode) +
    (maxHeartRate == null ? 0 : maxHeartRate!.hashCode) +
    (timeZone == null ? 0 : timeZone!.hashCode) +
    (firstDayOfWeek.hashCode) +
    (emailNotifications.hashCode) +
    (hasPassword.hashCode) +
    (emailAccountNotifications.hashCode) +
    (emailTrainingNotifications.hashCode) +
    (soloTrialEndsAt == null ? 0 : soloTrialEndsAt!.hashCode);

  @override
  String toString() => 'ProfileResponse[displayName=$displayName, ftpW=$ftpW, weightKg=$weightKg, birthYear=$birthYear, maxHeartRate=$maxHeartRate, timeZone=$timeZone, firstDayOfWeek=$firstDayOfWeek, emailNotifications=$emailNotifications, hasPassword=$hasPassword, emailAccountNotifications=$emailAccountNotifications, emailTrainingNotifications=$emailTrainingNotifications, soloTrialEndsAt=$soloTrialEndsAt]';

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
    if (this.birthYear != null) {
      json[r'birthYear'] = this.birthYear;
    } else {
      json[r'birthYear'] = null;
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
      json[r'emailNotifications'] = this.emailNotifications;
      json[r'hasPassword'] = this.hasPassword;
      json[r'emailAccountNotifications'] = this.emailAccountNotifications;
      json[r'emailTrainingNotifications'] = this.emailTrainingNotifications;
    if (this.soloTrialEndsAt != null) {
      json[r'soloTrialEndsAt'] = _dateFormatter.format(this.soloTrialEndsAt!);
    } else {
      json[r'soloTrialEndsAt'] = null;
    }
    return json;
  }

  /// Clones this instance of [ProfileResponse] and returns a new one where some of the
  /// properties have changed.
  ProfileResponse copyWith({
    String? displayName,
    int? ftpW,
    bool ftpWSetToNull = false,
    double? weightKg,
    bool weightKgSetToNull = false,
    int? birthYear,
    bool birthYearSetToNull = false,
    int? maxHeartRate,
    bool maxHeartRateSetToNull = false,
    String? timeZone,
    bool timeZoneSetToNull = false,
    String? firstDayOfWeek,
    bool? emailNotifications,
    bool? hasPassword,
    bool? emailAccountNotifications,
    bool? emailTrainingNotifications,
    DateTime? soloTrialEndsAt,
    bool soloTrialEndsAtSetToNull = false,
  }) => ProfileResponse(
    displayName: displayName ?? this.displayName,
    ftpW: ftpWSetToNull ? null : ftpW ?? this.ftpW,
    weightKg: weightKgSetToNull ? null : weightKg ?? this.weightKg,
    birthYear: birthYearSetToNull ? null : birthYear ?? this.birthYear,
    maxHeartRate: maxHeartRateSetToNull ? null : maxHeartRate ?? this.maxHeartRate,
    timeZone: timeZoneSetToNull ? null : timeZone ?? this.timeZone,
    firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
    emailNotifications: emailNotifications ?? this.emailNotifications,
    hasPassword: hasPassword ?? this.hasPassword,
    emailAccountNotifications: emailAccountNotifications ?? this.emailAccountNotifications,
    emailTrainingNotifications: emailTrainingNotifications ?? this.emailTrainingNotifications,
    soloTrialEndsAt: soloTrialEndsAtSetToNull ? null : soloTrialEndsAt ?? this.soloTrialEndsAt,
  );

  /// Returns a new [ProfileResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProfileResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'displayName'), 'Required key "ProfileResponse[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null, 'Required key "ProfileResponse[displayName]" has a null value in JSON.');
        assert(json.containsKey(r'ftpW'), 'Required key "ProfileResponse[ftpW]" is missing from JSON.');
        assert(json.containsKey(r'weightKg'), 'Required key "ProfileResponse[weightKg]" is missing from JSON.');
        assert(json.containsKey(r'birthYear'), 'Required key "ProfileResponse[birthYear]" is missing from JSON.');
        assert(json.containsKey(r'maxHeartRate'), 'Required key "ProfileResponse[maxHeartRate]" is missing from JSON.');
        assert(json.containsKey(r'timeZone'), 'Required key "ProfileResponse[timeZone]" is missing from JSON.');
        assert(json.containsKey(r'firstDayOfWeek'), 'Required key "ProfileResponse[firstDayOfWeek]" is missing from JSON.');
        assert(json[r'firstDayOfWeek'] != null, 'Required key "ProfileResponse[firstDayOfWeek]" has a null value in JSON.');
        assert(json.containsKey(r'emailNotifications'), 'Required key "ProfileResponse[emailNotifications]" is missing from JSON.');
        assert(json[r'emailNotifications'] != null, 'Required key "ProfileResponse[emailNotifications]" has a null value in JSON.');
        assert(json.containsKey(r'hasPassword'), 'Required key "ProfileResponse[hasPassword]" is missing from JSON.');
        assert(json[r'hasPassword'] != null, 'Required key "ProfileResponse[hasPassword]" has a null value in JSON.');
        assert(json.containsKey(r'emailAccountNotifications'), 'Required key "ProfileResponse[emailAccountNotifications]" is missing from JSON.');
        assert(json[r'emailAccountNotifications'] != null, 'Required key "ProfileResponse[emailAccountNotifications]" has a null value in JSON.');
        assert(json.containsKey(r'emailTrainingNotifications'), 'Required key "ProfileResponse[emailTrainingNotifications]" is missing from JSON.');
        assert(json[r'emailTrainingNotifications'] != null, 'Required key "ProfileResponse[emailTrainingNotifications]" has a null value in JSON.');
        assert(json.containsKey(r'soloTrialEndsAt'), 'Required key "ProfileResponse[soloTrialEndsAt]" is missing from JSON.');
        return true;
      }());

      return ProfileResponse(
        displayName: mapValueOfType<String>(json, r'displayName')!,
        ftpW: mapValueOfType<int>(json, r'ftpW'),
        weightKg: mapValueOfType<double>(json, r'weightKg'),
        birthYear: mapValueOfType<int>(json, r'birthYear'),
        maxHeartRate: mapValueOfType<int>(json, r'maxHeartRate'),
        timeZone: mapValueOfType<String>(json, r'timeZone'),
        firstDayOfWeek: mapValueOfType<String>(json, r'firstDayOfWeek')!,
        emailNotifications: mapValueOfType<bool>(json, r'emailNotifications')!,
        hasPassword: mapValueOfType<bool>(json, r'hasPassword')!,
        emailAccountNotifications: mapValueOfType<bool>(json, r'emailAccountNotifications')!,
        emailTrainingNotifications: mapValueOfType<bool>(json, r'emailTrainingNotifications')!,
        soloTrialEndsAt: mapDateTime(json, r'soloTrialEndsAt', r''),
      );
    }
    return null;
  }

  static List<ProfileResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ProfileResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProfileResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProfileResponse> mapFromJson(dynamic json) {
    final map = <String, ProfileResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProfileResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProfileResponse-objects as value to a dart map
  static Map<String, List<ProfileResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ProfileResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProfileResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'displayName',
    'ftpW',
    'weightKg',
    'birthYear',
    'maxHeartRate',
    'timeZone',
    'firstDayOfWeek',
    'emailNotifications',
    'hasPassword',
    'emailAccountNotifications',
    'emailTrainingNotifications',
    'soloTrialEndsAt',
  };
}

