//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class RouteSummaryResponse {
  /// Returns a new [RouteSummaryResponse] instance.
  RouteSummaryResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.surface,
    required this.distanceM,
    required this.climbingM,
    required this.ownerId,
    required this.ownerName,
    required this.createdAt,
    required this.isMine,
    required this.isShared,
  });

  final String id;

  final String name;

  final String? description;

  final String surface;

  final double distanceM;

  final double? climbingM;

  final String ownerId;

  final String ownerName;

  final DateTime createdAt;

  final bool isMine;

  final bool isShared;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RouteSummaryResponse &&
    other.id == id &&
    other.name == name &&
    other.description == description &&
    other.surface == surface &&
    other.distanceM == distanceM &&
    other.climbingM == climbingM &&
    other.ownerId == ownerId &&
    other.ownerName == ownerName &&
    other.createdAt == createdAt &&
    other.isMine == isMine &&
    other.isShared == isShared;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (surface.hashCode) +
    (distanceM.hashCode) +
    (climbingM == null ? 0 : climbingM!.hashCode) +
    (ownerId.hashCode) +
    (ownerName.hashCode) +
    (createdAt.hashCode) +
    (isMine.hashCode) +
    (isShared.hashCode);

  @override
  String toString() => 'RouteSummaryResponse[id=$id, name=$name, description=$description, surface=$surface, distanceM=$distanceM, climbingM=$climbingM, ownerId=$ownerId, ownerName=$ownerName, createdAt=$createdAt, isMine=$isMine, isShared=$isShared]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
      json[r'surface'] = this.surface;
      json[r'distanceM'] = this.distanceM;
    if (this.climbingM != null) {
      json[r'climbingM'] = this.climbingM;
    } else {
      json[r'climbingM'] = null;
    }
      json[r'ownerId'] = this.ownerId;
      json[r'ownerName'] = this.ownerName;
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
      json[r'isMine'] = this.isMine;
      json[r'isShared'] = this.isShared;
    return json;
  }

  /// Clones this instance of [RouteSummaryResponse] and returns a new one where some of the
  /// properties have changed.
  RouteSummaryResponse copyWith({
    String? id,
    String? name,
    String? description,
    bool descriptionSetToNull = false,
    String? surface,
    double? distanceM,
    double? climbingM,
    bool climbingMSetToNull = false,
    String? ownerId,
    String? ownerName,
    DateTime? createdAt,
    bool? isMine,
    bool? isShared,
  }) => RouteSummaryResponse(
    id: id ?? this.id,
    name: name ?? this.name,
    description: descriptionSetToNull ? null : description ?? this.description,
    surface: surface ?? this.surface,
    distanceM: distanceM ?? this.distanceM,
    climbingM: climbingMSetToNull ? null : climbingM ?? this.climbingM,
    ownerId: ownerId ?? this.ownerId,
    ownerName: ownerName ?? this.ownerName,
    createdAt: createdAt ?? this.createdAt,
    isMine: isMine ?? this.isMine,
    isShared: isShared ?? this.isShared,
  );

  /// Returns a new [RouteSummaryResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RouteSummaryResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "RouteSummaryResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "RouteSummaryResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "RouteSummaryResponse[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "RouteSummaryResponse[name]" has a null value in JSON.');
        assert(json.containsKey(r'description'), 'Required key "RouteSummaryResponse[description]" is missing from JSON.');
        assert(json.containsKey(r'surface'), 'Required key "RouteSummaryResponse[surface]" is missing from JSON.');
        assert(json[r'surface'] != null, 'Required key "RouteSummaryResponse[surface]" has a null value in JSON.');
        assert(json.containsKey(r'distanceM'), 'Required key "RouteSummaryResponse[distanceM]" is missing from JSON.');
        assert(json[r'distanceM'] != null, 'Required key "RouteSummaryResponse[distanceM]" has a null value in JSON.');
        assert(json.containsKey(r'climbingM'), 'Required key "RouteSummaryResponse[climbingM]" is missing from JSON.');
        assert(json.containsKey(r'ownerId'), 'Required key "RouteSummaryResponse[ownerId]" is missing from JSON.');
        assert(json[r'ownerId'] != null, 'Required key "RouteSummaryResponse[ownerId]" has a null value in JSON.');
        assert(json.containsKey(r'ownerName'), 'Required key "RouteSummaryResponse[ownerName]" is missing from JSON.');
        assert(json[r'ownerName'] != null, 'Required key "RouteSummaryResponse[ownerName]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "RouteSummaryResponse[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "RouteSummaryResponse[createdAt]" has a null value in JSON.');
        assert(json.containsKey(r'isMine'), 'Required key "RouteSummaryResponse[isMine]" is missing from JSON.');
        assert(json[r'isMine'] != null, 'Required key "RouteSummaryResponse[isMine]" has a null value in JSON.');
        assert(json.containsKey(r'isShared'), 'Required key "RouteSummaryResponse[isShared]" is missing from JSON.');
        assert(json[r'isShared'] != null, 'Required key "RouteSummaryResponse[isShared]" has a null value in JSON.');
        return true;
      }());

      return RouteSummaryResponse(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description'),
        surface: mapValueOfType<String>(json, r'surface')!,
        distanceM: mapValueOfType<double>(json, r'distanceM')!,
        climbingM: mapValueOfType<double>(json, r'climbingM'),
        ownerId: mapValueOfType<String>(json, r'ownerId')!,
        ownerName: mapValueOfType<String>(json, r'ownerName')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        isMine: mapValueOfType<bool>(json, r'isMine')!,
        isShared: mapValueOfType<bool>(json, r'isShared')!,
      );
    }
    return null;
  }

  static List<RouteSummaryResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RouteSummaryResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RouteSummaryResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RouteSummaryResponse> mapFromJson(dynamic json) {
    final map = <String, RouteSummaryResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RouteSummaryResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RouteSummaryResponse-objects as value to a dart map
  static Map<String, List<RouteSummaryResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RouteSummaryResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RouteSummaryResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'description',
    'surface',
    'distanceM',
    'climbingM',
    'ownerId',
    'ownerName',
    'createdAt',
    'isMine',
    'isShared',
  };
}

