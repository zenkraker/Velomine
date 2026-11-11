//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ClubResponse {
  /// Returns a new [ClubResponse] instance.
  ClubResponse({
    required this.id,
    required this.name,
    required this.isActive,
    required this.myRole,
    required this.joinCode,
    required this.latitude,
    required this.longitude,
    required this.isDiscoverable,
    this.members = const [],
    required this.plan,
  });

  final String id;

  final String name;

  final bool isActive;

  final String myRole;

  final String? joinCode;

  final double? latitude;

  final double? longitude;

  final bool isDiscoverable;

  final List<ClubMemberResponse> members;

  final ClubPlanResponse? plan;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ClubResponse &&
    other.id == id &&
    other.name == name &&
    other.isActive == isActive &&
    other.myRole == myRole &&
    other.joinCode == joinCode &&
    other.latitude == latitude &&
    other.longitude == longitude &&
    other.isDiscoverable == isDiscoverable &&
    _deepEquality.equals(other.members, members) &&
    other.plan == plan;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (isActive.hashCode) +
    (myRole.hashCode) +
    (joinCode == null ? 0 : joinCode!.hashCode) +
    (latitude == null ? 0 : latitude!.hashCode) +
    (longitude == null ? 0 : longitude!.hashCode) +
    (isDiscoverable.hashCode) +
    (members.hashCode) +
    (plan == null ? 0 : plan!.hashCode);

  @override
  String toString() => 'ClubResponse[id=$id, name=$name, isActive=$isActive, myRole=$myRole, joinCode=$joinCode, latitude=$latitude, longitude=$longitude, isDiscoverable=$isDiscoverable, members=$members, plan=$plan]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'isActive'] = this.isActive;
      json[r'myRole'] = this.myRole;
    if (this.joinCode != null) {
      json[r'joinCode'] = this.joinCode;
    } else {
      json[r'joinCode'] = null;
    }
    if (this.latitude != null) {
      json[r'latitude'] = this.latitude;
    } else {
      json[r'latitude'] = null;
    }
    if (this.longitude != null) {
      json[r'longitude'] = this.longitude;
    } else {
      json[r'longitude'] = null;
    }
      json[r'isDiscoverable'] = this.isDiscoverable;
      json[r'members'] = this.members;
    if (this.plan != null) {
      json[r'plan'] = this.plan;
    } else {
      json[r'plan'] = null;
    }
    return json;
  }

  /// Clones this instance of [ClubResponse] and returns a new one where some of the
  /// properties have changed.
  ClubResponse copyWith({
    String? id,
    String? name,
    bool? isActive,
    String? myRole,
    String? joinCode,
    bool joinCodeSetToNull = false,
    double? latitude,
    bool latitudeSetToNull = false,
    double? longitude,
    bool longitudeSetToNull = false,
    bool? isDiscoverable,
    List<ClubMemberResponse>? members,
    ClubPlanResponse? plan,
    bool planSetToNull = false,
  }) => ClubResponse(
    id: id ?? this.id,
    name: name ?? this.name,
    isActive: isActive ?? this.isActive,
    myRole: myRole ?? this.myRole,
    joinCode: joinCodeSetToNull ? null : joinCode ?? this.joinCode,
    latitude: latitudeSetToNull ? null : latitude ?? this.latitude,
    longitude: longitudeSetToNull ? null : longitude ?? this.longitude,
    isDiscoverable: isDiscoverable ?? this.isDiscoverable,
    members: members ?? this.members,
    plan: planSetToNull ? null : plan ?? this.plan,
  );

  /// Returns a new [ClubResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ClubResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "ClubResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "ClubResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "ClubResponse[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "ClubResponse[name]" has a null value in JSON.');
        assert(json.containsKey(r'isActive'), 'Required key "ClubResponse[isActive]" is missing from JSON.');
        assert(json[r'isActive'] != null, 'Required key "ClubResponse[isActive]" has a null value in JSON.');
        assert(json.containsKey(r'myRole'), 'Required key "ClubResponse[myRole]" is missing from JSON.');
        assert(json[r'myRole'] != null, 'Required key "ClubResponse[myRole]" has a null value in JSON.');
        assert(json.containsKey(r'joinCode'), 'Required key "ClubResponse[joinCode]" is missing from JSON.');
        assert(json.containsKey(r'latitude'), 'Required key "ClubResponse[latitude]" is missing from JSON.');
        assert(json.containsKey(r'longitude'), 'Required key "ClubResponse[longitude]" is missing from JSON.');
        assert(json.containsKey(r'isDiscoverable'), 'Required key "ClubResponse[isDiscoverable]" is missing from JSON.');
        assert(json[r'isDiscoverable'] != null, 'Required key "ClubResponse[isDiscoverable]" has a null value in JSON.');
        assert(json.containsKey(r'members'), 'Required key "ClubResponse[members]" is missing from JSON.');
        assert(json[r'members'] != null, 'Required key "ClubResponse[members]" has a null value in JSON.');
        assert(json.containsKey(r'plan'), 'Required key "ClubResponse[plan]" is missing from JSON.');
        return true;
      }());

      return ClubResponse(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        isActive: mapValueOfType<bool>(json, r'isActive')!,
        myRole: mapValueOfType<String>(json, r'myRole')!,
        joinCode: mapValueOfType<String>(json, r'joinCode'),
        latitude: mapValueOfType<double>(json, r'latitude'),
        longitude: mapValueOfType<double>(json, r'longitude'),
        isDiscoverable: mapValueOfType<bool>(json, r'isDiscoverable')!,
        members: ClubMemberResponse.listFromJson(json[r'members']),
        plan: ClubPlanResponse.fromJson(json[r'plan']),
      );
    }
    return null;
  }

  static List<ClubResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ClubResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ClubResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ClubResponse> mapFromJson(dynamic json) {
    final map = <String, ClubResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ClubResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ClubResponse-objects as value to a dart map
  static Map<String, List<ClubResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ClubResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ClubResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'isActive',
    'myRole',
    'joinCode',
    'latitude',
    'longitude',
    'isDiscoverable',
    'members',
    'plan',
  };
}

