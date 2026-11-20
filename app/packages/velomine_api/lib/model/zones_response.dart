//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ZonesResponse {
  /// Returns a new [ZonesResponse] instance.
  ZonesResponse({
    this.sets = const [],
    required this.heartRateModel,
  });

  final List<ZoneSetResponse> sets;

  final String? heartRateModel;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ZonesResponse &&
    _deepEquality.equals(other.sets, sets) &&
    other.heartRateModel == heartRateModel;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (sets.hashCode) +
    (heartRateModel == null ? 0 : heartRateModel!.hashCode);

  @override
  String toString() => 'ZonesResponse[sets=$sets, heartRateModel=$heartRateModel]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'sets'] = this.sets;
    if (this.heartRateModel != null) {
      json[r'heartRateModel'] = this.heartRateModel;
    } else {
      json[r'heartRateModel'] = null;
    }
    return json;
  }

  /// Clones this instance of [ZonesResponse] and returns a new one where some of the
  /// properties have changed.
  ZonesResponse copyWith({
    List<ZoneSetResponse>? sets,
    String? heartRateModel,
    bool heartRateModelSetToNull = false,
  }) => ZonesResponse(
    sets: sets ?? this.sets,
    heartRateModel: heartRateModelSetToNull ? null : heartRateModel ?? this.heartRateModel,
  );

  /// Returns a new [ZonesResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ZonesResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'sets'), 'Required key "ZonesResponse[sets]" is missing from JSON.');
        assert(json[r'sets'] != null, 'Required key "ZonesResponse[sets]" has a null value in JSON.');
        assert(json.containsKey(r'heartRateModel'), 'Required key "ZonesResponse[heartRateModel]" is missing from JSON.');
        return true;
      }());

      return ZonesResponse(
        sets: ZoneSetResponse.listFromJson(json[r'sets']),
        heartRateModel: mapValueOfType<String>(json, r'heartRateModel'),
      );
    }
    return null;
  }

  static List<ZonesResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ZonesResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ZonesResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ZonesResponse> mapFromJson(dynamic json) {
    final map = <String, ZonesResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ZonesResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ZonesResponse-objects as value to a dart map
  static Map<String, List<ZonesResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ZonesResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ZonesResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'sets',
    'heartRateModel',
  };
}

