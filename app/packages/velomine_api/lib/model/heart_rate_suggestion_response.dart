//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class HeartRateSuggestionResponse {
  /// Returns a new [HeartRateSuggestionResponse] instance.
  HeartRateSuggestionResponse({
    required this.id,
    required this.rideId,
    required this.kind,
    required this.bpm,
    required this.createdAt,
  });

  final String id;

  final String rideId;

  final String kind;

  final int bpm;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is HeartRateSuggestionResponse &&
    other.id == id &&
    other.rideId == rideId &&
    other.kind == kind &&
    other.bpm == bpm &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (rideId.hashCode) +
    (kind.hashCode) +
    (bpm.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'HeartRateSuggestionResponse[id=$id, rideId=$rideId, kind=$kind, bpm=$bpm, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'rideId'] = this.rideId;
      json[r'kind'] = this.kind;
      json[r'bpm'] = this.bpm;
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [HeartRateSuggestionResponse] and returns a new one where some of the
  /// properties have changed.
  HeartRateSuggestionResponse copyWith({
    String? id,
    String? rideId,
    String? kind,
    int? bpm,
    DateTime? createdAt,
  }) => HeartRateSuggestionResponse(
    id: id ?? this.id,
    rideId: rideId ?? this.rideId,
    kind: kind ?? this.kind,
    bpm: bpm ?? this.bpm,
    createdAt: createdAt ?? this.createdAt,
  );

  /// Returns a new [HeartRateSuggestionResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HeartRateSuggestionResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "HeartRateSuggestionResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "HeartRateSuggestionResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'rideId'), 'Required key "HeartRateSuggestionResponse[rideId]" is missing from JSON.');
        assert(json[r'rideId'] != null, 'Required key "HeartRateSuggestionResponse[rideId]" has a null value in JSON.');
        assert(json.containsKey(r'kind'), 'Required key "HeartRateSuggestionResponse[kind]" is missing from JSON.');
        assert(json[r'kind'] != null, 'Required key "HeartRateSuggestionResponse[kind]" has a null value in JSON.');
        assert(json.containsKey(r'bpm'), 'Required key "HeartRateSuggestionResponse[bpm]" is missing from JSON.');
        assert(json[r'bpm'] != null, 'Required key "HeartRateSuggestionResponse[bpm]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "HeartRateSuggestionResponse[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "HeartRateSuggestionResponse[createdAt]" has a null value in JSON.');
        return true;
      }());

      return HeartRateSuggestionResponse(
        id: mapValueOfType<String>(json, r'id')!,
        rideId: mapValueOfType<String>(json, r'rideId')!,
        kind: mapValueOfType<String>(json, r'kind')!,
        bpm: mapValueOfType<int>(json, r'bpm')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<HeartRateSuggestionResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HeartRateSuggestionResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HeartRateSuggestionResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HeartRateSuggestionResponse> mapFromJson(dynamic json) {
    final map = <String, HeartRateSuggestionResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HeartRateSuggestionResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HeartRateSuggestionResponse-objects as value to a dart map
  static Map<String, List<HeartRateSuggestionResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<HeartRateSuggestionResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HeartRateSuggestionResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'rideId',
    'kind',
    'bpm',
    'createdAt',
  };
}

