//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class TrainingResponse {
  /// Returns a new [TrainingResponse] instance.
  TrainingResponse({
    required this.dayCount,
    required this.from,
    required this.to,
    required this.rides,
    required this.distanceM,
    required this.movingS,
    required this.elevationGainM,
    required this.tss,
    required this.trimp,
    this.days = const [],
    required this.intensity,
    this.intensityWeeks = const [],
    this.efficiency = const [],
    this.heartRateLoadRides = const Optional.present(0),
    this.monotony = const Optional.absent(),
    this.strain = const Optional.absent(),
    this.strainUsual = const Optional.absent(),
    this.monotonous = const Optional.present(false),
    this.heavyWeek = const Optional.present(false),
    this.monotonyFrom = const Optional.absent(),
    this.monotonyTo = const Optional.absent(),
  });

  final int dayCount;

  final DateTime from;

  final DateTime to;

  final int rides;

  final double distanceM;

  final double movingS;

  final double elevationGainM;

  final double tss;

  final double trimp;

  final List<TrainingDay> days;

  final IntensityResponse? intensity;

  final List<IntensityWeek> intensityWeeks;

  final List<EfficiencyWeek> efficiency;

  final Optional<int?> heartRateLoadRides;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<double?> monotony;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<double?> strain;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<double?> strainUsual;

  final Optional<bool?> monotonous;

  final Optional<bool?> heavyWeek;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<DateTime?> monotonyFrom;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<DateTime?> monotonyTo;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TrainingResponse &&
    other.dayCount == dayCount &&
    other.from == from &&
    other.to == to &&
    other.rides == rides &&
    other.distanceM == distanceM &&
    other.movingS == movingS &&
    other.elevationGainM == elevationGainM &&
    other.tss == tss &&
    other.trimp == trimp &&
    _deepEquality.equals(other.days, days) &&
    other.intensity == intensity &&
    _deepEquality.equals(other.intensityWeeks, intensityWeeks) &&
    _deepEquality.equals(other.efficiency, efficiency) &&
    other.heartRateLoadRides == heartRateLoadRides &&
    other.monotony == monotony &&
    other.strain == strain &&
    other.strainUsual == strainUsual &&
    other.monotonous == monotonous &&
    other.heavyWeek == heavyWeek &&
    other.monotonyFrom == monotonyFrom &&
    other.monotonyTo == monotonyTo;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (dayCount.hashCode) +
    (from.hashCode) +
    (to.hashCode) +
    (rides.hashCode) +
    (distanceM.hashCode) +
    (movingS.hashCode) +
    (elevationGainM.hashCode) +
    (tss.hashCode) +
    (trimp.hashCode) +
    (days.hashCode) +
    (intensity == null ? 0 : intensity!.hashCode) +
    (intensityWeeks.hashCode) +
    (efficiency.hashCode) +
    (heartRateLoadRides.hashCode) +
    (monotony == null ? 0 : monotony!.hashCode) +
    (strain == null ? 0 : strain!.hashCode) +
    (strainUsual == null ? 0 : strainUsual!.hashCode) +
    (monotonous.hashCode) +
    (heavyWeek.hashCode) +
    (monotonyFrom == null ? 0 : monotonyFrom!.hashCode) +
    (monotonyTo == null ? 0 : monotonyTo!.hashCode);

  @override
  String toString() => 'TrainingResponse[dayCount=$dayCount, from=$from, to=$to, rides=$rides, distanceM=$distanceM, movingS=$movingS, elevationGainM=$elevationGainM, tss=$tss, trimp=$trimp, days=$days, intensity=$intensity, intensityWeeks=$intensityWeeks, efficiency=$efficiency, heartRateLoadRides=$heartRateLoadRides, monotony=$monotony, strain=$strain, strainUsual=$strainUsual, monotonous=$monotonous, heavyWeek=$heavyWeek, monotonyFrom=$monotonyFrom, monotonyTo=$monotonyTo]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'dayCount'] = this.dayCount;
      json[r'from'] = _dateFormatter.format(this.from);
      json[r'to'] = _dateFormatter.format(this.to);
      json[r'rides'] = this.rides;
      json[r'distanceM'] = this.distanceM;
      json[r'movingS'] = this.movingS;
      json[r'elevationGainM'] = this.elevationGainM;
      json[r'tss'] = this.tss;
      json[r'trimp'] = this.trimp;
      json[r'days'] = this.days;
    if (this.intensity != null) {
      json[r'intensity'] = this.intensity;
    } else {
      json[r'intensity'] = null;
    }
      json[r'intensityWeeks'] = this.intensityWeeks;
      json[r'efficiency'] = this.efficiency;
    if (this.heartRateLoadRides.isPresent) {
      final value = this.heartRateLoadRides.value;
      json[r'heartRateLoadRides'] = value;
    }
    if (this.monotony.isPresent) {
      final value = this.monotony.value;
      json[r'monotony'] = value;
    }
    if (this.strain.isPresent) {
      final value = this.strain.value;
      json[r'strain'] = value;
    }
    if (this.strainUsual.isPresent) {
      final value = this.strainUsual.value;
      json[r'strainUsual'] = value;
    }
    if (this.monotonous.isPresent) {
      final value = this.monotonous.value;
      json[r'monotonous'] = value;
    }
    if (this.heavyWeek.isPresent) {
      final value = this.heavyWeek.value;
      json[r'heavyWeek'] = value;
    }
    if (this.monotonyFrom.isPresent) {
      final value = this.monotonyFrom.value;
      json[r'monotonyFrom'] = value == null ? null : _dateFormatter.format(value);
    }
    if (this.monotonyTo.isPresent) {
      final value = this.monotonyTo.value;
      json[r'monotonyTo'] = value == null ? null : _dateFormatter.format(value);
    }
    return json;
  }

  /// Clones this instance of [TrainingResponse] and returns a new one where some of the
  /// properties have changed.
  TrainingResponse copyWith({
    int? dayCount,
    DateTime? from,
    DateTime? to,
    int? rides,
    double? distanceM,
    double? movingS,
    double? elevationGainM,
    double? tss,
    double? trimp,
    List<TrainingDay>? days,
    IntensityResponse? intensity,
    bool intensitySetToNull = false,
    List<IntensityWeek>? intensityWeeks,
    List<EfficiencyWeek>? efficiency,
    Optional<int?>? heartRateLoadRides,
    Optional<double?>? monotony,
    Optional<double?>? strain,
    Optional<double?>? strainUsual,
    Optional<bool?>? monotonous,
    Optional<bool?>? heavyWeek,
    Optional<DateTime?>? monotonyFrom,
    Optional<DateTime?>? monotonyTo,
  }) => TrainingResponse(
    dayCount: dayCount ?? this.dayCount,
    from: from ?? this.from,
    to: to ?? this.to,
    rides: rides ?? this.rides,
    distanceM: distanceM ?? this.distanceM,
    movingS: movingS ?? this.movingS,
    elevationGainM: elevationGainM ?? this.elevationGainM,
    tss: tss ?? this.tss,
    trimp: trimp ?? this.trimp,
    days: days ?? this.days,
    intensity: intensitySetToNull ? null : intensity ?? this.intensity,
    intensityWeeks: intensityWeeks ?? this.intensityWeeks,
    efficiency: efficiency ?? this.efficiency,
    heartRateLoadRides: heartRateLoadRides ?? this.heartRateLoadRides,
    monotony: monotony ?? this.monotony,
    strain: strain ?? this.strain,
    strainUsual: strainUsual ?? this.strainUsual,
    monotonous: monotonous ?? this.monotonous,
    heavyWeek: heavyWeek ?? this.heavyWeek,
    monotonyFrom: monotonyFrom ?? this.monotonyFrom,
    monotonyTo: monotonyTo ?? this.monotonyTo,
  );

  /// Returns a new [TrainingResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TrainingResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'dayCount'), 'Required key "TrainingResponse[dayCount]" is missing from JSON.');
        assert(json[r'dayCount'] != null, 'Required key "TrainingResponse[dayCount]" has a null value in JSON.');
        assert(json.containsKey(r'from'), 'Required key "TrainingResponse[from]" is missing from JSON.');
        assert(json[r'from'] != null, 'Required key "TrainingResponse[from]" has a null value in JSON.');
        assert(json.containsKey(r'to'), 'Required key "TrainingResponse[to]" is missing from JSON.');
        assert(json[r'to'] != null, 'Required key "TrainingResponse[to]" has a null value in JSON.');
        assert(json.containsKey(r'rides'), 'Required key "TrainingResponse[rides]" is missing from JSON.');
        assert(json[r'rides'] != null, 'Required key "TrainingResponse[rides]" has a null value in JSON.');
        assert(json.containsKey(r'distanceM'), 'Required key "TrainingResponse[distanceM]" is missing from JSON.');
        assert(json[r'distanceM'] != null, 'Required key "TrainingResponse[distanceM]" has a null value in JSON.');
        assert(json.containsKey(r'movingS'), 'Required key "TrainingResponse[movingS]" is missing from JSON.');
        assert(json[r'movingS'] != null, 'Required key "TrainingResponse[movingS]" has a null value in JSON.');
        assert(json.containsKey(r'elevationGainM'), 'Required key "TrainingResponse[elevationGainM]" is missing from JSON.');
        assert(json[r'elevationGainM'] != null, 'Required key "TrainingResponse[elevationGainM]" has a null value in JSON.');
        assert(json.containsKey(r'tss'), 'Required key "TrainingResponse[tss]" is missing from JSON.');
        assert(json[r'tss'] != null, 'Required key "TrainingResponse[tss]" has a null value in JSON.');
        assert(json.containsKey(r'trimp'), 'Required key "TrainingResponse[trimp]" is missing from JSON.');
        assert(json[r'trimp'] != null, 'Required key "TrainingResponse[trimp]" has a null value in JSON.');
        assert(json.containsKey(r'days'), 'Required key "TrainingResponse[days]" is missing from JSON.');
        assert(json[r'days'] != null, 'Required key "TrainingResponse[days]" has a null value in JSON.');
        assert(json.containsKey(r'intensity'), 'Required key "TrainingResponse[intensity]" is missing from JSON.');
        assert(json.containsKey(r'intensityWeeks'), 'Required key "TrainingResponse[intensityWeeks]" is missing from JSON.');
        assert(json[r'intensityWeeks'] != null, 'Required key "TrainingResponse[intensityWeeks]" has a null value in JSON.');
        assert(json.containsKey(r'efficiency'), 'Required key "TrainingResponse[efficiency]" is missing from JSON.');
        assert(json[r'efficiency'] != null, 'Required key "TrainingResponse[efficiency]" has a null value in JSON.');
        return true;
      }());

      return TrainingResponse(
        dayCount: mapValueOfType<int>(json, r'dayCount')!,
        from: mapDateTime(json, r'from', r'')!,
        to: mapDateTime(json, r'to', r'')!,
        rides: mapValueOfType<int>(json, r'rides')!,
        distanceM: mapValueOfType<double>(json, r'distanceM')!,
        movingS: mapValueOfType<double>(json, r'movingS')!,
        elevationGainM: mapValueOfType<double>(json, r'elevationGainM')!,
        tss: mapValueOfType<double>(json, r'tss')!,
        trimp: mapValueOfType<double>(json, r'trimp')!,
        days: TrainingDay.listFromJson(json[r'days']),
        intensity: IntensityResponse.fromJson(json[r'intensity']),
        intensityWeeks: IntensityWeek.listFromJson(json[r'intensityWeeks']),
        efficiency: EfficiencyWeek.listFromJson(json[r'efficiency']),
        heartRateLoadRides: json.containsKey(r'heartRateLoadRides') ? Optional.present(json[r'heartRateLoadRides'] == null ? null : int.parse('${json[r'heartRateLoadRides']}')) : const Optional.absent(),
        monotony: json.containsKey(r'monotony') ? Optional.present(mapValueOfType<double>(json, r'monotony')) : const Optional.absent(),
        strain: json.containsKey(r'strain') ? Optional.present(mapValueOfType<double>(json, r'strain')) : const Optional.absent(),
        strainUsual: json.containsKey(r'strainUsual') ? Optional.present(mapValueOfType<double>(json, r'strainUsual')) : const Optional.absent(),
        monotonous: json.containsKey(r'monotonous') ? Optional.present(mapValueOfType<bool>(json, r'monotonous')) : const Optional.absent(),
        heavyWeek: json.containsKey(r'heavyWeek') ? Optional.present(mapValueOfType<bool>(json, r'heavyWeek')) : const Optional.absent(),
        monotonyFrom: json.containsKey(r'monotonyFrom') ? Optional.present(mapDateTime(json, r'monotonyFrom', r'')) : const Optional.absent(),
        monotonyTo: json.containsKey(r'monotonyTo') ? Optional.present(mapDateTime(json, r'monotonyTo', r'')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<TrainingResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TrainingResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TrainingResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TrainingResponse> mapFromJson(dynamic json) {
    final map = <String, TrainingResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TrainingResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TrainingResponse-objects as value to a dart map
  static Map<String, List<TrainingResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TrainingResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TrainingResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'dayCount',
    'from',
    'to',
    'rides',
    'distanceM',
    'movingS',
    'elevationGainM',
    'tss',
    'trimp',
    'days',
    'intensity',
    'intensityWeeks',
    'efficiency',
  };
}

