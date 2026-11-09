//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class JoinRequestResponse {
  /// Returns a new [JoinRequestResponse] instance.
  JoinRequestResponse({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.note,
    required this.createdAt,
  });

  final String id;

  final String userId;

  final String displayName;

  final String? note;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is JoinRequestResponse &&
    other.id == id &&
    other.userId == userId &&
    other.displayName == displayName &&
    other.note == note &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (userId.hashCode) +
    (displayName.hashCode) +
    (note == null ? 0 : note!.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'JoinRequestResponse[id=$id, userId=$userId, displayName=$displayName, note=$note, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'userId'] = this.userId;
      json[r'displayName'] = this.displayName;
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [JoinRequestResponse] and returns a new one where some of the
  /// properties have changed.
  JoinRequestResponse copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? note,
    bool noteSetToNull = false,
    DateTime? createdAt,
  }) => JoinRequestResponse(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    displayName: displayName ?? this.displayName,
    note: noteSetToNull ? null : note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
  );

  /// Returns a new [JoinRequestResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static JoinRequestResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "JoinRequestResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "JoinRequestResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'userId'), 'Required key "JoinRequestResponse[userId]" is missing from JSON.');
        assert(json[r'userId'] != null, 'Required key "JoinRequestResponse[userId]" has a null value in JSON.');
        assert(json.containsKey(r'displayName'), 'Required key "JoinRequestResponse[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null, 'Required key "JoinRequestResponse[displayName]" has a null value in JSON.');
        assert(json.containsKey(r'note'), 'Required key "JoinRequestResponse[note]" is missing from JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "JoinRequestResponse[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "JoinRequestResponse[createdAt]" has a null value in JSON.');
        return true;
      }());

      return JoinRequestResponse(
        id: mapValueOfType<String>(json, r'id')!,
        userId: mapValueOfType<String>(json, r'userId')!,
        displayName: mapValueOfType<String>(json, r'displayName')!,
        note: mapValueOfType<String>(json, r'note'),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<JoinRequestResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <JoinRequestResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = JoinRequestResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, JoinRequestResponse> mapFromJson(dynamic json) {
    final map = <String, JoinRequestResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = JoinRequestResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of JoinRequestResponse-objects as value to a dart map
  static Map<String, List<JoinRequestResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<JoinRequestResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = JoinRequestResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'userId',
    'displayName',
    'note',
    'createdAt',
  };
}

