//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ComponentTypeResponse {
  /// Returns a new [ComponentTypeResponse] instance.
  ComponentTypeResponse({
    required this.id,
    required this.name,
    required this.group,
    required this.typicalDistanceM,
    required this.typicalHours,
    required this.typicalMonths,
  });

  final String id;

  final String name;

  final String group;

  final double? typicalDistanceM;

  final double? typicalHours;

  final int? typicalMonths;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ComponentTypeResponse &&
    other.id == id &&
    other.name == name &&
    other.group == group &&
    other.typicalDistanceM == typicalDistanceM &&
    other.typicalHours == typicalHours &&
    other.typicalMonths == typicalMonths;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (group.hashCode) +
    (typicalDistanceM == null ? 0 : typicalDistanceM!.hashCode) +
    (typicalHours == null ? 0 : typicalHours!.hashCode) +
    (typicalMonths == null ? 0 : typicalMonths!.hashCode);

  @override
  String toString() => 'ComponentTypeResponse[id=$id, name=$name, group=$group, typicalDistanceM=$typicalDistanceM, typicalHours=$typicalHours, typicalMonths=$typicalMonths]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'group'] = this.group;
    if (this.typicalDistanceM != null) {
      json[r'typicalDistanceM'] = this.typicalDistanceM;
    } else {
      json[r'typicalDistanceM'] = null;
    }
    if (this.typicalHours != null) {
      json[r'typicalHours'] = this.typicalHours;
    } else {
      json[r'typicalHours'] = null;
    }
    if (this.typicalMonths != null) {
      json[r'typicalMonths'] = this.typicalMonths;
    } else {
      json[r'typicalMonths'] = null;
    }
    return json;
  }

  /// Clones this instance of [ComponentTypeResponse] and returns a new one where some of the
  /// properties have changed.
  ComponentTypeResponse copyWith({
    String? id,
    String? name,
    String? group,
    double? typicalDistanceM,
    bool typicalDistanceMSetToNull = false,
    double? typicalHours,
    bool typicalHoursSetToNull = false,
    int? typicalMonths,
    bool typicalMonthsSetToNull = false,
  }) => ComponentTypeResponse(
    id: id ?? this.id,
    name: name ?? this.name,
    group: group ?? this.group,
    typicalDistanceM: typicalDistanceMSetToNull ? null : typicalDistanceM ?? this.typicalDistanceM,
    typicalHours: typicalHoursSetToNull ? null : typicalHours ?? this.typicalHours,
    typicalMonths: typicalMonthsSetToNull ? null : typicalMonths ?? this.typicalMonths,
  );

  /// Returns a new [ComponentTypeResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ComponentTypeResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "ComponentTypeResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "ComponentTypeResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "ComponentTypeResponse[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "ComponentTypeResponse[name]" has a null value in JSON.');
        assert(json.containsKey(r'group'), 'Required key "ComponentTypeResponse[group]" is missing from JSON.');
        assert(json[r'group'] != null, 'Required key "ComponentTypeResponse[group]" has a null value in JSON.');
        assert(json.containsKey(r'typicalDistanceM'), 'Required key "ComponentTypeResponse[typicalDistanceM]" is missing from JSON.');
        assert(json.containsKey(r'typicalHours'), 'Required key "ComponentTypeResponse[typicalHours]" is missing from JSON.');
        assert(json.containsKey(r'typicalMonths'), 'Required key "ComponentTypeResponse[typicalMonths]" is missing from JSON.');
        return true;
      }());

      return ComponentTypeResponse(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        group: mapValueOfType<String>(json, r'group')!,
        typicalDistanceM: mapValueOfType<double>(json, r'typicalDistanceM'),
        typicalHours: mapValueOfType<double>(json, r'typicalHours'),
        typicalMonths: mapValueOfType<int>(json, r'typicalMonths'),
      );
    }
    return null;
  }

  static List<ComponentTypeResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ComponentTypeResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ComponentTypeResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ComponentTypeResponse> mapFromJson(dynamic json) {
    final map = <String, ComponentTypeResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ComponentTypeResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ComponentTypeResponse-objects as value to a dart map
  static Map<String, List<ComponentTypeResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ComponentTypeResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ComponentTypeResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'group',
    'typicalDistanceM',
    'typicalHours',
    'typicalMonths',
  };
}

