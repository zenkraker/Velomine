//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class FtpHistoryEntry {
  /// Returns a new [FtpHistoryEntry] instance.
  FtpHistoryEntry({
    required this.watts,
    required this.setAt,
    required this.source_,
    required this.rideId,
  });

  final int watts;

  final DateTime setAt;

  final String source_;

  final String? rideId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FtpHistoryEntry &&
    other.watts == watts &&
    other.setAt == setAt &&
    other.source_ == source_ &&
    other.rideId == rideId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (watts.hashCode) +
    (setAt.hashCode) +
    (source_.hashCode) +
    (rideId == null ? 0 : rideId!.hashCode);

  @override
  String toString() => 'FtpHistoryEntry[watts=$watts, setAt=$setAt, source_=$source_, rideId=$rideId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'watts'] = this.watts;
      json[r'setAt'] = this.setAt.toUtc().toIso8601String();
      json[r'source'] = this.source_;
    if (this.rideId != null) {
      json[r'rideId'] = this.rideId;
    } else {
      json[r'rideId'] = null;
    }
    return json;
  }

  /// Clones this instance of [FtpHistoryEntry] and returns a new one where some of the
  /// properties have changed.
  FtpHistoryEntry copyWith({
    int? watts,
    DateTime? setAt,
    String? source_,
    String? rideId,
    bool rideIdSetToNull = false,
  }) => FtpHistoryEntry(
    watts: watts ?? this.watts,
    setAt: setAt ?? this.setAt,
    source_: source_ ?? this.source_,
    rideId: rideIdSetToNull ? null : rideId ?? this.rideId,
  );

  /// Returns a new [FtpHistoryEntry] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FtpHistoryEntry? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'watts'), 'Required key "FtpHistoryEntry[watts]" is missing from JSON.');
        assert(json[r'watts'] != null, 'Required key "FtpHistoryEntry[watts]" has a null value in JSON.');
        assert(json.containsKey(r'setAt'), 'Required key "FtpHistoryEntry[setAt]" is missing from JSON.');
        assert(json[r'setAt'] != null, 'Required key "FtpHistoryEntry[setAt]" has a null value in JSON.');
        assert(json.containsKey(r'source'), 'Required key "FtpHistoryEntry[source]" is missing from JSON.');
        assert(json[r'source'] != null, 'Required key "FtpHistoryEntry[source]" has a null value in JSON.');
        assert(json.containsKey(r'rideId'), 'Required key "FtpHistoryEntry[rideId]" is missing from JSON.');
        return true;
      }());

      return FtpHistoryEntry(
        watts: mapValueOfType<int>(json, r'watts')!,
        setAt: mapDateTime(json, r'setAt', r'')!,
        source_: mapValueOfType<String>(json, r'source')!,
        rideId: mapValueOfType<String>(json, r'rideId'),
      );
    }
    return null;
  }

  static List<FtpHistoryEntry> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FtpHistoryEntry>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FtpHistoryEntry.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FtpHistoryEntry> mapFromJson(dynamic json) {
    final map = <String, FtpHistoryEntry>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FtpHistoryEntry.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FtpHistoryEntry-objects as value to a dart map
  static Map<String, List<FtpHistoryEntry>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FtpHistoryEntry>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FtpHistoryEntry.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'watts',
    'setAt',
    'source',
    'rideId',
  };
}

