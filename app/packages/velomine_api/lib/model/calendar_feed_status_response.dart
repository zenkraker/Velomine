//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class CalendarFeedStatusResponse {
  /// Returns a new [CalendarFeedStatusResponse] instance.
  CalendarFeedStatusResponse({
    required this.active,
    required this.createdAt,
  });

  final bool active;

  final DateTime? createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CalendarFeedStatusResponse &&
    other.active == active &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (active.hashCode) +
    (createdAt == null ? 0 : createdAt!.hashCode);

  @override
  String toString() => 'CalendarFeedStatusResponse[active=$active, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'active'] = this.active;
    if (this.createdAt != null) {
      json[r'createdAt'] = this.createdAt!.toUtc().toIso8601String();
    } else {
      json[r'createdAt'] = null;
    }
    return json;
  }

  /// Clones this instance of [CalendarFeedStatusResponse] and returns a new one where some of the
  /// properties have changed.
  CalendarFeedStatusResponse copyWith({
    bool? active,
    DateTime? createdAt,
    bool createdAtSetToNull = false,
  }) => CalendarFeedStatusResponse(
    active: active ?? this.active,
    createdAt: createdAtSetToNull ? null : createdAt ?? this.createdAt,
  );

  /// Returns a new [CalendarFeedStatusResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CalendarFeedStatusResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'active'), 'Required key "CalendarFeedStatusResponse[active]" is missing from JSON.');
        assert(json[r'active'] != null, 'Required key "CalendarFeedStatusResponse[active]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "CalendarFeedStatusResponse[createdAt]" is missing from JSON.');
        return true;
      }());

      return CalendarFeedStatusResponse(
        active: mapValueOfType<bool>(json, r'active')!,
        createdAt: mapDateTime(json, r'createdAt', r''),
      );
    }
    return null;
  }

  static List<CalendarFeedStatusResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CalendarFeedStatusResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CalendarFeedStatusResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CalendarFeedStatusResponse> mapFromJson(dynamic json) {
    final map = <String, CalendarFeedStatusResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CalendarFeedStatusResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CalendarFeedStatusResponse-objects as value to a dart map
  static Map<String, List<CalendarFeedStatusResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CalendarFeedStatusResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CalendarFeedStatusResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'active',
    'createdAt',
  };
}

