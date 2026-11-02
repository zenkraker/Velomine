//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ListRidesResponse {
  /// Returns a new [ListRidesResponse] instance.
  ListRidesResponse({
    this.rides = const [],
    required this.next,
  });

  final List<RideResponse> rides;

  final String? next;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ListRidesResponse &&
    _deepEquality.equals(other.rides, rides) &&
    other.next == next;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (rides.hashCode) +
    (next == null ? 0 : next!.hashCode);

  @override
  String toString() => 'ListRidesResponse[rides=$rides, next=$next]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'rides'] = this.rides;
    if (this.next != null) {
      json[r'next'] = this.next;
    } else {
      json[r'next'] = null;
    }
    return json;
  }

  /// Clones this instance of [ListRidesResponse] and returns a new one where some of the
  /// properties have changed.
  ListRidesResponse copyWith({
    List<RideResponse>? rides,
    String? next,
    bool nextSetToNull = false,
  }) => ListRidesResponse(
    rides: rides ?? this.rides,
    next: nextSetToNull ? null : next ?? this.next,
  );

  /// Returns a new [ListRidesResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ListRidesResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'rides'), 'Required key "ListRidesResponse[rides]" is missing from JSON.');
        assert(json[r'rides'] != null, 'Required key "ListRidesResponse[rides]" has a null value in JSON.');
        assert(json.containsKey(r'next'), 'Required key "ListRidesResponse[next]" is missing from JSON.');
        return true;
      }());

      return ListRidesResponse(
        rides: RideResponse.listFromJson(json[r'rides']),
        next: mapValueOfType<String>(json, r'next'),
      );
    }
    return null;
  }

  static List<ListRidesResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListRidesResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListRidesResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ListRidesResponse> mapFromJson(dynamic json) {
    final map = <String, ListRidesResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ListRidesResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ListRidesResponse-objects as value to a dart map
  static Map<String, List<ListRidesResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ListRidesResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ListRidesResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'rides',
    'next',
  };
}

