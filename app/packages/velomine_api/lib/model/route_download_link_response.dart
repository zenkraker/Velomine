//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class RouteDownloadLinkResponse {
  /// Returns a new [RouteDownloadLinkResponse] instance.
  RouteDownloadLinkResponse({
    required this.path,
    required this.expiresAt,
  });

  final String path;

  final DateTime expiresAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RouteDownloadLinkResponse &&
    other.path == path &&
    other.expiresAt == expiresAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (path.hashCode) +
    (expiresAt.hashCode);

  @override
  String toString() => 'RouteDownloadLinkResponse[path=$path, expiresAt=$expiresAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'path'] = this.path;
      json[r'expiresAt'] = this.expiresAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [RouteDownloadLinkResponse] and returns a new one where some of the
  /// properties have changed.
  RouteDownloadLinkResponse copyWith({
    String? path,
    DateTime? expiresAt,
  }) => RouteDownloadLinkResponse(
    path: path ?? this.path,
    expiresAt: expiresAt ?? this.expiresAt,
  );

  /// Returns a new [RouteDownloadLinkResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RouteDownloadLinkResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'path'), 'Required key "RouteDownloadLinkResponse[path]" is missing from JSON.');
        assert(json[r'path'] != null, 'Required key "RouteDownloadLinkResponse[path]" has a null value in JSON.');
        assert(json.containsKey(r'expiresAt'), 'Required key "RouteDownloadLinkResponse[expiresAt]" is missing from JSON.');
        assert(json[r'expiresAt'] != null, 'Required key "RouteDownloadLinkResponse[expiresAt]" has a null value in JSON.');
        return true;
      }());

      return RouteDownloadLinkResponse(
        path: mapValueOfType<String>(json, r'path')!,
        expiresAt: mapDateTime(json, r'expiresAt', r'')!,
      );
    }
    return null;
  }

  static List<RouteDownloadLinkResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RouteDownloadLinkResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RouteDownloadLinkResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RouteDownloadLinkResponse> mapFromJson(dynamic json) {
    final map = <String, RouteDownloadLinkResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RouteDownloadLinkResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RouteDownloadLinkResponse-objects as value to a dart map
  static Map<String, List<RouteDownloadLinkResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RouteDownloadLinkResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RouteDownloadLinkResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'path',
    'expiresAt',
  };
}

