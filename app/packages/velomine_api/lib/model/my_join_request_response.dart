//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class MyJoinRequestResponse {
  /// Returns a new [MyJoinRequestResponse] instance.
  MyJoinRequestResponse({
    required this.request,
  });

  final PendingJoinRequestResponse? request;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MyJoinRequestResponse &&
    other.request == request;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (request == null ? 0 : request!.hashCode);

  @override
  String toString() => 'MyJoinRequestResponse[request=$request]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.request != null) {
      json[r'request'] = this.request;
    } else {
      json[r'request'] = null;
    }
    return json;
  }

  /// Clones this instance of [MyJoinRequestResponse] and returns a new one where some of the
  /// properties have changed.
  MyJoinRequestResponse copyWith({
    PendingJoinRequestResponse? request,
    bool requestSetToNull = false,
  }) => MyJoinRequestResponse(
    request: requestSetToNull ? null : request ?? this.request,
  );

  /// Returns a new [MyJoinRequestResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MyJoinRequestResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'request'), 'Required key "MyJoinRequestResponse[request]" is missing from JSON.');
        return true;
      }());

      return MyJoinRequestResponse(
        request: PendingJoinRequestResponse.fromJson(json[r'request']),
      );
    }
    return null;
  }

  static List<MyJoinRequestResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MyJoinRequestResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MyJoinRequestResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MyJoinRequestResponse> mapFromJson(dynamic json) {
    final map = <String, MyJoinRequestResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MyJoinRequestResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MyJoinRequestResponse-objects as value to a dart map
  static Map<String, List<MyJoinRequestResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MyJoinRequestResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MyJoinRequestResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'request',
  };
}

