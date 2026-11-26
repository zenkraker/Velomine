//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class MatchTrainingSessionRequest {
  /// Returns a new [MatchTrainingSessionRequest] instance.
  MatchTrainingSessionRequest({
    required this.rideId,
    required this.answer,
  });

  final String rideId;

  final String answer;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MatchTrainingSessionRequest &&
    other.rideId == rideId &&
    other.answer == answer;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (rideId.hashCode) +
    (answer.hashCode);

  @override
  String toString() => 'MatchTrainingSessionRequest[rideId=$rideId, answer=$answer]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'rideId'] = this.rideId;
      json[r'answer'] = this.answer;
    return json;
  }

  /// Clones this instance of [MatchTrainingSessionRequest] and returns a new one where some of the
  /// properties have changed.
  MatchTrainingSessionRequest copyWith({
    String? rideId,
    String? answer,
  }) => MatchTrainingSessionRequest(
    rideId: rideId ?? this.rideId,
    answer: answer ?? this.answer,
  );

  /// Returns a new [MatchTrainingSessionRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MatchTrainingSessionRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'rideId'), 'Required key "MatchTrainingSessionRequest[rideId]" is missing from JSON.');
        assert(json[r'rideId'] != null, 'Required key "MatchTrainingSessionRequest[rideId]" has a null value in JSON.');
        assert(json.containsKey(r'answer'), 'Required key "MatchTrainingSessionRequest[answer]" is missing from JSON.');
        assert(json[r'answer'] != null, 'Required key "MatchTrainingSessionRequest[answer]" has a null value in JSON.');
        return true;
      }());

      return MatchTrainingSessionRequest(
        rideId: mapValueOfType<String>(json, r'rideId')!,
        answer: mapValueOfType<String>(json, r'answer')!,
      );
    }
    return null;
  }

  static List<MatchTrainingSessionRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MatchTrainingSessionRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MatchTrainingSessionRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MatchTrainingSessionRequest> mapFromJson(dynamic json) {
    final map = <String, MatchTrainingSessionRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MatchTrainingSessionRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MatchTrainingSessionRequest-objects as value to a dart map
  static Map<String, List<MatchTrainingSessionRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MatchTrainingSessionRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MatchTrainingSessionRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'rideId',
    'answer',
  };
}

