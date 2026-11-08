//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class MyClubResponse {
  /// Returns a new [MyClubResponse] instance.
  MyClubResponse({
    required this.club,
  });

  final ClubResponse? club;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MyClubResponse &&
    other.club == club;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (club == null ? 0 : club!.hashCode);

  @override
  String toString() => 'MyClubResponse[club=$club]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.club != null) {
      json[r'club'] = this.club;
    } else {
      json[r'club'] = null;
    }
    return json;
  }

  /// Clones this instance of [MyClubResponse] and returns a new one where some of the
  /// properties have changed.
  MyClubResponse copyWith({
    ClubResponse? club,
    bool clubSetToNull = false,
  }) => MyClubResponse(
    club: clubSetToNull ? null : club ?? this.club,
  );

  /// Returns a new [MyClubResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MyClubResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'club'), 'Required key "MyClubResponse[club]" is missing from JSON.');
        return true;
      }());

      return MyClubResponse(
        club: ClubResponse.fromJson(json[r'club']),
      );
    }
    return null;
  }

  static List<MyClubResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MyClubResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MyClubResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MyClubResponse> mapFromJson(dynamic json) {
    final map = <String, MyClubResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MyClubResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MyClubResponse-objects as value to a dart map
  static Map<String, List<MyClubResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MyClubResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MyClubResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'club',
  };
}

