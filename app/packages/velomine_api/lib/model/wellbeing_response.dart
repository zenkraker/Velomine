//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class WellbeingResponse {
  /// Returns a new [WellbeingResponse] instance.
  WellbeingResponse({
    required this.consentRequired,
    required this.consented,
    required this.today,
  });

  final bool consentRequired;

  final bool consented;

  final CheckInResponse? today;

  @override
  bool operator ==(Object other) => identical(this, other) || other is WellbeingResponse &&
    other.consentRequired == consentRequired &&
    other.consented == consented &&
    other.today == today;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (consentRequired.hashCode) +
    (consented.hashCode) +
    (today == null ? 0 : today!.hashCode);

  @override
  String toString() => 'WellbeingResponse[consentRequired=$consentRequired, consented=$consented, today=$today]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'consentRequired'] = this.consentRequired;
      json[r'consented'] = this.consented;
    if (this.today != null) {
      json[r'today'] = this.today;
    } else {
      json[r'today'] = null;
    }
    return json;
  }

  /// Clones this instance of [WellbeingResponse] and returns a new one where some of the
  /// properties have changed.
  WellbeingResponse copyWith({
    bool? consentRequired,
    bool? consented,
    CheckInResponse? today,
    bool todaySetToNull = false,
  }) => WellbeingResponse(
    consentRequired: consentRequired ?? this.consentRequired,
    consented: consented ?? this.consented,
    today: todaySetToNull ? null : today ?? this.today,
  );

  /// Returns a new [WellbeingResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WellbeingResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'consentRequired'), 'Required key "WellbeingResponse[consentRequired]" is missing from JSON.');
        assert(json[r'consentRequired'] != null, 'Required key "WellbeingResponse[consentRequired]" has a null value in JSON.');
        assert(json.containsKey(r'consented'), 'Required key "WellbeingResponse[consented]" is missing from JSON.');
        assert(json[r'consented'] != null, 'Required key "WellbeingResponse[consented]" has a null value in JSON.');
        assert(json.containsKey(r'today'), 'Required key "WellbeingResponse[today]" is missing from JSON.');
        return true;
      }());

      return WellbeingResponse(
        consentRequired: mapValueOfType<bool>(json, r'consentRequired')!,
        consented: mapValueOfType<bool>(json, r'consented')!,
        today: CheckInResponse.fromJson(json[r'today']),
      );
    }
    return null;
  }

  static List<WellbeingResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WellbeingResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WellbeingResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WellbeingResponse> mapFromJson(dynamic json) {
    final map = <String, WellbeingResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WellbeingResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WellbeingResponse-objects as value to a dart map
  static Map<String, List<WellbeingResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<WellbeingResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WellbeingResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'consentRequired',
    'consented',
    'today',
  };
}

