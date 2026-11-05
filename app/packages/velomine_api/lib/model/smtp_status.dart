//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SmtpStatus {
  /// Returns a new [SmtpStatus] instance.
  SmtpStatus({
    required this.configured,
    required this.host,
    required this.port,
    required this.security,
    required this.from,
  });

  final bool configured;

  final String? host;

  final int? port;

  final String? security;

  final String? from;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SmtpStatus &&
    other.configured == configured &&
    other.host == host &&
    other.port == port &&
    other.security == security &&
    other.from == from;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (configured.hashCode) +
    (host == null ? 0 : host!.hashCode) +
    (port == null ? 0 : port!.hashCode) +
    (security == null ? 0 : security!.hashCode) +
    (from == null ? 0 : from!.hashCode);

  @override
  String toString() => 'SmtpStatus[configured=$configured, host=$host, port=$port, security=$security, from=$from]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'configured'] = this.configured;
    if (this.host != null) {
      json[r'host'] = this.host;
    } else {
      json[r'host'] = null;
    }
    if (this.port != null) {
      json[r'port'] = this.port;
    } else {
      json[r'port'] = null;
    }
    if (this.security != null) {
      json[r'security'] = this.security;
    } else {
      json[r'security'] = null;
    }
    if (this.from != null) {
      json[r'from'] = this.from;
    } else {
      json[r'from'] = null;
    }
    return json;
  }

  /// Clones this instance of [SmtpStatus] and returns a new one where some of the
  /// properties have changed.
  SmtpStatus copyWith({
    bool? configured,
    String? host,
    bool hostSetToNull = false,
    int? port,
    bool portSetToNull = false,
    String? security,
    bool securitySetToNull = false,
    String? from,
    bool fromSetToNull = false,
  }) => SmtpStatus(
    configured: configured ?? this.configured,
    host: hostSetToNull ? null : host ?? this.host,
    port: portSetToNull ? null : port ?? this.port,
    security: securitySetToNull ? null : security ?? this.security,
    from: fromSetToNull ? null : from ?? this.from,
  );

  /// Returns a new [SmtpStatus] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SmtpStatus? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'configured'), 'Required key "SmtpStatus[configured]" is missing from JSON.');
        assert(json[r'configured'] != null, 'Required key "SmtpStatus[configured]" has a null value in JSON.');
        assert(json.containsKey(r'host'), 'Required key "SmtpStatus[host]" is missing from JSON.');
        assert(json.containsKey(r'port'), 'Required key "SmtpStatus[port]" is missing from JSON.');
        assert(json.containsKey(r'security'), 'Required key "SmtpStatus[security]" is missing from JSON.');
        assert(json.containsKey(r'from'), 'Required key "SmtpStatus[from]" is missing from JSON.');
        return true;
      }());

      return SmtpStatus(
        configured: mapValueOfType<bool>(json, r'configured')!,
        host: mapValueOfType<String>(json, r'host'),
        port: mapValueOfType<int>(json, r'port'),
        security: mapValueOfType<String>(json, r'security'),
        from: mapValueOfType<String>(json, r'from'),
      );
    }
    return null;
  }

  static List<SmtpStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SmtpStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SmtpStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SmtpStatus> mapFromJson(dynamic json) {
    final map = <String, SmtpStatus>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SmtpStatus.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SmtpStatus-objects as value to a dart map
  static Map<String, List<SmtpStatus>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SmtpStatus>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SmtpStatus.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'configured',
    'host',
    'port',
    'security',
    'from',
  };
}

