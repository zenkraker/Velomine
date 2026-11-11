//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class OverviewResponse {
  /// Returns a new [OverviewResponse] instance.
  OverviewResponse({
    required this.accounts,
    required this.waitingForApproval,
    required this.locked,
    required this.rides,
    required this.rideFilesBytes,
    required this.version,
    required this.parserVersion,
    required this.ridesToReread,
    required this.ridesNotReread,
  });

  final int accounts;

  final int waitingForApproval;

  final int locked;

  final int rides;

  final int rideFilesBytes;

  final String version;

  final int parserVersion;

  final int ridesToReread;

  final int ridesNotReread;

  @override
  bool operator ==(Object other) => identical(this, other) || other is OverviewResponse &&
    other.accounts == accounts &&
    other.waitingForApproval == waitingForApproval &&
    other.locked == locked &&
    other.rides == rides &&
    other.rideFilesBytes == rideFilesBytes &&
    other.version == version &&
    other.parserVersion == parserVersion &&
    other.ridesToReread == ridesToReread &&
    other.ridesNotReread == ridesNotReread;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (accounts.hashCode) +
    (waitingForApproval.hashCode) +
    (locked.hashCode) +
    (rides.hashCode) +
    (rideFilesBytes.hashCode) +
    (version.hashCode) +
    (parserVersion.hashCode) +
    (ridesToReread.hashCode) +
    (ridesNotReread.hashCode);

  @override
  String toString() => 'OverviewResponse[accounts=$accounts, waitingForApproval=$waitingForApproval, locked=$locked, rides=$rides, rideFilesBytes=$rideFilesBytes, version=$version, parserVersion=$parserVersion, ridesToReread=$ridesToReread, ridesNotReread=$ridesNotReread]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'accounts'] = this.accounts;
      json[r'waitingForApproval'] = this.waitingForApproval;
      json[r'locked'] = this.locked;
      json[r'rides'] = this.rides;
      json[r'rideFilesBytes'] = this.rideFilesBytes;
      json[r'version'] = this.version;
      json[r'parserVersion'] = this.parserVersion;
      json[r'ridesToReread'] = this.ridesToReread;
      json[r'ridesNotReread'] = this.ridesNotReread;
    return json;
  }

  /// Clones this instance of [OverviewResponse] and returns a new one where some of the
  /// properties have changed.
  OverviewResponse copyWith({
    int? accounts,
    int? waitingForApproval,
    int? locked,
    int? rides,
    int? rideFilesBytes,
    String? version,
    int? parserVersion,
    int? ridesToReread,
    int? ridesNotReread,
  }) => OverviewResponse(
    accounts: accounts ?? this.accounts,
    waitingForApproval: waitingForApproval ?? this.waitingForApproval,
    locked: locked ?? this.locked,
    rides: rides ?? this.rides,
    rideFilesBytes: rideFilesBytes ?? this.rideFilesBytes,
    version: version ?? this.version,
    parserVersion: parserVersion ?? this.parserVersion,
    ridesToReread: ridesToReread ?? this.ridesToReread,
    ridesNotReread: ridesNotReread ?? this.ridesNotReread,
  );

  /// Returns a new [OverviewResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OverviewResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'accounts'), 'Required key "OverviewResponse[accounts]" is missing from JSON.');
        assert(json[r'accounts'] != null, 'Required key "OverviewResponse[accounts]" has a null value in JSON.');
        assert(json.containsKey(r'waitingForApproval'), 'Required key "OverviewResponse[waitingForApproval]" is missing from JSON.');
        assert(json[r'waitingForApproval'] != null, 'Required key "OverviewResponse[waitingForApproval]" has a null value in JSON.');
        assert(json.containsKey(r'locked'), 'Required key "OverviewResponse[locked]" is missing from JSON.');
        assert(json[r'locked'] != null, 'Required key "OverviewResponse[locked]" has a null value in JSON.');
        assert(json.containsKey(r'rides'), 'Required key "OverviewResponse[rides]" is missing from JSON.');
        assert(json[r'rides'] != null, 'Required key "OverviewResponse[rides]" has a null value in JSON.');
        assert(json.containsKey(r'rideFilesBytes'), 'Required key "OverviewResponse[rideFilesBytes]" is missing from JSON.');
        assert(json[r'rideFilesBytes'] != null, 'Required key "OverviewResponse[rideFilesBytes]" has a null value in JSON.');
        assert(json.containsKey(r'version'), 'Required key "OverviewResponse[version]" is missing from JSON.');
        assert(json[r'version'] != null, 'Required key "OverviewResponse[version]" has a null value in JSON.');
        assert(json.containsKey(r'parserVersion'), 'Required key "OverviewResponse[parserVersion]" is missing from JSON.');
        assert(json[r'parserVersion'] != null, 'Required key "OverviewResponse[parserVersion]" has a null value in JSON.');
        assert(json.containsKey(r'ridesToReread'), 'Required key "OverviewResponse[ridesToReread]" is missing from JSON.');
        assert(json[r'ridesToReread'] != null, 'Required key "OverviewResponse[ridesToReread]" has a null value in JSON.');
        assert(json.containsKey(r'ridesNotReread'), 'Required key "OverviewResponse[ridesNotReread]" is missing from JSON.');
        assert(json[r'ridesNotReread'] != null, 'Required key "OverviewResponse[ridesNotReread]" has a null value in JSON.');
        return true;
      }());

      return OverviewResponse(
        accounts: mapValueOfType<int>(json, r'accounts')!,
        waitingForApproval: mapValueOfType<int>(json, r'waitingForApproval')!,
        locked: mapValueOfType<int>(json, r'locked')!,
        rides: mapValueOfType<int>(json, r'rides')!,
        rideFilesBytes: mapValueOfType<int>(json, r'rideFilesBytes')!,
        version: mapValueOfType<String>(json, r'version')!,
        parserVersion: mapValueOfType<int>(json, r'parserVersion')!,
        ridesToReread: mapValueOfType<int>(json, r'ridesToReread')!,
        ridesNotReread: mapValueOfType<int>(json, r'ridesNotReread')!,
      );
    }
    return null;
  }

  static List<OverviewResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OverviewResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OverviewResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OverviewResponse> mapFromJson(dynamic json) {
    final map = <String, OverviewResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OverviewResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OverviewResponse-objects as value to a dart map
  static Map<String, List<OverviewResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<OverviewResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OverviewResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'accounts',
    'waitingForApproval',
    'locked',
    'rides',
    'rideFilesBytes',
    'version',
    'parserVersion',
    'ridesToReread',
    'ridesNotReread',
  };
}

