//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ServerInfoResponse {
  /// Returns a new [ServerInfoResponse] instance.
  ServerInfoResponse({
    required this.name,
    required this.version,
    required this.mapTileUrl,
    required this.mapAttribution,
    required this.emailAvailable,
    required this.telemetryEnabled,
    required this.sentryDsn,
    required this.telemetryTermsVersion,
    required this.demo,
  });

  final String name;

  final String version;

  final String mapTileUrl;

  final String mapAttribution;

  final bool emailAvailable;

  final bool telemetryEnabled;

  final String? sentryDsn;

  final int telemetryTermsVersion;

  final bool demo;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ServerInfoResponse &&
    other.name == name &&
    other.version == version &&
    other.mapTileUrl == mapTileUrl &&
    other.mapAttribution == mapAttribution &&
    other.emailAvailable == emailAvailable &&
    other.telemetryEnabled == telemetryEnabled &&
    other.sentryDsn == sentryDsn &&
    other.telemetryTermsVersion == telemetryTermsVersion &&
    other.demo == demo;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (version.hashCode) +
    (mapTileUrl.hashCode) +
    (mapAttribution.hashCode) +
    (emailAvailable.hashCode) +
    (telemetryEnabled.hashCode) +
    (sentryDsn == null ? 0 : sentryDsn!.hashCode) +
    (telemetryTermsVersion.hashCode) +
    (demo.hashCode);

  @override
  String toString() => 'ServerInfoResponse[name=$name, version=$version, mapTileUrl=$mapTileUrl, mapAttribution=$mapAttribution, emailAvailable=$emailAvailable, telemetryEnabled=$telemetryEnabled, sentryDsn=$sentryDsn, telemetryTermsVersion=$telemetryTermsVersion, demo=$demo]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'version'] = this.version;
      json[r'mapTileUrl'] = this.mapTileUrl;
      json[r'mapAttribution'] = this.mapAttribution;
      json[r'emailAvailable'] = this.emailAvailable;
      json[r'telemetryEnabled'] = this.telemetryEnabled;
    if (this.sentryDsn != null) {
      json[r'sentryDsn'] = this.sentryDsn;
    } else {
      json[r'sentryDsn'] = null;
    }
      json[r'telemetryTermsVersion'] = this.telemetryTermsVersion;
      json[r'demo'] = this.demo;
    return json;
  }

  /// Clones this instance of [ServerInfoResponse] and returns a new one where some of the
  /// properties have changed.
  ServerInfoResponse copyWith({
    String? name,
    String? version,
    String? mapTileUrl,
    String? mapAttribution,
    bool? emailAvailable,
    bool? telemetryEnabled,
    String? sentryDsn,
    bool sentryDsnSetToNull = false,
    int? telemetryTermsVersion,
    bool? demo,
  }) => ServerInfoResponse(
    name: name ?? this.name,
    version: version ?? this.version,
    mapTileUrl: mapTileUrl ?? this.mapTileUrl,
    mapAttribution: mapAttribution ?? this.mapAttribution,
    emailAvailable: emailAvailable ?? this.emailAvailable,
    telemetryEnabled: telemetryEnabled ?? this.telemetryEnabled,
    sentryDsn: sentryDsnSetToNull ? null : sentryDsn ?? this.sentryDsn,
    telemetryTermsVersion: telemetryTermsVersion ?? this.telemetryTermsVersion,
    demo: demo ?? this.demo,
  );

  /// Returns a new [ServerInfoResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ServerInfoResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "ServerInfoResponse[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "ServerInfoResponse[name]" has a null value in JSON.');
        assert(json.containsKey(r'version'), 'Required key "ServerInfoResponse[version]" is missing from JSON.');
        assert(json[r'version'] != null, 'Required key "ServerInfoResponse[version]" has a null value in JSON.');
        assert(json.containsKey(r'mapTileUrl'), 'Required key "ServerInfoResponse[mapTileUrl]" is missing from JSON.');
        assert(json[r'mapTileUrl'] != null, 'Required key "ServerInfoResponse[mapTileUrl]" has a null value in JSON.');
        assert(json.containsKey(r'mapAttribution'), 'Required key "ServerInfoResponse[mapAttribution]" is missing from JSON.');
        assert(json[r'mapAttribution'] != null, 'Required key "ServerInfoResponse[mapAttribution]" has a null value in JSON.');
        assert(json.containsKey(r'emailAvailable'), 'Required key "ServerInfoResponse[emailAvailable]" is missing from JSON.');
        assert(json[r'emailAvailable'] != null, 'Required key "ServerInfoResponse[emailAvailable]" has a null value in JSON.');
        assert(json.containsKey(r'telemetryEnabled'), 'Required key "ServerInfoResponse[telemetryEnabled]" is missing from JSON.');
        assert(json[r'telemetryEnabled'] != null, 'Required key "ServerInfoResponse[telemetryEnabled]" has a null value in JSON.');
        assert(json.containsKey(r'sentryDsn'), 'Required key "ServerInfoResponse[sentryDsn]" is missing from JSON.');
        assert(json.containsKey(r'telemetryTermsVersion'), 'Required key "ServerInfoResponse[telemetryTermsVersion]" is missing from JSON.');
        assert(json[r'telemetryTermsVersion'] != null, 'Required key "ServerInfoResponse[telemetryTermsVersion]" has a null value in JSON.');
        assert(json.containsKey(r'demo'), 'Required key "ServerInfoResponse[demo]" is missing from JSON.');
        assert(json[r'demo'] != null, 'Required key "ServerInfoResponse[demo]" has a null value in JSON.');
        return true;
      }());

      return ServerInfoResponse(
        name: mapValueOfType<String>(json, r'name')!,
        version: mapValueOfType<String>(json, r'version')!,
        mapTileUrl: mapValueOfType<String>(json, r'mapTileUrl')!,
        mapAttribution: mapValueOfType<String>(json, r'mapAttribution')!,
        emailAvailable: mapValueOfType<bool>(json, r'emailAvailable')!,
        telemetryEnabled: mapValueOfType<bool>(json, r'telemetryEnabled')!,
        sentryDsn: mapValueOfType<String>(json, r'sentryDsn'),
        telemetryTermsVersion: mapValueOfType<int>(json, r'telemetryTermsVersion')!,
        demo: mapValueOfType<bool>(json, r'demo')!,
      );
    }
    return null;
  }

  static List<ServerInfoResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ServerInfoResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ServerInfoResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ServerInfoResponse> mapFromJson(dynamic json) {
    final map = <String, ServerInfoResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ServerInfoResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ServerInfoResponse-objects as value to a dart map
  static Map<String, List<ServerInfoResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ServerInfoResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ServerInfoResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'version',
    'mapTileUrl',
    'mapAttribution',
    'emailAvailable',
    'telemetryEnabled',
    'sentryDsn',
    'telemetryTermsVersion',
    'demo',
  };
}

