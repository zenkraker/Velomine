//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SessionResponse {
  /// Returns a new [SessionResponse] instance.
  SessionResponse({
    required this.id,
    required this.label,
    required this.createdAt,
    required this.lastUsedAt,
    required this.current,
  });

  final String id;

  final String label;

  final DateTime createdAt;

  final DateTime lastUsedAt;

  final bool current;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SessionResponse &&
    other.id == id &&
    other.label == label &&
    other.createdAt == createdAt &&
    other.lastUsedAt == lastUsedAt &&
    other.current == current;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (label.hashCode) +
    (createdAt.hashCode) +
    (lastUsedAt.hashCode) +
    (current.hashCode);

  @override
  String toString() => 'SessionResponse[id=$id, label=$label, createdAt=$createdAt, lastUsedAt=$lastUsedAt, current=$current]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'label'] = this.label;
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
      json[r'lastUsedAt'] = this.lastUsedAt.toUtc().toIso8601String();
      json[r'current'] = this.current;
    return json;
  }

  /// Clones this instance of [SessionResponse] and returns a new one where some of the
  /// properties have changed.
  SessionResponse copyWith({
    String? id,
    String? label,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    bool? current,
  }) => SessionResponse(
    id: id ?? this.id,
    label: label ?? this.label,
    createdAt: createdAt ?? this.createdAt,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    current: current ?? this.current,
  );

  /// Returns a new [SessionResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SessionResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "SessionResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "SessionResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'label'), 'Required key "SessionResponse[label]" is missing from JSON.');
        assert(json[r'label'] != null, 'Required key "SessionResponse[label]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "SessionResponse[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "SessionResponse[createdAt]" has a null value in JSON.');
        assert(json.containsKey(r'lastUsedAt'), 'Required key "SessionResponse[lastUsedAt]" is missing from JSON.');
        assert(json[r'lastUsedAt'] != null, 'Required key "SessionResponse[lastUsedAt]" has a null value in JSON.');
        assert(json.containsKey(r'current'), 'Required key "SessionResponse[current]" is missing from JSON.');
        assert(json[r'current'] != null, 'Required key "SessionResponse[current]" has a null value in JSON.');
        return true;
      }());

      return SessionResponse(
        id: mapValueOfType<String>(json, r'id')!,
        label: mapValueOfType<String>(json, r'label')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        lastUsedAt: mapDateTime(json, r'lastUsedAt', r'')!,
        current: mapValueOfType<bool>(json, r'current')!,
      );
    }
    return null;
  }

  static List<SessionResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SessionResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SessionResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SessionResponse> mapFromJson(dynamic json) {
    final map = <String, SessionResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SessionResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SessionResponse-objects as value to a dart map
  static Map<String, List<SessionResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SessionResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SessionResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'label',
    'createdAt',
    'lastUsedAt',
    'current',
  };
}

