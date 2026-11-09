//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class TelemetryResponse {
  /// Returns a new [TelemetryResponse] instance.
  TelemetryResponse({
    required this.consentRequired,
    required this.crash,
    required this.usage,
    required this.version,
  });

  final bool consentRequired;

  final bool crash;

  final bool usage;

  final int version;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TelemetryResponse &&
    other.consentRequired == consentRequired &&
    other.crash == crash &&
    other.usage == usage &&
    other.version == version;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (consentRequired.hashCode) +
    (crash.hashCode) +
    (usage.hashCode) +
    (version.hashCode);

  @override
  String toString() => 'TelemetryResponse[consentRequired=$consentRequired, crash=$crash, usage=$usage, version=$version]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'consentRequired'] = this.consentRequired;
      json[r'crash'] = this.crash;
      json[r'usage'] = this.usage;
      json[r'version'] = this.version;
    return json;
  }

  /// Clones this instance of [TelemetryResponse] and returns a new one where some of the
  /// properties have changed.
  TelemetryResponse copyWith({
    bool? consentRequired,
    bool? crash,
    bool? usage,
    int? version,
  }) => TelemetryResponse(
    consentRequired: consentRequired ?? this.consentRequired,
    crash: crash ?? this.crash,
    usage: usage ?? this.usage,
    version: version ?? this.version,
  );

  /// Returns a new [TelemetryResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TelemetryResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'consentRequired'), 'Required key "TelemetryResponse[consentRequired]" is missing from JSON.');
        assert(json[r'consentRequired'] != null, 'Required key "TelemetryResponse[consentRequired]" has a null value in JSON.');
        assert(json.containsKey(r'crash'), 'Required key "TelemetryResponse[crash]" is missing from JSON.');
        assert(json[r'crash'] != null, 'Required key "TelemetryResponse[crash]" has a null value in JSON.');
        assert(json.containsKey(r'usage'), 'Required key "TelemetryResponse[usage]" is missing from JSON.');
        assert(json[r'usage'] != null, 'Required key "TelemetryResponse[usage]" has a null value in JSON.');
        assert(json.containsKey(r'version'), 'Required key "TelemetryResponse[version]" is missing from JSON.');
        assert(json[r'version'] != null, 'Required key "TelemetryResponse[version]" has a null value in JSON.');
        return true;
      }());

      return TelemetryResponse(
        consentRequired: mapValueOfType<bool>(json, r'consentRequired')!,
        crash: mapValueOfType<bool>(json, r'crash')!,
        usage: mapValueOfType<bool>(json, r'usage')!,
        version: mapValueOfType<int>(json, r'version')!,
      );
    }
    return null;
  }

  static List<TelemetryResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TelemetryResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TelemetryResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TelemetryResponse> mapFromJson(dynamic json) {
    final map = <String, TelemetryResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TelemetryResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TelemetryResponse-objects as value to a dart map
  static Map<String, List<TelemetryResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TelemetryResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TelemetryResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'consentRequired',
    'crash',
    'usage',
    'version',
  };
}

