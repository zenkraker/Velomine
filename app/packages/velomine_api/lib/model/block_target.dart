//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class BlockTarget {
  /// Returns a new [BlockTarget] instance.
  BlockTarget({
    required this.role,
    required this.minutes,
    required this.wattsLow,
    required this.wattsHigh,
    required this.heartRateLow,
    required this.heartRateHigh,
    required this.feelLow,
    required this.feelHigh,
  });

  final String role;

  final int minutes;

  final int? wattsLow;

  final int? wattsHigh;

  final int? heartRateLow;

  final int? heartRateHigh;

  final int feelLow;

  final int feelHigh;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BlockTarget &&
    other.role == role &&
    other.minutes == minutes &&
    other.wattsLow == wattsLow &&
    other.wattsHigh == wattsHigh &&
    other.heartRateLow == heartRateLow &&
    other.heartRateHigh == heartRateHigh &&
    other.feelLow == feelLow &&
    other.feelHigh == feelHigh;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (role.hashCode) +
    (minutes.hashCode) +
    (wattsLow == null ? 0 : wattsLow!.hashCode) +
    (wattsHigh == null ? 0 : wattsHigh!.hashCode) +
    (heartRateLow == null ? 0 : heartRateLow!.hashCode) +
    (heartRateHigh == null ? 0 : heartRateHigh!.hashCode) +
    (feelLow.hashCode) +
    (feelHigh.hashCode);

  @override
  String toString() => 'BlockTarget[role=$role, minutes=$minutes, wattsLow=$wattsLow, wattsHigh=$wattsHigh, heartRateLow=$heartRateLow, heartRateHigh=$heartRateHigh, feelLow=$feelLow, feelHigh=$feelHigh]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'role'] = this.role;
      json[r'minutes'] = this.minutes;
    if (this.wattsLow != null) {
      json[r'wattsLow'] = this.wattsLow;
    } else {
      json[r'wattsLow'] = null;
    }
    if (this.wattsHigh != null) {
      json[r'wattsHigh'] = this.wattsHigh;
    } else {
      json[r'wattsHigh'] = null;
    }
    if (this.heartRateLow != null) {
      json[r'heartRateLow'] = this.heartRateLow;
    } else {
      json[r'heartRateLow'] = null;
    }
    if (this.heartRateHigh != null) {
      json[r'heartRateHigh'] = this.heartRateHigh;
    } else {
      json[r'heartRateHigh'] = null;
    }
      json[r'feelLow'] = this.feelLow;
      json[r'feelHigh'] = this.feelHigh;
    return json;
  }

  /// Clones this instance of [BlockTarget] and returns a new one where some of the
  /// properties have changed.
  BlockTarget copyWith({
    String? role,
    int? minutes,
    int? wattsLow,
    bool wattsLowSetToNull = false,
    int? wattsHigh,
    bool wattsHighSetToNull = false,
    int? heartRateLow,
    bool heartRateLowSetToNull = false,
    int? heartRateHigh,
    bool heartRateHighSetToNull = false,
    int? feelLow,
    int? feelHigh,
  }) => BlockTarget(
    role: role ?? this.role,
    minutes: minutes ?? this.minutes,
    wattsLow: wattsLowSetToNull ? null : wattsLow ?? this.wattsLow,
    wattsHigh: wattsHighSetToNull ? null : wattsHigh ?? this.wattsHigh,
    heartRateLow: heartRateLowSetToNull ? null : heartRateLow ?? this.heartRateLow,
    heartRateHigh: heartRateHighSetToNull ? null : heartRateHigh ?? this.heartRateHigh,
    feelLow: feelLow ?? this.feelLow,
    feelHigh: feelHigh ?? this.feelHigh,
  );

  /// Returns a new [BlockTarget] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BlockTarget? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'role'), 'Required key "BlockTarget[role]" is missing from JSON.');
        assert(json[r'role'] != null, 'Required key "BlockTarget[role]" has a null value in JSON.');
        assert(json.containsKey(r'minutes'), 'Required key "BlockTarget[minutes]" is missing from JSON.');
        assert(json[r'minutes'] != null, 'Required key "BlockTarget[minutes]" has a null value in JSON.');
        assert(json.containsKey(r'wattsLow'), 'Required key "BlockTarget[wattsLow]" is missing from JSON.');
        assert(json.containsKey(r'wattsHigh'), 'Required key "BlockTarget[wattsHigh]" is missing from JSON.');
        assert(json.containsKey(r'heartRateLow'), 'Required key "BlockTarget[heartRateLow]" is missing from JSON.');
        assert(json.containsKey(r'heartRateHigh'), 'Required key "BlockTarget[heartRateHigh]" is missing from JSON.');
        assert(json.containsKey(r'feelLow'), 'Required key "BlockTarget[feelLow]" is missing from JSON.');
        assert(json[r'feelLow'] != null, 'Required key "BlockTarget[feelLow]" has a null value in JSON.');
        assert(json.containsKey(r'feelHigh'), 'Required key "BlockTarget[feelHigh]" is missing from JSON.');
        assert(json[r'feelHigh'] != null, 'Required key "BlockTarget[feelHigh]" has a null value in JSON.');
        return true;
      }());

      return BlockTarget(
        role: mapValueOfType<String>(json, r'role')!,
        minutes: mapValueOfType<int>(json, r'minutes')!,
        wattsLow: mapValueOfType<int>(json, r'wattsLow'),
        wattsHigh: mapValueOfType<int>(json, r'wattsHigh'),
        heartRateLow: mapValueOfType<int>(json, r'heartRateLow'),
        heartRateHigh: mapValueOfType<int>(json, r'heartRateHigh'),
        feelLow: mapValueOfType<int>(json, r'feelLow')!,
        feelHigh: mapValueOfType<int>(json, r'feelHigh')!,
      );
    }
    return null;
  }

  static List<BlockTarget> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BlockTarget>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BlockTarget.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BlockTarget> mapFromJson(dynamic json) {
    final map = <String, BlockTarget>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BlockTarget.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BlockTarget-objects as value to a dart map
  static Map<String, List<BlockTarget>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<BlockTarget>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BlockTarget.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'role',
    'minutes',
    'wattsLow',
    'wattsHigh',
    'heartRateLow',
    'heartRateHigh',
    'feelLow',
    'feelHigh',
  };
}

