//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ReadinessResponse {
  /// Returns a new [ReadinessResponse] instance.
  ReadinessResponse({
    required this.date,
    required this.score,
    required this.band,
    required this.hasWellbeing,
    this.factors = const [],
  });

  final DateTime date;

  final int? score;

  final String band;

  final bool hasWellbeing;

  final List<ReadinessFactor> factors;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ReadinessResponse &&
    other.date == date &&
    other.score == score &&
    other.band == band &&
    other.hasWellbeing == hasWellbeing &&
    _deepEquality.equals(other.factors, factors);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (date.hashCode) +
    (score == null ? 0 : score!.hashCode) +
    (band.hashCode) +
    (hasWellbeing.hashCode) +
    (factors.hashCode);

  @override
  String toString() => 'ReadinessResponse[date=$date, score=$score, band=$band, hasWellbeing=$hasWellbeing, factors=$factors]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'date'] = _dateFormatter.format(this.date);
    if (this.score != null) {
      json[r'score'] = this.score;
    } else {
      json[r'score'] = null;
    }
      json[r'band'] = this.band;
      json[r'hasWellbeing'] = this.hasWellbeing;
      json[r'factors'] = this.factors;
    return json;
  }

  /// Clones this instance of [ReadinessResponse] and returns a new one where some of the
  /// properties have changed.
  ReadinessResponse copyWith({
    DateTime? date,
    int? score,
    bool scoreSetToNull = false,
    String? band,
    bool? hasWellbeing,
    List<ReadinessFactor>? factors,
  }) => ReadinessResponse(
    date: date ?? this.date,
    score: scoreSetToNull ? null : score ?? this.score,
    band: band ?? this.band,
    hasWellbeing: hasWellbeing ?? this.hasWellbeing,
    factors: factors ?? this.factors,
  );

  /// Returns a new [ReadinessResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ReadinessResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'date'), 'Required key "ReadinessResponse[date]" is missing from JSON.');
        assert(json[r'date'] != null, 'Required key "ReadinessResponse[date]" has a null value in JSON.');
        assert(json.containsKey(r'score'), 'Required key "ReadinessResponse[score]" is missing from JSON.');
        assert(json.containsKey(r'band'), 'Required key "ReadinessResponse[band]" is missing from JSON.');
        assert(json[r'band'] != null, 'Required key "ReadinessResponse[band]" has a null value in JSON.');
        assert(json.containsKey(r'hasWellbeing'), 'Required key "ReadinessResponse[hasWellbeing]" is missing from JSON.');
        assert(json[r'hasWellbeing'] != null, 'Required key "ReadinessResponse[hasWellbeing]" has a null value in JSON.');
        assert(json.containsKey(r'factors'), 'Required key "ReadinessResponse[factors]" is missing from JSON.');
        assert(json[r'factors'] != null, 'Required key "ReadinessResponse[factors]" has a null value in JSON.');
        return true;
      }());

      return ReadinessResponse(
        date: mapDateTime(json, r'date', r'')!,
        score: mapValueOfType<int>(json, r'score'),
        band: mapValueOfType<String>(json, r'band')!,
        hasWellbeing: mapValueOfType<bool>(json, r'hasWellbeing')!,
        factors: ReadinessFactor.listFromJson(json[r'factors']),
      );
    }
    return null;
  }

  static List<ReadinessResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ReadinessResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ReadinessResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ReadinessResponse> mapFromJson(dynamic json) {
    final map = <String, ReadinessResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ReadinessResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ReadinessResponse-objects as value to a dart map
  static Map<String, List<ReadinessResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ReadinessResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ReadinessResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'date',
    'score',
    'band',
    'hasWellbeing',
    'factors',
  };
}

