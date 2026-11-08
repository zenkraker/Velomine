//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ZoneTime {
  /// Returns a new [ZoneTime] instance.
  ZoneTime({
    required this.zone,
    required this.from,
    required this.to,
    required this.seconds,
  });

  final int zone;

  final int from;

  final int? to;

  final double seconds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ZoneTime &&
    other.zone == zone &&
    other.from == from &&
    other.to == to &&
    other.seconds == seconds;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (zone.hashCode) +
    (from.hashCode) +
    (to == null ? 0 : to!.hashCode) +
    (seconds.hashCode);

  @override
  String toString() => 'ZoneTime[zone=$zone, from=$from, to=$to, seconds=$seconds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'zone'] = this.zone;
      json[r'from'] = this.from;
    if (this.to != null) {
      json[r'to'] = this.to;
    } else {
      json[r'to'] = null;
    }
      json[r'seconds'] = this.seconds;
    return json;
  }

  /// Clones this instance of [ZoneTime] and returns a new one where some of the
  /// properties have changed.
  ZoneTime copyWith({
    int? zone,
    int? from,
    int? to,
    bool toSetToNull = false,
    double? seconds,
  }) => ZoneTime(
    zone: zone ?? this.zone,
    from: from ?? this.from,
    to: toSetToNull ? null : to ?? this.to,
    seconds: seconds ?? this.seconds,
  );

  /// Returns a new [ZoneTime] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ZoneTime? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'zone'), 'Required key "ZoneTime[zone]" is missing from JSON.');
        assert(json[r'zone'] != null, 'Required key "ZoneTime[zone]" has a null value in JSON.');
        assert(json.containsKey(r'from'), 'Required key "ZoneTime[from]" is missing from JSON.');
        assert(json[r'from'] != null, 'Required key "ZoneTime[from]" has a null value in JSON.');
        assert(json.containsKey(r'to'), 'Required key "ZoneTime[to]" is missing from JSON.');
        assert(json.containsKey(r'seconds'), 'Required key "ZoneTime[seconds]" is missing from JSON.');
        assert(json[r'seconds'] != null, 'Required key "ZoneTime[seconds]" has a null value in JSON.');
        return true;
      }());

      return ZoneTime(
        zone: mapValueOfType<int>(json, r'zone')!,
        from: mapValueOfType<int>(json, r'from')!,
        to: mapValueOfType<int>(json, r'to'),
        seconds: mapValueOfType<double>(json, r'seconds')!,
      );
    }
    return null;
  }

  static List<ZoneTime> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ZoneTime>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ZoneTime.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ZoneTime> mapFromJson(dynamic json) {
    final map = <String, ZoneTime>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ZoneTime.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ZoneTime-objects as value to a dart map
  static Map<String, List<ZoneTime>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ZoneTime>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ZoneTime.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'zone',
    'from',
    'to',
    'seconds',
  };
}

