//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ExchangeSsoCodeRequest {
  /// Returns a new [ExchangeSsoCodeRequest] instance.
  ExchangeSsoCodeRequest({
    required this.code,
    required this.codeVerifier,
  });

  final String code;

  final String codeVerifier;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ExchangeSsoCodeRequest &&
    other.code == code &&
    other.codeVerifier == codeVerifier;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (code.hashCode) +
    (codeVerifier.hashCode);

  @override
  String toString() => 'ExchangeSsoCodeRequest[code=$code, codeVerifier=$codeVerifier]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'code'] = this.code;
      json[r'codeVerifier'] = this.codeVerifier;
    return json;
  }

  /// Clones this instance of [ExchangeSsoCodeRequest] and returns a new one where some of the
  /// properties have changed.
  ExchangeSsoCodeRequest copyWith({
    String? code,
    String? codeVerifier,
  }) => ExchangeSsoCodeRequest(
    code: code ?? this.code,
    codeVerifier: codeVerifier ?? this.codeVerifier,
  );

  /// Returns a new [ExchangeSsoCodeRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ExchangeSsoCodeRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'code'), 'Required key "ExchangeSsoCodeRequest[code]" is missing from JSON.');
        assert(json[r'code'] != null, 'Required key "ExchangeSsoCodeRequest[code]" has a null value in JSON.');
        assert(json.containsKey(r'codeVerifier'), 'Required key "ExchangeSsoCodeRequest[codeVerifier]" is missing from JSON.');
        assert(json[r'codeVerifier'] != null, 'Required key "ExchangeSsoCodeRequest[codeVerifier]" has a null value in JSON.');
        return true;
      }());

      return ExchangeSsoCodeRequest(
        code: mapValueOfType<String>(json, r'code')!,
        codeVerifier: mapValueOfType<String>(json, r'codeVerifier')!,
      );
    }
    return null;
  }

  static List<ExchangeSsoCodeRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ExchangeSsoCodeRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ExchangeSsoCodeRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ExchangeSsoCodeRequest> mapFromJson(dynamic json) {
    final map = <String, ExchangeSsoCodeRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ExchangeSsoCodeRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ExchangeSsoCodeRequest-objects as value to a dart map
  static Map<String, List<ExchangeSsoCodeRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ExchangeSsoCodeRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ExchangeSsoCodeRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'code',
    'codeVerifier',
  };
}

