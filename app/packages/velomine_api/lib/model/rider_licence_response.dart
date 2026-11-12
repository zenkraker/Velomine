//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class RiderLicenceResponse {
  /// Returns a new [RiderLicenceResponse] instance.
  RiderLicenceResponse({
    required this.holder,
    required this.serial,
    required this.activatedAt,
    required this.hidden,
  });

  final String holder;

  final int serial;

  final DateTime activatedAt;

  final bool hidden;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RiderLicenceResponse &&
    other.holder == holder &&
    other.serial == serial &&
    other.activatedAt == activatedAt &&
    other.hidden == hidden;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (holder.hashCode) +
    (serial.hashCode) +
    (activatedAt.hashCode) +
    (hidden.hashCode);

  @override
  String toString() => 'RiderLicenceResponse[holder=$holder, serial=$serial, activatedAt=$activatedAt, hidden=$hidden]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'holder'] = this.holder;
      json[r'serial'] = this.serial;
      json[r'activatedAt'] = this.activatedAt.toUtc().toIso8601String();
      json[r'hidden'] = this.hidden;
    return json;
  }

  /// Clones this instance of [RiderLicenceResponse] and returns a new one where some of the
  /// properties have changed.
  RiderLicenceResponse copyWith({
    String? holder,
    int? serial,
    DateTime? activatedAt,
    bool? hidden,
  }) => RiderLicenceResponse(
    holder: holder ?? this.holder,
    serial: serial ?? this.serial,
    activatedAt: activatedAt ?? this.activatedAt,
    hidden: hidden ?? this.hidden,
  );

  /// Returns a new [RiderLicenceResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RiderLicenceResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'holder'), 'Required key "RiderLicenceResponse[holder]" is missing from JSON.');
        assert(json[r'holder'] != null, 'Required key "RiderLicenceResponse[holder]" has a null value in JSON.');
        assert(json.containsKey(r'serial'), 'Required key "RiderLicenceResponse[serial]" is missing from JSON.');
        assert(json[r'serial'] != null, 'Required key "RiderLicenceResponse[serial]" has a null value in JSON.');
        assert(json.containsKey(r'activatedAt'), 'Required key "RiderLicenceResponse[activatedAt]" is missing from JSON.');
        assert(json[r'activatedAt'] != null, 'Required key "RiderLicenceResponse[activatedAt]" has a null value in JSON.');
        assert(json.containsKey(r'hidden'), 'Required key "RiderLicenceResponse[hidden]" is missing from JSON.');
        assert(json[r'hidden'] != null, 'Required key "RiderLicenceResponse[hidden]" has a null value in JSON.');
        return true;
      }());

      return RiderLicenceResponse(
        holder: mapValueOfType<String>(json, r'holder')!,
        serial: mapValueOfType<int>(json, r'serial')!,
        activatedAt: mapDateTime(json, r'activatedAt', r'')!,
        hidden: mapValueOfType<bool>(json, r'hidden')!,
      );
    }
    return null;
  }

  static List<RiderLicenceResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RiderLicenceResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RiderLicenceResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RiderLicenceResponse> mapFromJson(dynamic json) {
    final map = <String, RiderLicenceResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RiderLicenceResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RiderLicenceResponse-objects as value to a dart map
  static Map<String, List<RiderLicenceResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RiderLicenceResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RiderLicenceResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'holder',
    'serial',
    'activatedAt',
    'hidden',
  };
}

