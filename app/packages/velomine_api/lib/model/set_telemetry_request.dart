//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SetTelemetryRequest {
  /// Returns a new [SetTelemetryRequest] instance.
  SetTelemetryRequest({
    required this.crash,
    required this.usage,
  });

  final bool crash;

  final bool usage;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SetTelemetryRequest &&
    other.crash == crash &&
    other.usage == usage;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (crash.hashCode) +
    (usage.hashCode);

  @override
  String toString() => 'SetTelemetryRequest[crash=$crash, usage=$usage]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'crash'] = this.crash;
      json[r'usage'] = this.usage;
    return json;
  }

  /// Clones this instance of [SetTelemetryRequest] and returns a new one where some of the
  /// properties have changed.
  SetTelemetryRequest copyWith({
    bool? crash,
    bool? usage,
  }) => SetTelemetryRequest(
    crash: crash ?? this.crash,
    usage: usage ?? this.usage,
  );

  /// Returns a new [SetTelemetryRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SetTelemetryRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'crash'), 'Required key "SetTelemetryRequest[crash]" is missing from JSON.');
        assert(json[r'crash'] != null, 'Required key "SetTelemetryRequest[crash]" has a null value in JSON.');
        assert(json.containsKey(r'usage'), 'Required key "SetTelemetryRequest[usage]" is missing from JSON.');
        assert(json[r'usage'] != null, 'Required key "SetTelemetryRequest[usage]" has a null value in JSON.');
        return true;
      }());

      return SetTelemetryRequest(
        crash: mapValueOfType<bool>(json, r'crash')!,
        usage: mapValueOfType<bool>(json, r'usage')!,
      );
    }
    return null;
  }

  static List<SetTelemetryRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SetTelemetryRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SetTelemetryRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SetTelemetryRequest> mapFromJson(dynamic json) {
    final map = <String, SetTelemetryRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SetTelemetryRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SetTelemetryRequest-objects as value to a dart map
  static Map<String, List<SetTelemetryRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SetTelemetryRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SetTelemetryRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'crash',
    'usage',
  };
}

