//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SsoStatus {
  /// Returns a new [SsoStatus] instance.
  SsoStatus({
    required this.enabled,
    required this.displayName,
    required this.authority,
  });

  final bool enabled;

  final String? displayName;

  final String? authority;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SsoStatus &&
    other.enabled == enabled &&
    other.displayName == displayName &&
    other.authority == authority;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (enabled.hashCode) +
    (displayName == null ? 0 : displayName!.hashCode) +
    (authority == null ? 0 : authority!.hashCode);

  @override
  String toString() => 'SsoStatus[enabled=$enabled, displayName=$displayName, authority=$authority]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'enabled'] = this.enabled;
    if (this.displayName != null) {
      json[r'displayName'] = this.displayName;
    } else {
      json[r'displayName'] = null;
    }
    if (this.authority != null) {
      json[r'authority'] = this.authority;
    } else {
      json[r'authority'] = null;
    }
    return json;
  }

  /// Clones this instance of [SsoStatus] and returns a new one where some of the
  /// properties have changed.
  SsoStatus copyWith({
    bool? enabled,
    String? displayName,
    bool displayNameSetToNull = false,
    String? authority,
    bool authoritySetToNull = false,
  }) => SsoStatus(
    enabled: enabled ?? this.enabled,
    displayName: displayNameSetToNull ? null : displayName ?? this.displayName,
    authority: authoritySetToNull ? null : authority ?? this.authority,
  );

  /// Returns a new [SsoStatus] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SsoStatus? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'enabled'), 'Required key "SsoStatus[enabled]" is missing from JSON.');
        assert(json[r'enabled'] != null, 'Required key "SsoStatus[enabled]" has a null value in JSON.');
        assert(json.containsKey(r'displayName'), 'Required key "SsoStatus[displayName]" is missing from JSON.');
        assert(json.containsKey(r'authority'), 'Required key "SsoStatus[authority]" is missing from JSON.');
        return true;
      }());

      return SsoStatus(
        enabled: mapValueOfType<bool>(json, r'enabled')!,
        displayName: mapValueOfType<String>(json, r'displayName'),
        authority: mapValueOfType<String>(json, r'authority'),
      );
    }
    return null;
  }

  static List<SsoStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SsoStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SsoStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SsoStatus> mapFromJson(dynamic json) {
    final map = <String, SsoStatus>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SsoStatus.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SsoStatus-objects as value to a dart map
  static Map<String, List<SsoStatus>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SsoStatus>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SsoStatus.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'enabled',
    'displayName',
    'authority',
  };
}

