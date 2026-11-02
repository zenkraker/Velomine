//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class RideResponse {
  /// Returns a new [RideResponse] instance.
  RideResponse({
    required this.id,
    required this.status,
    required this.error,
    required this.duplicateOf,
    required this.fileName,
    required this.uploadedAt,
    required this.startTime,
    required this.utcOffsetMinutes,
    required this.device,
    required this.distanceM,
    required this.elapsedS,
    required this.movingS,
    required this.elevationGainM,
    required this.elevationLossM,
    required this.avgSpeedMs,
    required this.maxSpeedMs,
    required this.speedSource,
    required this.avgPowerW,
    required this.maxPowerW,
    required this.normalizedPowerW,
    required this.avgHeartRate,
    required this.maxHeartRate,
    required this.avgCadence,
  });

  final String id;

  final String status;

  final String? error;

  final String? duplicateOf;

  final String fileName;

  final DateTime uploadedAt;

  final DateTime? startTime;

  final int? utcOffsetMinutes;

  final String? device;

  final double? distanceM;

  final double? elapsedS;

  final double? movingS;

  final double? elevationGainM;

  final double? elevationLossM;

  final double? avgSpeedMs;

  final double? maxSpeedMs;

  final String? speedSource;

  final int? avgPowerW;

  final int? maxPowerW;

  final int? normalizedPowerW;

  final int? avgHeartRate;

  final int? maxHeartRate;

  final int? avgCadence;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RideResponse &&
    other.id == id &&
    other.status == status &&
    other.error == error &&
    other.duplicateOf == duplicateOf &&
    other.fileName == fileName &&
    other.uploadedAt == uploadedAt &&
    other.startTime == startTime &&
    other.utcOffsetMinutes == utcOffsetMinutes &&
    other.device == device &&
    other.distanceM == distanceM &&
    other.elapsedS == elapsedS &&
    other.movingS == movingS &&
    other.elevationGainM == elevationGainM &&
    other.elevationLossM == elevationLossM &&
    other.avgSpeedMs == avgSpeedMs &&
    other.maxSpeedMs == maxSpeedMs &&
    other.speedSource == speedSource &&
    other.avgPowerW == avgPowerW &&
    other.maxPowerW == maxPowerW &&
    other.normalizedPowerW == normalizedPowerW &&
    other.avgHeartRate == avgHeartRate &&
    other.maxHeartRate == maxHeartRate &&
    other.avgCadence == avgCadence;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (status.hashCode) +
    (error == null ? 0 : error!.hashCode) +
    (duplicateOf == null ? 0 : duplicateOf!.hashCode) +
    (fileName.hashCode) +
    (uploadedAt.hashCode) +
    (startTime == null ? 0 : startTime!.hashCode) +
    (utcOffsetMinutes == null ? 0 : utcOffsetMinutes!.hashCode) +
    (device == null ? 0 : device!.hashCode) +
    (distanceM == null ? 0 : distanceM!.hashCode) +
    (elapsedS == null ? 0 : elapsedS!.hashCode) +
    (movingS == null ? 0 : movingS!.hashCode) +
    (elevationGainM == null ? 0 : elevationGainM!.hashCode) +
    (elevationLossM == null ? 0 : elevationLossM!.hashCode) +
    (avgSpeedMs == null ? 0 : avgSpeedMs!.hashCode) +
    (maxSpeedMs == null ? 0 : maxSpeedMs!.hashCode) +
    (speedSource == null ? 0 : speedSource!.hashCode) +
    (avgPowerW == null ? 0 : avgPowerW!.hashCode) +
    (maxPowerW == null ? 0 : maxPowerW!.hashCode) +
    (normalizedPowerW == null ? 0 : normalizedPowerW!.hashCode) +
    (avgHeartRate == null ? 0 : avgHeartRate!.hashCode) +
    (maxHeartRate == null ? 0 : maxHeartRate!.hashCode) +
    (avgCadence == null ? 0 : avgCadence!.hashCode);

  @override
  String toString() => 'RideResponse[id=$id, status=$status, error=$error, duplicateOf=$duplicateOf, fileName=$fileName, uploadedAt=$uploadedAt, startTime=$startTime, utcOffsetMinutes=$utcOffsetMinutes, device=$device, distanceM=$distanceM, elapsedS=$elapsedS, movingS=$movingS, elevationGainM=$elevationGainM, elevationLossM=$elevationLossM, avgSpeedMs=$avgSpeedMs, maxSpeedMs=$maxSpeedMs, speedSource=$speedSource, avgPowerW=$avgPowerW, maxPowerW=$maxPowerW, normalizedPowerW=$normalizedPowerW, avgHeartRate=$avgHeartRate, maxHeartRate=$maxHeartRate, avgCadence=$avgCadence]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'status'] = this.status;
    if (this.error != null) {
      json[r'error'] = this.error;
    } else {
      json[r'error'] = null;
    }
    if (this.duplicateOf != null) {
      json[r'duplicateOf'] = this.duplicateOf;
    } else {
      json[r'duplicateOf'] = null;
    }
      json[r'fileName'] = this.fileName;
      json[r'uploadedAt'] = this.uploadedAt.toUtc().toIso8601String();
    if (this.startTime != null) {
      json[r'startTime'] = this.startTime!.toUtc().toIso8601String();
    } else {
      json[r'startTime'] = null;
    }
    if (this.utcOffsetMinutes != null) {
      json[r'utcOffsetMinutes'] = this.utcOffsetMinutes;
    } else {
      json[r'utcOffsetMinutes'] = null;
    }
    if (this.device != null) {
      json[r'device'] = this.device;
    } else {
      json[r'device'] = null;
    }
    if (this.distanceM != null) {
      json[r'distanceM'] = this.distanceM;
    } else {
      json[r'distanceM'] = null;
    }
    if (this.elapsedS != null) {
      json[r'elapsedS'] = this.elapsedS;
    } else {
      json[r'elapsedS'] = null;
    }
    if (this.movingS != null) {
      json[r'movingS'] = this.movingS;
    } else {
      json[r'movingS'] = null;
    }
    if (this.elevationGainM != null) {
      json[r'elevationGainM'] = this.elevationGainM;
    } else {
      json[r'elevationGainM'] = null;
    }
    if (this.elevationLossM != null) {
      json[r'elevationLossM'] = this.elevationLossM;
    } else {
      json[r'elevationLossM'] = null;
    }
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
    if (this.speedSource != null) {
      json[r'speedSource'] = this.speedSource;
    } else {
      json[r'speedSource'] = null;
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
    if (this.normalizedPowerW != null) {
      json[r'normalizedPowerW'] = this.normalizedPowerW;
    } else {
      json[r'normalizedPowerW'] = null;
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
    return json;
  }

  /// Clones this instance of [RideResponse] and returns a new one where some of the
  /// properties have changed.
  RideResponse copyWith({
    String? id,
    String? status,
    String? error,
    bool errorSetToNull = false,
    String? duplicateOf,
    bool duplicateOfSetToNull = false,
    String? fileName,
    DateTime? uploadedAt,
    DateTime? startTime,
    bool startTimeSetToNull = false,
    int? utcOffsetMinutes,
    bool utcOffsetMinutesSetToNull = false,
    String? device,
    bool deviceSetToNull = false,
    double? distanceM,
    bool distanceMSetToNull = false,
    double? elapsedS,
    bool elapsedSSetToNull = false,
    double? movingS,
    bool movingSSetToNull = false,
    double? elevationGainM,
    bool elevationGainMSetToNull = false,
    double? elevationLossM,
    bool elevationLossMSetToNull = false,
    double? avgSpeedMs,
    bool avgSpeedMsSetToNull = false,
    double? maxSpeedMs,
    bool maxSpeedMsSetToNull = false,
    String? speedSource,
    bool speedSourceSetToNull = false,
    int? avgPowerW,
    bool avgPowerWSetToNull = false,
    int? maxPowerW,
    bool maxPowerWSetToNull = false,
    int? normalizedPowerW,
    bool normalizedPowerWSetToNull = false,
    int? avgHeartRate,
    bool avgHeartRateSetToNull = false,
    int? maxHeartRate,
    bool maxHeartRateSetToNull = false,
    int? avgCadence,
    bool avgCadenceSetToNull = false,
  }) => RideResponse(
    id: id ?? this.id,
    status: status ?? this.status,
    error: errorSetToNull ? null : error ?? this.error,
    duplicateOf: duplicateOfSetToNull ? null : duplicateOf ?? this.duplicateOf,
    fileName: fileName ?? this.fileName,
    uploadedAt: uploadedAt ?? this.uploadedAt,
    startTime: startTimeSetToNull ? null : startTime ?? this.startTime,
    utcOffsetMinutes: utcOffsetMinutesSetToNull ? null : utcOffsetMinutes ?? this.utcOffsetMinutes,
    device: deviceSetToNull ? null : device ?? this.device,
    distanceM: distanceMSetToNull ? null : distanceM ?? this.distanceM,
    elapsedS: elapsedSSetToNull ? null : elapsedS ?? this.elapsedS,
    movingS: movingSSetToNull ? null : movingS ?? this.movingS,
    elevationGainM: elevationGainMSetToNull ? null : elevationGainM ?? this.elevationGainM,
    elevationLossM: elevationLossMSetToNull ? null : elevationLossM ?? this.elevationLossM,
    avgSpeedMs: avgSpeedMsSetToNull ? null : avgSpeedMs ?? this.avgSpeedMs,
    maxSpeedMs: maxSpeedMsSetToNull ? null : maxSpeedMs ?? this.maxSpeedMs,
    speedSource: speedSourceSetToNull ? null : speedSource ?? this.speedSource,
    avgPowerW: avgPowerWSetToNull ? null : avgPowerW ?? this.avgPowerW,
    maxPowerW: maxPowerWSetToNull ? null : maxPowerW ?? this.maxPowerW,
    normalizedPowerW: normalizedPowerWSetToNull ? null : normalizedPowerW ?? this.normalizedPowerW,
    avgHeartRate: avgHeartRateSetToNull ? null : avgHeartRate ?? this.avgHeartRate,
    maxHeartRate: maxHeartRateSetToNull ? null : maxHeartRate ?? this.maxHeartRate,
    avgCadence: avgCadenceSetToNull ? null : avgCadence ?? this.avgCadence,
  );

  /// Returns a new [RideResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RideResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "RideResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "RideResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "RideResponse[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "RideResponse[status]" has a null value in JSON.');
        assert(json.containsKey(r'error'), 'Required key "RideResponse[error]" is missing from JSON.');
        assert(json.containsKey(r'duplicateOf'), 'Required key "RideResponse[duplicateOf]" is missing from JSON.');
        assert(json.containsKey(r'fileName'), 'Required key "RideResponse[fileName]" is missing from JSON.');
        assert(json[r'fileName'] != null, 'Required key "RideResponse[fileName]" has a null value in JSON.');
        assert(json.containsKey(r'uploadedAt'), 'Required key "RideResponse[uploadedAt]" is missing from JSON.');
        assert(json[r'uploadedAt'] != null, 'Required key "RideResponse[uploadedAt]" has a null value in JSON.');
        assert(json.containsKey(r'startTime'), 'Required key "RideResponse[startTime]" is missing from JSON.');
        assert(json.containsKey(r'utcOffsetMinutes'), 'Required key "RideResponse[utcOffsetMinutes]" is missing from JSON.');
        assert(json.containsKey(r'device'), 'Required key "RideResponse[device]" is missing from JSON.');
        assert(json.containsKey(r'distanceM'), 'Required key "RideResponse[distanceM]" is missing from JSON.');
        assert(json.containsKey(r'elapsedS'), 'Required key "RideResponse[elapsedS]" is missing from JSON.');
        assert(json.containsKey(r'movingS'), 'Required key "RideResponse[movingS]" is missing from JSON.');
        assert(json.containsKey(r'elevationGainM'), 'Required key "RideResponse[elevationGainM]" is missing from JSON.');
        assert(json.containsKey(r'elevationLossM'), 'Required key "RideResponse[elevationLossM]" is missing from JSON.');
        assert(json.containsKey(r'avgSpeedMs'), 'Required key "RideResponse[avgSpeedMs]" is missing from JSON.');
        assert(json.containsKey(r'maxSpeedMs'), 'Required key "RideResponse[maxSpeedMs]" is missing from JSON.');
        assert(json.containsKey(r'speedSource'), 'Required key "RideResponse[speedSource]" is missing from JSON.');
        assert(json.containsKey(r'avgPowerW'), 'Required key "RideResponse[avgPowerW]" is missing from JSON.');
        assert(json.containsKey(r'maxPowerW'), 'Required key "RideResponse[maxPowerW]" is missing from JSON.');
        assert(json.containsKey(r'normalizedPowerW'), 'Required key "RideResponse[normalizedPowerW]" is missing from JSON.');
        assert(json.containsKey(r'avgHeartRate'), 'Required key "RideResponse[avgHeartRate]" is missing from JSON.');
        assert(json.containsKey(r'maxHeartRate'), 'Required key "RideResponse[maxHeartRate]" is missing from JSON.');
        assert(json.containsKey(r'avgCadence'), 'Required key "RideResponse[avgCadence]" is missing from JSON.');
        return true;
      }());

      return RideResponse(
        id: mapValueOfType<String>(json, r'id')!,
        status: mapValueOfType<String>(json, r'status')!,
        error: mapValueOfType<String>(json, r'error'),
        duplicateOf: mapValueOfType<String>(json, r'duplicateOf'),
        fileName: mapValueOfType<String>(json, r'fileName')!,
        uploadedAt: mapDateTime(json, r'uploadedAt', r'')!,
        startTime: mapDateTime(json, r'startTime', r''),
        utcOffsetMinutes: mapValueOfType<int>(json, r'utcOffsetMinutes'),
        device: mapValueOfType<String>(json, r'device'),
        distanceM: mapValueOfType<double>(json, r'distanceM'),
        elapsedS: mapValueOfType<double>(json, r'elapsedS'),
        movingS: mapValueOfType<double>(json, r'movingS'),
        elevationGainM: mapValueOfType<double>(json, r'elevationGainM'),
        elevationLossM: mapValueOfType<double>(json, r'elevationLossM'),
        avgSpeedMs: mapValueOfType<double>(json, r'avgSpeedMs'),
        maxSpeedMs: mapValueOfType<double>(json, r'maxSpeedMs'),
        speedSource: mapValueOfType<String>(json, r'speedSource'),
        avgPowerW: mapValueOfType<int>(json, r'avgPowerW'),
        maxPowerW: mapValueOfType<int>(json, r'maxPowerW'),
        normalizedPowerW: mapValueOfType<int>(json, r'normalizedPowerW'),
        avgHeartRate: mapValueOfType<int>(json, r'avgHeartRate'),
        maxHeartRate: mapValueOfType<int>(json, r'maxHeartRate'),
        avgCadence: mapValueOfType<int>(json, r'avgCadence'),
      );
    }
    return null;
  }

  static List<RideResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RideResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RideResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RideResponse> mapFromJson(dynamic json) {
    final map = <String, RideResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RideResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RideResponse-objects as value to a dart map
  static Map<String, List<RideResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RideResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RideResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'status',
    'error',
    'duplicateOf',
    'fileName',
    'uploadedAt',
    'startTime',
    'utcOffsetMinutes',
    'device',
    'distanceM',
    'elapsedS',
    'movingS',
    'elevationGainM',
    'elevationLossM',
    'avgSpeedMs',
    'maxSpeedMs',
    'speedSource',
    'avgPowerW',
    'maxPowerW',
    'normalizedPowerW',
    'avgHeartRate',
    'maxHeartRate',
    'avgCadence',
  };
}

