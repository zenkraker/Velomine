//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class PasswordResetLinkResponse {
  /// Returns a new [PasswordResetLinkResponse] instance.
  PasswordResetLinkResponse({
    required this.link,
    required this.expiresAt,
  });

  final String link;

  final DateTime expiresAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PasswordResetLinkResponse &&
    other.link == link &&
    other.expiresAt == expiresAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (link.hashCode) +
    (expiresAt.hashCode);

  @override
  String toString() => 'PasswordResetLinkResponse[link=$link, expiresAt=$expiresAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'link'] = this.link;
      json[r'expiresAt'] = this.expiresAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [PasswordResetLinkResponse] and returns a new one where some of the
  /// properties have changed.
  PasswordResetLinkResponse copyWith({
    String? link,
    DateTime? expiresAt,
  }) => PasswordResetLinkResponse(
    link: link ?? this.link,
    expiresAt: expiresAt ?? this.expiresAt,
  );

  /// Returns a new [PasswordResetLinkResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PasswordResetLinkResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'link'), 'Required key "PasswordResetLinkResponse[link]" is missing from JSON.');
        assert(json[r'link'] != null, 'Required key "PasswordResetLinkResponse[link]" has a null value in JSON.');
        assert(json.containsKey(r'expiresAt'), 'Required key "PasswordResetLinkResponse[expiresAt]" is missing from JSON.');
        assert(json[r'expiresAt'] != null, 'Required key "PasswordResetLinkResponse[expiresAt]" has a null value in JSON.');
        return true;
      }());

      return PasswordResetLinkResponse(
        link: mapValueOfType<String>(json, r'link')!,
        expiresAt: mapDateTime(json, r'expiresAt', r'')!,
      );
    }
    return null;
  }

  static List<PasswordResetLinkResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PasswordResetLinkResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PasswordResetLinkResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PasswordResetLinkResponse> mapFromJson(dynamic json) {
    final map = <String, PasswordResetLinkResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PasswordResetLinkResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PasswordResetLinkResponse-objects as value to a dart map
  static Map<String, List<PasswordResetLinkResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PasswordResetLinkResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PasswordResetLinkResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'link',
    'expiresAt',
  };
}

