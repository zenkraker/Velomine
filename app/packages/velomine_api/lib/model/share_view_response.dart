//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ShareViewResponse {
  /// Returns a new [ShareViewResponse] instance.
  ShareViewResponse({
    required this.viewerName,
    required this.what,
    required this.at,
  });

  final String viewerName;

  final String what;

  final DateTime at;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ShareViewResponse &&
    other.viewerName == viewerName &&
    other.what == what &&
    other.at == at;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (viewerName.hashCode) +
    (what.hashCode) +
    (at.hashCode);

  @override
  String toString() => 'ShareViewResponse[viewerName=$viewerName, what=$what, at=$at]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'viewerName'] = this.viewerName;
      json[r'what'] = this.what;
      json[r'at'] = this.at.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [ShareViewResponse] and returns a new one where some of the
  /// properties have changed.
  ShareViewResponse copyWith({
    String? viewerName,
    String? what,
    DateTime? at,
  }) => ShareViewResponse(
    viewerName: viewerName ?? this.viewerName,
    what: what ?? this.what,
    at: at ?? this.at,
  );

  /// Returns a new [ShareViewResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShareViewResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'viewerName'), 'Required key "ShareViewResponse[viewerName]" is missing from JSON.');
        assert(json[r'viewerName'] != null, 'Required key "ShareViewResponse[viewerName]" has a null value in JSON.');
        assert(json.containsKey(r'what'), 'Required key "ShareViewResponse[what]" is missing from JSON.');
        assert(json[r'what'] != null, 'Required key "ShareViewResponse[what]" has a null value in JSON.');
        assert(json.containsKey(r'at'), 'Required key "ShareViewResponse[at]" is missing from JSON.');
        assert(json[r'at'] != null, 'Required key "ShareViewResponse[at]" has a null value in JSON.');
        return true;
      }());

      return ShareViewResponse(
        viewerName: mapValueOfType<String>(json, r'viewerName')!,
        what: mapValueOfType<String>(json, r'what')!,
        at: mapDateTime(json, r'at', r'')!,
      );
    }
    return null;
  }

  static List<ShareViewResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ShareViewResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShareViewResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShareViewResponse> mapFromJson(dynamic json) {
    final map = <String, ShareViewResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShareViewResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShareViewResponse-objects as value to a dart map
  static Map<String, List<ShareViewResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ShareViewResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ShareViewResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'viewerName',
    'what',
    'at',
  };
}

