//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class PowerCurveResponse {
  /// Returns a new [PowerCurveResponse] instance.
  PowerCurveResponse({
    required this.dayCount,
    required this.from,
    required this.to,
    required this.rides,
    required this.hasPower,
    required this.currentFtpW,
    required this.weightKg,
    this.points = const [],
    required this.ftp,
    required this.vo2Max,
  });

  final int dayCount;

  final DateTime from;

  final DateTime to;

  final int rides;

  final bool hasPower;

  final int? currentFtpW;

  final double? weightKg;

  final List<PowerCurvePoint> points;

  final FtpEstimate? ftp;

  final Vo2MaxEstimate? vo2Max;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PowerCurveResponse &&
    other.dayCount == dayCount &&
    other.from == from &&
    other.to == to &&
    other.rides == rides &&
    other.hasPower == hasPower &&
    other.currentFtpW == currentFtpW &&
    other.weightKg == weightKg &&
    _deepEquality.equals(other.points, points) &&
    other.ftp == ftp &&
    other.vo2Max == vo2Max;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (dayCount.hashCode) +
    (from.hashCode) +
    (to.hashCode) +
    (rides.hashCode) +
    (hasPower.hashCode) +
    (currentFtpW == null ? 0 : currentFtpW!.hashCode) +
    (weightKg == null ? 0 : weightKg!.hashCode) +
    (points.hashCode) +
    (ftp == null ? 0 : ftp!.hashCode) +
    (vo2Max == null ? 0 : vo2Max!.hashCode);

  @override
  String toString() => 'PowerCurveResponse[dayCount=$dayCount, from=$from, to=$to, rides=$rides, hasPower=$hasPower, currentFtpW=$currentFtpW, weightKg=$weightKg, points=$points, ftp=$ftp, vo2Max=$vo2Max]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'dayCount'] = this.dayCount;
      json[r'from'] = _dateFormatter.format(this.from);
      json[r'to'] = _dateFormatter.format(this.to);
      json[r'rides'] = this.rides;
      json[r'hasPower'] = this.hasPower;
    if (this.currentFtpW != null) {
      json[r'currentFtpW'] = this.currentFtpW;
    } else {
      json[r'currentFtpW'] = null;
    }
    if (this.weightKg != null) {
      json[r'weightKg'] = this.weightKg;
    } else {
      json[r'weightKg'] = null;
    }
      json[r'points'] = this.points;
    if (this.ftp != null) {
      json[r'ftp'] = this.ftp;
    } else {
      json[r'ftp'] = null;
    }
    if (this.vo2Max != null) {
      json[r'vo2Max'] = this.vo2Max;
    } else {
      json[r'vo2Max'] = null;
    }
    return json;
  }

  /// Clones this instance of [PowerCurveResponse] and returns a new one where some of the
  /// properties have changed.
  PowerCurveResponse copyWith({
    int? dayCount,
    DateTime? from,
    DateTime? to,
    int? rides,
    bool? hasPower,
    int? currentFtpW,
    bool currentFtpWSetToNull = false,
    double? weightKg,
    bool weightKgSetToNull = false,
    List<PowerCurvePoint>? points,
    FtpEstimate? ftp,
    bool ftpSetToNull = false,
    Vo2MaxEstimate? vo2Max,
    bool vo2MaxSetToNull = false,
  }) => PowerCurveResponse(
    dayCount: dayCount ?? this.dayCount,
    from: from ?? this.from,
    to: to ?? this.to,
    rides: rides ?? this.rides,
    hasPower: hasPower ?? this.hasPower,
    currentFtpW: currentFtpWSetToNull ? null : currentFtpW ?? this.currentFtpW,
    weightKg: weightKgSetToNull ? null : weightKg ?? this.weightKg,
    points: points ?? this.points,
    ftp: ftpSetToNull ? null : ftp ?? this.ftp,
    vo2Max: vo2MaxSetToNull ? null : vo2Max ?? this.vo2Max,
  );

  /// Returns a new [PowerCurveResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PowerCurveResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'dayCount'), 'Required key "PowerCurveResponse[dayCount]" is missing from JSON.');
        assert(json[r'dayCount'] != null, 'Required key "PowerCurveResponse[dayCount]" has a null value in JSON.');
        assert(json.containsKey(r'from'), 'Required key "PowerCurveResponse[from]" is missing from JSON.');
        assert(json[r'from'] != null, 'Required key "PowerCurveResponse[from]" has a null value in JSON.');
        assert(json.containsKey(r'to'), 'Required key "PowerCurveResponse[to]" is missing from JSON.');
        assert(json[r'to'] != null, 'Required key "PowerCurveResponse[to]" has a null value in JSON.');
        assert(json.containsKey(r'rides'), 'Required key "PowerCurveResponse[rides]" is missing from JSON.');
        assert(json[r'rides'] != null, 'Required key "PowerCurveResponse[rides]" has a null value in JSON.');
        assert(json.containsKey(r'hasPower'), 'Required key "PowerCurveResponse[hasPower]" is missing from JSON.');
        assert(json[r'hasPower'] != null, 'Required key "PowerCurveResponse[hasPower]" has a null value in JSON.');
        assert(json.containsKey(r'currentFtpW'), 'Required key "PowerCurveResponse[currentFtpW]" is missing from JSON.');
        assert(json.containsKey(r'weightKg'), 'Required key "PowerCurveResponse[weightKg]" is missing from JSON.');
        assert(json.containsKey(r'points'), 'Required key "PowerCurveResponse[points]" is missing from JSON.');
        assert(json[r'points'] != null, 'Required key "PowerCurveResponse[points]" has a null value in JSON.');
        assert(json.containsKey(r'ftp'), 'Required key "PowerCurveResponse[ftp]" is missing from JSON.');
        assert(json.containsKey(r'vo2Max'), 'Required key "PowerCurveResponse[vo2Max]" is missing from JSON.');
        return true;
      }());

      return PowerCurveResponse(
        dayCount: mapValueOfType<int>(json, r'dayCount')!,
        from: mapDateTime(json, r'from', r'')!,
        to: mapDateTime(json, r'to', r'')!,
        rides: mapValueOfType<int>(json, r'rides')!,
        hasPower: mapValueOfType<bool>(json, r'hasPower')!,
        currentFtpW: mapValueOfType<int>(json, r'currentFtpW'),
        weightKg: mapValueOfType<double>(json, r'weightKg'),
        points: PowerCurvePoint.listFromJson(json[r'points']),
        ftp: FtpEstimate.fromJson(json[r'ftp']),
        vo2Max: Vo2MaxEstimate.fromJson(json[r'vo2Max']),
      );
    }
    return null;
  }

  static List<PowerCurveResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PowerCurveResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PowerCurveResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PowerCurveResponse> mapFromJson(dynamic json) {
    final map = <String, PowerCurveResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PowerCurveResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PowerCurveResponse-objects as value to a dart map
  static Map<String, List<PowerCurveResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PowerCurveResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PowerCurveResponse.listFromJson(entry.value, growable: growable,);
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
    'hasPower',
    'currentFtpW',
    'weightKg',
    'points',
    'ftp',
    'vo2Max',
  };
}

