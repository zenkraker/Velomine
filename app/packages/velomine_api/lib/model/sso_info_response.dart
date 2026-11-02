//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SsoInfoResponse {
  /// Returns a new [SsoInfoResponse] instance.
  SsoInfoResponse({
    required this.enabled,
    required this.displayName,
    required this.loginUrl,
  });

  final bool enabled;

  final String? displayName;

  final String? loginUrl;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SsoInfoResponse &&
    other.enabled == enabled &&
    other.displayName == displayName &&
    other.loginUrl == loginUrl;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (enabled.hashCode) +
    (displayName == null ? 0 : displayName!.hashCode) +
    (loginUrl == null ? 0 : loginUrl!.hashCode);

  @override
  String toString() => 'SsoInfoResponse[enabled=$enabled, displayName=$displayName, loginUrl=$loginUrl]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'enabled'] = this.enabled;
    if (this.displayName != null) {
      json[r'displayName'] = this.displayName;
    } else {
      json[r'displayName'] = null;
    }
    if (this.loginUrl != null) {
      json[r'loginUrl'] = this.loginUrl;
    } else {
      json[r'loginUrl'] = null;
    }
    return json;
  }

  /// Clones this instance of [SsoInfoResponse] and returns a new one where some of the
  /// properties have changed.
  SsoInfoResponse copyWith({
    bool? enabled,
    String? displayName,
    bool displayNameSetToNull = false,
    String? loginUrl,
    bool loginUrlSetToNull = false,
  }) => SsoInfoResponse(
    enabled: enabled ?? this.enabled,
    displayName: displayNameSetToNull ? null : displayName ?? this.displayName,
    loginUrl: loginUrlSetToNull ? null : loginUrl ?? this.loginUrl,
  );

  /// Returns a new [SsoInfoResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SsoInfoResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'enabled'), 'Required key "SsoInfoResponse[enabled]" is missing from JSON.');
        assert(json[r'enabled'] != null, 'Required key "SsoInfoResponse[enabled]" has a null value in JSON.');
        assert(json.containsKey(r'displayName'), 'Required key "SsoInfoResponse[displayName]" is missing from JSON.');
        assert(json.containsKey(r'loginUrl'), 'Required key "SsoInfoResponse[loginUrl]" is missing from JSON.');
        return true;
      }());

      return SsoInfoResponse(
        enabled: mapValueOfType<bool>(json, r'enabled')!,
        displayName: mapValueOfType<String>(json, r'displayName'),
        loginUrl: mapValueOfType<String>(json, r'loginUrl'),
      );
    }
    return null;
  }

  static List<SsoInfoResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SsoInfoResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SsoInfoResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SsoInfoResponse> mapFromJson(dynamic json) {
    final map = <String, SsoInfoResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SsoInfoResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SsoInfoResponse-objects as value to a dart map
  static Map<String, List<SsoInfoResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SsoInfoResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SsoInfoResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'enabled',
    'displayName',
    'loginUrl',
  };
}

