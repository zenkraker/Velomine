//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SetClubPlanRequest {
  /// Returns a new [SetClubPlanRequest] instance.
  SetClubPlanRequest({
    this.memberLimit = const Optional.absent(),
    this.paidUntil = const Optional.absent(),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> memberLimit;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<DateTime?> paidUntil;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SetClubPlanRequest &&
    other.memberLimit == memberLimit &&
    other.paidUntil == paidUntil;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (memberLimit == null ? 0 : memberLimit!.hashCode) +
    (paidUntil == null ? 0 : paidUntil!.hashCode);

  @override
  String toString() => 'SetClubPlanRequest[memberLimit=$memberLimit, paidUntil=$paidUntil]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.memberLimit.isPresent) {
      final value = this.memberLimit.value;
      json[r'memberLimit'] = value;
    }
    if (this.paidUntil.isPresent) {
      final value = this.paidUntil.value;
      json[r'paidUntil'] = value == null ? null : _dateFormatter.format(value);
    }
    return json;
  }

  /// Clones this instance of [SetClubPlanRequest] and returns a new one where some of the
  /// properties have changed.
  SetClubPlanRequest copyWith({
    Optional<int?>? memberLimit,
    Optional<DateTime?>? paidUntil,
  }) => SetClubPlanRequest(
    memberLimit: memberLimit ?? this.memberLimit,
    paidUntil: paidUntil ?? this.paidUntil,
  );

  /// Returns a new [SetClubPlanRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SetClubPlanRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return SetClubPlanRequest(
        memberLimit: json.containsKey(r'memberLimit') ? Optional.present(json[r'memberLimit'] == null ? null : int.parse('${json[r'memberLimit']}')) : const Optional.absent(),
        paidUntil: json.containsKey(r'paidUntil') ? Optional.present(mapDateTime(json, r'paidUntil', r'')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<SetClubPlanRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SetClubPlanRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SetClubPlanRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SetClubPlanRequest> mapFromJson(dynamic json) {
    final map = <String, SetClubPlanRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SetClubPlanRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SetClubPlanRequest-objects as value to a dart map
  static Map<String, List<SetClubPlanRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SetClubPlanRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SetClubPlanRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

