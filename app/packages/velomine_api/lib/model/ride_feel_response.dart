//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class RideFeelResponse {
  /// Returns a new [RideFeelResponse] instance.
  RideFeelResponse({
    required this.consentRequired,
    required this.rpe,
    required this.notes,
  });

  final bool consentRequired;

  final int? rpe;

  final String? notes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RideFeelResponse &&
    other.consentRequired == consentRequired &&
    other.rpe == rpe &&
    other.notes == notes;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (consentRequired.hashCode) +
    (rpe == null ? 0 : rpe!.hashCode) +
    (notes == null ? 0 : notes!.hashCode);

  @override
  String toString() => 'RideFeelResponse[consentRequired=$consentRequired, rpe=$rpe, notes=$notes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'consentRequired'] = this.consentRequired;
    if (this.rpe != null) {
      json[r'rpe'] = this.rpe;
    } else {
      json[r'rpe'] = null;
    }
    if (this.notes != null) {
      json[r'notes'] = this.notes;
    } else {
      json[r'notes'] = null;
    }
    return json;
  }

  /// Clones this instance of [RideFeelResponse] and returns a new one where some of the
  /// properties have changed.
  RideFeelResponse copyWith({
    bool? consentRequired,
    int? rpe,
    bool rpeSetToNull = false,
    String? notes,
    bool notesSetToNull = false,
  }) => RideFeelResponse(
    consentRequired: consentRequired ?? this.consentRequired,
    rpe: rpeSetToNull ? null : rpe ?? this.rpe,
    notes: notesSetToNull ? null : notes ?? this.notes,
  );

  /// Returns a new [RideFeelResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RideFeelResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'consentRequired'), 'Required key "RideFeelResponse[consentRequired]" is missing from JSON.');
        assert(json[r'consentRequired'] != null, 'Required key "RideFeelResponse[consentRequired]" has a null value in JSON.');
        assert(json.containsKey(r'rpe'), 'Required key "RideFeelResponse[rpe]" is missing from JSON.');
        assert(json.containsKey(r'notes'), 'Required key "RideFeelResponse[notes]" is missing from JSON.');
        return true;
      }());

      return RideFeelResponse(
        consentRequired: mapValueOfType<bool>(json, r'consentRequired')!,
        rpe: mapValueOfType<int>(json, r'rpe'),
        notes: mapValueOfType<String>(json, r'notes'),
      );
    }
    return null;
  }

  static List<RideFeelResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RideFeelResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RideFeelResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RideFeelResponse> mapFromJson(dynamic json) {
    final map = <String, RideFeelResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RideFeelResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RideFeelResponse-objects as value to a dart map
  static Map<String, List<RideFeelResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RideFeelResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RideFeelResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'consentRequired',
    'rpe',
    'notes',
  };
}

