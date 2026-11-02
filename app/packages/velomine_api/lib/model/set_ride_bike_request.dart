//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SetRideBikeRequest {
  /// Returns a new [SetRideBikeRequest] instance.
  SetRideBikeRequest({
    this.bikeId = const Optional.absent(),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> bikeId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SetRideBikeRequest &&
    other.bikeId == bikeId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (bikeId == null ? 0 : bikeId!.hashCode);

  @override
  String toString() => 'SetRideBikeRequest[bikeId=$bikeId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.bikeId.isPresent) {
      final value = this.bikeId.value;
      json[r'bikeId'] = value;
    }
    return json;
  }

  /// Clones this instance of [SetRideBikeRequest] and returns a new one where some of the
  /// properties have changed.
  SetRideBikeRequest copyWith({
    Optional<String?>? bikeId,
  }) => SetRideBikeRequest(
    bikeId: bikeId ?? this.bikeId,
  );

  /// Returns a new [SetRideBikeRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SetRideBikeRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return SetRideBikeRequest(
        bikeId: json.containsKey(r'bikeId') ? Optional.present(mapValueOfType<String>(json, r'bikeId')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<SetRideBikeRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SetRideBikeRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SetRideBikeRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SetRideBikeRequest> mapFromJson(dynamic json) {
    final map = <String, SetRideBikeRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SetRideBikeRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SetRideBikeRequest-objects as value to a dart map
  static Map<String, List<SetRideBikeRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SetRideBikeRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SetRideBikeRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

