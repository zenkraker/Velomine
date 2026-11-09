//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ExchangeSsoTokenRequest {
  /// Returns a new [ExchangeSsoTokenRequest] instance.
  ExchangeSsoTokenRequest({
    required this.idToken,
    required this.accessToken,
  });

  final String idToken;

  final String? accessToken;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ExchangeSsoTokenRequest &&
    other.idToken == idToken &&
    other.accessToken == accessToken;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (idToken.hashCode) +
    (accessToken == null ? 0 : accessToken!.hashCode);

  @override
  String toString() => 'ExchangeSsoTokenRequest[idToken=$idToken, accessToken=$accessToken]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'idToken'] = this.idToken;
    if (this.accessToken != null) {
      json[r'accessToken'] = this.accessToken;
    } else {
      json[r'accessToken'] = null;
    }
    return json;
  }

  /// Clones this instance of [ExchangeSsoTokenRequest] and returns a new one where some of the
  /// properties have changed.
  ExchangeSsoTokenRequest copyWith({
    String? idToken,
    String? accessToken,
    bool accessTokenSetToNull = false,
  }) => ExchangeSsoTokenRequest(
    idToken: idToken ?? this.idToken,
    accessToken: accessTokenSetToNull ? null : accessToken ?? this.accessToken,
  );

  /// Returns a new [ExchangeSsoTokenRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ExchangeSsoTokenRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'idToken'), 'Required key "ExchangeSsoTokenRequest[idToken]" is missing from JSON.');
        assert(json[r'idToken'] != null, 'Required key "ExchangeSsoTokenRequest[idToken]" has a null value in JSON.');
        assert(json.containsKey(r'accessToken'), 'Required key "ExchangeSsoTokenRequest[accessToken]" is missing from JSON.');
        return true;
      }());

      return ExchangeSsoTokenRequest(
        idToken: mapValueOfType<String>(json, r'idToken')!,
        accessToken: mapValueOfType<String>(json, r'accessToken'),
      );
    }
    return null;
  }

  static List<ExchangeSsoTokenRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ExchangeSsoTokenRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ExchangeSsoTokenRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ExchangeSsoTokenRequest> mapFromJson(dynamic json) {
    final map = <String, ExchangeSsoTokenRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ExchangeSsoTokenRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ExchangeSsoTokenRequest-objects as value to a dart map
  static Map<String, List<ExchangeSsoTokenRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ExchangeSsoTokenRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ExchangeSsoTokenRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'idToken',
    'accessToken',
  };
}

