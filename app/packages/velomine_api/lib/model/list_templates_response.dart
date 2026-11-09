//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ListTemplatesResponse {
  /// Returns a new [ListTemplatesResponse] instance.
  ListTemplatesResponse({
    this.templates = const [],
  });

  final List<BikeTemplateResponse> templates;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ListTemplatesResponse &&
    _deepEquality.equals(other.templates, templates);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (templates.hashCode);

  @override
  String toString() => 'ListTemplatesResponse[templates=$templates]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'templates'] = this.templates;
    return json;
  }

  /// Clones this instance of [ListTemplatesResponse] and returns a new one where some of the
  /// properties have changed.
  ListTemplatesResponse copyWith({
    List<BikeTemplateResponse>? templates,
  }) => ListTemplatesResponse(
    templates: templates ?? this.templates,
  );

  /// Returns a new [ListTemplatesResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ListTemplatesResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'templates'), 'Required key "ListTemplatesResponse[templates]" is missing from JSON.');
        assert(json[r'templates'] != null, 'Required key "ListTemplatesResponse[templates]" has a null value in JSON.');
        return true;
      }());

      return ListTemplatesResponse(
        templates: BikeTemplateResponse.listFromJson(json[r'templates']),
      );
    }
    return null;
  }

  static List<ListTemplatesResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListTemplatesResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListTemplatesResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ListTemplatesResponse> mapFromJson(dynamic json) {
    final map = <String, ListTemplatesResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ListTemplatesResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ListTemplatesResponse-objects as value to a dart map
  static Map<String, List<ListTemplatesResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ListTemplatesResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ListTemplatesResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'templates',
  };
}

