//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class TrainingDay {
  /// Returns a new [TrainingDay] instance.
  TrainingDay({
    required this.date,
    required this.rides,
    required this.distanceM,
    required this.movingS,
    required this.elevationGainM,
    required this.tss,
    required this.trimp,
    required this.fitness,
    required this.fatigue,
    required this.form,
  });

  final DateTime date;

  final int rides;

  final double distanceM;

  final double movingS;

  final double elevationGainM;

  final double tss;

  final double trimp;

  final double fitness;

  final double fatigue;

  final double form;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TrainingDay &&
    other.date == date &&
    other.rides == rides &&
    other.distanceM == distanceM &&
    other.movingS == movingS &&
    other.elevationGainM == elevationGainM &&
    other.tss == tss &&
    other.trimp == trimp &&
    other.fitness == fitness &&
    other.fatigue == fatigue &&
    other.form == form;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (date.hashCode) +
    (rides.hashCode) +
    (distanceM.hashCode) +
    (movingS.hashCode) +
    (elevationGainM.hashCode) +
    (tss.hashCode) +
    (trimp.hashCode) +
    (fitness.hashCode) +
    (fatigue.hashCode) +
    (form.hashCode);

  @override
  String toString() => 'TrainingDay[date=$date, rides=$rides, distanceM=$distanceM, movingS=$movingS, elevationGainM=$elevationGainM, tss=$tss, trimp=$trimp, fitness=$fitness, fatigue=$fatigue, form=$form]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'date'] = _dateFormatter.format(this.date);
      json[r'rides'] = this.rides;
      json[r'distanceM'] = this.distanceM;
      json[r'movingS'] = this.movingS;
      json[r'elevationGainM'] = this.elevationGainM;
      json[r'tss'] = this.tss;
      json[r'trimp'] = this.trimp;
      json[r'fitness'] = this.fitness;
      json[r'fatigue'] = this.fatigue;
      json[r'form'] = this.form;
    return json;
  }

  /// Clones this instance of [TrainingDay] and returns a new one where some of the
  /// properties have changed.
  TrainingDay copyWith({
    DateTime? date,
    int? rides,
    double? distanceM,
    double? movingS,
    double? elevationGainM,
    double? tss,
    double? trimp,
    double? fitness,
    double? fatigue,
    double? form,
  }) => TrainingDay(
    date: date ?? this.date,
    rides: rides ?? this.rides,
    distanceM: distanceM ?? this.distanceM,
    movingS: movingS ?? this.movingS,
    elevationGainM: elevationGainM ?? this.elevationGainM,
    tss: tss ?? this.tss,
    trimp: trimp ?? this.trimp,
    fitness: fitness ?? this.fitness,
    fatigue: fatigue ?? this.fatigue,
    form: form ?? this.form,
  );

  /// Returns a new [TrainingDay] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TrainingDay? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'date'), 'Required key "TrainingDay[date]" is missing from JSON.');
        assert(json[r'date'] != null, 'Required key "TrainingDay[date]" has a null value in JSON.');
        assert(json.containsKey(r'rides'), 'Required key "TrainingDay[rides]" is missing from JSON.');
        assert(json[r'rides'] != null, 'Required key "TrainingDay[rides]" has a null value in JSON.');
        assert(json.containsKey(r'distanceM'), 'Required key "TrainingDay[distanceM]" is missing from JSON.');
        assert(json[r'distanceM'] != null, 'Required key "TrainingDay[distanceM]" has a null value in JSON.');
        assert(json.containsKey(r'movingS'), 'Required key "TrainingDay[movingS]" is missing from JSON.');
        assert(json[r'movingS'] != null, 'Required key "TrainingDay[movingS]" has a null value in JSON.');
        assert(json.containsKey(r'elevationGainM'), 'Required key "TrainingDay[elevationGainM]" is missing from JSON.');
        assert(json[r'elevationGainM'] != null, 'Required key "TrainingDay[elevationGainM]" has a null value in JSON.');
        assert(json.containsKey(r'tss'), 'Required key "TrainingDay[tss]" is missing from JSON.');
        assert(json[r'tss'] != null, 'Required key "TrainingDay[tss]" has a null value in JSON.');
        assert(json.containsKey(r'trimp'), 'Required key "TrainingDay[trimp]" is missing from JSON.');
        assert(json[r'trimp'] != null, 'Required key "TrainingDay[trimp]" has a null value in JSON.');
        assert(json.containsKey(r'fitness'), 'Required key "TrainingDay[fitness]" is missing from JSON.');
        assert(json[r'fitness'] != null, 'Required key "TrainingDay[fitness]" has a null value in JSON.');
        assert(json.containsKey(r'fatigue'), 'Required key "TrainingDay[fatigue]" is missing from JSON.');
        assert(json[r'fatigue'] != null, 'Required key "TrainingDay[fatigue]" has a null value in JSON.');
        assert(json.containsKey(r'form'), 'Required key "TrainingDay[form]" is missing from JSON.');
        assert(json[r'form'] != null, 'Required key "TrainingDay[form]" has a null value in JSON.');
        return true;
      }());

      return TrainingDay(
        date: mapDateTime(json, r'date', r'')!,
        rides: mapValueOfType<int>(json, r'rides')!,
        distanceM: mapValueOfType<double>(json, r'distanceM')!,
        movingS: mapValueOfType<double>(json, r'movingS')!,
        elevationGainM: mapValueOfType<double>(json, r'elevationGainM')!,
        tss: mapValueOfType<double>(json, r'tss')!,
        trimp: mapValueOfType<double>(json, r'trimp')!,
        fitness: mapValueOfType<double>(json, r'fitness')!,
        fatigue: mapValueOfType<double>(json, r'fatigue')!,
        form: mapValueOfType<double>(json, r'form')!,
      );
    }
    return null;
  }

  static List<TrainingDay> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TrainingDay>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TrainingDay.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TrainingDay> mapFromJson(dynamic json) {
    final map = <String, TrainingDay>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TrainingDay.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TrainingDay-objects as value to a dart map
  static Map<String, List<TrainingDay>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TrainingDay>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TrainingDay.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'date',
    'rides',
    'distanceM',
    'movingS',
    'elevationGainM',
    'tss',
    'trimp',
    'fitness',
    'fatigue',
    'form',
  };
}

