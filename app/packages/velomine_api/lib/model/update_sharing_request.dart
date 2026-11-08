//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class UpdateSharingRequest {
  /// Returns a new [UpdateSharingRequest] instance.
  UpdateSharingRequest({
    required this.rides,
    required this.analytics,
    required this.routes,
  });

  final String rides;

  final String analytics;

  final String routes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UpdateSharingRequest &&
    other.rides == rides &&
    other.analytics == analytics &&
    other.routes == routes;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (rides.hashCode) +
    (analytics.hashCode) +
    (routes.hashCode);

  @override
  String toString() => 'UpdateSharingRequest[rides=$rides, analytics=$analytics, routes=$routes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'rides'] = this.rides;
      json[r'analytics'] = this.analytics;
      json[r'routes'] = this.routes;
    return json;
  }

  /// Clones this instance of [UpdateSharingRequest] and returns a new one where some of the
  /// properties have changed.
  UpdateSharingRequest copyWith({
    String? rides,
    String? analytics,
    String? routes,
  }) => UpdateSharingRequest(
    rides: rides ?? this.rides,
    analytics: analytics ?? this.analytics,
    routes: routes ?? this.routes,
  );

  /// Returns a new [UpdateSharingRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateSharingRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'rides'), 'Required key "UpdateSharingRequest[rides]" is missing from JSON.');
        assert(json[r'rides'] != null, 'Required key "UpdateSharingRequest[rides]" has a null value in JSON.');
        assert(json.containsKey(r'analytics'), 'Required key "UpdateSharingRequest[analytics]" is missing from JSON.');
        assert(json[r'analytics'] != null, 'Required key "UpdateSharingRequest[analytics]" has a null value in JSON.');
        assert(json.containsKey(r'routes'), 'Required key "UpdateSharingRequest[routes]" is missing from JSON.');
        assert(json[r'routes'] != null, 'Required key "UpdateSharingRequest[routes]" has a null value in JSON.');
        return true;
      }());

      return UpdateSharingRequest(
        rides: mapValueOfType<String>(json, r'rides')!,
        analytics: mapValueOfType<String>(json, r'analytics')!,
        routes: mapValueOfType<String>(json, r'routes')!,
      );
    }
    return null;
  }

  static List<UpdateSharingRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UpdateSharingRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateSharingRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateSharingRequest> mapFromJson(dynamic json) {
    final map = <String, UpdateSharingRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateSharingRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateSharingRequest-objects as value to a dart map
  static Map<String, List<UpdateSharingRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UpdateSharingRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateSharingRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'rides',
    'analytics',
    'routes',
  };
}

