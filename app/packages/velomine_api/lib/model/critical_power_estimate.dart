//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class CriticalPowerEstimate {
  /// Returns a new [CriticalPowerEstimate] instance.
  CriticalPowerEstimate({
    required this.cpW,
    required this.wPrimeJ,
    required this.peakW,
    required this.r2,
    this.durations = const [],
  });

  final int cpW;

  final int wPrimeJ;

  final int? peakW;

  final double r2;

  final List<int> durations;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CriticalPowerEstimate &&
    other.cpW == cpW &&
    other.wPrimeJ == wPrimeJ &&
    other.peakW == peakW &&
    other.r2 == r2 &&
    _deepEquality.equals(other.durations, durations);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (cpW.hashCode) +
    (wPrimeJ.hashCode) +
    (peakW == null ? 0 : peakW!.hashCode) +
    (r2.hashCode) +
    (durations.hashCode);

  @override
  String toString() => 'CriticalPowerEstimate[cpW=$cpW, wPrimeJ=$wPrimeJ, peakW=$peakW, r2=$r2, durations=$durations]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'cpW'] = this.cpW;
      json[r'wPrimeJ'] = this.wPrimeJ;
    if (this.peakW != null) {
      json[r'peakW'] = this.peakW;
    } else {
      json[r'peakW'] = null;
    }
      json[r'r2'] = this.r2;
      json[r'durations'] = this.durations;
    return json;
  }

  /// Clones this instance of [CriticalPowerEstimate] and returns a new one where some of the
  /// properties have changed.
  CriticalPowerEstimate copyWith({
    int? cpW,
    int? wPrimeJ,
    int? peakW,
    bool peakWSetToNull = false,
    double? r2,
    List<int>? durations,
  }) => CriticalPowerEstimate(
    cpW: cpW ?? this.cpW,
    wPrimeJ: wPrimeJ ?? this.wPrimeJ,
    peakW: peakWSetToNull ? null : peakW ?? this.peakW,
    r2: r2 ?? this.r2,
    durations: durations ?? this.durations,
  );

  /// Returns a new [CriticalPowerEstimate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CriticalPowerEstimate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'cpW'), 'Required key "CriticalPowerEstimate[cpW]" is missing from JSON.');
        assert(json[r'cpW'] != null, 'Required key "CriticalPowerEstimate[cpW]" has a null value in JSON.');
        assert(json.containsKey(r'wPrimeJ'), 'Required key "CriticalPowerEstimate[wPrimeJ]" is missing from JSON.');
        assert(json[r'wPrimeJ'] != null, 'Required key "CriticalPowerEstimate[wPrimeJ]" has a null value in JSON.');
        assert(json.containsKey(r'peakW'), 'Required key "CriticalPowerEstimate[peakW]" is missing from JSON.');
        assert(json.containsKey(r'r2'), 'Required key "CriticalPowerEstimate[r2]" is missing from JSON.');
        assert(json[r'r2'] != null, 'Required key "CriticalPowerEstimate[r2]" has a null value in JSON.');
        assert(json.containsKey(r'durations'), 'Required key "CriticalPowerEstimate[durations]" is missing from JSON.');
        assert(json[r'durations'] != null, 'Required key "CriticalPowerEstimate[durations]" has a null value in JSON.');
        return true;
      }());

      return CriticalPowerEstimate(
        cpW: mapValueOfType<int>(json, r'cpW')!,
        wPrimeJ: mapValueOfType<int>(json, r'wPrimeJ')!,
        peakW: mapValueOfType<int>(json, r'peakW'),
        r2: mapValueOfType<double>(json, r'r2')!,
        durations: json[r'durations'] is Iterable
            ? (json[r'durations'] as Iterable).map((e) => (e as num).toInt()).toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<CriticalPowerEstimate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CriticalPowerEstimate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CriticalPowerEstimate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CriticalPowerEstimate> mapFromJson(dynamic json) {
    final map = <String, CriticalPowerEstimate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CriticalPowerEstimate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CriticalPowerEstimate-objects as value to a dart map
  static Map<String, List<CriticalPowerEstimate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CriticalPowerEstimate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CriticalPowerEstimate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'cpW',
    'wPrimeJ',
    'peakW',
    'r2',
    'durations',
  };
}

