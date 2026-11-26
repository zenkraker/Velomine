//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class UpdateEventRequest {
  /// Returns a new [UpdateEventRequest] instance.
  UpdateEventRequest({
    required this.name,
    required this.date,
    this.kind = const Optional.absent(),
    this.distanceM = const Optional.absent(),
    this.elevationGainM = const Optional.absent(),
    this.notes = const Optional.absent(),
  });

  final String name;

  final DateTime date;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> kind;

  /// Minimum value: 0
  /// Maximum value: 1000000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<double?> distanceM;

  /// Minimum value: 0
  /// Maximum value: 30000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<double?> elevationGainM;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> notes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UpdateEventRequest &&
    other.name == name &&
    other.date == date &&
    other.kind == kind &&
    other.distanceM == distanceM &&
    other.elevationGainM == elevationGainM &&
    other.notes == notes;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (date.hashCode) +
    (kind == null ? 0 : kind!.hashCode) +
    (distanceM == null ? 0 : distanceM!.hashCode) +
    (elevationGainM == null ? 0 : elevationGainM!.hashCode) +
    (notes == null ? 0 : notes!.hashCode);

  @override
  String toString() => 'UpdateEventRequest[name=$name, date=$date, kind=$kind, distanceM=$distanceM, elevationGainM=$elevationGainM, notes=$notes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'date'] = _dateFormatter.format(this.date);
    if (this.kind.isPresent) {
      final value = this.kind.value;
      json[r'kind'] = value;
    }
    if (this.distanceM.isPresent) {
      final value = this.distanceM.value;
      json[r'distanceM'] = value;
    }
    if (this.elevationGainM.isPresent) {
      final value = this.elevationGainM.value;
      json[r'elevationGainM'] = value;
    }
    if (this.notes.isPresent) {
      final value = this.notes.value;
      json[r'notes'] = value;
    }
    return json;
  }

  /// Clones this instance of [UpdateEventRequest] and returns a new one where some of the
  /// properties have changed.
  UpdateEventRequest copyWith({
    String? name,
    DateTime? date,
    Optional<String?>? kind,
    Optional<double?>? distanceM,
    Optional<double?>? elevationGainM,
    Optional<String?>? notes,
  }) => UpdateEventRequest(
    name: name ?? this.name,
    date: date ?? this.date,
    kind: kind ?? this.kind,
    distanceM: distanceM ?? this.distanceM,
    elevationGainM: elevationGainM ?? this.elevationGainM,
    notes: notes ?? this.notes,
  );

  /// Returns a new [UpdateEventRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateEventRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "UpdateEventRequest[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "UpdateEventRequest[name]" has a null value in JSON.');
        assert(json.containsKey(r'date'), 'Required key "UpdateEventRequest[date]" is missing from JSON.');
        assert(json[r'date'] != null, 'Required key "UpdateEventRequest[date]" has a null value in JSON.');
        return true;
      }());

      return UpdateEventRequest(
        name: mapValueOfType<String>(json, r'name')!,
        date: mapDateTime(json, r'date', r'')!,
        kind: json.containsKey(r'kind') ? Optional.present(mapValueOfType<String>(json, r'kind')) : const Optional.absent(),
        distanceM: json.containsKey(r'distanceM') ? Optional.present(mapValueOfType<double>(json, r'distanceM')) : const Optional.absent(),
        elevationGainM: json.containsKey(r'elevationGainM') ? Optional.present(mapValueOfType<double>(json, r'elevationGainM')) : const Optional.absent(),
        notes: json.containsKey(r'notes') ? Optional.present(mapValueOfType<String>(json, r'notes')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<UpdateEventRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UpdateEventRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateEventRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateEventRequest> mapFromJson(dynamic json) {
    final map = <String, UpdateEventRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateEventRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateEventRequest-objects as value to a dart map
  static Map<String, List<UpdateEventRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UpdateEventRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateEventRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'date',
  };
}

