//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class FtpEstimate {
  /// Returns a new [FtpEstimate] instance.
  FtpEstimate({
    required this.watts,
    required this.method,
    required this.from,
    required this.wPerKg,
  });

  final int watts;

  final String method;

  final DateTime from;

  final double? wPerKg;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FtpEstimate &&
    other.watts == watts &&
    other.method == method &&
    other.from == from &&
    other.wPerKg == wPerKg;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (watts.hashCode) +
    (method.hashCode) +
    (from.hashCode) +
    (wPerKg == null ? 0 : wPerKg!.hashCode);

  @override
  String toString() => 'FtpEstimate[watts=$watts, method=$method, from=$from, wPerKg=$wPerKg]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'watts'] = this.watts;
      json[r'method'] = this.method;
      json[r'from'] = _dateFormatter.format(this.from);
    if (this.wPerKg != null) {
      json[r'wPerKg'] = this.wPerKg;
    } else {
      json[r'wPerKg'] = null;
    }
    return json;
  }

  /// Clones this instance of [FtpEstimate] and returns a new one where some of the
  /// properties have changed.
  FtpEstimate copyWith({
    int? watts,
    String? method,
    DateTime? from,
    double? wPerKg,
    bool wPerKgSetToNull = false,
  }) => FtpEstimate(
    watts: watts ?? this.watts,
    method: method ?? this.method,
    from: from ?? this.from,
    wPerKg: wPerKgSetToNull ? null : wPerKg ?? this.wPerKg,
  );

  /// Returns a new [FtpEstimate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FtpEstimate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'watts'), 'Required key "FtpEstimate[watts]" is missing from JSON.');
        assert(json[r'watts'] != null, 'Required key "FtpEstimate[watts]" has a null value in JSON.');
        assert(json.containsKey(r'method'), 'Required key "FtpEstimate[method]" is missing from JSON.');
        assert(json[r'method'] != null, 'Required key "FtpEstimate[method]" has a null value in JSON.');
        assert(json.containsKey(r'from'), 'Required key "FtpEstimate[from]" is missing from JSON.');
        assert(json[r'from'] != null, 'Required key "FtpEstimate[from]" has a null value in JSON.');
        assert(json.containsKey(r'wPerKg'), 'Required key "FtpEstimate[wPerKg]" is missing from JSON.');
        return true;
      }());

      return FtpEstimate(
        watts: mapValueOfType<int>(json, r'watts')!,
        method: mapValueOfType<String>(json, r'method')!,
        from: mapDateTime(json, r'from', r'')!,
        wPerKg: mapValueOfType<double>(json, r'wPerKg'),
      );
    }
    return null;
  }

  static List<FtpEstimate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FtpEstimate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FtpEstimate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FtpEstimate> mapFromJson(dynamic json) {
    final map = <String, FtpEstimate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FtpEstimate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FtpEstimate-objects as value to a dart map
  static Map<String, List<FtpEstimate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FtpEstimate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FtpEstimate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'watts',
    'method',
    'from',
    'wPerKg',
  };
}

