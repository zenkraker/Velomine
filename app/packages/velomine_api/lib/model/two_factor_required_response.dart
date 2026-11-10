//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class TwoFactorRequiredResponse {
  /// Returns a new [TwoFactorRequiredResponse] instance.
  TwoFactorRequiredResponse({
    required this.twoFactorRequired,
    required this.challenge,
  });

  final bool twoFactorRequired;

  final String challenge;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TwoFactorRequiredResponse &&
    other.twoFactorRequired == twoFactorRequired &&
    other.challenge == challenge;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (twoFactorRequired.hashCode) +
    (challenge.hashCode);

  @override
  String toString() => 'TwoFactorRequiredResponse[twoFactorRequired=$twoFactorRequired, challenge=$challenge]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'twoFactorRequired'] = this.twoFactorRequired;
      json[r'challenge'] = this.challenge;
    return json;
  }

  /// Clones this instance of [TwoFactorRequiredResponse] and returns a new one where some of the
  /// properties have changed.
  TwoFactorRequiredResponse copyWith({
    bool? twoFactorRequired,
    String? challenge,
  }) => TwoFactorRequiredResponse(
    twoFactorRequired: twoFactorRequired ?? this.twoFactorRequired,
    challenge: challenge ?? this.challenge,
  );

  /// Returns a new [TwoFactorRequiredResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TwoFactorRequiredResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'twoFactorRequired'), 'Required key "TwoFactorRequiredResponse[twoFactorRequired]" is missing from JSON.');
        assert(json[r'twoFactorRequired'] != null, 'Required key "TwoFactorRequiredResponse[twoFactorRequired]" has a null value in JSON.');
        assert(json.containsKey(r'challenge'), 'Required key "TwoFactorRequiredResponse[challenge]" is missing from JSON.');
        assert(json[r'challenge'] != null, 'Required key "TwoFactorRequiredResponse[challenge]" has a null value in JSON.');
        return true;
      }());

      return TwoFactorRequiredResponse(
        twoFactorRequired: mapValueOfType<bool>(json, r'twoFactorRequired')!,
        challenge: mapValueOfType<String>(json, r'challenge')!,
      );
    }
    return null;
  }

  static List<TwoFactorRequiredResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TwoFactorRequiredResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TwoFactorRequiredResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TwoFactorRequiredResponse> mapFromJson(dynamic json) {
    final map = <String, TwoFactorRequiredResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TwoFactorRequiredResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TwoFactorRequiredResponse-objects as value to a dart map
  static Map<String, List<TwoFactorRequiredResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TwoFactorRequiredResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TwoFactorRequiredResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'twoFactorRequired',
    'challenge',
  };
}

