//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class CreateClubRequest {
  /// Returns a new [CreateClubRequest] instance.
  CreateClubRequest({
    required this.name,
    required this.ownerEmail,
  });

  final String name;

  final String ownerEmail;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreateClubRequest &&
    other.name == name &&
    other.ownerEmail == ownerEmail;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (ownerEmail.hashCode);

  @override
  String toString() => 'CreateClubRequest[name=$name, ownerEmail=$ownerEmail]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'ownerEmail'] = this.ownerEmail;
    return json;
  }

  /// Clones this instance of [CreateClubRequest] and returns a new one where some of the
  /// properties have changed.
  CreateClubRequest copyWith({
    String? name,
    String? ownerEmail,
  }) => CreateClubRequest(
    name: name ?? this.name,
    ownerEmail: ownerEmail ?? this.ownerEmail,
  );

  /// Returns a new [CreateClubRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateClubRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "CreateClubRequest[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "CreateClubRequest[name]" has a null value in JSON.');
        assert(json.containsKey(r'ownerEmail'), 'Required key "CreateClubRequest[ownerEmail]" is missing from JSON.');
        assert(json[r'ownerEmail'] != null, 'Required key "CreateClubRequest[ownerEmail]" has a null value in JSON.');
        return true;
      }());

      return CreateClubRequest(
        name: mapValueOfType<String>(json, r'name')!,
        ownerEmail: mapValueOfType<String>(json, r'ownerEmail')!,
      );
    }
    return null;
  }

  static List<CreateClubRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateClubRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateClubRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateClubRequest> mapFromJson(dynamic json) {
    final map = <String, CreateClubRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateClubRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateClubRequest-objects as value to a dart map
  static Map<String, List<CreateClubRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreateClubRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateClubRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'ownerEmail',
  };
}

