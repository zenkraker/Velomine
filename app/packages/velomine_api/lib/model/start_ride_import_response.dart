//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class StartRideImportResponse {
  /// Returns a new [StartRideImportResponse] instance.
  StartRideImportResponse({
    required this.importId,
    required this.status,
  });

  final String importId;

  final String status;

  @override
  bool operator ==(Object other) => identical(this, other) || other is StartRideImportResponse &&
    other.importId == importId &&
    other.status == status;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (importId.hashCode) +
    (status.hashCode);

  @override
  String toString() => 'StartRideImportResponse[importId=$importId, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'importId'] = this.importId;
      json[r'status'] = this.status;
    return json;
  }

  /// Clones this instance of [StartRideImportResponse] and returns a new one where some of the
  /// properties have changed.
  StartRideImportResponse copyWith({
    String? importId,
    String? status,
  }) => StartRideImportResponse(
    importId: importId ?? this.importId,
    status: status ?? this.status,
  );

  /// Returns a new [StartRideImportResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StartRideImportResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'importId'), 'Required key "StartRideImportResponse[importId]" is missing from JSON.');
        assert(json[r'importId'] != null, 'Required key "StartRideImportResponse[importId]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "StartRideImportResponse[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "StartRideImportResponse[status]" has a null value in JSON.');
        return true;
      }());

      return StartRideImportResponse(
        importId: mapValueOfType<String>(json, r'importId')!,
        status: mapValueOfType<String>(json, r'status')!,
      );
    }
    return null;
  }

  static List<StartRideImportResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <StartRideImportResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StartRideImportResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StartRideImportResponse> mapFromJson(dynamic json) {
    final map = <String, StartRideImportResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StartRideImportResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StartRideImportResponse-objects as value to a dart map
  static Map<String, List<StartRideImportResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<StartRideImportResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StartRideImportResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'importId',
    'status',
  };
}

