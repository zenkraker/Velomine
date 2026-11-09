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
    required this.appSsoEnabled,
    required this.appAuthority,
    required this.appClientId,
    this.appScopes = const [],
    required this.appRedirectUri,
  });

  final bool enabled;

  final String? displayName;

  final String? loginUrl;

  final bool appSsoEnabled;

  final String? appAuthority;

  final String? appClientId;

  final List<String> appScopes;

  final String? appRedirectUri;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SsoInfoResponse &&
    other.enabled == enabled &&
    other.displayName == displayName &&
    other.loginUrl == loginUrl &&
    other.appSsoEnabled == appSsoEnabled &&
    other.appAuthority == appAuthority &&
    other.appClientId == appClientId &&
    _deepEquality.equals(other.appScopes, appScopes) &&
    other.appRedirectUri == appRedirectUri;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (enabled.hashCode) +
    (displayName == null ? 0 : displayName!.hashCode) +
    (loginUrl == null ? 0 : loginUrl!.hashCode) +
    (appSsoEnabled.hashCode) +
    (appAuthority == null ? 0 : appAuthority!.hashCode) +
    (appClientId == null ? 0 : appClientId!.hashCode) +
    (appScopes.hashCode) +
    (appRedirectUri == null ? 0 : appRedirectUri!.hashCode);

  @override
  String toString() => 'SsoInfoResponse[enabled=$enabled, displayName=$displayName, loginUrl=$loginUrl, appSsoEnabled=$appSsoEnabled, appAuthority=$appAuthority, appClientId=$appClientId, appScopes=$appScopes, appRedirectUri=$appRedirectUri]';

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
      json[r'appSsoEnabled'] = this.appSsoEnabled;
    if (this.appAuthority != null) {
      json[r'appAuthority'] = this.appAuthority;
    } else {
      json[r'appAuthority'] = null;
    }
    if (this.appClientId != null) {
      json[r'appClientId'] = this.appClientId;
    } else {
      json[r'appClientId'] = null;
    }
      json[r'appScopes'] = this.appScopes;
    if (this.appRedirectUri != null) {
      json[r'appRedirectUri'] = this.appRedirectUri;
    } else {
      json[r'appRedirectUri'] = null;
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
    bool? appSsoEnabled,
    String? appAuthority,
    bool appAuthoritySetToNull = false,
    String? appClientId,
    bool appClientIdSetToNull = false,
    List<String>? appScopes,
    String? appRedirectUri,
    bool appRedirectUriSetToNull = false,
  }) => SsoInfoResponse(
    enabled: enabled ?? this.enabled,
    displayName: displayNameSetToNull ? null : displayName ?? this.displayName,
    loginUrl: loginUrlSetToNull ? null : loginUrl ?? this.loginUrl,
    appSsoEnabled: appSsoEnabled ?? this.appSsoEnabled,
    appAuthority: appAuthoritySetToNull ? null : appAuthority ?? this.appAuthority,
    appClientId: appClientIdSetToNull ? null : appClientId ?? this.appClientId,
    appScopes: appScopes ?? this.appScopes,
    appRedirectUri: appRedirectUriSetToNull ? null : appRedirectUri ?? this.appRedirectUri,
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
        assert(json.containsKey(r'appSsoEnabled'), 'Required key "SsoInfoResponse[appSsoEnabled]" is missing from JSON.');
        assert(json[r'appSsoEnabled'] != null, 'Required key "SsoInfoResponse[appSsoEnabled]" has a null value in JSON.');
        assert(json.containsKey(r'appAuthority'), 'Required key "SsoInfoResponse[appAuthority]" is missing from JSON.');
        assert(json.containsKey(r'appClientId'), 'Required key "SsoInfoResponse[appClientId]" is missing from JSON.');
        assert(json.containsKey(r'appScopes'), 'Required key "SsoInfoResponse[appScopes]" is missing from JSON.');
        assert(json[r'appScopes'] != null, 'Required key "SsoInfoResponse[appScopes]" has a null value in JSON.');
        assert(json.containsKey(r'appRedirectUri'), 'Required key "SsoInfoResponse[appRedirectUri]" is missing from JSON.');
        return true;
      }());

      return SsoInfoResponse(
        enabled: mapValueOfType<bool>(json, r'enabled')!,
        displayName: mapValueOfType<String>(json, r'displayName'),
        loginUrl: mapValueOfType<String>(json, r'loginUrl'),
        appSsoEnabled: mapValueOfType<bool>(json, r'appSsoEnabled')!,
        appAuthority: mapValueOfType<String>(json, r'appAuthority'),
        appClientId: mapValueOfType<String>(json, r'appClientId'),
        appScopes: json[r'appScopes'] is Iterable
            ? (json[r'appScopes'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        appRedirectUri: mapValueOfType<String>(json, r'appRedirectUri'),
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
    'appSsoEnabled',
    'appAuthority',
    'appClientId',
    'appScopes',
    'appRedirectUri',
  };
}

