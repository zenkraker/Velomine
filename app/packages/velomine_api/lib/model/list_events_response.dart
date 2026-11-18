//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ListEventsResponse {
  /// Returns a new [ListEventsResponse] instance.
  ListEventsResponse({
    this.events = const [],
  });

  final List<EventResponse> events;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ListEventsResponse &&
    _deepEquality.equals(other.events, events);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (events.hashCode);

  @override
  String toString() => 'ListEventsResponse[events=$events]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'events'] = this.events;
    return json;
  }

  /// Clones this instance of [ListEventsResponse] and returns a new one where some of the
  /// properties have changed.
  ListEventsResponse copyWith({
    List<EventResponse>? events,
  }) => ListEventsResponse(
    events: events ?? this.events,
  );

  /// Returns a new [ListEventsResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ListEventsResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'events'), 'Required key "ListEventsResponse[events]" is missing from JSON.');
        assert(json[r'events'] != null, 'Required key "ListEventsResponse[events]" has a null value in JSON.');
        return true;
      }());

      return ListEventsResponse(
        events: EventResponse.listFromJson(json[r'events']),
      );
    }
    return null;
  }

  static List<ListEventsResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListEventsResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListEventsResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ListEventsResponse> mapFromJson(dynamic json) {
    final map = <String, ListEventsResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ListEventsResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ListEventsResponse-objects as value to a dart map
  static Map<String, List<ListEventsResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ListEventsResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ListEventsResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'events',
  };
}

