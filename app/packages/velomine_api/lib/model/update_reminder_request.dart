//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class UpdateReminderRequest {
  /// Returns a new [UpdateReminderRequest] instance.
  UpdateReminderRequest({
    required this.name,
    this.intervalDistanceM = const Optional.absent(),
    this.intervalHours = const Optional.absent(),
    this.intervalMonths = const Optional.absent(),
    this.isPaused = const Optional.absent(),
  });

  final String name;

  /// Minimum value: 1
  /// Maximum value: 10000000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<double?> intervalDistanceM;

  /// Minimum value: 0.1
  /// Maximum value: 100000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<double?> intervalHours;

  /// Minimum value: 1
  /// Maximum value: 600
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> intervalMonths;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> isPaused;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UpdateReminderRequest &&
    other.name == name &&
    other.intervalDistanceM == intervalDistanceM &&
    other.intervalHours == intervalHours &&
    other.intervalMonths == intervalMonths &&
    other.isPaused == isPaused;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (intervalDistanceM == null ? 0 : intervalDistanceM!.hashCode) +
    (intervalHours == null ? 0 : intervalHours!.hashCode) +
    (intervalMonths == null ? 0 : intervalMonths!.hashCode) +
    (isPaused == null ? 0 : isPaused!.hashCode);

  @override
  String toString() => 'UpdateReminderRequest[name=$name, intervalDistanceM=$intervalDistanceM, intervalHours=$intervalHours, intervalMonths=$intervalMonths, isPaused=$isPaused]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
    if (this.intervalDistanceM.isPresent) {
      final value = this.intervalDistanceM.value;
      json[r'intervalDistanceM'] = value;
    }
    if (this.intervalHours.isPresent) {
      final value = this.intervalHours.value;
      json[r'intervalHours'] = value;
    }
    if (this.intervalMonths.isPresent) {
      final value = this.intervalMonths.value;
      json[r'intervalMonths'] = value;
    }
    if (this.isPaused.isPresent) {
      final value = this.isPaused.value;
      json[r'isPaused'] = value;
    }
    return json;
  }

  /// Clones this instance of [UpdateReminderRequest] and returns a new one where some of the
  /// properties have changed.
  UpdateReminderRequest copyWith({
    String? name,
    Optional<double?>? intervalDistanceM,
    Optional<double?>? intervalHours,
    Optional<int?>? intervalMonths,
    Optional<bool?>? isPaused,
  }) => UpdateReminderRequest(
    name: name ?? this.name,
    intervalDistanceM: intervalDistanceM ?? this.intervalDistanceM,
    intervalHours: intervalHours ?? this.intervalHours,
    intervalMonths: intervalMonths ?? this.intervalMonths,
    isPaused: isPaused ?? this.isPaused,
  );

  /// Returns a new [UpdateReminderRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateReminderRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "UpdateReminderRequest[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "UpdateReminderRequest[name]" has a null value in JSON.');
        return true;
      }());

      return UpdateReminderRequest(
        name: mapValueOfType<String>(json, r'name')!,
        intervalDistanceM: json.containsKey(r'intervalDistanceM') ? Optional.present(mapValueOfType<double>(json, r'intervalDistanceM')) : const Optional.absent(),
        intervalHours: json.containsKey(r'intervalHours') ? Optional.present(mapValueOfType<double>(json, r'intervalHours')) : const Optional.absent(),
        intervalMonths: json.containsKey(r'intervalMonths') ? Optional.present(json[r'intervalMonths'] == null ? null : int.parse('${json[r'intervalMonths']}')) : const Optional.absent(),
        isPaused: json.containsKey(r'isPaused') ? Optional.present(mapValueOfType<bool>(json, r'isPaused')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<UpdateReminderRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UpdateReminderRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateReminderRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateReminderRequest> mapFromJson(dynamic json) {
    final map = <String, UpdateReminderRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateReminderRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateReminderRequest-objects as value to a dart map
  static Map<String, List<UpdateReminderRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UpdateReminderRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateReminderRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
  };
}

