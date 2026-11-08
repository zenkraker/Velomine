//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ClubMemberResponse {
  /// Returns a new [ClubMemberResponse] instance.
  ClubMemberResponse({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  final String userId;

  final String displayName;

  final String role;

  final DateTime joinedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ClubMemberResponse &&
    other.userId == userId &&
    other.displayName == displayName &&
    other.role == role &&
    other.joinedAt == joinedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (userId.hashCode) +
    (displayName.hashCode) +
    (role.hashCode) +
    (joinedAt.hashCode);

  @override
  String toString() => 'ClubMemberResponse[userId=$userId, displayName=$displayName, role=$role, joinedAt=$joinedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'userId'] = this.userId;
      json[r'displayName'] = this.displayName;
      json[r'role'] = this.role;
      json[r'joinedAt'] = this.joinedAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [ClubMemberResponse] and returns a new one where some of the
  /// properties have changed.
  ClubMemberResponse copyWith({
    String? userId,
    String? displayName,
    String? role,
    DateTime? joinedAt,
  }) => ClubMemberResponse(
    userId: userId ?? this.userId,
    displayName: displayName ?? this.displayName,
    role: role ?? this.role,
    joinedAt: joinedAt ?? this.joinedAt,
  );

  /// Returns a new [ClubMemberResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ClubMemberResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'userId'), 'Required key "ClubMemberResponse[userId]" is missing from JSON.');
        assert(json[r'userId'] != null, 'Required key "ClubMemberResponse[userId]" has a null value in JSON.');
        assert(json.containsKey(r'displayName'), 'Required key "ClubMemberResponse[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null, 'Required key "ClubMemberResponse[displayName]" has a null value in JSON.');
        assert(json.containsKey(r'role'), 'Required key "ClubMemberResponse[role]" is missing from JSON.');
        assert(json[r'role'] != null, 'Required key "ClubMemberResponse[role]" has a null value in JSON.');
        assert(json.containsKey(r'joinedAt'), 'Required key "ClubMemberResponse[joinedAt]" is missing from JSON.');
        assert(json[r'joinedAt'] != null, 'Required key "ClubMemberResponse[joinedAt]" has a null value in JSON.');
        return true;
      }());

      return ClubMemberResponse(
        userId: mapValueOfType<String>(json, r'userId')!,
        displayName: mapValueOfType<String>(json, r'displayName')!,
        role: mapValueOfType<String>(json, r'role')!,
        joinedAt: mapDateTime(json, r'joinedAt', r'')!,
      );
    }
    return null;
  }

  static List<ClubMemberResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ClubMemberResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ClubMemberResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ClubMemberResponse> mapFromJson(dynamic json) {
    final map = <String, ClubMemberResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ClubMemberResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ClubMemberResponse-objects as value to a dart map
  static Map<String, List<ClubMemberResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ClubMemberResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ClubMemberResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'userId',
    'displayName',
    'role',
    'joinedAt',
  };
}

