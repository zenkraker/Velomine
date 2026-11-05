//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SettingsResponse {
  /// Returns a new [SettingsResponse] instance.
  SettingsResponse({
    required this.signUpEnabled,
    required this.requireAdminApproval,
    required this.mapTileUrl,
    required this.mapAttribution,
    required this.smtp,
    required this.sso,
  });

  final bool signUpEnabled;

  final bool requireAdminApproval;

  final String? mapTileUrl;

  final String? mapAttribution;

  final SmtpStatus smtp;

  final SsoStatus sso;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SettingsResponse &&
    other.signUpEnabled == signUpEnabled &&
    other.requireAdminApproval == requireAdminApproval &&
    other.mapTileUrl == mapTileUrl &&
    other.mapAttribution == mapAttribution &&
    other.smtp == smtp &&
    other.sso == sso;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (signUpEnabled.hashCode) +
    (requireAdminApproval.hashCode) +
    (mapTileUrl == null ? 0 : mapTileUrl!.hashCode) +
    (mapAttribution == null ? 0 : mapAttribution!.hashCode) +
    (smtp.hashCode) +
    (sso.hashCode);

  @override
  String toString() => 'SettingsResponse[signUpEnabled=$signUpEnabled, requireAdminApproval=$requireAdminApproval, mapTileUrl=$mapTileUrl, mapAttribution=$mapAttribution, smtp=$smtp, sso=$sso]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'signUpEnabled'] = this.signUpEnabled;
      json[r'requireAdminApproval'] = this.requireAdminApproval;
    if (this.mapTileUrl != null) {
      json[r'mapTileUrl'] = this.mapTileUrl;
    } else {
      json[r'mapTileUrl'] = null;
    }
    if (this.mapAttribution != null) {
      json[r'mapAttribution'] = this.mapAttribution;
    } else {
      json[r'mapAttribution'] = null;
    }
      json[r'smtp'] = this.smtp;
      json[r'sso'] = this.sso;
    return json;
  }

  /// Clones this instance of [SettingsResponse] and returns a new one where some of the
  /// properties have changed.
  SettingsResponse copyWith({
    bool? signUpEnabled,
    bool? requireAdminApproval,
    String? mapTileUrl,
    bool mapTileUrlSetToNull = false,
    String? mapAttribution,
    bool mapAttributionSetToNull = false,
    SmtpStatus? smtp,
    SsoStatus? sso,
  }) => SettingsResponse(
    signUpEnabled: signUpEnabled ?? this.signUpEnabled,
    requireAdminApproval: requireAdminApproval ?? this.requireAdminApproval,
    mapTileUrl: mapTileUrlSetToNull ? null : mapTileUrl ?? this.mapTileUrl,
    mapAttribution: mapAttributionSetToNull ? null : mapAttribution ?? this.mapAttribution,
    smtp: smtp ?? this.smtp,
    sso: sso ?? this.sso,
  );

  /// Returns a new [SettingsResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SettingsResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'signUpEnabled'), 'Required key "SettingsResponse[signUpEnabled]" is missing from JSON.');
        assert(json[r'signUpEnabled'] != null, 'Required key "SettingsResponse[signUpEnabled]" has a null value in JSON.');
        assert(json.containsKey(r'requireAdminApproval'), 'Required key "SettingsResponse[requireAdminApproval]" is missing from JSON.');
        assert(json[r'requireAdminApproval'] != null, 'Required key "SettingsResponse[requireAdminApproval]" has a null value in JSON.');
        assert(json.containsKey(r'mapTileUrl'), 'Required key "SettingsResponse[mapTileUrl]" is missing from JSON.');
        assert(json.containsKey(r'mapAttribution'), 'Required key "SettingsResponse[mapAttribution]" is missing from JSON.');
        assert(json.containsKey(r'smtp'), 'Required key "SettingsResponse[smtp]" is missing from JSON.');
        assert(json[r'smtp'] != null, 'Required key "SettingsResponse[smtp]" has a null value in JSON.');
        assert(json.containsKey(r'sso'), 'Required key "SettingsResponse[sso]" is missing from JSON.');
        assert(json[r'sso'] != null, 'Required key "SettingsResponse[sso]" has a null value in JSON.');
        return true;
      }());

      return SettingsResponse(
        signUpEnabled: mapValueOfType<bool>(json, r'signUpEnabled')!,
        requireAdminApproval: mapValueOfType<bool>(json, r'requireAdminApproval')!,
        mapTileUrl: mapValueOfType<String>(json, r'mapTileUrl'),
        mapAttribution: mapValueOfType<String>(json, r'mapAttribution'),
        smtp: SmtpStatus.fromJson(json[r'smtp'])!,
        sso: SsoStatus.fromJson(json[r'sso'])!,
      );
    }
    return null;
  }

  static List<SettingsResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SettingsResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SettingsResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SettingsResponse> mapFromJson(dynamic json) {
    final map = <String, SettingsResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SettingsResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SettingsResponse-objects as value to a dart map
  static Map<String, List<SettingsResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SettingsResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SettingsResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'signUpEnabled',
    'requireAdminApproval',
    'mapTileUrl',
    'mapAttribution',
    'smtp',
    'sso',
  };
}

