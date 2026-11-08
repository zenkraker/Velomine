//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class Vo2MaxEstimate {
  /// Returns a new [Vo2MaxEstimate] instance.
  Vo2MaxEstimate({
    required this.value,
    required this.method,
    required this.from,
  });

  final double value;

  final String method;

  final DateTime from;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Vo2MaxEstimate &&
    other.value == value &&
    other.method == method &&
    other.from == from;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (value.hashCode) +
    (method.hashCode) +
    (from.hashCode);

  @override
  String toString() => 'Vo2MaxEstimate[value=$value, method=$method, from=$from]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'value'] = this.value;
      json[r'method'] = this.method;
      json[r'from'] = _dateFormatter.format(this.from);
    return json;
  }

  /// Clones this instance of [Vo2MaxEstimate] and returns a new one where some of the
  /// properties have changed.
  Vo2MaxEstimate copyWith({
    double? value,
    String? method,
    DateTime? from,
  }) => Vo2MaxEstimate(
    value: value ?? this.value,
    method: method ?? this.method,
    from: from ?? this.from,
  );

  /// Returns a new [Vo2MaxEstimate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Vo2MaxEstimate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'value'), 'Required key "Vo2MaxEstimate[value]" is missing from JSON.');
        assert(json[r'value'] != null, 'Required key "Vo2MaxEstimate[value]" has a null value in JSON.');
        assert(json.containsKey(r'method'), 'Required key "Vo2MaxEstimate[method]" is missing from JSON.');
        assert(json[r'method'] != null, 'Required key "Vo2MaxEstimate[method]" has a null value in JSON.');
        assert(json.containsKey(r'from'), 'Required key "Vo2MaxEstimate[from]" is missing from JSON.');
        assert(json[r'from'] != null, 'Required key "Vo2MaxEstimate[from]" has a null value in JSON.');
        return true;
      }());

      return Vo2MaxEstimate(
        value: mapValueOfType<double>(json, r'value')!,
        method: mapValueOfType<String>(json, r'method')!,
        from: mapDateTime(json, r'from', r'')!,
      );
    }
    return null;
  }

  static List<Vo2MaxEstimate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Vo2MaxEstimate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Vo2MaxEstimate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Vo2MaxEstimate> mapFromJson(dynamic json) {
    final map = <String, Vo2MaxEstimate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Vo2MaxEstimate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Vo2MaxEstimate-objects as value to a dart map
  static Map<String, List<Vo2MaxEstimate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Vo2MaxEstimate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Vo2MaxEstimate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'value',
    'method',
    'from',
  };
}

