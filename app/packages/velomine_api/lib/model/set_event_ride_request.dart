//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SetEventRideRequest {
  /// Returns a new [SetEventRideRequest] instance.
  SetEventRideRequest({
    this.rideId = const Optional.present(null),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> rideId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SetEventRideRequest &&
    other.rideId == rideId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (rideId == null ? 0 : rideId!.hashCode);

  @override
  String toString() => 'SetEventRideRequest[rideId=$rideId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.rideId.isPresent) {
      final value = this.rideId.value;
      json[r'rideId'] = value;
    }
    return json;
  }

  /// Clones this instance of [SetEventRideRequest] and returns a new one where some of the
  /// properties have changed.
  SetEventRideRequest copyWith({
    Optional<String?>? rideId,
  }) => SetEventRideRequest(
    rideId: rideId ?? this.rideId,
  );

  /// Returns a new [SetEventRideRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SetEventRideRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return SetEventRideRequest(
        rideId: json.containsKey(r'rideId') ? Optional.present(mapValueOfType<String>(json, r'rideId')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<SetEventRideRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SetEventRideRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SetEventRideRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SetEventRideRequest> mapFromJson(dynamic json) {
    final map = <String, SetEventRideRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SetEventRideRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SetEventRideRequest-objects as value to a dart map
  static Map<String, List<SetEventRideRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SetEventRideRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SetEventRideRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

