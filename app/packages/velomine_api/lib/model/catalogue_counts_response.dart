//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class CatalogueCountsResponse {
  /// Returns a new [CatalogueCountsResponse] instance.
  CatalogueCountsResponse({
    required this.pending,
    required this.sent,
    required this.rejected,
    required this.failed,
  });

  final int pending;

  final int sent;

  final int rejected;

  final int failed;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CatalogueCountsResponse &&
    other.pending == pending &&
    other.sent == sent &&
    other.rejected == rejected &&
    other.failed == failed;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (pending.hashCode) +
    (sent.hashCode) +
    (rejected.hashCode) +
    (failed.hashCode);

  @override
  String toString() => 'CatalogueCountsResponse[pending=$pending, sent=$sent, rejected=$rejected, failed=$failed]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'pending'] = this.pending;
      json[r'sent'] = this.sent;
      json[r'rejected'] = this.rejected;
      json[r'failed'] = this.failed;
    return json;
  }

  /// Clones this instance of [CatalogueCountsResponse] and returns a new one where some of the
  /// properties have changed.
  CatalogueCountsResponse copyWith({
    int? pending,
    int? sent,
    int? rejected,
    int? failed,
  }) => CatalogueCountsResponse(
    pending: pending ?? this.pending,
    sent: sent ?? this.sent,
    rejected: rejected ?? this.rejected,
    failed: failed ?? this.failed,
  );

  /// Returns a new [CatalogueCountsResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CatalogueCountsResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'pending'), 'Required key "CatalogueCountsResponse[pending]" is missing from JSON.');
        assert(json[r'pending'] != null, 'Required key "CatalogueCountsResponse[pending]" has a null value in JSON.');
        assert(json.containsKey(r'sent'), 'Required key "CatalogueCountsResponse[sent]" is missing from JSON.');
        assert(json[r'sent'] != null, 'Required key "CatalogueCountsResponse[sent]" has a null value in JSON.');
        assert(json.containsKey(r'rejected'), 'Required key "CatalogueCountsResponse[rejected]" is missing from JSON.');
        assert(json[r'rejected'] != null, 'Required key "CatalogueCountsResponse[rejected]" has a null value in JSON.');
        assert(json.containsKey(r'failed'), 'Required key "CatalogueCountsResponse[failed]" is missing from JSON.');
        assert(json[r'failed'] != null, 'Required key "CatalogueCountsResponse[failed]" has a null value in JSON.');
        return true;
      }());

      return CatalogueCountsResponse(
        pending: mapValueOfType<int>(json, r'pending')!,
        sent: mapValueOfType<int>(json, r'sent')!,
        rejected: mapValueOfType<int>(json, r'rejected')!,
        failed: mapValueOfType<int>(json, r'failed')!,
      );
    }
    return null;
  }

  static List<CatalogueCountsResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CatalogueCountsResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CatalogueCountsResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CatalogueCountsResponse> mapFromJson(dynamic json) {
    final map = <String, CatalogueCountsResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CatalogueCountsResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CatalogueCountsResponse-objects as value to a dart map
  static Map<String, List<CatalogueCountsResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CatalogueCountsResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CatalogueCountsResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'pending',
    'sent',
    'rejected',
    'failed',
  };
}

