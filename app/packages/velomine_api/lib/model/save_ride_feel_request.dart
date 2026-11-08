//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SaveRideFeelRequest {
  /// Returns a new [SaveRideFeelRequest] instance.
  SaveRideFeelRequest({
    required this.rpe,
    this.notes = const Optional.absent(),
  });

  /// Minimum value: 1
  /// Maximum value: 10
  final int rpe;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> notes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SaveRideFeelRequest &&
    other.rpe == rpe &&
    other.notes == notes;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (rpe.hashCode) +
    (notes == null ? 0 : notes!.hashCode);

  @override
  String toString() => 'SaveRideFeelRequest[rpe=$rpe, notes=$notes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'rpe'] = this.rpe;
    if (this.notes.isPresent) {
      final value = this.notes.value;
      json[r'notes'] = value;
    }
    return json;
  }

  /// Clones this instance of [SaveRideFeelRequest] and returns a new one where some of the
  /// properties have changed.
  SaveRideFeelRequest copyWith({
    int? rpe,
    Optional<String?>? notes,
  }) => SaveRideFeelRequest(
    rpe: rpe ?? this.rpe,
    notes: notes ?? this.notes,
  );

  /// Returns a new [SaveRideFeelRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SaveRideFeelRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'rpe'), 'Required key "SaveRideFeelRequest[rpe]" is missing from JSON.');
        assert(json[r'rpe'] != null, 'Required key "SaveRideFeelRequest[rpe]" has a null value in JSON.');
        return true;
      }());

      return SaveRideFeelRequest(
        rpe: mapValueOfType<int>(json, r'rpe')!,
        notes: json.containsKey(r'notes') ? Optional.present(mapValueOfType<String>(json, r'notes')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<SaveRideFeelRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SaveRideFeelRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SaveRideFeelRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SaveRideFeelRequest> mapFromJson(dynamic json) {
    final map = <String, SaveRideFeelRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SaveRideFeelRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SaveRideFeelRequest-objects as value to a dart map
  static Map<String, List<SaveRideFeelRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SaveRideFeelRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SaveRideFeelRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'rpe',
  };
}

