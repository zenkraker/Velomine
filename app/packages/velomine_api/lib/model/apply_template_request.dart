//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ApplyTemplateRequest {
  /// Returns a new [ApplyTemplateRequest] instance.
  ApplyTemplateRequest({
    required this.installedOn,
  });

  final DateTime installedOn;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ApplyTemplateRequest &&
    other.installedOn == installedOn;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (installedOn.hashCode);

  @override
  String toString() => 'ApplyTemplateRequest[installedOn=$installedOn]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'installedOn'] = _dateFormatter.format(this.installedOn);
    return json;
  }

  /// Clones this instance of [ApplyTemplateRequest] and returns a new one where some of the
  /// properties have changed.
  ApplyTemplateRequest copyWith({
    DateTime? installedOn,
  }) => ApplyTemplateRequest(
    installedOn: installedOn ?? this.installedOn,
  );

  /// Returns a new [ApplyTemplateRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ApplyTemplateRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'installedOn'), 'Required key "ApplyTemplateRequest[installedOn]" is missing from JSON.');
        assert(json[r'installedOn'] != null, 'Required key "ApplyTemplateRequest[installedOn]" has a null value in JSON.');
        return true;
      }());

      return ApplyTemplateRequest(
        installedOn: mapDateTime(json, r'installedOn', r'')!,
      );
    }
    return null;
  }

  static List<ApplyTemplateRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ApplyTemplateRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApplyTemplateRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ApplyTemplateRequest> mapFromJson(dynamic json) {
    final map = <String, ApplyTemplateRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ApplyTemplateRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ApplyTemplateRequest-objects as value to a dart map
  static Map<String, List<ApplyTemplateRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ApplyTemplateRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ApplyTemplateRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'installedOn',
  };
}

