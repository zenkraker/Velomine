//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class GoalResponse {
  /// Returns a new [GoalResponse] instance.
  GoalResponse({
    required this.id,
    required this.period,
    required this.metric,
    required this.target,
    required this.periodStart,
    required this.periodEnd,
    required this.current,
    required this.percent,
    required this.reached,
  });

  final String id;

  final String period;

  final String metric;

  final double target;

  final DateTime periodStart;

  final DateTime periodEnd;

  final double current;

  final int percent;

  final bool reached;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GoalResponse &&
    other.id == id &&
    other.period == period &&
    other.metric == metric &&
    other.target == target &&
    other.periodStart == periodStart &&
    other.periodEnd == periodEnd &&
    other.current == current &&
    other.percent == percent &&
    other.reached == reached;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (period.hashCode) +
    (metric.hashCode) +
    (target.hashCode) +
    (periodStart.hashCode) +
    (periodEnd.hashCode) +
    (current.hashCode) +
    (percent.hashCode) +
    (reached.hashCode);

  @override
  String toString() => 'GoalResponse[id=$id, period=$period, metric=$metric, target=$target, periodStart=$periodStart, periodEnd=$periodEnd, current=$current, percent=$percent, reached=$reached]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'period'] = this.period;
      json[r'metric'] = this.metric;
      json[r'target'] = this.target;
      json[r'periodStart'] = _dateFormatter.format(this.periodStart);
      json[r'periodEnd'] = _dateFormatter.format(this.periodEnd);
      json[r'current'] = this.current;
      json[r'percent'] = this.percent;
      json[r'reached'] = this.reached;
    return json;
  }

  /// Clones this instance of [GoalResponse] and returns a new one where some of the
  /// properties have changed.
  GoalResponse copyWith({
    String? id,
    String? period,
    String? metric,
    double? target,
    DateTime? periodStart,
    DateTime? periodEnd,
    double? current,
    int? percent,
    bool? reached,
  }) => GoalResponse(
    id: id ?? this.id,
    period: period ?? this.period,
    metric: metric ?? this.metric,
    target: target ?? this.target,
    periodStart: periodStart ?? this.periodStart,
    periodEnd: periodEnd ?? this.periodEnd,
    current: current ?? this.current,
    percent: percent ?? this.percent,
    reached: reached ?? this.reached,
  );

  /// Returns a new [GoalResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GoalResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "GoalResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "GoalResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'period'), 'Required key "GoalResponse[period]" is missing from JSON.');
        assert(json[r'period'] != null, 'Required key "GoalResponse[period]" has a null value in JSON.');
        assert(json.containsKey(r'metric'), 'Required key "GoalResponse[metric]" is missing from JSON.');
        assert(json[r'metric'] != null, 'Required key "GoalResponse[metric]" has a null value in JSON.');
        assert(json.containsKey(r'target'), 'Required key "GoalResponse[target]" is missing from JSON.');
        assert(json[r'target'] != null, 'Required key "GoalResponse[target]" has a null value in JSON.');
        assert(json.containsKey(r'periodStart'), 'Required key "GoalResponse[periodStart]" is missing from JSON.');
        assert(json[r'periodStart'] != null, 'Required key "GoalResponse[periodStart]" has a null value in JSON.');
        assert(json.containsKey(r'periodEnd'), 'Required key "GoalResponse[periodEnd]" is missing from JSON.');
        assert(json[r'periodEnd'] != null, 'Required key "GoalResponse[periodEnd]" has a null value in JSON.');
        assert(json.containsKey(r'current'), 'Required key "GoalResponse[current]" is missing from JSON.');
        assert(json[r'current'] != null, 'Required key "GoalResponse[current]" has a null value in JSON.');
        assert(json.containsKey(r'percent'), 'Required key "GoalResponse[percent]" is missing from JSON.');
        assert(json[r'percent'] != null, 'Required key "GoalResponse[percent]" has a null value in JSON.');
        assert(json.containsKey(r'reached'), 'Required key "GoalResponse[reached]" is missing from JSON.');
        assert(json[r'reached'] != null, 'Required key "GoalResponse[reached]" has a null value in JSON.');
        return true;
      }());

      return GoalResponse(
        id: mapValueOfType<String>(json, r'id')!,
        period: mapValueOfType<String>(json, r'period')!,
        metric: mapValueOfType<String>(json, r'metric')!,
        target: mapValueOfType<double>(json, r'target')!,
        periodStart: mapDateTime(json, r'periodStart', r'')!,
        periodEnd: mapDateTime(json, r'periodEnd', r'')!,
        current: mapValueOfType<double>(json, r'current')!,
        percent: mapValueOfType<int>(json, r'percent')!,
        reached: mapValueOfType<bool>(json, r'reached')!,
      );
    }
    return null;
  }

  static List<GoalResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GoalResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GoalResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GoalResponse> mapFromJson(dynamic json) {
    final map = <String, GoalResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GoalResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GoalResponse-objects as value to a dart map
  static Map<String, List<GoalResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<GoalResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GoalResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'period',
    'metric',
    'target',
    'periodStart',
    'periodEnd',
    'current',
    'percent',
    'reached',
  };
}

