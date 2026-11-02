//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class UploadRideResponse {
  /// Returns a new [UploadRideResponse] instance.
  UploadRideResponse({
    required this.rideId,
    required this.status,
  });

  final String rideId;

  final String status;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UploadRideResponse &&
    other.rideId == rideId &&
    other.status == status;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (rideId.hashCode) +
    (status.hashCode);

  @override
  String toString() => 'UploadRideResponse[rideId=$rideId, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'rideId'] = this.rideId;
      json[r'status'] = this.status;
    return json;
  }

  /// Clones this instance of [UploadRideResponse] and returns a new one where some of the
  /// properties have changed.
  UploadRideResponse copyWith({
    String? rideId,
    String? status,
  }) => UploadRideResponse(
    rideId: rideId ?? this.rideId,
    status: status ?? this.status,
  );

  /// Returns a new [UploadRideResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UploadRideResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'rideId'), 'Required key "UploadRideResponse[rideId]" is missing from JSON.');
        assert(json[r'rideId'] != null, 'Required key "UploadRideResponse[rideId]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "UploadRideResponse[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "UploadRideResponse[status]" has a null value in JSON.');
        return true;
      }());

      return UploadRideResponse(
        rideId: mapValueOfType<String>(json, r'rideId')!,
        status: mapValueOfType<String>(json, r'status')!,
      );
    }
    return null;
  }

  static List<UploadRideResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UploadRideResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UploadRideResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UploadRideResponse> mapFromJson(dynamic json) {
    final map = <String, UploadRideResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UploadRideResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UploadRideResponse-objects as value to a dart map
  static Map<String, List<UploadRideResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UploadRideResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UploadRideResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'rideId',
    'status',
  };
}

