//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ListAdminUsersResponse {
  /// Returns a new [ListAdminUsersResponse] instance.
  ListAdminUsersResponse({
    this.users = const [],
  });

  final List<AdminUserSummary> users;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ListAdminUsersResponse &&
    _deepEquality.equals(other.users, users);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (users.hashCode);

  @override
  String toString() => 'ListAdminUsersResponse[users=$users]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'users'] = this.users;
    return json;
  }

  /// Clones this instance of [ListAdminUsersResponse] and returns a new one where some of the
  /// properties have changed.
  ListAdminUsersResponse copyWith({
    List<AdminUserSummary>? users,
  }) => ListAdminUsersResponse(
    users: users ?? this.users,
  );

  /// Returns a new [ListAdminUsersResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ListAdminUsersResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'users'), 'Required key "ListAdminUsersResponse[users]" is missing from JSON.');
        assert(json[r'users'] != null, 'Required key "ListAdminUsersResponse[users]" has a null value in JSON.');
        return true;
      }());

      return ListAdminUsersResponse(
        users: AdminUserSummary.listFromJson(json[r'users']),
      );
    }
    return null;
  }

  static List<ListAdminUsersResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListAdminUsersResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListAdminUsersResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ListAdminUsersResponse> mapFromJson(dynamic json) {
    final map = <String, ListAdminUsersResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ListAdminUsersResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ListAdminUsersResponse-objects as value to a dart map
  static Map<String, List<ListAdminUsersResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ListAdminUsersResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ListAdminUsersResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'users',
  };
}

