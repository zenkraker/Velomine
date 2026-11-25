//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class MoveDay {
  /// Returns a new [MoveDay] instance.
  MoveDay({
    required this.localDate,
    required this.allowed,
    required this.reason,
  });

  final DateTime localDate;

  final bool allowed;

  final String? reason;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MoveDay &&
    other.localDate == localDate &&
    other.allowed == allowed &&
    other.reason == reason;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (localDate.hashCode) +
    (allowed.hashCode) +
    (reason == null ? 0 : reason!.hashCode);

  @override
  String toString() => 'MoveDay[localDate=$localDate, allowed=$allowed, reason=$reason]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'localDate'] = _dateFormatter.format(this.localDate);
      json[r'allowed'] = this.allowed;
    if (this.reason != null) {
      json[r'reason'] = this.reason;
    } else {
      json[r'reason'] = null;
    }
    return json;
  }

  /// Clones this instance of [MoveDay] and returns a new one where some of the
  /// properties have changed.
  MoveDay copyWith({
    DateTime? localDate,
    bool? allowed,
    String? reason,
    bool reasonSetToNull = false,
  }) => MoveDay(
    localDate: localDate ?? this.localDate,
    allowed: allowed ?? this.allowed,
    reason: reasonSetToNull ? null : reason ?? this.reason,
  );

  /// Returns a new [MoveDay] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MoveDay? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'localDate'), 'Required key "MoveDay[localDate]" is missing from JSON.');
        assert(json[r'localDate'] != null, 'Required key "MoveDay[localDate]" has a null value in JSON.');
        assert(json.containsKey(r'allowed'), 'Required key "MoveDay[allowed]" is missing from JSON.');
        assert(json[r'allowed'] != null, 'Required key "MoveDay[allowed]" has a null value in JSON.');
        assert(json.containsKey(r'reason'), 'Required key "MoveDay[reason]" is missing from JSON.');
        return true;
      }());

      return MoveDay(
        localDate: mapDateTime(json, r'localDate', r'')!,
        allowed: mapValueOfType<bool>(json, r'allowed')!,
        reason: mapValueOfType<String>(json, r'reason'),
      );
    }
    return null;
  }

  static List<MoveDay> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MoveDay>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MoveDay.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MoveDay> mapFromJson(dynamic json) {
    final map = <String, MoveDay>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MoveDay.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MoveDay-objects as value to a dart map
  static Map<String, List<MoveDay>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MoveDay>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MoveDay.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'localDate',
    'allowed',
    'reason',
  };
}

