//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class TrainingWeek {
  /// Returns a new [TrainingWeek] instance.
  TrainingWeek({
    required this.start,
    required this.end,
    required this.plannedLoad,
    required this.isLighterWeek,
    required this.note,
    this.sessions = const [],
  });

  final DateTime start;

  final DateTime end;

  final double plannedLoad;

  final bool isLighterWeek;

  final TrainingNote? note;

  final List<TrainingWeekSession> sessions;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TrainingWeek &&
    other.start == start &&
    other.end == end &&
    other.plannedLoad == plannedLoad &&
    other.isLighterWeek == isLighterWeek &&
    other.note == note &&
    _deepEquality.equals(other.sessions, sessions);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (start.hashCode) +
    (end.hashCode) +
    (plannedLoad.hashCode) +
    (isLighterWeek.hashCode) +
    (note == null ? 0 : note!.hashCode) +
    (sessions.hashCode);

  @override
  String toString() => 'TrainingWeek[start=$start, end=$end, plannedLoad=$plannedLoad, isLighterWeek=$isLighterWeek, note=$note, sessions=$sessions]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'start'] = _dateFormatter.format(this.start);
      json[r'end'] = _dateFormatter.format(this.end);
      json[r'plannedLoad'] = this.plannedLoad;
      json[r'isLighterWeek'] = this.isLighterWeek;
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
      json[r'sessions'] = this.sessions;
    return json;
  }

  /// Clones this instance of [TrainingWeek] and returns a new one where some of the
  /// properties have changed.
  TrainingWeek copyWith({
    DateTime? start,
    DateTime? end,
    double? plannedLoad,
    bool? isLighterWeek,
    TrainingNote? note,
    bool noteSetToNull = false,
    List<TrainingWeekSession>? sessions,
  }) => TrainingWeek(
    start: start ?? this.start,
    end: end ?? this.end,
    plannedLoad: plannedLoad ?? this.plannedLoad,
    isLighterWeek: isLighterWeek ?? this.isLighterWeek,
    note: noteSetToNull ? null : note ?? this.note,
    sessions: sessions ?? this.sessions,
  );

  /// Returns a new [TrainingWeek] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TrainingWeek? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'start'), 'Required key "TrainingWeek[start]" is missing from JSON.');
        assert(json[r'start'] != null, 'Required key "TrainingWeek[start]" has a null value in JSON.');
        assert(json.containsKey(r'end'), 'Required key "TrainingWeek[end]" is missing from JSON.');
        assert(json[r'end'] != null, 'Required key "TrainingWeek[end]" has a null value in JSON.');
        assert(json.containsKey(r'plannedLoad'), 'Required key "TrainingWeek[plannedLoad]" is missing from JSON.');
        assert(json[r'plannedLoad'] != null, 'Required key "TrainingWeek[plannedLoad]" has a null value in JSON.');
        assert(json.containsKey(r'isLighterWeek'), 'Required key "TrainingWeek[isLighterWeek]" is missing from JSON.');
        assert(json[r'isLighterWeek'] != null, 'Required key "TrainingWeek[isLighterWeek]" has a null value in JSON.');
        assert(json.containsKey(r'note'), 'Required key "TrainingWeek[note]" is missing from JSON.');
        assert(json.containsKey(r'sessions'), 'Required key "TrainingWeek[sessions]" is missing from JSON.');
        assert(json[r'sessions'] != null, 'Required key "TrainingWeek[sessions]" has a null value in JSON.');
        return true;
      }());

      return TrainingWeek(
        start: mapDateTime(json, r'start', r'')!,
        end: mapDateTime(json, r'end', r'')!,
        plannedLoad: mapValueOfType<double>(json, r'plannedLoad')!,
        isLighterWeek: mapValueOfType<bool>(json, r'isLighterWeek')!,
        note: TrainingNote.fromJson(json[r'note']),
        sessions: TrainingWeekSession.listFromJson(json[r'sessions']),
      );
    }
    return null;
  }

  static List<TrainingWeek> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TrainingWeek>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TrainingWeek.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TrainingWeek> mapFromJson(dynamic json) {
    final map = <String, TrainingWeek>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TrainingWeek.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TrainingWeek-objects as value to a dart map
  static Map<String, List<TrainingWeek>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TrainingWeek>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TrainingWeek.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'start',
    'end',
    'plannedLoad',
    'isLighterWeek',
    'note',
    'sessions',
  };
}

