//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class SupporterStatusResponse {
  /// Returns a new [SupporterStatusResponse] instance.
  SupporterStatusResponse({
    required this.available,
    required this.rider,
    required this.club,
  });

  final bool available;

  final RiderLicenceResponse? rider;

  final ClubSupporterResponse? club;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SupporterStatusResponse &&
    other.available == available &&
    other.rider == rider &&
    other.club == club;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (available.hashCode) +
    (rider == null ? 0 : rider!.hashCode) +
    (club == null ? 0 : club!.hashCode);

  @override
  String toString() => 'SupporterStatusResponse[available=$available, rider=$rider, club=$club]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'available'] = this.available;
    if (this.rider != null) {
      json[r'rider'] = this.rider;
    } else {
      json[r'rider'] = null;
    }
    if (this.club != null) {
      json[r'club'] = this.club;
    } else {
      json[r'club'] = null;
    }
    return json;
  }

  /// Clones this instance of [SupporterStatusResponse] and returns a new one where some of the
  /// properties have changed.
  SupporterStatusResponse copyWith({
    bool? available,
    RiderLicenceResponse? rider,
    bool riderSetToNull = false,
    ClubSupporterResponse? club,
    bool clubSetToNull = false,
  }) => SupporterStatusResponse(
    available: available ?? this.available,
    rider: riderSetToNull ? null : rider ?? this.rider,
    club: clubSetToNull ? null : club ?? this.club,
  );

  /// Returns a new [SupporterStatusResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SupporterStatusResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'available'), 'Required key "SupporterStatusResponse[available]" is missing from JSON.');
        assert(json[r'available'] != null, 'Required key "SupporterStatusResponse[available]" has a null value in JSON.');
        assert(json.containsKey(r'rider'), 'Required key "SupporterStatusResponse[rider]" is missing from JSON.');
        assert(json.containsKey(r'club'), 'Required key "SupporterStatusResponse[club]" is missing from JSON.');
        return true;
      }());

      return SupporterStatusResponse(
        available: mapValueOfType<bool>(json, r'available')!,
        rider: RiderLicenceResponse.fromJson(json[r'rider']),
        club: ClubSupporterResponse.fromJson(json[r'club']),
      );
    }
    return null;
  }

  static List<SupporterStatusResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SupporterStatusResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SupporterStatusResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SupporterStatusResponse> mapFromJson(dynamic json) {
    final map = <String, SupporterStatusResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SupporterStatusResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SupporterStatusResponse-objects as value to a dart map
  static Map<String, List<SupporterStatusResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SupporterStatusResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SupporterStatusResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'available',
    'rider',
    'club',
  };
}

