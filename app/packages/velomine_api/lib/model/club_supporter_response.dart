//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ClubSupporterResponse {
  /// Returns a new [ClubSupporterResponse] instance.
  ClubSupporterResponse({
    required this.clubId,
    required this.clubName,
    required this.holder,
    required this.serial,
    required this.activatedAt,
    required this.hidden,
  });

  final String clubId;

  final String clubName;

  final String holder;

  final int serial;

  final DateTime activatedAt;

  final bool hidden;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ClubSupporterResponse &&
    other.clubId == clubId &&
    other.clubName == clubName &&
    other.holder == holder &&
    other.serial == serial &&
    other.activatedAt == activatedAt &&
    other.hidden == hidden;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (clubId.hashCode) +
    (clubName.hashCode) +
    (holder.hashCode) +
    (serial.hashCode) +
    (activatedAt.hashCode) +
    (hidden.hashCode);

  @override
  String toString() => 'ClubSupporterResponse[clubId=$clubId, clubName=$clubName, holder=$holder, serial=$serial, activatedAt=$activatedAt, hidden=$hidden]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'clubId'] = this.clubId;
      json[r'clubName'] = this.clubName;
      json[r'holder'] = this.holder;
      json[r'serial'] = this.serial;
      json[r'activatedAt'] = this.activatedAt.toUtc().toIso8601String();
      json[r'hidden'] = this.hidden;
    return json;
  }

  /// Clones this instance of [ClubSupporterResponse] and returns a new one where some of the
  /// properties have changed.
  ClubSupporterResponse copyWith({
    String? clubId,
    String? clubName,
    String? holder,
    int? serial,
    DateTime? activatedAt,
    bool? hidden,
  }) => ClubSupporterResponse(
    clubId: clubId ?? this.clubId,
    clubName: clubName ?? this.clubName,
    holder: holder ?? this.holder,
    serial: serial ?? this.serial,
    activatedAt: activatedAt ?? this.activatedAt,
    hidden: hidden ?? this.hidden,
  );

  /// Returns a new [ClubSupporterResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ClubSupporterResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'clubId'), 'Required key "ClubSupporterResponse[clubId]" is missing from JSON.');
        assert(json[r'clubId'] != null, 'Required key "ClubSupporterResponse[clubId]" has a null value in JSON.');
        assert(json.containsKey(r'clubName'), 'Required key "ClubSupporterResponse[clubName]" is missing from JSON.');
        assert(json[r'clubName'] != null, 'Required key "ClubSupporterResponse[clubName]" has a null value in JSON.');
        assert(json.containsKey(r'holder'), 'Required key "ClubSupporterResponse[holder]" is missing from JSON.');
        assert(json[r'holder'] != null, 'Required key "ClubSupporterResponse[holder]" has a null value in JSON.');
        assert(json.containsKey(r'serial'), 'Required key "ClubSupporterResponse[serial]" is missing from JSON.');
        assert(json[r'serial'] != null, 'Required key "ClubSupporterResponse[serial]" has a null value in JSON.');
        assert(json.containsKey(r'activatedAt'), 'Required key "ClubSupporterResponse[activatedAt]" is missing from JSON.');
        assert(json[r'activatedAt'] != null, 'Required key "ClubSupporterResponse[activatedAt]" has a null value in JSON.');
        assert(json.containsKey(r'hidden'), 'Required key "ClubSupporterResponse[hidden]" is missing from JSON.');
        assert(json[r'hidden'] != null, 'Required key "ClubSupporterResponse[hidden]" has a null value in JSON.');
        return true;
      }());

      return ClubSupporterResponse(
        clubId: mapValueOfType<String>(json, r'clubId')!,
        clubName: mapValueOfType<String>(json, r'clubName')!,
        holder: mapValueOfType<String>(json, r'holder')!,
        serial: mapValueOfType<int>(json, r'serial')!,
        activatedAt: mapDateTime(json, r'activatedAt', r'')!,
        hidden: mapValueOfType<bool>(json, r'hidden')!,
      );
    }
    return null;
  }

  static List<ClubSupporterResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ClubSupporterResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ClubSupporterResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ClubSupporterResponse> mapFromJson(dynamic json) {
    final map = <String, ClubSupporterResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ClubSupporterResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ClubSupporterResponse-objects as value to a dart map
  static Map<String, List<ClubSupporterResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ClubSupporterResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ClubSupporterResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'clubId',
    'clubName',
    'holder',
    'serial',
    'activatedAt',
    'hidden',
  };
}

