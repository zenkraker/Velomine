//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ListBikesResponse {
  /// Returns a new [ListBikesResponse] instance.
  ListBikesResponse({
    this.bikes = const [],
  });

  final List<BikeResponse> bikes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ListBikesResponse &&
    _deepEquality.equals(other.bikes, bikes);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (bikes.hashCode);

  @override
  String toString() => 'ListBikesResponse[bikes=$bikes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'bikes'] = this.bikes;
    return json;
  }

  /// Clones this instance of [ListBikesResponse] and returns a new one where some of the
  /// properties have changed.
  ListBikesResponse copyWith({
    List<BikeResponse>? bikes,
  }) => ListBikesResponse(
    bikes: bikes ?? this.bikes,
  );

  /// Returns a new [ListBikesResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ListBikesResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'bikes'), 'Required key "ListBikesResponse[bikes]" is missing from JSON.');
        assert(json[r'bikes'] != null, 'Required key "ListBikesResponse[bikes]" has a null value in JSON.');
        return true;
      }());

      return ListBikesResponse(
        bikes: BikeResponse.listFromJson(json[r'bikes']),
      );
    }
    return null;
  }

  static List<ListBikesResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListBikesResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListBikesResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ListBikesResponse> mapFromJson(dynamic json) {
    final map = <String, ListBikesResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ListBikesResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ListBikesResponse-objects as value to a dart map
  static Map<String, List<ListBikesResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ListBikesResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ListBikesResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'bikes',
  };
}

