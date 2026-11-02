//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class UserSummary {
  /// Returns a new [UserSummary] instance.
  UserSummary({
    required this.id,
    required this.email,
    required this.displayName,
    required this.isApproved,
    required this.createdAt,
  });

  final String id;

  final String email;

  final String displayName;

  final bool isApproved;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UserSummary &&
    other.id == id &&
    other.email == email &&
    other.displayName == displayName &&
    other.isApproved == isApproved &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (email.hashCode) +
    (displayName.hashCode) +
    (isApproved.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'UserSummary[id=$id, email=$email, displayName=$displayName, isApproved=$isApproved, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'email'] = this.email;
      json[r'displayName'] = this.displayName;
      json[r'isApproved'] = this.isApproved;
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [UserSummary] and returns a new one where some of the
  /// properties have changed.
  UserSummary copyWith({
    String? id,
    String? email,
    String? displayName,
    bool? isApproved,
    DateTime? createdAt,
  }) => UserSummary(
    id: id ?? this.id,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    isApproved: isApproved ?? this.isApproved,
    createdAt: createdAt ?? this.createdAt,
  );

  /// Returns a new [UserSummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UserSummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "UserSummary[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "UserSummary[id]" has a null value in JSON.');
        assert(json.containsKey(r'email'), 'Required key "UserSummary[email]" is missing from JSON.');
        assert(json[r'email'] != null, 'Required key "UserSummary[email]" has a null value in JSON.');
        assert(json.containsKey(r'displayName'), 'Required key "UserSummary[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null, 'Required key "UserSummary[displayName]" has a null value in JSON.');
        assert(json.containsKey(r'isApproved'), 'Required key "UserSummary[isApproved]" is missing from JSON.');
        assert(json[r'isApproved'] != null, 'Required key "UserSummary[isApproved]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "UserSummary[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "UserSummary[createdAt]" has a null value in JSON.');
        return true;
      }());

      return UserSummary(
        id: mapValueOfType<String>(json, r'id')!,
        email: mapValueOfType<String>(json, r'email')!,
        displayName: mapValueOfType<String>(json, r'displayName')!,
        isApproved: mapValueOfType<bool>(json, r'isApproved')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<UserSummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UserSummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserSummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UserSummary> mapFromJson(dynamic json) {
    final map = <String, UserSummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UserSummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UserSummary-objects as value to a dart map
  static Map<String, List<UserSummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UserSummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UserSummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'email',
    'displayName',
    'isApproved',
    'createdAt',
  };
}

