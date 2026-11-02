//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class TokenResponse {
  /// Returns a new [TokenResponse] instance.
  TokenResponse({
    required this.tokenType,
    required this.accessToken,
    required this.expiresIn,
    required this.refreshToken,
  });

  final String tokenType;

  final String accessToken;

  final int expiresIn;

  final String refreshToken;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TokenResponse &&
    other.tokenType == tokenType &&
    other.accessToken == accessToken &&
    other.expiresIn == expiresIn &&
    other.refreshToken == refreshToken;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (tokenType.hashCode) +
    (accessToken.hashCode) +
    (expiresIn.hashCode) +
    (refreshToken.hashCode);

  @override
  String toString() => 'TokenResponse[tokenType=$tokenType, accessToken=$accessToken, expiresIn=$expiresIn, refreshToken=$refreshToken]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'tokenType'] = this.tokenType;
      json[r'accessToken'] = this.accessToken;
      json[r'expiresIn'] = this.expiresIn;
      json[r'refreshToken'] = this.refreshToken;
    return json;
  }

  /// Clones this instance of [TokenResponse] and returns a new one where some of the
  /// properties have changed.
  TokenResponse copyWith({
    String? tokenType,
    String? accessToken,
    int? expiresIn,
    String? refreshToken,
  }) => TokenResponse(
    tokenType: tokenType ?? this.tokenType,
    accessToken: accessToken ?? this.accessToken,
    expiresIn: expiresIn ?? this.expiresIn,
    refreshToken: refreshToken ?? this.refreshToken,
  );

  /// Returns a new [TokenResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TokenResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'tokenType'), 'Required key "TokenResponse[tokenType]" is missing from JSON.');
        assert(json[r'tokenType'] != null, 'Required key "TokenResponse[tokenType]" has a null value in JSON.');
        assert(json.containsKey(r'accessToken'), 'Required key "TokenResponse[accessToken]" is missing from JSON.');
        assert(json[r'accessToken'] != null, 'Required key "TokenResponse[accessToken]" has a null value in JSON.');
        assert(json.containsKey(r'expiresIn'), 'Required key "TokenResponse[expiresIn]" is missing from JSON.');
        assert(json[r'expiresIn'] != null, 'Required key "TokenResponse[expiresIn]" has a null value in JSON.');
        assert(json.containsKey(r'refreshToken'), 'Required key "TokenResponse[refreshToken]" is missing from JSON.');
        assert(json[r'refreshToken'] != null, 'Required key "TokenResponse[refreshToken]" has a null value in JSON.');
        return true;
      }());

      return TokenResponse(
        tokenType: mapValueOfType<String>(json, r'tokenType')!,
        accessToken: mapValueOfType<String>(json, r'accessToken')!,
        expiresIn: mapValueOfType<int>(json, r'expiresIn')!,
        refreshToken: mapValueOfType<String>(json, r'refreshToken')!,
      );
    }
    return null;
  }

  static List<TokenResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TokenResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TokenResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TokenResponse> mapFromJson(dynamic json) {
    final map = <String, TokenResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TokenResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TokenResponse-objects as value to a dart map
  static Map<String, List<TokenResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TokenResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TokenResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'tokenType',
    'accessToken',
    'expiresIn',
    'refreshToken',
  };
}

