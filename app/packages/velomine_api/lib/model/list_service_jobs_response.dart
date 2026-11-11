//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ListServiceJobsResponse {
  /// Returns a new [ListServiceJobsResponse] instance.
  ListServiceJobsResponse({
    this.jobs = const [],
  });

  final List<MaintenanceJob> jobs;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ListServiceJobsResponse &&
    _deepEquality.equals(other.jobs, jobs);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (jobs.hashCode);

  @override
  String toString() => 'ListServiceJobsResponse[jobs=$jobs]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'jobs'] = this.jobs;
    return json;
  }

  /// Clones this instance of [ListServiceJobsResponse] and returns a new one where some of the
  /// properties have changed.
  ListServiceJobsResponse copyWith({
    List<MaintenanceJob>? jobs,
  }) => ListServiceJobsResponse(
    jobs: jobs ?? this.jobs,
  );

  /// Returns a new [ListServiceJobsResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ListServiceJobsResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'jobs'), 'Required key "ListServiceJobsResponse[jobs]" is missing from JSON.');
        assert(json[r'jobs'] != null, 'Required key "ListServiceJobsResponse[jobs]" has a null value in JSON.');
        return true;
      }());

      return ListServiceJobsResponse(
        jobs: MaintenanceJob.listFromJson(json[r'jobs']),
      );
    }
    return null;
  }

  static List<ListServiceJobsResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListServiceJobsResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListServiceJobsResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ListServiceJobsResponse> mapFromJson(dynamic json) {
    final map = <String, ListServiceJobsResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ListServiceJobsResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ListServiceJobsResponse-objects as value to a dart map
  static Map<String, List<ListServiceJobsResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ListServiceJobsResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ListServiceJobsResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'jobs',
  };
}

