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
    this.hideHeartRate = const Optional.absent(),
    this.hidePower = const Optional.absent(),
    this.hideCadence = const Optional.absent(),
    this.hideSpeed = const Optional.absent(),
    this.hideElevation = const Optional.absent(),
    this.hideTemperature = const Optional.absent(),
    required this.trimStartM,
    required this.trimEndM,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> hideHeartRate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> hidePower;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> hideCadence;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> hideSpeed;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> hideElevation;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> hideTemperature;

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
    (hideHeartRate == null ? 0 : hideHeartRate!.hashCode) +
    (hidePower == null ? 0 : hidePower!.hashCode) +
    (hideCadence == null ? 0 : hideCadence!.hashCode) +
    (hideSpeed == null ? 0 : hideSpeed!.hashCode) +
    (hideElevation == null ? 0 : hideElevation!.hashCode) +
    (hideTemperature == null ? 0 : hideTemperature!.hashCode) +
    (trimStartM.hashCode) +
    (trimEndM.hashCode);

  @override
  String toString() => 'UpdatePrivacyRequest[hideHeartRate=$hideHeartRate, hidePower=$hidePower, hideCadence=$hideCadence, hideSpeed=$hideSpeed, hideElevation=$hideElevation, hideTemperature=$hideTemperature, trimStartM=$trimStartM, trimEndM=$trimEndM]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.hideHeartRate.isPresent) {
      final value = this.hideHeartRate.value;
      json[r'hideHeartRate'] = value;
    }
    if (this.hidePower.isPresent) {
      final value = this.hidePower.value;
      json[r'hidePower'] = value;
    }
    if (this.hideCadence.isPresent) {
      final value = this.hideCadence.value;
      json[r'hideCadence'] = value;
    }
    if (this.hideSpeed.isPresent) {
      final value = this.hideSpeed.value;
      json[r'hideSpeed'] = value;
    }
    if (this.hideElevation.isPresent) {
      final value = this.hideElevation.value;
      json[r'hideElevation'] = value;
    }
    if (this.hideTemperature.isPresent) {
      final value = this.hideTemperature.value;
      json[r'hideTemperature'] = value;
    }
      json[r'trimStartM'] = this.trimStartM;
      json[r'trimEndM'] = this.trimEndM;
    return json;
  }

  /// Clones this instance of [UpdatePrivacyRequest] and returns a new one where some of the
  /// properties have changed.
  UpdatePrivacyRequest copyWith({
    Optional<bool?>? hideHeartRate,
    Optional<bool?>? hidePower,
    Optional<bool?>? hideCadence,
    Optional<bool?>? hideSpeed,
    Optional<bool?>? hideElevation,
    Optional<bool?>? hideTemperature,
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
        assert(json.containsKey(r'trimStartM'), 'Required key "UpdatePrivacyRequest[trimStartM]" is missing from JSON.');
        assert(json[r'trimStartM'] != null, 'Required key "UpdatePrivacyRequest[trimStartM]" has a null value in JSON.');
        assert(json.containsKey(r'trimEndM'), 'Required key "UpdatePrivacyRequest[trimEndM]" is missing from JSON.');
        assert(json[r'trimEndM'] != null, 'Required key "UpdatePrivacyRequest[trimEndM]" has a null value in JSON.');
        return true;
      }());

      return UpdatePrivacyRequest(
        hideHeartRate: json.containsKey(r'hideHeartRate') ? Optional.present(mapValueOfType<bool>(json, r'hideHeartRate')) : const Optional.absent(),
        hidePower: json.containsKey(r'hidePower') ? Optional.present(mapValueOfType<bool>(json, r'hidePower')) : const Optional.absent(),
        hideCadence: json.containsKey(r'hideCadence') ? Optional.present(mapValueOfType<bool>(json, r'hideCadence')) : const Optional.absent(),
        hideSpeed: json.containsKey(r'hideSpeed') ? Optional.present(mapValueOfType<bool>(json, r'hideSpeed')) : const Optional.absent(),
        hideElevation: json.containsKey(r'hideElevation') ? Optional.present(mapValueOfType<bool>(json, r'hideElevation')) : const Optional.absent(),
        hideTemperature: json.containsKey(r'hideTemperature') ? Optional.present(mapValueOfType<bool>(json, r'hideTemperature')) : const Optional.absent(),
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
    'trimStartM',
    'trimEndM',
  };
}

