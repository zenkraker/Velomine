//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class AdminClubResponse {
  /// Returns a new [AdminClubResponse] instance.
  AdminClubResponse({
    required this.id,
    required this.name,
    required this.joinCode,
    required this.isActive,
    required this.createdAt,
    required this.memberCount,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerRole,
  });

  final String id;

  final String name;

  final String joinCode;

  final bool isActive;

  final DateTime createdAt;

  final int memberCount;

  final String? ownerId;

  final String? ownerName;

  final String? ownerEmail;

  final String? ownerRole;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdminClubResponse &&
    other.id == id &&
    other.name == name &&
    other.joinCode == joinCode &&
    other.isActive == isActive &&
    other.createdAt == createdAt &&
    other.memberCount == memberCount &&
    other.ownerId == ownerId &&
    other.ownerName == ownerName &&
    other.ownerEmail == ownerEmail &&
    other.ownerRole == ownerRole;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (joinCode.hashCode) +
    (isActive.hashCode) +
    (createdAt.hashCode) +
    (memberCount.hashCode) +
    (ownerId == null ? 0 : ownerId!.hashCode) +
    (ownerName == null ? 0 : ownerName!.hashCode) +
    (ownerEmail == null ? 0 : ownerEmail!.hashCode) +
    (ownerRole == null ? 0 : ownerRole!.hashCode);

  @override
  String toString() => 'AdminClubResponse[id=$id, name=$name, joinCode=$joinCode, isActive=$isActive, createdAt=$createdAt, memberCount=$memberCount, ownerId=$ownerId, ownerName=$ownerName, ownerEmail=$ownerEmail, ownerRole=$ownerRole]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'joinCode'] = this.joinCode;
      json[r'isActive'] = this.isActive;
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
      json[r'memberCount'] = this.memberCount;
    if (this.ownerId != null) {
      json[r'ownerId'] = this.ownerId;
    } else {
      json[r'ownerId'] = null;
    }
    if (this.ownerName != null) {
      json[r'ownerName'] = this.ownerName;
    } else {
      json[r'ownerName'] = null;
    }
    if (this.ownerEmail != null) {
      json[r'ownerEmail'] = this.ownerEmail;
    } else {
      json[r'ownerEmail'] = null;
    }
    if (this.ownerRole != null) {
      json[r'ownerRole'] = this.ownerRole;
    } else {
      json[r'ownerRole'] = null;
    }
    return json;
  }

  /// Clones this instance of [AdminClubResponse] and returns a new one where some of the
  /// properties have changed.
  AdminClubResponse copyWith({
    String? id,
    String? name,
    String? joinCode,
    bool? isActive,
    DateTime? createdAt,
    int? memberCount,
    String? ownerId,
    bool ownerIdSetToNull = false,
    String? ownerName,
    bool ownerNameSetToNull = false,
    String? ownerEmail,
    bool ownerEmailSetToNull = false,
    String? ownerRole,
    bool ownerRoleSetToNull = false,
  }) => AdminClubResponse(
    id: id ?? this.id,
    name: name ?? this.name,
    joinCode: joinCode ?? this.joinCode,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    memberCount: memberCount ?? this.memberCount,
    ownerId: ownerIdSetToNull ? null : ownerId ?? this.ownerId,
    ownerName: ownerNameSetToNull ? null : ownerName ?? this.ownerName,
    ownerEmail: ownerEmailSetToNull ? null : ownerEmail ?? this.ownerEmail,
    ownerRole: ownerRoleSetToNull ? null : ownerRole ?? this.ownerRole,
  );

  /// Returns a new [AdminClubResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminClubResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "AdminClubResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "AdminClubResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "AdminClubResponse[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "AdminClubResponse[name]" has a null value in JSON.');
        assert(json.containsKey(r'joinCode'), 'Required key "AdminClubResponse[joinCode]" is missing from JSON.');
        assert(json[r'joinCode'] != null, 'Required key "AdminClubResponse[joinCode]" has a null value in JSON.');
        assert(json.containsKey(r'isActive'), 'Required key "AdminClubResponse[isActive]" is missing from JSON.');
        assert(json[r'isActive'] != null, 'Required key "AdminClubResponse[isActive]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "AdminClubResponse[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "AdminClubResponse[createdAt]" has a null value in JSON.');
        assert(json.containsKey(r'memberCount'), 'Required key "AdminClubResponse[memberCount]" is missing from JSON.');
        assert(json[r'memberCount'] != null, 'Required key "AdminClubResponse[memberCount]" has a null value in JSON.');
        assert(json.containsKey(r'ownerId'), 'Required key "AdminClubResponse[ownerId]" is missing from JSON.');
        assert(json.containsKey(r'ownerName'), 'Required key "AdminClubResponse[ownerName]" is missing from JSON.');
        assert(json.containsKey(r'ownerEmail'), 'Required key "AdminClubResponse[ownerEmail]" is missing from JSON.');
        assert(json.containsKey(r'ownerRole'), 'Required key "AdminClubResponse[ownerRole]" is missing from JSON.');
        return true;
      }());

      return AdminClubResponse(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        joinCode: mapValueOfType<String>(json, r'joinCode')!,
        isActive: mapValueOfType<bool>(json, r'isActive')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        memberCount: mapValueOfType<int>(json, r'memberCount')!,
        ownerId: mapValueOfType<String>(json, r'ownerId'),
        ownerName: mapValueOfType<String>(json, r'ownerName'),
        ownerEmail: mapValueOfType<String>(json, r'ownerEmail'),
        ownerRole: mapValueOfType<String>(json, r'ownerRole'),
      );
    }
    return null;
  }

  static List<AdminClubResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminClubResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminClubResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminClubResponse> mapFromJson(dynamic json) {
    final map = <String, AdminClubResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminClubResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminClubResponse-objects as value to a dart map
  static Map<String, List<AdminClubResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdminClubResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminClubResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'joinCode',
    'isActive',
    'createdAt',
    'memberCount',
    'ownerId',
    'ownerName',
    'ownerEmail',
    'ownerRole',
  };
}

