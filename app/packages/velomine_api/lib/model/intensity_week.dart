//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class IntensityWeek {
  /// Returns a new [IntensityWeek] instance.
  IntensityWeek({
    required this.weekStart,
    required this.easyS,
    required this.moderateS,
    required this.hardS,
  });

  final DateTime weekStart;

  final double easyS;

  final double moderateS;

  final double hardS;

  @override
  bool operator ==(Object other) => identical(this, other) || other is IntensityWeek &&
    other.weekStart == weekStart &&
    other.easyS == easyS &&
    other.moderateS == moderateS &&
    other.hardS == hardS;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (weekStart.hashCode) +
    (easyS.hashCode) +
    (moderateS.hashCode) +
    (hardS.hashCode);

  @override
  String toString() => 'IntensityWeek[weekStart=$weekStart, easyS=$easyS, moderateS=$moderateS, hardS=$hardS]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'weekStart'] = _dateFormatter.format(this.weekStart);
      json[r'easyS'] = this.easyS;
      json[r'moderateS'] = this.moderateS;
      json[r'hardS'] = this.hardS;
    return json;
  }

  /// Clones this instance of [IntensityWeek] and returns a new one where some of the
  /// properties have changed.
  IntensityWeek copyWith({
    DateTime? weekStart,
    double? easyS,
    double? moderateS,
    double? hardS,
  }) => IntensityWeek(
    weekStart: weekStart ?? this.weekStart,
    easyS: easyS ?? this.easyS,
    moderateS: moderateS ?? this.moderateS,
    hardS: hardS ?? this.hardS,
  );

  /// Returns a new [IntensityWeek] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static IntensityWeek? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'weekStart'), 'Required key "IntensityWeek[weekStart]" is missing from JSON.');
        assert(json[r'weekStart'] != null, 'Required key "IntensityWeek[weekStart]" has a null value in JSON.');
        assert(json.containsKey(r'easyS'), 'Required key "IntensityWeek[easyS]" is missing from JSON.');
        assert(json[r'easyS'] != null, 'Required key "IntensityWeek[easyS]" has a null value in JSON.');
        assert(json.containsKey(r'moderateS'), 'Required key "IntensityWeek[moderateS]" is missing from JSON.');
        assert(json[r'moderateS'] != null, 'Required key "IntensityWeek[moderateS]" has a null value in JSON.');
        assert(json.containsKey(r'hardS'), 'Required key "IntensityWeek[hardS]" is missing from JSON.');
        assert(json[r'hardS'] != null, 'Required key "IntensityWeek[hardS]" has a null value in JSON.');
        return true;
      }());

      return IntensityWeek(
        weekStart: mapDateTime(json, r'weekStart', r'')!,
        easyS: mapValueOfType<double>(json, r'easyS')!,
        moderateS: mapValueOfType<double>(json, r'moderateS')!,
        hardS: mapValueOfType<double>(json, r'hardS')!,
      );
    }
    return null;
  }

  static List<IntensityWeek> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <IntensityWeek>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = IntensityWeek.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, IntensityWeek> mapFromJson(dynamic json) {
    final map = <String, IntensityWeek>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = IntensityWeek.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of IntensityWeek-objects as value to a dart map
  static Map<String, List<IntensityWeek>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<IntensityWeek>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = IntensityWeek.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'weekStart',
    'easyS',
    'moderateS',
    'hardS',
  };
}

