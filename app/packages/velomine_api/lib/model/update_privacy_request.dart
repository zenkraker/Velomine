//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class UpdatePrivacyRequest {
  /// Returns a new [UpdatePrivacyRequest] instance.
  UpdatePrivacyRequest({
    required this.hideHeartRate,
    required this.hidePower,
    required this.hideCadence,
    required this.hideSpeed,
    required this.hideElevation,
    required this.hideTemperature,
    required this.trimStartM,
    required this.trimEndM,
  });

  final bool hideHeartRate;

  final bool hidePower;

  final bool hideCadence;

  final bool hideSpeed;

  final bool hideElevation;

  final bool hideTemperature;

  /// Minimum value: 0
  /// Maximum value: 5000
  final int trimStartM;

  /// Minimum value: 0
  /// Maximum value: 5000
  final int trimEndM;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UpdatePrivacyRequest &&
    other.hideHeartRate == hideHeartRate &&
    other.hidePower == hidePower &&
    other.hideCadence == hideCadence &&
    other.hideSpeed == hideSpeed &&
    other.hideElevation == hideElevation &&
    other.hideTemperature == hideTemperature &&
    other.trimStartM == trimStartM &&
    other.trimEndM == trimEndM;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (hideHeartRate.hashCode) +
    (hidePower.hashCode) +
    (hideCadence.hashCode) +
    (hideSpeed.hashCode) +
    (hideElevation.hashCode) +
    (hideTemperature.hashCode) +
    (trimStartM.hashCode) +
    (trimEndM.hashCode);

  @override
  String toString() => 'UpdatePrivacyRequest[hideHeartRate=$hideHeartRate, hidePower=$hidePower, hideCadence=$hideCadence, hideSpeed=$hideSpeed, hideElevation=$hideElevation, hideTemperature=$hideTemperature, trimStartM=$trimStartM, trimEndM=$trimEndM]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'hideHeartRate'] = this.hideHeartRate;
      json[r'hidePower'] = this.hidePower;
      json[r'hideCadence'] = this.hideCadence;
      json[r'hideSpeed'] = this.hideSpeed;
      json[r'hideElevation'] = this.hideElevation;
      json[r'hideTemperature'] = this.hideTemperature;
      json[r'trimStartM'] = this.trimStartM;
      json[r'trimEndM'] = this.trimEndM;
    return json;
  }

  /// Clones this instance of [UpdatePrivacyRequest] and returns a new one where some of the
  /// properties have changed.
  UpdatePrivacyRequest copyWith({
    bool? hideHeartRate,
    bool? hidePower,
    bool? hideCadence,
    bool? hideSpeed,
    bool? hideElevation,
    bool? hideTemperature,
    int? trimStartM,
    int? trimEndM,
  }) => UpdatePrivacyRequest(
    hideHeartRate: hideHeartRate ?? this.hideHeartRate,
    hidePower: hidePower ?? this.hidePower,
    hideCadence: hideCadence ?? this.hideCadence,
    hideSpeed: hideSpeed ?? this.hideSpeed,
    hideElevation: hideElevation ?? this.hideElevation,
    hideTemperature: hideTemperature ?? this.hideTemperature,
    trimStartM: trimStartM ?? this.trimStartM,
    trimEndM: trimEndM ?? this.trimEndM,
  );

  /// Returns a new [UpdatePrivacyRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdatePrivacyRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'hideHeartRate'), 'Required key "UpdatePrivacyRequest[hideHeartRate]" is missing from JSON.');
        assert(json[r'hideHeartRate'] != null, 'Required key "UpdatePrivacyRequest[hideHeartRate]" has a null value in JSON.');
        assert(json.containsKey(r'hidePower'), 'Required key "UpdatePrivacyRequest[hidePower]" is missing from JSON.');
        assert(json[r'hidePower'] != null, 'Required key "UpdatePrivacyRequest[hidePower]" has a null value in JSON.');
        assert(json.containsKey(r'hideCadence'), 'Required key "UpdatePrivacyRequest[hideCadence]" is missing from JSON.');
        assert(json[r'hideCadence'] != null, 'Required key "UpdatePrivacyRequest[hideCadence]" has a null value in JSON.');
        assert(json.containsKey(r'hideSpeed'), 'Required key "UpdatePrivacyRequest[hideSpeed]" is missing from JSON.');
        assert(json[r'hideSpeed'] != null, 'Required key "UpdatePrivacyRequest[hideSpeed]" has a null value in JSON.');
        assert(json.containsKey(r'hideElevation'), 'Required key "UpdatePrivacyRequest[hideElevation]" is missing from JSON.');
        assert(json[r'hideElevation'] != null, 'Required key "UpdatePrivacyRequest[hideElevation]" has a null value in JSON.');
        assert(json.containsKey(r'hideTemperature'), 'Required key "UpdatePrivacyRequest[hideTemperature]" is missing from JSON.');
        assert(json[r'hideTemperature'] != null, 'Required key "UpdatePrivacyRequest[hideTemperature]" has a null value in JSON.');
        assert(json.containsKey(r'trimStartM'), 'Required key "UpdatePrivacyRequest[trimStartM]" is missing from JSON.');
        assert(json[r'trimStartM'] != null, 'Required key "UpdatePrivacyRequest[trimStartM]" has a null value in JSON.');
        assert(json.containsKey(r'trimEndM'), 'Required key "UpdatePrivacyRequest[trimEndM]" is missing from JSON.');
        assert(json[r'trimEndM'] != null, 'Required key "UpdatePrivacyRequest[trimEndM]" has a null value in JSON.');
        return true;
      }());

      return UpdatePrivacyRequest(
        hideHeartRate: mapValueOfType<bool>(json, r'hideHeartRate')!,
        hidePower: mapValueOfType<bool>(json, r'hidePower')!,
        hideCadence: mapValueOfType<bool>(json, r'hideCadence')!,
        hideSpeed: mapValueOfType<bool>(json, r'hideSpeed')!,
        hideElevation: mapValueOfType<bool>(json, r'hideElevation')!,
        hideTemperature: mapValueOfType<bool>(json, r'hideTemperature')!,
        trimStartM: mapValueOfType<int>(json, r'trimStartM')!,
        trimEndM: mapValueOfType<int>(json, r'trimEndM')!,
      );
    }
    return null;
  }

  static List<UpdatePrivacyRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UpdatePrivacyRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdatePrivacyRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdatePrivacyRequest> mapFromJson(dynamic json) {
    final map = <String, UpdatePrivacyRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdatePrivacyRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdatePrivacyRequest-objects as value to a dart map
  static Map<String, List<UpdatePrivacyRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UpdatePrivacyRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdatePrivacyRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'hideHeartRate',
    'hidePower',
    'hideCadence',
    'hideSpeed',
    'hideElevation',
    'hideTemperature',
    'trimStartM',
    'trimEndM',
  };
}

