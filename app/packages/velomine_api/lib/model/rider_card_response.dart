//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class RiderCardResponse {
  /// Returns a new [RiderCardResponse] instance.
  RiderCardResponse({
    required this.ftpW,
    required this.weightKg,
    required this.wattsPerKg,
    required this.ftpSource,
    required this.ftpSetAt,
    required this.ftpRideId,
    required this.ftpRideDate,
    required this.criticalPowerW,
    required this.wPrimeJ,
    required this.peakPowerW,
    this.bests = const [],
    required this.maxHeartRate,
    required this.maxHeartRateSource,
    required this.maxHeartRateSetAt,
    required this.maxHeartRateRideId,
    required this.maxHeartRateRideDate,
    required this.thresholdHeartRate,
    required this.thresholdHeartRateSource,
    required this.thresholdHeartRateSetAt,
    required this.thresholdHeartRateRideId,
    required this.thresholdHeartRateRideDate,
    this.efficiency = const [],
    required this.rides,
    required this.distanceM,
    required this.movingS,
    required this.elevationGainM,
    required this.fitness,
    required this.fatigue,
    required this.form,
    required this.nextEvent,
  });

  final int? ftpW;

  final double? weightKg;

  final double? wattsPerKg;

  final String? ftpSource;

  final DateTime? ftpSetAt;

  final String? ftpRideId;

  final DateTime? ftpRideDate;

  final int? criticalPowerW;

  final int? wPrimeJ;

  final int? peakPowerW;

  final List<RiderCardBest> bests;

  final int? maxHeartRate;

  final String? maxHeartRateSource;

  final DateTime? maxHeartRateSetAt;

  final String? maxHeartRateRideId;

  final DateTime? maxHeartRateRideDate;

  final int? thresholdHeartRate;

  final String? thresholdHeartRateSource;

  final DateTime? thresholdHeartRateSetAt;

  final String? thresholdHeartRateRideId;

  final DateTime? thresholdHeartRateRideDate;

  final List<EfficiencyWeek> efficiency;

  final int rides;

  final double distanceM;

  final double movingS;

  final double elevationGainM;

  final double? fitness;

  final double? fatigue;

  final double? form;

  final EventResponse? nextEvent;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RiderCardResponse &&
    other.ftpW == ftpW &&
    other.weightKg == weightKg &&
    other.wattsPerKg == wattsPerKg &&
    other.ftpSource == ftpSource &&
    other.ftpSetAt == ftpSetAt &&
    other.ftpRideId == ftpRideId &&
    other.ftpRideDate == ftpRideDate &&
    other.criticalPowerW == criticalPowerW &&
    other.wPrimeJ == wPrimeJ &&
    other.peakPowerW == peakPowerW &&
    _deepEquality.equals(other.bests, bests) &&
    other.maxHeartRate == maxHeartRate &&
    other.maxHeartRateSource == maxHeartRateSource &&
    other.maxHeartRateSetAt == maxHeartRateSetAt &&
    other.maxHeartRateRideId == maxHeartRateRideId &&
    other.maxHeartRateRideDate == maxHeartRateRideDate &&
    other.thresholdHeartRate == thresholdHeartRate &&
    other.thresholdHeartRateSource == thresholdHeartRateSource &&
    other.thresholdHeartRateSetAt == thresholdHeartRateSetAt &&
    other.thresholdHeartRateRideId == thresholdHeartRateRideId &&
    other.thresholdHeartRateRideDate == thresholdHeartRateRideDate &&
    _deepEquality.equals(other.efficiency, efficiency) &&
    other.rides == rides &&
    other.distanceM == distanceM &&
    other.movingS == movingS &&
    other.elevationGainM == elevationGainM &&
    other.fitness == fitness &&
    other.fatigue == fatigue &&
    other.form == form &&
    other.nextEvent == nextEvent;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (ftpW == null ? 0 : ftpW!.hashCode) +
    (weightKg == null ? 0 : weightKg!.hashCode) +
    (wattsPerKg == null ? 0 : wattsPerKg!.hashCode) +
    (ftpSource == null ? 0 : ftpSource!.hashCode) +
    (ftpSetAt == null ? 0 : ftpSetAt!.hashCode) +
    (ftpRideId == null ? 0 : ftpRideId!.hashCode) +
    (ftpRideDate == null ? 0 : ftpRideDate!.hashCode) +
    (criticalPowerW == null ? 0 : criticalPowerW!.hashCode) +
    (wPrimeJ == null ? 0 : wPrimeJ!.hashCode) +
    (peakPowerW == null ? 0 : peakPowerW!.hashCode) +
    (bests.hashCode) +
    (maxHeartRate == null ? 0 : maxHeartRate!.hashCode) +
    (maxHeartRateSource == null ? 0 : maxHeartRateSource!.hashCode) +
    (maxHeartRateSetAt == null ? 0 : maxHeartRateSetAt!.hashCode) +
    (maxHeartRateRideId == null ? 0 : maxHeartRateRideId!.hashCode) +
    (maxHeartRateRideDate == null ? 0 : maxHeartRateRideDate!.hashCode) +
    (thresholdHeartRate == null ? 0 : thresholdHeartRate!.hashCode) +
    (thresholdHeartRateSource == null ? 0 : thresholdHeartRateSource!.hashCode) +
    (thresholdHeartRateSetAt == null ? 0 : thresholdHeartRateSetAt!.hashCode) +
    (thresholdHeartRateRideId == null ? 0 : thresholdHeartRateRideId!.hashCode) +
    (thresholdHeartRateRideDate == null ? 0 : thresholdHeartRateRideDate!.hashCode) +
    (efficiency.hashCode) +
    (rides.hashCode) +
    (distanceM.hashCode) +
    (movingS.hashCode) +
    (elevationGainM.hashCode) +
    (fitness == null ? 0 : fitness!.hashCode) +
    (fatigue == null ? 0 : fatigue!.hashCode) +
    (form == null ? 0 : form!.hashCode) +
    (nextEvent == null ? 0 : nextEvent!.hashCode);

  @override
  String toString() => 'RiderCardResponse[ftpW=$ftpW, weightKg=$weightKg, wattsPerKg=$wattsPerKg, ftpSource=$ftpSource, ftpSetAt=$ftpSetAt, ftpRideId=$ftpRideId, ftpRideDate=$ftpRideDate, criticalPowerW=$criticalPowerW, wPrimeJ=$wPrimeJ, peakPowerW=$peakPowerW, bests=$bests, maxHeartRate=$maxHeartRate, maxHeartRateSource=$maxHeartRateSource, maxHeartRateSetAt=$maxHeartRateSetAt, maxHeartRateRideId=$maxHeartRateRideId, maxHeartRateRideDate=$maxHeartRateRideDate, thresholdHeartRate=$thresholdHeartRate, thresholdHeartRateSource=$thresholdHeartRateSource, thresholdHeartRateSetAt=$thresholdHeartRateSetAt, thresholdHeartRateRideId=$thresholdHeartRateRideId, thresholdHeartRateRideDate=$thresholdHeartRateRideDate, efficiency=$efficiency, rides=$rides, distanceM=$distanceM, movingS=$movingS, elevationGainM=$elevationGainM, fitness=$fitness, fatigue=$fatigue, form=$form, nextEvent=$nextEvent]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.ftpW != null) {
      json[r'ftpW'] = this.ftpW;
    } else {
      json[r'ftpW'] = null;
    }
    if (this.weightKg != null) {
      json[r'weightKg'] = this.weightKg;
    } else {
      json[r'weightKg'] = null;
    }
    if (this.wattsPerKg != null) {
      json[r'wattsPerKg'] = this.wattsPerKg;
    } else {
      json[r'wattsPerKg'] = null;
    }
    if (this.ftpSource != null) {
      json[r'ftpSource'] = this.ftpSource;
    } else {
      json[r'ftpSource'] = null;
    }
    if (this.ftpSetAt != null) {
      json[r'ftpSetAt'] = this.ftpSetAt!.toUtc().toIso8601String();
    } else {
      json[r'ftpSetAt'] = null;
    }
    if (this.ftpRideId != null) {
      json[r'ftpRideId'] = this.ftpRideId;
    } else {
      json[r'ftpRideId'] = null;
    }
    if (this.ftpRideDate != null) {
      json[r'ftpRideDate'] = _dateFormatter.format(this.ftpRideDate!);
    } else {
      json[r'ftpRideDate'] = null;
    }
    if (this.criticalPowerW != null) {
      json[r'criticalPowerW'] = this.criticalPowerW;
    } else {
      json[r'criticalPowerW'] = null;
    }
    if (this.wPrimeJ != null) {
      json[r'wPrimeJ'] = this.wPrimeJ;
    } else {
      json[r'wPrimeJ'] = null;
    }
    if (this.peakPowerW != null) {
      json[r'peakPowerW'] = this.peakPowerW;
    } else {
      json[r'peakPowerW'] = null;
    }
      json[r'bests'] = this.bests;
    if (this.maxHeartRate != null) {
      json[r'maxHeartRate'] = this.maxHeartRate;
    } else {
      json[r'maxHeartRate'] = null;
    }
    if (this.maxHeartRateSource != null) {
      json[r'maxHeartRateSource'] = this.maxHeartRateSource;
    } else {
      json[r'maxHeartRateSource'] = null;
    }
    if (this.maxHeartRateSetAt != null) {
      json[r'maxHeartRateSetAt'] = this.maxHeartRateSetAt!.toUtc().toIso8601String();
    } else {
      json[r'maxHeartRateSetAt'] = null;
    }
    if (this.maxHeartRateRideId != null) {
      json[r'maxHeartRateRideId'] = this.maxHeartRateRideId;
    } else {
      json[r'maxHeartRateRideId'] = null;
    }
    if (this.maxHeartRateRideDate != null) {
      json[r'maxHeartRateRideDate'] = _dateFormatter.format(this.maxHeartRateRideDate!);
    } else {
      json[r'maxHeartRateRideDate'] = null;
    }
    if (this.thresholdHeartRate != null) {
      json[r'thresholdHeartRate'] = this.thresholdHeartRate;
    } else {
      json[r'thresholdHeartRate'] = null;
    }
    if (this.thresholdHeartRateSource != null) {
      json[r'thresholdHeartRateSource'] = this.thresholdHeartRateSource;
    } else {
      json[r'thresholdHeartRateSource'] = null;
    }
    if (this.thresholdHeartRateSetAt != null) {
      json[r'thresholdHeartRateSetAt'] = this.thresholdHeartRateSetAt!.toUtc().toIso8601String();
    } else {
      json[r'thresholdHeartRateSetAt'] = null;
    }
    if (this.thresholdHeartRateRideId != null) {
      json[r'thresholdHeartRateRideId'] = this.thresholdHeartRateRideId;
    } else {
      json[r'thresholdHeartRateRideId'] = null;
    }
    if (this.thresholdHeartRateRideDate != null) {
      json[r'thresholdHeartRateRideDate'] = _dateFormatter.format(this.thresholdHeartRateRideDate!);
    } else {
      json[r'thresholdHeartRateRideDate'] = null;
    }
      json[r'efficiency'] = this.efficiency;
      json[r'rides'] = this.rides;
      json[r'distanceM'] = this.distanceM;
      json[r'movingS'] = this.movingS;
      json[r'elevationGainM'] = this.elevationGainM;
    if (this.fitness != null) {
      json[r'fitness'] = this.fitness;
    } else {
      json[r'fitness'] = null;
    }
    if (this.fatigue != null) {
      json[r'fatigue'] = this.fatigue;
    } else {
      json[r'fatigue'] = null;
    }
    if (this.form != null) {
      json[r'form'] = this.form;
    } else {
      json[r'form'] = null;
    }
    if (this.nextEvent != null) {
      json[r'nextEvent'] = this.nextEvent;
    } else {
      json[r'nextEvent'] = null;
    }
    return json;
  }

  /// Clones this instance of [RiderCardResponse] and returns a new one where some of the
  /// properties have changed.
  RiderCardResponse copyWith({
    int? ftpW,
    bool ftpWSetToNull = false,
    double? weightKg,
    bool weightKgSetToNull = false,
    double? wattsPerKg,
    bool wattsPerKgSetToNull = false,
    String? ftpSource,
    bool ftpSourceSetToNull = false,
    DateTime? ftpSetAt,
    bool ftpSetAtSetToNull = false,
    String? ftpRideId,
    bool ftpRideIdSetToNull = false,
    DateTime? ftpRideDate,
    bool ftpRideDateSetToNull = false,
    int? criticalPowerW,
    bool criticalPowerWSetToNull = false,
    int? wPrimeJ,
    bool wPrimeJSetToNull = false,
    int? peakPowerW,
    bool peakPowerWSetToNull = false,
    List<RiderCardBest>? bests,
    int? maxHeartRate,
    bool maxHeartRateSetToNull = false,
    String? maxHeartRateSource,
    bool maxHeartRateSourceSetToNull = false,
    DateTime? maxHeartRateSetAt,
    bool maxHeartRateSetAtSetToNull = false,
    String? maxHeartRateRideId,
    bool maxHeartRateRideIdSetToNull = false,
    DateTime? maxHeartRateRideDate,
    bool maxHeartRateRideDateSetToNull = false,
    int? thresholdHeartRate,
    bool thresholdHeartRateSetToNull = false,
    String? thresholdHeartRateSource,
    bool thresholdHeartRateSourceSetToNull = false,
    DateTime? thresholdHeartRateSetAt,
    bool thresholdHeartRateSetAtSetToNull = false,
    String? thresholdHeartRateRideId,
    bool thresholdHeartRateRideIdSetToNull = false,
    DateTime? thresholdHeartRateRideDate,
    bool thresholdHeartRateRideDateSetToNull = false,
    List<EfficiencyWeek>? efficiency,
    int? rides,
    double? distanceM,
    double? movingS,
    double? elevationGainM,
    double? fitness,
    bool fitnessSetToNull = false,
    double? fatigue,
    bool fatigueSetToNull = false,
    double? form,
    bool formSetToNull = false,
    EventResponse? nextEvent,
    bool nextEventSetToNull = false,
  }) => RiderCardResponse(
    ftpW: ftpWSetToNull ? null : ftpW ?? this.ftpW,
    weightKg: weightKgSetToNull ? null : weightKg ?? this.weightKg,
    wattsPerKg: wattsPerKgSetToNull ? null : wattsPerKg ?? this.wattsPerKg,
    ftpSource: ftpSourceSetToNull ? null : ftpSource ?? this.ftpSource,
    ftpSetAt: ftpSetAtSetToNull ? null : ftpSetAt ?? this.ftpSetAt,
    ftpRideId: ftpRideIdSetToNull ? null : ftpRideId ?? this.ftpRideId,
    ftpRideDate: ftpRideDateSetToNull ? null : ftpRideDate ?? this.ftpRideDate,
    criticalPowerW: criticalPowerWSetToNull ? null : criticalPowerW ?? this.criticalPowerW,
    wPrimeJ: wPrimeJSetToNull ? null : wPrimeJ ?? this.wPrimeJ,
    peakPowerW: peakPowerWSetToNull ? null : peakPowerW ?? this.peakPowerW,
    bests: bests ?? this.bests,
    maxHeartRate: maxHeartRateSetToNull ? null : maxHeartRate ?? this.maxHeartRate,
    maxHeartRateSource: maxHeartRateSourceSetToNull ? null : maxHeartRateSource ?? this.maxHeartRateSource,
    maxHeartRateSetAt: maxHeartRateSetAtSetToNull ? null : maxHeartRateSetAt ?? this.maxHeartRateSetAt,
    maxHeartRateRideId: maxHeartRateRideIdSetToNull ? null : maxHeartRateRideId ?? this.maxHeartRateRideId,
    maxHeartRateRideDate: maxHeartRateRideDateSetToNull ? null : maxHeartRateRideDate ?? this.maxHeartRateRideDate,
    thresholdHeartRate: thresholdHeartRateSetToNull ? null : thresholdHeartRate ?? this.thresholdHeartRate,
    thresholdHeartRateSource: thresholdHeartRateSourceSetToNull ? null : thresholdHeartRateSource ?? this.thresholdHeartRateSource,
    thresholdHeartRateSetAt: thresholdHeartRateSetAtSetToNull ? null : thresholdHeartRateSetAt ?? this.thresholdHeartRateSetAt,
    thresholdHeartRateRideId: thresholdHeartRateRideIdSetToNull ? null : thresholdHeartRateRideId ?? this.thresholdHeartRateRideId,
    thresholdHeartRateRideDate: thresholdHeartRateRideDateSetToNull ? null : thresholdHeartRateRideDate ?? this.thresholdHeartRateRideDate,
    efficiency: efficiency ?? this.efficiency,
    rides: rides ?? this.rides,
    distanceM: distanceM ?? this.distanceM,
    movingS: movingS ?? this.movingS,
    elevationGainM: elevationGainM ?? this.elevationGainM,
    fitness: fitnessSetToNull ? null : fitness ?? this.fitness,
    fatigue: fatigueSetToNull ? null : fatigue ?? this.fatigue,
    form: formSetToNull ? null : form ?? this.form,
    nextEvent: nextEventSetToNull ? null : nextEvent ?? this.nextEvent,
  );

  /// Returns a new [RiderCardResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RiderCardResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'ftpW'), 'Required key "RiderCardResponse[ftpW]" is missing from JSON.');
        assert(json.containsKey(r'weightKg'), 'Required key "RiderCardResponse[weightKg]" is missing from JSON.');
        assert(json.containsKey(r'wattsPerKg'), 'Required key "RiderCardResponse[wattsPerKg]" is missing from JSON.');
        assert(json.containsKey(r'ftpSource'), 'Required key "RiderCardResponse[ftpSource]" is missing from JSON.');
        assert(json.containsKey(r'ftpSetAt'), 'Required key "RiderCardResponse[ftpSetAt]" is missing from JSON.');
        assert(json.containsKey(r'ftpRideId'), 'Required key "RiderCardResponse[ftpRideId]" is missing from JSON.');
        assert(json.containsKey(r'ftpRideDate'), 'Required key "RiderCardResponse[ftpRideDate]" is missing from JSON.');
        assert(json.containsKey(r'criticalPowerW'), 'Required key "RiderCardResponse[criticalPowerW]" is missing from JSON.');
        assert(json.containsKey(r'wPrimeJ'), 'Required key "RiderCardResponse[wPrimeJ]" is missing from JSON.');
        assert(json.containsKey(r'peakPowerW'), 'Required key "RiderCardResponse[peakPowerW]" is missing from JSON.');
        assert(json.containsKey(r'bests'), 'Required key "RiderCardResponse[bests]" is missing from JSON.');
        assert(json[r'bests'] != null, 'Required key "RiderCardResponse[bests]" has a null value in JSON.');
        assert(json.containsKey(r'maxHeartRate'), 'Required key "RiderCardResponse[maxHeartRate]" is missing from JSON.');
        assert(json.containsKey(r'maxHeartRateSource'), 'Required key "RiderCardResponse[maxHeartRateSource]" is missing from JSON.');
        assert(json.containsKey(r'maxHeartRateSetAt'), 'Required key "RiderCardResponse[maxHeartRateSetAt]" is missing from JSON.');
        assert(json.containsKey(r'maxHeartRateRideId'), 'Required key "RiderCardResponse[maxHeartRateRideId]" is missing from JSON.');
        assert(json.containsKey(r'maxHeartRateRideDate'), 'Required key "RiderCardResponse[maxHeartRateRideDate]" is missing from JSON.');
        assert(json.containsKey(r'thresholdHeartRate'), 'Required key "RiderCardResponse[thresholdHeartRate]" is missing from JSON.');
        assert(json.containsKey(r'thresholdHeartRateSource'), 'Required key "RiderCardResponse[thresholdHeartRateSource]" is missing from JSON.');
        assert(json.containsKey(r'thresholdHeartRateSetAt'), 'Required key "RiderCardResponse[thresholdHeartRateSetAt]" is missing from JSON.');
        assert(json.containsKey(r'thresholdHeartRateRideId'), 'Required key "RiderCardResponse[thresholdHeartRateRideId]" is missing from JSON.');
        assert(json.containsKey(r'thresholdHeartRateRideDate'), 'Required key "RiderCardResponse[thresholdHeartRateRideDate]" is missing from JSON.');
        assert(json.containsKey(r'efficiency'), 'Required key "RiderCardResponse[efficiency]" is missing from JSON.');
        assert(json[r'efficiency'] != null, 'Required key "RiderCardResponse[efficiency]" has a null value in JSON.');
        assert(json.containsKey(r'rides'), 'Required key "RiderCardResponse[rides]" is missing from JSON.');
        assert(json[r'rides'] != null, 'Required key "RiderCardResponse[rides]" has a null value in JSON.');
        assert(json.containsKey(r'distanceM'), 'Required key "RiderCardResponse[distanceM]" is missing from JSON.');
        assert(json[r'distanceM'] != null, 'Required key "RiderCardResponse[distanceM]" has a null value in JSON.');
        assert(json.containsKey(r'movingS'), 'Required key "RiderCardResponse[movingS]" is missing from JSON.');
        assert(json[r'movingS'] != null, 'Required key "RiderCardResponse[movingS]" has a null value in JSON.');
        assert(json.containsKey(r'elevationGainM'), 'Required key "RiderCardResponse[elevationGainM]" is missing from JSON.');
        assert(json[r'elevationGainM'] != null, 'Required key "RiderCardResponse[elevationGainM]" has a null value in JSON.');
        assert(json.containsKey(r'fitness'), 'Required key "RiderCardResponse[fitness]" is missing from JSON.');
        assert(json.containsKey(r'fatigue'), 'Required key "RiderCardResponse[fatigue]" is missing from JSON.');
        assert(json.containsKey(r'form'), 'Required key "RiderCardResponse[form]" is missing from JSON.');
        assert(json.containsKey(r'nextEvent'), 'Required key "RiderCardResponse[nextEvent]" is missing from JSON.');
        return true;
      }());

      return RiderCardResponse(
        ftpW: mapValueOfType<int>(json, r'ftpW'),
        weightKg: mapValueOfType<double>(json, r'weightKg'),
        wattsPerKg: mapValueOfType<double>(json, r'wattsPerKg'),
        ftpSource: mapValueOfType<String>(json, r'ftpSource'),
        ftpSetAt: mapDateTime(json, r'ftpSetAt', r''),
        ftpRideId: mapValueOfType<String>(json, r'ftpRideId'),
        ftpRideDate: mapDateTime(json, r'ftpRideDate', r''),
        criticalPowerW: mapValueOfType<int>(json, r'criticalPowerW'),
        wPrimeJ: mapValueOfType<int>(json, r'wPrimeJ'),
        peakPowerW: mapValueOfType<int>(json, r'peakPowerW'),
        bests: RiderCardBest.listFromJson(json[r'bests']),
        maxHeartRate: mapValueOfType<int>(json, r'maxHeartRate'),
        maxHeartRateSource: mapValueOfType<String>(json, r'maxHeartRateSource'),
        maxHeartRateSetAt: mapDateTime(json, r'maxHeartRateSetAt', r''),
        maxHeartRateRideId: mapValueOfType<String>(json, r'maxHeartRateRideId'),
        maxHeartRateRideDate: mapDateTime(json, r'maxHeartRateRideDate', r''),
        thresholdHeartRate: mapValueOfType<int>(json, r'thresholdHeartRate'),
        thresholdHeartRateSource: mapValueOfType<String>(json, r'thresholdHeartRateSource'),
        thresholdHeartRateSetAt: mapDateTime(json, r'thresholdHeartRateSetAt', r''),
        thresholdHeartRateRideId: mapValueOfType<String>(json, r'thresholdHeartRateRideId'),
        thresholdHeartRateRideDate: mapDateTime(json, r'thresholdHeartRateRideDate', r''),
        efficiency: EfficiencyWeek.listFromJson(json[r'efficiency']),
        rides: mapValueOfType<int>(json, r'rides')!,
        distanceM: mapValueOfType<double>(json, r'distanceM')!,
        movingS: mapValueOfType<double>(json, r'movingS')!,
        elevationGainM: mapValueOfType<double>(json, r'elevationGainM')!,
        fitness: mapValueOfType<double>(json, r'fitness'),
        fatigue: mapValueOfType<double>(json, r'fatigue'),
        form: mapValueOfType<double>(json, r'form'),
        nextEvent: EventResponse.fromJson(json[r'nextEvent']),
      );
    }
    return null;
  }

  static List<RiderCardResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RiderCardResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RiderCardResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RiderCardResponse> mapFromJson(dynamic json) {
    final map = <String, RiderCardResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RiderCardResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RiderCardResponse-objects as value to a dart map
  static Map<String, List<RiderCardResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RiderCardResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RiderCardResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'ftpW',
    'weightKg',
    'wattsPerKg',
    'ftpSource',
    'ftpSetAt',
    'ftpRideId',
    'ftpRideDate',
    'criticalPowerW',
    'wPrimeJ',
    'peakPowerW',
    'bests',
    'maxHeartRate',
    'maxHeartRateSource',
    'maxHeartRateSetAt',
    'maxHeartRateRideId',
    'maxHeartRateRideDate',
    'thresholdHeartRate',
    'thresholdHeartRateSource',
    'thresholdHeartRateSetAt',
    'thresholdHeartRateRideId',
    'thresholdHeartRateRideDate',
    'efficiency',
    'rides',
    'distanceM',
    'movingS',
    'elevationGainM',
    'fitness',
    'fatigue',
    'form',
    'nextEvent',
  };
}

