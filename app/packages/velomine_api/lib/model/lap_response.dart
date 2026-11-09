//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class LapResponse {
  /// Returns a new [LapResponse] instance.
  LapResponse({
    required this.index,
    required this.startS,
    required this.endS,
    required this.durationS,
    required this.movingS,
    required this.distanceM,
    required this.avgSpeedMs,
    required this.maxSpeedMs,
    required this.avgPowerW,
    required this.maxPowerW,
    required this.avgHeartRate,
    required this.maxHeartRate,
    required this.avgCadence,
    required this.elevationGainM,
  });

  final int index;

  final double startS;

  final double endS;

  final double durationS;

  final double movingS;

  final double distanceM;

  final double? avgSpeedMs;

  final double? maxSpeedMs;

  final int? avgPowerW;

  final int? maxPowerW;

  final int? avgHeartRate;

  final int? maxHeartRate;

  final int? avgCadence;

  final double? elevationGainM;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LapResponse &&
    other.index == index &&
    other.startS == startS &&
    other.endS == endS &&
    other.durationS == durationS &&
    other.movingS == movingS &&
    other.distanceM == distanceM &&
    other.avgSpeedMs == avgSpeedMs &&
    other.maxSpeedMs == maxSpeedMs &&
    other.avgPowerW == avgPowerW &&
    other.maxPowerW == maxPowerW &&
    other.avgHeartRate == avgHeartRate &&
    other.maxHeartRate == maxHeartRate &&
    other.avgCadence == avgCadence &&
    other.elevationGainM == elevationGainM;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (index.hashCode) +
    (startS.hashCode) +
    (endS.hashCode) +
    (durationS.hashCode) +
    (movingS.hashCode) +
    (distanceM.hashCode) +
    (avgSpeedMs == null ? 0 : avgSpeedMs!.hashCode) +
    (maxSpeedMs == null ? 0 : maxSpeedMs!.hashCode) +
    (avgPowerW == null ? 0 : avgPowerW!.hashCode) +
    (maxPowerW == null ? 0 : maxPowerW!.hashCode) +
    (avgHeartRate == null ? 0 : avgHeartRate!.hashCode) +
    (maxHeartRate == null ? 0 : maxHeartRate!.hashCode) +
    (avgCadence == null ? 0 : avgCadence!.hashCode) +
    (elevationGainM == null ? 0 : elevationGainM!.hashCode);

  @override
  String toString() => 'LapResponse[index=$index, startS=$startS, endS=$endS, durationS=$durationS, movingS=$movingS, distanceM=$distanceM, avgSpeedMs=$avgSpeedMs, maxSpeedMs=$maxSpeedMs, avgPowerW=$avgPowerW, maxPowerW=$maxPowerW, avgHeartRate=$avgHeartRate, maxHeartRate=$maxHeartRate, avgCadence=$avgCadence, elevationGainM=$elevationGainM]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'index'] = this.index;
      json[r'startS'] = this.startS;
      json[r'endS'] = this.endS;
      json[r'durationS'] = this.durationS;
      json[r'movingS'] = this.movingS;
      json[r'distanceM'] = this.distanceM;
    if (this.avgSpeedMs != null) {
      json[r'avgSpeedMs'] = this.avgSpeedMs;
    } else {
      json[r'avgSpeedMs'] = null;
    }
    if (this.maxSpeedMs != null) {
      json[r'maxSpeedMs'] = this.maxSpeedMs;
    } else {
      json[r'maxSpeedMs'] = null;
    }
    if (this.avgPowerW != null) {
      json[r'avgPowerW'] = this.avgPowerW;
    } else {
      json[r'avgPowerW'] = null;
    }
    if (this.maxPowerW != null) {
      json[r'maxPowerW'] = this.maxPowerW;
    } else {
      json[r'maxPowerW'] = null;
    }
    if (this.avgHeartRate != null) {
      json[r'avgHeartRate'] = this.avgHeartRate;
    } else {
      json[r'avgHeartRate'] = null;
    }
    if (this.maxHeartRate != null) {
      json[r'maxHeartRate'] = this.maxHeartRate;
    } else {
      json[r'maxHeartRate'] = null;
    }
    if (this.avgCadence != null) {
      json[r'avgCadence'] = this.avgCadence;
    } else {
      json[r'avgCadence'] = null;
    }
    if (this.elevationGainM != null) {
      json[r'elevationGainM'] = this.elevationGainM;
    } else {
      json[r'elevationGainM'] = null;
    }
    return json;
  }

  /// Clones this instance of [LapResponse] and returns a new one where some of the
  /// properties have changed.
  LapResponse copyWith({
    int? index,
    double? startS,
    double? endS,
    double? durationS,
    double? movingS,
    double? distanceM,
    double? avgSpeedMs,
    bool avgSpeedMsSetToNull = false,
    double? maxSpeedMs,
    bool maxSpeedMsSetToNull = false,
    int? avgPowerW,
    bool avgPowerWSetToNull = false,
    int? maxPowerW,
    bool maxPowerWSetToNull = false,
    int? avgHeartRate,
    bool avgHeartRateSetToNull = false,
    int? maxHeartRate,
    bool maxHeartRateSetToNull = false,
    int? avgCadence,
    bool avgCadenceSetToNull = false,
    double? elevationGainM,
    bool elevationGainMSetToNull = false,
  }) => LapResponse(
    index: index ?? this.index,
    startS: startS ?? this.startS,
    endS: endS ?? this.endS,
    durationS: durationS ?? this.durationS,
    movingS: movingS ?? this.movingS,
    distanceM: distanceM ?? this.distanceM,
    avgSpeedMs: avgSpeedMsSetToNull ? null : avgSpeedMs ?? this.avgSpeedMs,
    maxSpeedMs: maxSpeedMsSetToNull ? null : maxSpeedMs ?? this.maxSpeedMs,
    avgPowerW: avgPowerWSetToNull ? null : avgPowerW ?? this.avgPowerW,
    maxPowerW: maxPowerWSetToNull ? null : maxPowerW ?? this.maxPowerW,
    avgHeartRate: avgHeartRateSetToNull ? null : avgHeartRate ?? this.avgHeartRate,
    maxHeartRate: maxHeartRateSetToNull ? null : maxHeartRate ?? this.maxHeartRate,
    avgCadence: avgCadenceSetToNull ? null : avgCadence ?? this.avgCadence,
    elevationGainM: elevationGainMSetToNull ? null : elevationGainM ?? this.elevationGainM,
  );

  /// Returns a new [LapResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LapResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'index'), 'Required key "LapResponse[index]" is missing from JSON.');
        assert(json[r'index'] != null, 'Required key "LapResponse[index]" has a null value in JSON.');
        assert(json.containsKey(r'startS'), 'Required key "LapResponse[startS]" is missing from JSON.');
        assert(json[r'startS'] != null, 'Required key "LapResponse[startS]" has a null value in JSON.');
        assert(json.containsKey(r'endS'), 'Required key "LapResponse[endS]" is missing from JSON.');
        assert(json[r'endS'] != null, 'Required key "LapResponse[endS]" has a null value in JSON.');
        assert(json.containsKey(r'durationS'), 'Required key "LapResponse[durationS]" is missing from JSON.');
        assert(json[r'durationS'] != null, 'Required key "LapResponse[durationS]" has a null value in JSON.');
        assert(json.containsKey(r'movingS'), 'Required key "LapResponse[movingS]" is missing from JSON.');
        assert(json[r'movingS'] != null, 'Required key "LapResponse[movingS]" has a null value in JSON.');
        assert(json.containsKey(r'distanceM'), 'Required key "LapResponse[distanceM]" is missing from JSON.');
        assert(json[r'distanceM'] != null, 'Required key "LapResponse[distanceM]" has a null value in JSON.');
        assert(json.containsKey(r'avgSpeedMs'), 'Required key "LapResponse[avgSpeedMs]" is missing from JSON.');
        assert(json.containsKey(r'maxSpeedMs'), 'Required key "LapResponse[maxSpeedMs]" is missing from JSON.');
        assert(json.containsKey(r'avgPowerW'), 'Required key "LapResponse[avgPowerW]" is missing from JSON.');
        assert(json.containsKey(r'maxPowerW'), 'Required key "LapResponse[maxPowerW]" is missing from JSON.');
        assert(json.containsKey(r'avgHeartRate'), 'Required key "LapResponse[avgHeartRate]" is missing from JSON.');
        assert(json.containsKey(r'maxHeartRate'), 'Required key "LapResponse[maxHeartRate]" is missing from JSON.');
        assert(json.containsKey(r'avgCadence'), 'Required key "LapResponse[avgCadence]" is missing from JSON.');
        assert(json.containsKey(r'elevationGainM'), 'Required key "LapResponse[elevationGainM]" is missing from JSON.');
        return true;
      }());

      return LapResponse(
        index: mapValueOfType<int>(json, r'index')!,
        startS: mapValueOfType<double>(json, r'startS')!,
        endS: mapValueOfType<double>(json, r'endS')!,
        durationS: mapValueOfType<double>(json, r'durationS')!,
        movingS: mapValueOfType<double>(json, r'movingS')!,
        distanceM: mapValueOfType<double>(json, r'distanceM')!,
        avgSpeedMs: mapValueOfType<double>(json, r'avgSpeedMs'),
        maxSpeedMs: mapValueOfType<double>(json, r'maxSpeedMs'),
        avgPowerW: mapValueOfType<int>(json, r'avgPowerW'),
        maxPowerW: mapValueOfType<int>(json, r'maxPowerW'),
        avgHeartRate: mapValueOfType<int>(json, r'avgHeartRate'),
        maxHeartRate: mapValueOfType<int>(json, r'maxHeartRate'),
        avgCadence: mapValueOfType<int>(json, r'avgCadence'),
        elevationGainM: mapValueOfType<double>(json, r'elevationGainM'),
      );
    }
    return null;
  }

  static List<LapResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LapResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LapResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LapResponse> mapFromJson(dynamic json) {
    final map = <String, LapResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LapResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LapResponse-objects as value to a dart map
  static Map<String, List<LapResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LapResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LapResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'index',
    'startS',
    'endS',
    'durationS',
    'movingS',
    'distanceM',
    'avgSpeedMs',
    'maxSpeedMs',
    'avgPowerW',
    'maxPowerW',
    'avgHeartRate',
    'maxHeartRate',
    'avgCadence',
    'elevationGainM',
  };
}

