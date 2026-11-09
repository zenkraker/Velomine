//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class CatalogueAdminResponse {
  /// Returns a new [CatalogueAdminResponse] instance.
  CatalogueAdminResponse({
    required this.contributionEndpointConfigured,
    required this.contributionKeyConfigured,
    required this.syncedAt,
    required this.contributions,
    this.problems = const [],
  });

  final bool contributionEndpointConfigured;

  final bool contributionKeyConfigured;

  final DateTime? syncedAt;

  final CatalogueCountsResponse contributions;

  final List<CatalogueContributionResponse> problems;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CatalogueAdminResponse &&
    other.contributionEndpointConfigured == contributionEndpointConfigured &&
    other.contributionKeyConfigured == contributionKeyConfigured &&
    other.syncedAt == syncedAt &&
    other.contributions == contributions &&
    _deepEquality.equals(other.problems, problems);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (contributionEndpointConfigured.hashCode) +
    (contributionKeyConfigured.hashCode) +
    (syncedAt == null ? 0 : syncedAt!.hashCode) +
    (contributions.hashCode) +
    (problems.hashCode);

  @override
  String toString() => 'CatalogueAdminResponse[contributionEndpointConfigured=$contributionEndpointConfigured, contributionKeyConfigured=$contributionKeyConfigured, syncedAt=$syncedAt, contributions=$contributions, problems=$problems]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'contributionEndpointConfigured'] = this.contributionEndpointConfigured;
      json[r'contributionKeyConfigured'] = this.contributionKeyConfigured;
    if (this.syncedAt != null) {
      json[r'syncedAt'] = this.syncedAt!.toUtc().toIso8601String();
    } else {
      json[r'syncedAt'] = null;
    }
      json[r'contributions'] = this.contributions;
      json[r'problems'] = this.problems;
    return json;
  }

  /// Clones this instance of [CatalogueAdminResponse] and returns a new one where some of the
  /// properties have changed.
  CatalogueAdminResponse copyWith({
    bool? contributionEndpointConfigured,
    bool? contributionKeyConfigured,
    DateTime? syncedAt,
    bool syncedAtSetToNull = false,
    CatalogueCountsResponse? contributions,
    List<CatalogueContributionResponse>? problems,
  }) => CatalogueAdminResponse(
    contributionEndpointConfigured: contributionEndpointConfigured ?? this.contributionEndpointConfigured,
    contributionKeyConfigured: contributionKeyConfigured ?? this.contributionKeyConfigured,
    syncedAt: syncedAtSetToNull ? null : syncedAt ?? this.syncedAt,
    contributions: contributions ?? this.contributions,
    problems: problems ?? this.problems,
  );

  /// Returns a new [CatalogueAdminResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CatalogueAdminResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'contributionEndpointConfigured'), 'Required key "CatalogueAdminResponse[contributionEndpointConfigured]" is missing from JSON.');
        assert(json[r'contributionEndpointConfigured'] != null, 'Required key "CatalogueAdminResponse[contributionEndpointConfigured]" has a null value in JSON.');
        assert(json.containsKey(r'contributionKeyConfigured'), 'Required key "CatalogueAdminResponse[contributionKeyConfigured]" is missing from JSON.');
        assert(json[r'contributionKeyConfigured'] != null, 'Required key "CatalogueAdminResponse[contributionKeyConfigured]" has a null value in JSON.');
        assert(json.containsKey(r'syncedAt'), 'Required key "CatalogueAdminResponse[syncedAt]" is missing from JSON.');
        assert(json.containsKey(r'contributions'), 'Required key "CatalogueAdminResponse[contributions]" is missing from JSON.');
        assert(json[r'contributions'] != null, 'Required key "CatalogueAdminResponse[contributions]" has a null value in JSON.');
        assert(json.containsKey(r'problems'), 'Required key "CatalogueAdminResponse[problems]" is missing from JSON.');
        assert(json[r'problems'] != null, 'Required key "CatalogueAdminResponse[problems]" has a null value in JSON.');
        return true;
      }());

      return CatalogueAdminResponse(
        contributionEndpointConfigured: mapValueOfType<bool>(json, r'contributionEndpointConfigured')!,
        contributionKeyConfigured: mapValueOfType<bool>(json, r'contributionKeyConfigured')!,
        syncedAt: mapDateTime(json, r'syncedAt', r''),
        contributions: CatalogueCountsResponse.fromJson(json[r'contributions'])!,
        problems: CatalogueContributionResponse.listFromJson(json[r'problems']),
      );
    }
    return null;
  }

  static List<CatalogueAdminResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CatalogueAdminResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CatalogueAdminResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CatalogueAdminResponse> mapFromJson(dynamic json) {
    final map = <String, CatalogueAdminResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CatalogueAdminResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CatalogueAdminResponse-objects as value to a dart map
  static Map<String, List<CatalogueAdminResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CatalogueAdminResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CatalogueAdminResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'contributionEndpointConfigured',
    'contributionKeyConfigured',
    'syncedAt',
    'contributions',
    'problems',
  };
}

