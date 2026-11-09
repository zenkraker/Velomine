//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class PendingJoinRequestResponse {
  /// Returns a new [PendingJoinRequestResponse] instance.
  PendingJoinRequestResponse({
    required this.id,
    required this.clubId,
    required this.clubName,
    required this.note,
    required this.createdAt,
  });

  final String id;

  final String clubId;

  final String clubName;

  final String? note;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PendingJoinRequestResponse &&
    other.id == id &&
    other.clubId == clubId &&
    other.clubName == clubName &&
    other.note == note &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (clubId.hashCode) +
    (clubName.hashCode) +
    (note == null ? 0 : note!.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'PendingJoinRequestResponse[id=$id, clubId=$clubId, clubName=$clubName, note=$note, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'clubId'] = this.clubId;
      json[r'clubName'] = this.clubName;
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [PendingJoinRequestResponse] and returns a new one where some of the
  /// properties have changed.
  PendingJoinRequestResponse copyWith({
    String? id,
    String? clubId,
    String? clubName,
    String? note,
    bool noteSetToNull = false,
    DateTime? createdAt,
  }) => PendingJoinRequestResponse(
    id: id ?? this.id,
    clubId: clubId ?? this.clubId,
    clubName: clubName ?? this.clubName,
    note: noteSetToNull ? null : note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
  );

  /// Returns a new [PendingJoinRequestResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PendingJoinRequestResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "PendingJoinRequestResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "PendingJoinRequestResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'clubId'), 'Required key "PendingJoinRequestResponse[clubId]" is missing from JSON.');
        assert(json[r'clubId'] != null, 'Required key "PendingJoinRequestResponse[clubId]" has a null value in JSON.');
        assert(json.containsKey(r'clubName'), 'Required key "PendingJoinRequestResponse[clubName]" is missing from JSON.');
        assert(json[r'clubName'] != null, 'Required key "PendingJoinRequestResponse[clubName]" has a null value in JSON.');
        assert(json.containsKey(r'note'), 'Required key "PendingJoinRequestResponse[note]" is missing from JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "PendingJoinRequestResponse[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "PendingJoinRequestResponse[createdAt]" has a null value in JSON.');
        return true;
      }());

      return PendingJoinRequestResponse(
        id: mapValueOfType<String>(json, r'id')!,
        clubId: mapValueOfType<String>(json, r'clubId')!,
        clubName: mapValueOfType<String>(json, r'clubName')!,
        note: mapValueOfType<String>(json, r'note'),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<PendingJoinRequestResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PendingJoinRequestResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PendingJoinRequestResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PendingJoinRequestResponse> mapFromJson(dynamic json) {
    final map = <String, PendingJoinRequestResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PendingJoinRequestResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PendingJoinRequestResponse-objects as value to a dart map
  static Map<String, List<PendingJoinRequestResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PendingJoinRequestResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PendingJoinRequestResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'clubId',
    'clubName',
    'note',
    'createdAt',
  };
}

