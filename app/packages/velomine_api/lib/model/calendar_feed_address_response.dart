//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class CalendarFeedAddressResponse {
  /// Returns a new [CalendarFeedAddressResponse] instance.
  CalendarFeedAddressResponse({
    required this.url,
    required this.createdAt,
  });

  final String url;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CalendarFeedAddressResponse &&
    other.url == url &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (url.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'CalendarFeedAddressResponse[url=$url, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'url'] = this.url;
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [CalendarFeedAddressResponse] and returns a new one where some of the
  /// properties have changed.
  CalendarFeedAddressResponse copyWith({
    String? url,
    DateTime? createdAt,
  }) => CalendarFeedAddressResponse(
    url: url ?? this.url,
    createdAt: createdAt ?? this.createdAt,
  );

  /// Returns a new [CalendarFeedAddressResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CalendarFeedAddressResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'url'), 'Required key "CalendarFeedAddressResponse[url]" is missing from JSON.');
        assert(json[r'url'] != null, 'Required key "CalendarFeedAddressResponse[url]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "CalendarFeedAddressResponse[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "CalendarFeedAddressResponse[createdAt]" has a null value in JSON.');
        return true;
      }());

      return CalendarFeedAddressResponse(
        url: mapValueOfType<String>(json, r'url')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<CalendarFeedAddressResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CalendarFeedAddressResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CalendarFeedAddressResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CalendarFeedAddressResponse> mapFromJson(dynamic json) {
    final map = <String, CalendarFeedAddressResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CalendarFeedAddressResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CalendarFeedAddressResponse-objects as value to a dart map
  static Map<String, List<CalendarFeedAddressResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CalendarFeedAddressResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CalendarFeedAddressResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'url',
    'createdAt',
  };
}

