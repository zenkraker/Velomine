//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class FtpSuggestionResponse {
  /// Returns a new [FtpSuggestionResponse] instance.
  FtpSuggestionResponse({
    required this.id,
    required this.rideId,
    required this.watts,
    required this.method,
    required this.effortWatts,
    required this.createdAt,
  });

  final String id;

  final String rideId;

  final int watts;

  final String method;

  final int effortWatts;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FtpSuggestionResponse &&
    other.id == id &&
    other.rideId == rideId &&
    other.watts == watts &&
    other.method == method &&
    other.effortWatts == effortWatts &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (rideId.hashCode) +
    (watts.hashCode) +
    (method.hashCode) +
    (effortWatts.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'FtpSuggestionResponse[id=$id, rideId=$rideId, watts=$watts, method=$method, effortWatts=$effortWatts, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'rideId'] = this.rideId;
      json[r'watts'] = this.watts;
      json[r'method'] = this.method;
      json[r'effortWatts'] = this.effortWatts;
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [FtpSuggestionResponse] and returns a new one where some of the
  /// properties have changed.
  FtpSuggestionResponse copyWith({
    String? id,
    String? rideId,
    int? watts,
    String? method,
    int? effortWatts,
    DateTime? createdAt,
  }) => FtpSuggestionResponse(
    id: id ?? this.id,
    rideId: rideId ?? this.rideId,
    watts: watts ?? this.watts,
    method: method ?? this.method,
    effortWatts: effortWatts ?? this.effortWatts,
    createdAt: createdAt ?? this.createdAt,
  );

  /// Returns a new [FtpSuggestionResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FtpSuggestionResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "FtpSuggestionResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "FtpSuggestionResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'rideId'), 'Required key "FtpSuggestionResponse[rideId]" is missing from JSON.');
        assert(json[r'rideId'] != null, 'Required key "FtpSuggestionResponse[rideId]" has a null value in JSON.');
        assert(json.containsKey(r'watts'), 'Required key "FtpSuggestionResponse[watts]" is missing from JSON.');
        assert(json[r'watts'] != null, 'Required key "FtpSuggestionResponse[watts]" has a null value in JSON.');
        assert(json.containsKey(r'method'), 'Required key "FtpSuggestionResponse[method]" is missing from JSON.');
        assert(json[r'method'] != null, 'Required key "FtpSuggestionResponse[method]" has a null value in JSON.');
        assert(json.containsKey(r'effortWatts'), 'Required key "FtpSuggestionResponse[effortWatts]" is missing from JSON.');
        assert(json[r'effortWatts'] != null, 'Required key "FtpSuggestionResponse[effortWatts]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "FtpSuggestionResponse[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "FtpSuggestionResponse[createdAt]" has a null value in JSON.');
        return true;
      }());

      return FtpSuggestionResponse(
        id: mapValueOfType<String>(json, r'id')!,
        rideId: mapValueOfType<String>(json, r'rideId')!,
        watts: mapValueOfType<int>(json, r'watts')!,
        method: mapValueOfType<String>(json, r'method')!,
        effortWatts: mapValueOfType<int>(json, r'effortWatts')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<FtpSuggestionResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FtpSuggestionResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FtpSuggestionResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FtpSuggestionResponse> mapFromJson(dynamic json) {
    final map = <String, FtpSuggestionResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FtpSuggestionResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FtpSuggestionResponse-objects as value to a dart map
  static Map<String, List<FtpSuggestionResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FtpSuggestionResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FtpSuggestionResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'rideId',
    'watts',
    'method',
    'effortWatts',
    'createdAt',
  };
}

