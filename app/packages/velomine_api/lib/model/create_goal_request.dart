//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class CreateGoalRequest {
  /// Returns a new [CreateGoalRequest] instance.
  CreateGoalRequest({
    required this.period,
    required this.metric,
    required this.target,
  });

  final String period;

  final String metric;

  /// Minimum value: 0
  /// Maximum value: 100000000
  final double target;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreateGoalRequest &&
    other.period == period &&
    other.metric == metric &&
    other.target == target;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (period.hashCode) +
    (metric.hashCode) +
    (target.hashCode);

  @override
  String toString() => 'CreateGoalRequest[period=$period, metric=$metric, target=$target]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'period'] = this.period;
      json[r'metric'] = this.metric;
      json[r'target'] = this.target;
    return json;
  }

  /// Clones this instance of [CreateGoalRequest] and returns a new one where some of the
  /// properties have changed.
  CreateGoalRequest copyWith({
    String? period,
    String? metric,
    double? target,
  }) => CreateGoalRequest(
    period: period ?? this.period,
    metric: metric ?? this.metric,
    target: target ?? this.target,
  );

  /// Returns a new [CreateGoalRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateGoalRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'period'), 'Required key "CreateGoalRequest[period]" is missing from JSON.');
        assert(json[r'period'] != null, 'Required key "CreateGoalRequest[period]" has a null value in JSON.');
        assert(json.containsKey(r'metric'), 'Required key "CreateGoalRequest[metric]" is missing from JSON.');
        assert(json[r'metric'] != null, 'Required key "CreateGoalRequest[metric]" has a null value in JSON.');
        assert(json.containsKey(r'target'), 'Required key "CreateGoalRequest[target]" is missing from JSON.');
        assert(json[r'target'] != null, 'Required key "CreateGoalRequest[target]" has a null value in JSON.');
        return true;
      }());

      return CreateGoalRequest(
        period: mapValueOfType<String>(json, r'period')!,
        metric: mapValueOfType<String>(json, r'metric')!,
        target: mapValueOfType<double>(json, r'target')!,
      );
    }
    return null;
  }

  static List<CreateGoalRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateGoalRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateGoalRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateGoalRequest> mapFromJson(dynamic json) {
    final map = <String, CreateGoalRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateGoalRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateGoalRequest-objects as value to a dart map
  static Map<String, List<CreateGoalRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreateGoalRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateGoalRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'period',
    'metric',
    'target',
  };
}

