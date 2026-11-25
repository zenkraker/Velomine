//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class TrainingWeekSession {
  /// Returns a new [TrainingWeekSession] instance.
  TrainingWeekSession({
    required this.id,
    required this.localDate,
    required this.minutes,
    required this.state,
    required this.skipReason,
    required this.rideId,
    required this.recipe,
    required this.technicalName,
    required this.englishName,
    required this.italianName,
    required this.englishLine,
    required this.italianLine,
    this.blocks = const [],
    this.notes = const [],
    required this.heartRateEstimated,
    this.result = const Optional.absent(),
  });

  final String id;

  final DateTime localDate;

  final int minutes;

  final String state;

  final String? skipReason;

  final String? rideId;

  final String recipe;

  final String technicalName;

  final String englishName;

  final String italianName;

  final String englishLine;

  final String italianLine;

  final List<BlockTarget> blocks;

  final List<SessionNote> notes;

  final bool heartRateEstimated;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<SessionResult?> result;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TrainingWeekSession &&
    other.id == id &&
    other.localDate == localDate &&
    other.minutes == minutes &&
    other.state == state &&
    other.skipReason == skipReason &&
    other.rideId == rideId &&
    other.recipe == recipe &&
    other.technicalName == technicalName &&
    other.englishName == englishName &&
    other.italianName == italianName &&
    other.englishLine == englishLine &&
    other.italianLine == italianLine &&
    _deepEquality.equals(other.blocks, blocks) &&
    _deepEquality.equals(other.notes, notes) &&
    other.heartRateEstimated == heartRateEstimated &&
    other.result == result;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (localDate.hashCode) +
    (minutes.hashCode) +
    (state.hashCode) +
    (skipReason == null ? 0 : skipReason!.hashCode) +
    (rideId == null ? 0 : rideId!.hashCode) +
    (recipe.hashCode) +
    (technicalName.hashCode) +
    (englishName.hashCode) +
    (italianName.hashCode) +
    (englishLine.hashCode) +
    (italianLine.hashCode) +
    (blocks.hashCode) +
    (notes.hashCode) +
    (heartRateEstimated.hashCode) +
    (result == null ? 0 : result!.hashCode);

  @override
  String toString() => 'TrainingWeekSession[id=$id, localDate=$localDate, minutes=$minutes, state=$state, skipReason=$skipReason, rideId=$rideId, recipe=$recipe, technicalName=$technicalName, englishName=$englishName, italianName=$italianName, englishLine=$englishLine, italianLine=$italianLine, blocks=$blocks, notes=$notes, heartRateEstimated=$heartRateEstimated, result=$result]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'localDate'] = _dateFormatter.format(this.localDate);
      json[r'minutes'] = this.minutes;
      json[r'state'] = this.state;
    if (this.skipReason != null) {
      json[r'skipReason'] = this.skipReason;
    } else {
      json[r'skipReason'] = null;
    }
    if (this.rideId != null) {
      json[r'rideId'] = this.rideId;
    } else {
      json[r'rideId'] = null;
    }
      json[r'recipe'] = this.recipe;
      json[r'technicalName'] = this.technicalName;
      json[r'englishName'] = this.englishName;
      json[r'italianName'] = this.italianName;
      json[r'englishLine'] = this.englishLine;
      json[r'italianLine'] = this.italianLine;
      json[r'blocks'] = this.blocks;
      json[r'notes'] = this.notes;
      json[r'heartRateEstimated'] = this.heartRateEstimated;
    if (this.result.isPresent) {
      final value = this.result.value;
      json[r'result'] = value;
    }
    return json;
  }

  /// Clones this instance of [TrainingWeekSession] and returns a new one where some of the
  /// properties have changed.
  TrainingWeekSession copyWith({
    String? id,
    DateTime? localDate,
    int? minutes,
    String? state,
    String? skipReason,
    bool skipReasonSetToNull = false,
    String? rideId,
    bool rideIdSetToNull = false,
    String? recipe,
    String? technicalName,
    String? englishName,
    String? italianName,
    String? englishLine,
    String? italianLine,
    List<BlockTarget>? blocks,
    List<SessionNote>? notes,
    bool? heartRateEstimated,
    Optional<SessionResult?>? result,
  }) => TrainingWeekSession(
    id: id ?? this.id,
    localDate: localDate ?? this.localDate,
    minutes: minutes ?? this.minutes,
    state: state ?? this.state,
    skipReason: skipReasonSetToNull ? null : skipReason ?? this.skipReason,
    rideId: rideIdSetToNull ? null : rideId ?? this.rideId,
    recipe: recipe ?? this.recipe,
    technicalName: technicalName ?? this.technicalName,
    englishName: englishName ?? this.englishName,
    italianName: italianName ?? this.italianName,
    englishLine: englishLine ?? this.englishLine,
    italianLine: italianLine ?? this.italianLine,
    blocks: blocks ?? this.blocks,
    notes: notes ?? this.notes,
    heartRateEstimated: heartRateEstimated ?? this.heartRateEstimated,
    result: result ?? this.result,
  );

  /// Returns a new [TrainingWeekSession] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TrainingWeekSession? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "TrainingWeekSession[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "TrainingWeekSession[id]" has a null value in JSON.');
        assert(json.containsKey(r'localDate'), 'Required key "TrainingWeekSession[localDate]" is missing from JSON.');
        assert(json[r'localDate'] != null, 'Required key "TrainingWeekSession[localDate]" has a null value in JSON.');
        assert(json.containsKey(r'minutes'), 'Required key "TrainingWeekSession[minutes]" is missing from JSON.');
        assert(json[r'minutes'] != null, 'Required key "TrainingWeekSession[minutes]" has a null value in JSON.');
        assert(json.containsKey(r'state'), 'Required key "TrainingWeekSession[state]" is missing from JSON.');
        assert(json[r'state'] != null, 'Required key "TrainingWeekSession[state]" has a null value in JSON.');
        assert(json.containsKey(r'skipReason'), 'Required key "TrainingWeekSession[skipReason]" is missing from JSON.');
        assert(json.containsKey(r'rideId'), 'Required key "TrainingWeekSession[rideId]" is missing from JSON.');
        assert(json.containsKey(r'recipe'), 'Required key "TrainingWeekSession[recipe]" is missing from JSON.');
        assert(json[r'recipe'] != null, 'Required key "TrainingWeekSession[recipe]" has a null value in JSON.');
        assert(json.containsKey(r'technicalName'), 'Required key "TrainingWeekSession[technicalName]" is missing from JSON.');
        assert(json[r'technicalName'] != null, 'Required key "TrainingWeekSession[technicalName]" has a null value in JSON.');
        assert(json.containsKey(r'englishName'), 'Required key "TrainingWeekSession[englishName]" is missing from JSON.');
        assert(json[r'englishName'] != null, 'Required key "TrainingWeekSession[englishName]" has a null value in JSON.');
        assert(json.containsKey(r'italianName'), 'Required key "TrainingWeekSession[italianName]" is missing from JSON.');
        assert(json[r'italianName'] != null, 'Required key "TrainingWeekSession[italianName]" has a null value in JSON.');
        assert(json.containsKey(r'englishLine'), 'Required key "TrainingWeekSession[englishLine]" is missing from JSON.');
        assert(json[r'englishLine'] != null, 'Required key "TrainingWeekSession[englishLine]" has a null value in JSON.');
        assert(json.containsKey(r'italianLine'), 'Required key "TrainingWeekSession[italianLine]" is missing from JSON.');
        assert(json[r'italianLine'] != null, 'Required key "TrainingWeekSession[italianLine]" has a null value in JSON.');
        assert(json.containsKey(r'blocks'), 'Required key "TrainingWeekSession[blocks]" is missing from JSON.');
        assert(json[r'blocks'] != null, 'Required key "TrainingWeekSession[blocks]" has a null value in JSON.');
        assert(json.containsKey(r'notes'), 'Required key "TrainingWeekSession[notes]" is missing from JSON.');
        assert(json[r'notes'] != null, 'Required key "TrainingWeekSession[notes]" has a null value in JSON.');
        assert(json.containsKey(r'heartRateEstimated'), 'Required key "TrainingWeekSession[heartRateEstimated]" is missing from JSON.');
        assert(json[r'heartRateEstimated'] != null, 'Required key "TrainingWeekSession[heartRateEstimated]" has a null value in JSON.');
        return true;
      }());

      return TrainingWeekSession(
        id: mapValueOfType<String>(json, r'id')!,
        localDate: mapDateTime(json, r'localDate', r'')!,
        minutes: mapValueOfType<int>(json, r'minutes')!,
        state: mapValueOfType<String>(json, r'state')!,
        skipReason: mapValueOfType<String>(json, r'skipReason'),
        rideId: mapValueOfType<String>(json, r'rideId'),
        recipe: mapValueOfType<String>(json, r'recipe')!,
        technicalName: mapValueOfType<String>(json, r'technicalName')!,
        englishName: mapValueOfType<String>(json, r'englishName')!,
        italianName: mapValueOfType<String>(json, r'italianName')!,
        englishLine: mapValueOfType<String>(json, r'englishLine')!,
        italianLine: mapValueOfType<String>(json, r'italianLine')!,
        blocks: BlockTarget.listFromJson(json[r'blocks']),
        notes: SessionNote.listFromJson(json[r'notes']),
        heartRateEstimated: mapValueOfType<bool>(json, r'heartRateEstimated')!,
        result: json.containsKey(r'result') ? Optional.present(SessionResult.fromJson(json[r'result'])) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<TrainingWeekSession> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TrainingWeekSession>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TrainingWeekSession.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TrainingWeekSession> mapFromJson(dynamic json) {
    final map = <String, TrainingWeekSession>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TrainingWeekSession.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TrainingWeekSession-objects as value to a dart map
  static Map<String, List<TrainingWeekSession>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TrainingWeekSession>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TrainingWeekSession.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'localDate',
    'minutes',
    'state',
    'skipReason',
    'rideId',
    'recipe',
    'technicalName',
    'englishName',
    'italianName',
    'englishLine',
    'italianLine',
    'blocks',
    'notes',
    'heartRateEstimated',
  };
}

