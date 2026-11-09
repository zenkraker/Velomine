//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class BikeTemplateResponse {
  /// Returns a new [BikeTemplateResponse] instance.
  BikeTemplateResponse({
    required this.id,
    required this.name,
    required this.createdAt,
    this.parts = const [],
  });

  final String id;

  final String name;

  final DateTime createdAt;

  final List<TemplatePartResponse> parts;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BikeTemplateResponse &&
    other.id == id &&
    other.name == name &&
    other.createdAt == createdAt &&
    _deepEquality.equals(other.parts, parts);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (createdAt.hashCode) +
    (parts.hashCode);

  @override
  String toString() => 'BikeTemplateResponse[id=$id, name=$name, createdAt=$createdAt, parts=$parts]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
      json[r'parts'] = this.parts;
    return json;
  }

  /// Clones this instance of [BikeTemplateResponse] and returns a new one where some of the
  /// properties have changed.
  BikeTemplateResponse copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<TemplatePartResponse>? parts,
  }) => BikeTemplateResponse(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    parts: parts ?? this.parts,
  );

  /// Returns a new [BikeTemplateResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BikeTemplateResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "BikeTemplateResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "BikeTemplateResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "BikeTemplateResponse[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "BikeTemplateResponse[name]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "BikeTemplateResponse[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "BikeTemplateResponse[createdAt]" has a null value in JSON.');
        assert(json.containsKey(r'parts'), 'Required key "BikeTemplateResponse[parts]" is missing from JSON.');
        assert(json[r'parts'] != null, 'Required key "BikeTemplateResponse[parts]" has a null value in JSON.');
        return true;
      }());

      return BikeTemplateResponse(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        parts: TemplatePartResponse.listFromJson(json[r'parts']),
      );
    }
    return null;
  }

  static List<BikeTemplateResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BikeTemplateResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BikeTemplateResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BikeTemplateResponse> mapFromJson(dynamic json) {
    final map = <String, BikeTemplateResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BikeTemplateResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BikeTemplateResponse-objects as value to a dart map
  static Map<String, List<BikeTemplateResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<BikeTemplateResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BikeTemplateResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'createdAt',
    'parts',
  };
}

