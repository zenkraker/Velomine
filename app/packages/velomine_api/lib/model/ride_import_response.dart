//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class RideImportResponse {
  /// Returns a new [RideImportResponse] instance.
  RideImportResponse({
    required this.id,
    required this.status,
    required this.total,
    required this.imported,
    required this.duplicates,
    required this.failed,
    required this.skipped,
    required this.pending,
    required this.createdAt,
    required this.finishedAt,
    required this.error,
  });

  final String id;

  final String status;

  final int total;

  final int imported;

  final int duplicates;

  final int failed;

  final int skipped;

  final int pending;

  final DateTime createdAt;

  final DateTime? finishedAt;

  final String? error;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RideImportResponse &&
    other.id == id &&
    other.status == status &&
    other.total == total &&
    other.imported == imported &&
    other.duplicates == duplicates &&
    other.failed == failed &&
    other.skipped == skipped &&
    other.pending == pending &&
    other.createdAt == createdAt &&
    other.finishedAt == finishedAt &&
    other.error == error;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (status.hashCode) +
    (total.hashCode) +
    (imported.hashCode) +
    (duplicates.hashCode) +
    (failed.hashCode) +
    (skipped.hashCode) +
    (pending.hashCode) +
    (createdAt.hashCode) +
    (finishedAt == null ? 0 : finishedAt!.hashCode) +
    (error == null ? 0 : error!.hashCode);

  @override
  String toString() => 'RideImportResponse[id=$id, status=$status, total=$total, imported=$imported, duplicates=$duplicates, failed=$failed, skipped=$skipped, pending=$pending, createdAt=$createdAt, finishedAt=$finishedAt, error=$error]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'status'] = this.status;
      json[r'total'] = this.total;
      json[r'imported'] = this.imported;
      json[r'duplicates'] = this.duplicates;
      json[r'failed'] = this.failed;
      json[r'skipped'] = this.skipped;
      json[r'pending'] = this.pending;
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    if (this.finishedAt != null) {
      json[r'finishedAt'] = this.finishedAt!.toUtc().toIso8601String();
    } else {
      json[r'finishedAt'] = null;
    }
    if (this.error != null) {
      json[r'error'] = this.error;
    } else {
      json[r'error'] = null;
    }
    return json;
  }

  /// Clones this instance of [RideImportResponse] and returns a new one where some of the
  /// properties have changed.
  RideImportResponse copyWith({
    String? id,
    String? status,
    int? total,
    int? imported,
    int? duplicates,
    int? failed,
    int? skipped,
    int? pending,
    DateTime? createdAt,
    DateTime? finishedAt,
    bool finishedAtSetToNull = false,
    String? error,
    bool errorSetToNull = false,
  }) => RideImportResponse(
    id: id ?? this.id,
    status: status ?? this.status,
    total: total ?? this.total,
    imported: imported ?? this.imported,
    duplicates: duplicates ?? this.duplicates,
    failed: failed ?? this.failed,
    skipped: skipped ?? this.skipped,
    pending: pending ?? this.pending,
    createdAt: createdAt ?? this.createdAt,
    finishedAt: finishedAtSetToNull ? null : finishedAt ?? this.finishedAt,
    error: errorSetToNull ? null : error ?? this.error,
  );

  /// Returns a new [RideImportResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RideImportResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "RideImportResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "RideImportResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "RideImportResponse[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "RideImportResponse[status]" has a null value in JSON.');
        assert(json.containsKey(r'total'), 'Required key "RideImportResponse[total]" is missing from JSON.');
        assert(json[r'total'] != null, 'Required key "RideImportResponse[total]" has a null value in JSON.');
        assert(json.containsKey(r'imported'), 'Required key "RideImportResponse[imported]" is missing from JSON.');
        assert(json[r'imported'] != null, 'Required key "RideImportResponse[imported]" has a null value in JSON.');
        assert(json.containsKey(r'duplicates'), 'Required key "RideImportResponse[duplicates]" is missing from JSON.');
        assert(json[r'duplicates'] != null, 'Required key "RideImportResponse[duplicates]" has a null value in JSON.');
        assert(json.containsKey(r'failed'), 'Required key "RideImportResponse[failed]" is missing from JSON.');
        assert(json[r'failed'] != null, 'Required key "RideImportResponse[failed]" has a null value in JSON.');
        assert(json.containsKey(r'skipped'), 'Required key "RideImportResponse[skipped]" is missing from JSON.');
        assert(json[r'skipped'] != null, 'Required key "RideImportResponse[skipped]" has a null value in JSON.');
        assert(json.containsKey(r'pending'), 'Required key "RideImportResponse[pending]" is missing from JSON.');
        assert(json[r'pending'] != null, 'Required key "RideImportResponse[pending]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "RideImportResponse[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "RideImportResponse[createdAt]" has a null value in JSON.');
        assert(json.containsKey(r'finishedAt'), 'Required key "RideImportResponse[finishedAt]" is missing from JSON.');
        assert(json.containsKey(r'error'), 'Required key "RideImportResponse[error]" is missing from JSON.');
        return true;
      }());

      return RideImportResponse(
        id: mapValueOfType<String>(json, r'id')!,
        status: mapValueOfType<String>(json, r'status')!,
        total: mapValueOfType<int>(json, r'total')!,
        imported: mapValueOfType<int>(json, r'imported')!,
        duplicates: mapValueOfType<int>(json, r'duplicates')!,
        failed: mapValueOfType<int>(json, r'failed')!,
        skipped: mapValueOfType<int>(json, r'skipped')!,
        pending: mapValueOfType<int>(json, r'pending')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        finishedAt: mapDateTime(json, r'finishedAt', r''),
        error: mapValueOfType<String>(json, r'error'),
      );
    }
    return null;
  }

  static List<RideImportResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RideImportResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RideImportResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RideImportResponse> mapFromJson(dynamic json) {
    final map = <String, RideImportResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RideImportResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RideImportResponse-objects as value to a dart map
  static Map<String, List<RideImportResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RideImportResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RideImportResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'status',
    'total',
    'imported',
    'duplicates',
    'failed',
    'skipped',
    'pending',
    'createdAt',
    'finishedAt',
    'error',
  };
}

