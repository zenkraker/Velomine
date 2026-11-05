//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class TotalsResponse {
  /// Returns a new [TotalsResponse] instance.
  TotalsResponse({
    required this.period,
    this.totals = const [],
  });

  final String period;

  final List<PeriodTotals> totals;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TotalsResponse &&
    other.period == period &&
    _deepEquality.equals(other.totals, totals);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (period.hashCode) +
    (totals.hashCode);

  @override
  String toString() => 'TotalsResponse[period=$period, totals=$totals]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'period'] = this.period;
      json[r'totals'] = this.totals;
    return json;
  }

  /// Clones this instance of [TotalsResponse] and returns a new one where some of the
  /// properties have changed.
  TotalsResponse copyWith({
    String? period,
    List<PeriodTotals>? totals,
  }) => TotalsResponse(
    period: period ?? this.period,
    totals: totals ?? this.totals,
  );

  /// Returns a new [TotalsResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TotalsResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'period'), 'Required key "TotalsResponse[period]" is missing from JSON.');
        assert(json[r'period'] != null, 'Required key "TotalsResponse[period]" has a null value in JSON.');
        assert(json.containsKey(r'totals'), 'Required key "TotalsResponse[totals]" is missing from JSON.');
        assert(json[r'totals'] != null, 'Required key "TotalsResponse[totals]" has a null value in JSON.');
        return true;
      }());

      return TotalsResponse(
        period: mapValueOfType<String>(json, r'period')!,
        totals: PeriodTotals.listFromJson(json[r'totals']),
      );
    }
    return null;
  }

  static List<TotalsResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TotalsResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TotalsResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TotalsResponse> mapFromJson(dynamic json) {
    final map = <String, TotalsResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TotalsResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TotalsResponse-objects as value to a dart map
  static Map<String, List<TotalsResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TotalsResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TotalsResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'period',
    'totals',
  };
}

