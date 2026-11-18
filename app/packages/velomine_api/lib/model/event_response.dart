//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class EventResponse {
  /// Returns a new [EventResponse] instance.
  EventResponse({
    required this.id,
    required this.name,
    required this.date,
    required this.kind,
    required this.distanceM,
    required this.elevationGainM,
    required this.notes,
    required this.rideId,
    required this.createdAt,
  });

  final String id;

  final String name;

  final DateTime date;

  final String kind;

  final double? distanceM;

  final double? elevationGainM;

  final String? notes;

  final String? rideId;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is EventResponse &&
    other.id == id &&
    other.name == name &&
    other.date == date &&
    other.kind == kind &&
    other.distanceM == distanceM &&
    other.elevationGainM == elevationGainM &&
    other.notes == notes &&
    other.rideId == rideId &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (date.hashCode) +
    (kind.hashCode) +
    (distanceM == null ? 0 : distanceM!.hashCode) +
    (elevationGainM == null ? 0 : elevationGainM!.hashCode) +
    (notes == null ? 0 : notes!.hashCode) +
    (rideId == null ? 0 : rideId!.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'EventResponse[id=$id, name=$name, date=$date, kind=$kind, distanceM=$distanceM, elevationGainM=$elevationGainM, notes=$notes, rideId=$rideId, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'date'] = _dateFormatter.format(this.date);
      json[r'kind'] = this.kind;
    if (this.distanceM != null) {
      json[r'distanceM'] = this.distanceM;
    } else {
      json[r'distanceM'] = null;
    }
    if (this.elevationGainM != null) {
      json[r'elevationGainM'] = this.elevationGainM;
    } else {
      json[r'elevationGainM'] = null;
    }
    if (this.notes != null) {
      json[r'notes'] = this.notes;
    } else {
      json[r'notes'] = null;
    }
    if (this.rideId != null) {
      json[r'rideId'] = this.rideId;
    } else {
      json[r'rideId'] = null;
    }
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [EventResponse] and returns a new one where some of the
  /// properties have changed.
  EventResponse copyWith({
    String? id,
    String? name,
    DateTime? date,
    String? kind,
    double? distanceM,
    bool distanceMSetToNull = false,
    double? elevationGainM,
    bool elevationGainMSetToNull = false,
    String? notes,
    bool notesSetToNull = false,
    String? rideId,
    bool rideIdSetToNull = false,
    DateTime? createdAt,
  }) => EventResponse(
    id: id ?? this.id,
    name: name ?? this.name,
    date: date ?? this.date,
    kind: kind ?? this.kind,
    distanceM: distanceMSetToNull ? null : distanceM ?? this.distanceM,
    elevationGainM: elevationGainMSetToNull ? null : elevationGainM ?? this.elevationGainM,
    notes: notesSetToNull ? null : notes ?? this.notes,
    rideId: rideIdSetToNull ? null : rideId ?? this.rideId,
    createdAt: createdAt ?? this.createdAt,
  );

  /// Returns a new [EventResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static EventResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "EventResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "EventResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "EventResponse[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "EventResponse[name]" has a null value in JSON.');
        assert(json.containsKey(r'date'), 'Required key "EventResponse[date]" is missing from JSON.');
        assert(json[r'date'] != null, 'Required key "EventResponse[date]" has a null value in JSON.');
        assert(json.containsKey(r'kind'), 'Required key "EventResponse[kind]" is missing from JSON.');
        assert(json[r'kind'] != null, 'Required key "EventResponse[kind]" has a null value in JSON.');
        assert(json.containsKey(r'distanceM'), 'Required key "EventResponse[distanceM]" is missing from JSON.');
        assert(json.containsKey(r'elevationGainM'), 'Required key "EventResponse[elevationGainM]" is missing from JSON.');
        assert(json.containsKey(r'notes'), 'Required key "EventResponse[notes]" is missing from JSON.');
        assert(json.containsKey(r'rideId'), 'Required key "EventResponse[rideId]" is missing from JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "EventResponse[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "EventResponse[createdAt]" has a null value in JSON.');
        return true;
      }());

      return EventResponse(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        date: mapDateTime(json, r'date', r'')!,
        kind: mapValueOfType<String>(json, r'kind')!,
        distanceM: mapValueOfType<double>(json, r'distanceM'),
        elevationGainM: mapValueOfType<double>(json, r'elevationGainM'),
        notes: mapValueOfType<String>(json, r'notes'),
        rideId: mapValueOfType<String>(json, r'rideId'),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<EventResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <EventResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = EventResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, EventResponse> mapFromJson(dynamic json) {
    final map = <String, EventResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = EventResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of EventResponse-objects as value to a dart map
  static Map<String, List<EventResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<EventResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = EventResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'date',
    'kind',
    'distanceM',
    'elevationGainM',
    'notes',
    'rideId',
    'createdAt',
  };
}

