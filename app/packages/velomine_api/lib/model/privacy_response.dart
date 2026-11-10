//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class PrivacyResponse {
  /// Returns a new [PrivacyResponse] instance.
  PrivacyResponse({
    required this.streams,
    required this.trimStartM,
    required this.trimEndM,
    this.zones = const [],
  });

  final PrivacyStreamsResponse streams;

  final int trimStartM;

  final int trimEndM;

  final List<PrivacyZoneResponse> zones;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PrivacyResponse &&
    other.streams == streams &&
    other.trimStartM == trimStartM &&
    other.trimEndM == trimEndM &&
    _deepEquality.equals(other.zones, zones);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (streams.hashCode) +
    (trimStartM.hashCode) +
    (trimEndM.hashCode) +
    (zones.hashCode);

  @override
  String toString() => 'PrivacyResponse[streams=$streams, trimStartM=$trimStartM, trimEndM=$trimEndM, zones=$zones]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'streams'] = this.streams;
      json[r'trimStartM'] = this.trimStartM;
      json[r'trimEndM'] = this.trimEndM;
      json[r'zones'] = this.zones;
    return json;
  }

  /// Clones this instance of [PrivacyResponse] and returns a new one where some of the
  /// properties have changed.
  PrivacyResponse copyWith({
    PrivacyStreamsResponse? streams,
    int? trimStartM,
    int? trimEndM,
    List<PrivacyZoneResponse>? zones,
  }) => PrivacyResponse(
    streams: streams ?? this.streams,
    trimStartM: trimStartM ?? this.trimStartM,
    trimEndM: trimEndM ?? this.trimEndM,
    zones: zones ?? this.zones,
  );

  /// Returns a new [PrivacyResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PrivacyResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'streams'), 'Required key "PrivacyResponse[streams]" is missing from JSON.');
        assert(json[r'streams'] != null, 'Required key "PrivacyResponse[streams]" has a null value in JSON.');
        assert(json.containsKey(r'trimStartM'), 'Required key "PrivacyResponse[trimStartM]" is missing from JSON.');
        assert(json[r'trimStartM'] != null, 'Required key "PrivacyResponse[trimStartM]" has a null value in JSON.');
        assert(json.containsKey(r'trimEndM'), 'Required key "PrivacyResponse[trimEndM]" is missing from JSON.');
        assert(json[r'trimEndM'] != null, 'Required key "PrivacyResponse[trimEndM]" has a null value in JSON.');
        assert(json.containsKey(r'zones'), 'Required key "PrivacyResponse[zones]" is missing from JSON.');
        assert(json[r'zones'] != null, 'Required key "PrivacyResponse[zones]" has a null value in JSON.');
        return true;
      }());

      return PrivacyResponse(
        streams: PrivacyStreamsResponse.fromJson(json[r'streams'])!,
        trimStartM: mapValueOfType<int>(json, r'trimStartM')!,
        trimEndM: mapValueOfType<int>(json, r'trimEndM')!,
        zones: PrivacyZoneResponse.listFromJson(json[r'zones']),
      );
    }
    return null;
  }

  static List<PrivacyResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PrivacyResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PrivacyResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PrivacyResponse> mapFromJson(dynamic json) {
    final map = <String, PrivacyResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PrivacyResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PrivacyResponse-objects as value to a dart map
  static Map<String, List<PrivacyResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PrivacyResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PrivacyResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'streams',
    'trimStartM',
    'trimEndM',
    'zones',
  };
}

