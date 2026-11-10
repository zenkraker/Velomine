//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class PrivacyStreamsResponse {
  /// Returns a new [PrivacyStreamsResponse] instance.
  PrivacyStreamsResponse({
    required this.hideHeartRate,
    required this.hidePower,
    required this.hideCadence,
    required this.hideSpeed,
    required this.hideElevation,
    required this.hideTemperature,
  });

  final bool hideHeartRate;

  final bool hidePower;

  final bool hideCadence;

  final bool hideSpeed;

  final bool hideElevation;

  final bool hideTemperature;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PrivacyStreamsResponse &&
    other.hideHeartRate == hideHeartRate &&
    other.hidePower == hidePower &&
    other.hideCadence == hideCadence &&
    other.hideSpeed == hideSpeed &&
    other.hideElevation == hideElevation &&
    other.hideTemperature == hideTemperature;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (hideHeartRate.hashCode) +
    (hidePower.hashCode) +
    (hideCadence.hashCode) +
    (hideSpeed.hashCode) +
    (hideElevation.hashCode) +
    (hideTemperature.hashCode);

  @override
  String toString() => 'PrivacyStreamsResponse[hideHeartRate=$hideHeartRate, hidePower=$hidePower, hideCadence=$hideCadence, hideSpeed=$hideSpeed, hideElevation=$hideElevation, hideTemperature=$hideTemperature]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'hideHeartRate'] = this.hideHeartRate;
      json[r'hidePower'] = this.hidePower;
      json[r'hideCadence'] = this.hideCadence;
      json[r'hideSpeed'] = this.hideSpeed;
      json[r'hideElevation'] = this.hideElevation;
      json[r'hideTemperature'] = this.hideTemperature;
    return json;
  }

  /// Clones this instance of [PrivacyStreamsResponse] and returns a new one where some of the
  /// properties have changed.
  PrivacyStreamsResponse copyWith({
    bool? hideHeartRate,
    bool? hidePower,
    bool? hideCadence,
    bool? hideSpeed,
    bool? hideElevation,
    bool? hideTemperature,
  }) => PrivacyStreamsResponse(
    hideHeartRate: hideHeartRate ?? this.hideHeartRate,
    hidePower: hidePower ?? this.hidePower,
    hideCadence: hideCadence ?? this.hideCadence,
    hideSpeed: hideSpeed ?? this.hideSpeed,
    hideElevation: hideElevation ?? this.hideElevation,
    hideTemperature: hideTemperature ?? this.hideTemperature,
  );

  /// Returns a new [PrivacyStreamsResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PrivacyStreamsResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'hideHeartRate'), 'Required key "PrivacyStreamsResponse[hideHeartRate]" is missing from JSON.');
        assert(json[r'hideHeartRate'] != null, 'Required key "PrivacyStreamsResponse[hideHeartRate]" has a null value in JSON.');
        assert(json.containsKey(r'hidePower'), 'Required key "PrivacyStreamsResponse[hidePower]" is missing from JSON.');
        assert(json[r'hidePower'] != null, 'Required key "PrivacyStreamsResponse[hidePower]" has a null value in JSON.');
        assert(json.containsKey(r'hideCadence'), 'Required key "PrivacyStreamsResponse[hideCadence]" is missing from JSON.');
        assert(json[r'hideCadence'] != null, 'Required key "PrivacyStreamsResponse[hideCadence]" has a null value in JSON.');
        assert(json.containsKey(r'hideSpeed'), 'Required key "PrivacyStreamsResponse[hideSpeed]" is missing from JSON.');
        assert(json[r'hideSpeed'] != null, 'Required key "PrivacyStreamsResponse[hideSpeed]" has a null value in JSON.');
        assert(json.containsKey(r'hideElevation'), 'Required key "PrivacyStreamsResponse[hideElevation]" is missing from JSON.');
        assert(json[r'hideElevation'] != null, 'Required key "PrivacyStreamsResponse[hideElevation]" has a null value in JSON.');
        assert(json.containsKey(r'hideTemperature'), 'Required key "PrivacyStreamsResponse[hideTemperature]" is missing from JSON.');
        assert(json[r'hideTemperature'] != null, 'Required key "PrivacyStreamsResponse[hideTemperature]" has a null value in JSON.');
        return true;
      }());

      return PrivacyStreamsResponse(
        hideHeartRate: mapValueOfType<bool>(json, r'hideHeartRate')!,
        hidePower: mapValueOfType<bool>(json, r'hidePower')!,
        hideCadence: mapValueOfType<bool>(json, r'hideCadence')!,
        hideSpeed: mapValueOfType<bool>(json, r'hideSpeed')!,
        hideElevation: mapValueOfType<bool>(json, r'hideElevation')!,
        hideTemperature: mapValueOfType<bool>(json, r'hideTemperature')!,
      );
    }
    return null;
  }

  static List<PrivacyStreamsResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PrivacyStreamsResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PrivacyStreamsResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PrivacyStreamsResponse> mapFromJson(dynamic json) {
    final map = <String, PrivacyStreamsResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PrivacyStreamsResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PrivacyStreamsResponse-objects as value to a dart map
  static Map<String, List<PrivacyStreamsResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PrivacyStreamsResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PrivacyStreamsResponse.listFromJson(entry.value, growable: growable,);
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
  };
}

