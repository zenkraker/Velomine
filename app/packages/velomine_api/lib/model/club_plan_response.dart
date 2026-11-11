//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ClubPlanResponse {
  /// Returns a new [ClubPlanResponse] instance.
  ClubPlanResponse({
    required this.memberCount,
    required this.memberLimit,
    required this.paidUntil,
    required this.blocked,
  });

  final int memberCount;

  final int? memberLimit;

  final DateTime? paidUntil;

  final String? blocked;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ClubPlanResponse &&
    other.memberCount == memberCount &&
    other.memberLimit == memberLimit &&
    other.paidUntil == paidUntil &&
    other.blocked == blocked;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (memberCount.hashCode) +
    (memberLimit == null ? 0 : memberLimit!.hashCode) +
    (paidUntil == null ? 0 : paidUntil!.hashCode) +
    (blocked == null ? 0 : blocked!.hashCode);

  @override
  String toString() => 'ClubPlanResponse[memberCount=$memberCount, memberLimit=$memberLimit, paidUntil=$paidUntil, blocked=$blocked]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'memberCount'] = this.memberCount;
    if (this.memberLimit != null) {
      json[r'memberLimit'] = this.memberLimit;
    } else {
      json[r'memberLimit'] = null;
    }
    if (this.paidUntil != null) {
      json[r'paidUntil'] = _dateFormatter.format(this.paidUntil!);
    } else {
      json[r'paidUntil'] = null;
    }
    if (this.blocked != null) {
      json[r'blocked'] = this.blocked;
    } else {
      json[r'blocked'] = null;
    }
    return json;
  }

  /// Clones this instance of [ClubPlanResponse] and returns a new one where some of the
  /// properties have changed.
  ClubPlanResponse copyWith({
    int? memberCount,
    int? memberLimit,
    bool memberLimitSetToNull = false,
    DateTime? paidUntil,
    bool paidUntilSetToNull = false,
    String? blocked,
    bool blockedSetToNull = false,
  }) => ClubPlanResponse(
    memberCount: memberCount ?? this.memberCount,
    memberLimit: memberLimitSetToNull ? null : memberLimit ?? this.memberLimit,
    paidUntil: paidUntilSetToNull ? null : paidUntil ?? this.paidUntil,
    blocked: blockedSetToNull ? null : blocked ?? this.blocked,
  );

  /// Returns a new [ClubPlanResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ClubPlanResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'memberCount'), 'Required key "ClubPlanResponse[memberCount]" is missing from JSON.');
        assert(json[r'memberCount'] != null, 'Required key "ClubPlanResponse[memberCount]" has a null value in JSON.');
        assert(json.containsKey(r'memberLimit'), 'Required key "ClubPlanResponse[memberLimit]" is missing from JSON.');
        assert(json.containsKey(r'paidUntil'), 'Required key "ClubPlanResponse[paidUntil]" is missing from JSON.');
        assert(json.containsKey(r'blocked'), 'Required key "ClubPlanResponse[blocked]" is missing from JSON.');
        return true;
      }());

      return ClubPlanResponse(
        memberCount: mapValueOfType<int>(json, r'memberCount')!,
        memberLimit: mapValueOfType<int>(json, r'memberLimit'),
        paidUntil: mapDateTime(json, r'paidUntil', r''),
        blocked: mapValueOfType<String>(json, r'blocked'),
      );
    }
    return null;
  }

  static List<ClubPlanResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ClubPlanResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ClubPlanResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ClubPlanResponse> mapFromJson(dynamic json) {
    final map = <String, ClubPlanResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ClubPlanResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ClubPlanResponse-objects as value to a dart map
  static Map<String, List<ClubPlanResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ClubPlanResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ClubPlanResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'memberCount',
    'memberLimit',
    'paidUntil',
    'blocked',
  };
}

