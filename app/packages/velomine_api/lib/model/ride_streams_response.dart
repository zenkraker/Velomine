//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class RideStreamsResponse {
  /// Returns a new [RideStreamsResponse] instance.
  RideStreamsResponse({
    this.time = const [],
    this.latitude = const [],
    this.longitude = const [],
    this.altitude = const [],
    this.speed = const [],
    this.distance = const [],
    this.heartRate = const [],
    this.power = const [],
    this.cadence = const [],
    this.temperature = const [],
  });

  final List<double> time;

  final List<double?>? latitude;

  final List<double?>? longitude;

  final List<double?>? altitude;

  final List<double?>? speed;

  final List<double?>? distance;

  final List<int?>? heartRate;

  final List<int?>? power;

  final List<int?>? cadence;

  final List<int?>? temperature;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RideStreamsResponse &&
    _deepEquality.equals(other.time, time) &&
    _deepEquality.equals(other.latitude, latitude) &&
    _deepEquality.equals(other.longitude, longitude) &&
    _deepEquality.equals(other.altitude, altitude) &&
    _deepEquality.equals(other.speed, speed) &&
    _deepEquality.equals(other.distance, distance) &&
    _deepEquality.equals(other.heartRate, heartRate) &&
    _deepEquality.equals(other.power, power) &&
    _deepEquality.equals(other.cadence, cadence) &&
    _deepEquality.equals(other.temperature, temperature);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (time.hashCode) +
    (latitude == null ? 0 : latitude!.hashCode) +
    (longitude == null ? 0 : longitude!.hashCode) +
    (altitude == null ? 0 : altitude!.hashCode) +
    (speed == null ? 0 : speed!.hashCode) +
    (distance == null ? 0 : distance!.hashCode) +
    (heartRate == null ? 0 : heartRate!.hashCode) +
    (power == null ? 0 : power!.hashCode) +
    (cadence == null ? 0 : cadence!.hashCode) +
    (temperature == null ? 0 : temperature!.hashCode);

  @override
  String toString() => 'RideStreamsResponse[time=$time, latitude=$latitude, longitude=$longitude, altitude=$altitude, speed=$speed, distance=$distance, heartRate=$heartRate, power=$power, cadence=$cadence, temperature=$temperature]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'time'] = this.time;
    if (this.latitude != null) {
      json[r'latitude'] = this.latitude;
    } else {
      json[r'latitude'] = null;
    }
    if (this.longitude != null) {
      json[r'longitude'] = this.longitude;
    } else {
      json[r'longitude'] = null;
    }
    if (this.altitude != null) {
      json[r'altitude'] = this.altitude;
    } else {
      json[r'altitude'] = null;
    }
    if (this.speed != null) {
      json[r'speed'] = this.speed;
    } else {
      json[r'speed'] = null;
    }
    if (this.distance != null) {
      json[r'distance'] = this.distance;
    } else {
      json[r'distance'] = null;
    }
    if (this.heartRate != null) {
      json[r'heartRate'] = this.heartRate;
    } else {
      json[r'heartRate'] = null;
    }
    if (this.power != null) {
      json[r'power'] = this.power;
    } else {
      json[r'power'] = null;
    }
    if (this.cadence != null) {
      json[r'cadence'] = this.cadence;
    } else {
      json[r'cadence'] = null;
    }
    if (this.temperature != null) {
      json[r'temperature'] = this.temperature;
    } else {
      json[r'temperature'] = null;
    }
    return json;
  }

  /// Clones this instance of [RideStreamsResponse] and returns a new one where some of the
  /// properties have changed.
  RideStreamsResponse copyWith({
    List<double>? time,
    List<double?>? latitude,
    bool latitudeSetToNull = false,
    List<double?>? longitude,
    bool longitudeSetToNull = false,
    List<double?>? altitude,
    bool altitudeSetToNull = false,
    List<double?>? speed,
    bool speedSetToNull = false,
    List<double?>? distance,
    bool distanceSetToNull = false,
    List<int?>? heartRate,
    bool heartRateSetToNull = false,
    List<int?>? power,
    bool powerSetToNull = false,
    List<int?>? cadence,
    bool cadenceSetToNull = false,
    List<int?>? temperature,
    bool temperatureSetToNull = false,
  }) => RideStreamsResponse(
    time: time ?? this.time,
    latitude: latitudeSetToNull ? null : latitude ?? this.latitude,
    longitude: longitudeSetToNull ? null : longitude ?? this.longitude,
    altitude: altitudeSetToNull ? null : altitude ?? this.altitude,
    speed: speedSetToNull ? null : speed ?? this.speed,
    distance: distanceSetToNull ? null : distance ?? this.distance,
    heartRate: heartRateSetToNull ? null : heartRate ?? this.heartRate,
    power: powerSetToNull ? null : power ?? this.power,
    cadence: cadenceSetToNull ? null : cadence ?? this.cadence,
    temperature: temperatureSetToNull ? null : temperature ?? this.temperature,
  );

  /// Returns a new [RideStreamsResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RideStreamsResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'time'), 'Required key "RideStreamsResponse[time]" is missing from JSON.');
        assert(json[r'time'] != null, 'Required key "RideStreamsResponse[time]" has a null value in JSON.');
        assert(json.containsKey(r'latitude'), 'Required key "RideStreamsResponse[latitude]" is missing from JSON.');
        assert(json.containsKey(r'longitude'), 'Required key "RideStreamsResponse[longitude]" is missing from JSON.');
        assert(json.containsKey(r'altitude'), 'Required key "RideStreamsResponse[altitude]" is missing from JSON.');
        assert(json.containsKey(r'speed'), 'Required key "RideStreamsResponse[speed]" is missing from JSON.');
        assert(json.containsKey(r'distance'), 'Required key "RideStreamsResponse[distance]" is missing from JSON.');
        assert(json.containsKey(r'heartRate'), 'Required key "RideStreamsResponse[heartRate]" is missing from JSON.');
        assert(json.containsKey(r'power'), 'Required key "RideStreamsResponse[power]" is missing from JSON.');
        assert(json.containsKey(r'cadence'), 'Required key "RideStreamsResponse[cadence]" is missing from JSON.');
        assert(json.containsKey(r'temperature'), 'Required key "RideStreamsResponse[temperature]" is missing from JSON.');
        return true;
      }());

      return RideStreamsResponse(
        time: json[r'time'] is Iterable
            ? (json[r'time'] as Iterable).map((e) => (e as num).toDouble()).toList(growable: false)
            : const [],
        latitude: json[r'latitude'] is Iterable
            ? (json[r'latitude'] as Iterable).map((e) => (e as num?)?.toDouble()).toList(growable: false)
            : const [],
        longitude: json[r'longitude'] is Iterable
            ? (json[r'longitude'] as Iterable).map((e) => (e as num?)?.toDouble()).toList(growable: false)
            : const [],
        altitude: json[r'altitude'] is Iterable
            ? (json[r'altitude'] as Iterable).map((e) => (e as num?)?.toDouble()).toList(growable: false)
            : const [],
        speed: json[r'speed'] is Iterable
            ? (json[r'speed'] as Iterable).map((e) => (e as num?)?.toDouble()).toList(growable: false)
            : const [],
        distance: json[r'distance'] is Iterable
            ? (json[r'distance'] as Iterable).map((e) => (e as num?)?.toDouble()).toList(growable: false)
            : const [],
        heartRate: json[r'heartRate'] is Iterable
            ? (json[r'heartRate'] as Iterable).map((e) => (e as num?)?.toInt()).toList(growable: false)
            : const [],
        power: json[r'power'] is Iterable
            ? (json[r'power'] as Iterable).map((e) => (e as num?)?.toInt()).toList(growable: false)
            : const [],
        cadence: json[r'cadence'] is Iterable
            ? (json[r'cadence'] as Iterable).map((e) => (e as num?)?.toInt()).toList(growable: false)
            : const [],
        temperature: json[r'temperature'] is Iterable
            ? (json[r'temperature'] as Iterable).map((e) => (e as num?)?.toInt()).toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<RideStreamsResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RideStreamsResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RideStreamsResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RideStreamsResponse> mapFromJson(dynamic json) {
    final map = <String, RideStreamsResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RideStreamsResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RideStreamsResponse-objects as value to a dart map
  static Map<String, List<RideStreamsResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RideStreamsResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RideStreamsResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'time',
    'latitude',
    'longitude',
    'altitude',
    'speed',
    'distance',
    'heartRate',
    'power',
    'cadence',
    'temperature',
  };
}

