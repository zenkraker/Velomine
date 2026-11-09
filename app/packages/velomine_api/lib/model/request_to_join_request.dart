//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class RequestToJoinRequest {
  /// Returns a new [RequestToJoinRequest] instance.
  RequestToJoinRequest({
    required this.clubId,
    this.note = const Optional.absent(),
  });

  final String clubId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> note;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RequestToJoinRequest &&
    other.clubId == clubId &&
    other.note == note;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (clubId.hashCode) +
    (note == null ? 0 : note!.hashCode);

  @override
  String toString() => 'RequestToJoinRequest[clubId=$clubId, note=$note]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'clubId'] = this.clubId;
    if (this.note.isPresent) {
      final value = this.note.value;
      json[r'note'] = value;
    }
    return json;
  }

  /// Clones this instance of [RequestToJoinRequest] and returns a new one where some of the
  /// properties have changed.
  RequestToJoinRequest copyWith({
    String? clubId,
    Optional<String?>? note,
  }) => RequestToJoinRequest(
    clubId: clubId ?? this.clubId,
    note: note ?? this.note,
  );

  /// Returns a new [RequestToJoinRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RequestToJoinRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'clubId'), 'Required key "RequestToJoinRequest[clubId]" is missing from JSON.');
        assert(json[r'clubId'] != null, 'Required key "RequestToJoinRequest[clubId]" has a null value in JSON.');
        return true;
      }());

      return RequestToJoinRequest(
        clubId: mapValueOfType<String>(json, r'clubId')!,
        note: json.containsKey(r'note') ? Optional.present(mapValueOfType<String>(json, r'note')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<RequestToJoinRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RequestToJoinRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RequestToJoinRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RequestToJoinRequest> mapFromJson(dynamic json) {
    final map = <String, RequestToJoinRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RequestToJoinRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RequestToJoinRequest-objects as value to a dart map
  static Map<String, List<RequestToJoinRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RequestToJoinRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RequestToJoinRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'clubId',
  };
}

