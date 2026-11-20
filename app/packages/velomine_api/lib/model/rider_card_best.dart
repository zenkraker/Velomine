//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class RiderCardBest {
  /// Returns a new [RiderCardBest] instance.
  RiderCardBest({
    required this.seconds,
    required this.watts,
    required this.rideId,
    required this.date,
  });

  final int seconds;

  final int? watts;

  final String? rideId;

  final DateTime? date;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RiderCardBest &&
    other.seconds == seconds &&
    other.watts == watts &&
    other.rideId == rideId &&
    other.date == date;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (seconds.hashCode) +
    (watts == null ? 0 : watts!.hashCode) +
    (rideId == null ? 0 : rideId!.hashCode) +
    (date == null ? 0 : date!.hashCode);

  @override
  String toString() => 'RiderCardBest[seconds=$seconds, watts=$watts, rideId=$rideId, date=$date]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'seconds'] = this.seconds;
    if (this.watts != null) {
      json[r'watts'] = this.watts;
    } else {
      json[r'watts'] = null;
    }
    if (this.rideId != null) {
      json[r'rideId'] = this.rideId;
    } else {
      json[r'rideId'] = null;
    }
    if (this.date != null) {
      json[r'date'] = _dateFormatter.format(this.date!);
    } else {
      json[r'date'] = null;
    }
    return json;
  }

  /// Clones this instance of [RiderCardBest] and returns a new one where some of the
  /// properties have changed.
  RiderCardBest copyWith({
    int? seconds,
    int? watts,
    bool wattsSetToNull = false,
    String? rideId,
    bool rideIdSetToNull = false,
    DateTime? date,
    bool dateSetToNull = false,
  }) => RiderCardBest(
    seconds: seconds ?? this.seconds,
    watts: wattsSetToNull ? null : watts ?? this.watts,
    rideId: rideIdSetToNull ? null : rideId ?? this.rideId,
    date: dateSetToNull ? null : date ?? this.date,
  );

  /// Returns a new [RiderCardBest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RiderCardBest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'seconds'), 'Required key "RiderCardBest[seconds]" is missing from JSON.');
        assert(json[r'seconds'] != null, 'Required key "RiderCardBest[seconds]" has a null value in JSON.');
        assert(json.containsKey(r'watts'), 'Required key "RiderCardBest[watts]" is missing from JSON.');
        assert(json.containsKey(r'rideId'), 'Required key "RiderCardBest[rideId]" is missing from JSON.');
        assert(json.containsKey(r'date'), 'Required key "RiderCardBest[date]" is missing from JSON.');
        return true;
      }());

      return RiderCardBest(
        seconds: mapValueOfType<int>(json, r'seconds')!,
        watts: mapValueOfType<int>(json, r'watts'),
        rideId: mapValueOfType<String>(json, r'rideId'),
        date: mapDateTime(json, r'date', r''),
      );
    }
    return null;
  }

  static List<RiderCardBest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RiderCardBest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RiderCardBest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RiderCardBest> mapFromJson(dynamic json) {
    final map = <String, RiderCardBest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RiderCardBest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RiderCardBest-objects as value to a dart map
  static Map<String, List<RiderCardBest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RiderCardBest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RiderCardBest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'seconds',
    'watts',
    'rideId',
    'date',
  };
}

