//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SetZonesRequest {
  /// Returns a new [SetZonesRequest] instance.
  SetZonesRequest({
    this.bounds = const [],
  });

  final List<double> bounds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SetZonesRequest &&
    _deepEquality.equals(other.bounds, bounds);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (bounds.hashCode);

  @override
  String toString() => 'SetZonesRequest[bounds=$bounds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'bounds'] = this.bounds;
    return json;
  }

  /// Clones this instance of [SetZonesRequest] and returns a new one where some of the
  /// properties have changed.
  SetZonesRequest copyWith({
    List<double>? bounds,
  }) => SetZonesRequest(
    bounds: bounds ?? this.bounds,
  );

  /// Returns a new [SetZonesRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SetZonesRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'bounds'), 'Required key "SetZonesRequest[bounds]" is missing from JSON.');
        assert(json[r'bounds'] != null, 'Required key "SetZonesRequest[bounds]" has a null value in JSON.');
        return true;
      }());

      return SetZonesRequest(
        bounds: json[r'bounds'] is Iterable
            ? (json[r'bounds'] as Iterable).map((e) => (e as num).toDouble()).toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<SetZonesRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SetZonesRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SetZonesRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SetZonesRequest> mapFromJson(dynamic json) {
    final map = <String, SetZonesRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SetZonesRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SetZonesRequest-objects as value to a dart map
  static Map<String, List<SetZonesRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SetZonesRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SetZonesRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'bounds',
  };
}

