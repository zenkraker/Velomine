//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class BikeResponse {
  /// Returns a new [BikeResponse] instance.
  BikeResponse({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.modelYear,
    required this.buildSpec,
    required this.frameSize,
    required this.kind,
    required this.wheelCircumferenceMm,
    required this.initialDistanceM,
    required this.purchasedOn,
    required this.isDefault,
    required this.isActive,
    required this.rideCount,
    required this.distanceM,
    required this.movingS,
  });

  final String id;

  final String name;

  final String? brand;

  final String? model;

  final int? modelYear;

  final String? buildSpec;

  final String? frameSize;

  final String kind;

  final int wheelCircumferenceMm;

  final double initialDistanceM;

  final DateTime? purchasedOn;

  final bool isDefault;

  final bool isActive;

  final int rideCount;

  final double distanceM;

  final double movingS;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BikeResponse &&
    other.id == id &&
    other.name == name &&
    other.brand == brand &&
    other.model == model &&
    other.modelYear == modelYear &&
    other.buildSpec == buildSpec &&
    other.frameSize == frameSize &&
    other.kind == kind &&
    other.wheelCircumferenceMm == wheelCircumferenceMm &&
    other.initialDistanceM == initialDistanceM &&
    other.purchasedOn == purchasedOn &&
    other.isDefault == isDefault &&
    other.isActive == isActive &&
    other.rideCount == rideCount &&
    other.distanceM == distanceM &&
    other.movingS == movingS;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (brand == null ? 0 : brand!.hashCode) +
    (model == null ? 0 : model!.hashCode) +
    (modelYear == null ? 0 : modelYear!.hashCode) +
    (buildSpec == null ? 0 : buildSpec!.hashCode) +
    (frameSize == null ? 0 : frameSize!.hashCode) +
    (kind.hashCode) +
    (wheelCircumferenceMm.hashCode) +
    (initialDistanceM.hashCode) +
    (purchasedOn == null ? 0 : purchasedOn!.hashCode) +
    (isDefault.hashCode) +
    (isActive.hashCode) +
    (rideCount.hashCode) +
    (distanceM.hashCode) +
    (movingS.hashCode);

  @override
  String toString() => 'BikeResponse[id=$id, name=$name, brand=$brand, model=$model, modelYear=$modelYear, buildSpec=$buildSpec, frameSize=$frameSize, kind=$kind, wheelCircumferenceMm=$wheelCircumferenceMm, initialDistanceM=$initialDistanceM, purchasedOn=$purchasedOn, isDefault=$isDefault, isActive=$isActive, rideCount=$rideCount, distanceM=$distanceM, movingS=$movingS]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
    if (this.brand != null) {
      json[r'brand'] = this.brand;
    } else {
      json[r'brand'] = null;
    }
    if (this.model != null) {
      json[r'model'] = this.model;
    } else {
      json[r'model'] = null;
    }
    if (this.modelYear != null) {
      json[r'modelYear'] = this.modelYear;
    } else {
      json[r'modelYear'] = null;
    }
    if (this.buildSpec != null) {
      json[r'buildSpec'] = this.buildSpec;
    } else {
      json[r'buildSpec'] = null;
    }
    if (this.frameSize != null) {
      json[r'frameSize'] = this.frameSize;
    } else {
      json[r'frameSize'] = null;
    }
      json[r'kind'] = this.kind;
      json[r'wheelCircumferenceMm'] = this.wheelCircumferenceMm;
      json[r'initialDistanceM'] = this.initialDistanceM;
    if (this.purchasedOn != null) {
      json[r'purchasedOn'] = _dateFormatter.format(this.purchasedOn!);
    } else {
      json[r'purchasedOn'] = null;
    }
      json[r'isDefault'] = this.isDefault;
      json[r'isActive'] = this.isActive;
      json[r'rideCount'] = this.rideCount;
      json[r'distanceM'] = this.distanceM;
      json[r'movingS'] = this.movingS;
    return json;
  }

  /// Clones this instance of [BikeResponse] and returns a new one where some of the
  /// properties have changed.
  BikeResponse copyWith({
    String? id,
    String? name,
    String? brand,
    bool brandSetToNull = false,
    String? model,
    bool modelSetToNull = false,
    int? modelYear,
    bool modelYearSetToNull = false,
    String? buildSpec,
    bool buildSpecSetToNull = false,
    String? frameSize,
    bool frameSizeSetToNull = false,
    String? kind,
    int? wheelCircumferenceMm,
    double? initialDistanceM,
    DateTime? purchasedOn,
    bool purchasedOnSetToNull = false,
    bool? isDefault,
    bool? isActive,
    int? rideCount,
    double? distanceM,
    double? movingS,
  }) => BikeResponse(
    id: id ?? this.id,
    name: name ?? this.name,
    brand: brandSetToNull ? null : brand ?? this.brand,
    model: modelSetToNull ? null : model ?? this.model,
    modelYear: modelYearSetToNull ? null : modelYear ?? this.modelYear,
    buildSpec: buildSpecSetToNull ? null : buildSpec ?? this.buildSpec,
    frameSize: frameSizeSetToNull ? null : frameSize ?? this.frameSize,
    kind: kind ?? this.kind,
    wheelCircumferenceMm: wheelCircumferenceMm ?? this.wheelCircumferenceMm,
    initialDistanceM: initialDistanceM ?? this.initialDistanceM,
    purchasedOn: purchasedOnSetToNull ? null : purchasedOn ?? this.purchasedOn,
    isDefault: isDefault ?? this.isDefault,
    isActive: isActive ?? this.isActive,
    rideCount: rideCount ?? this.rideCount,
    distanceM: distanceM ?? this.distanceM,
    movingS: movingS ?? this.movingS,
  );

  /// Returns a new [BikeResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BikeResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "BikeResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "BikeResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "BikeResponse[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "BikeResponse[name]" has a null value in JSON.');
        assert(json.containsKey(r'brand'), 'Required key "BikeResponse[brand]" is missing from JSON.');
        assert(json.containsKey(r'model'), 'Required key "BikeResponse[model]" is missing from JSON.');
        assert(json.containsKey(r'modelYear'), 'Required key "BikeResponse[modelYear]" is missing from JSON.');
        assert(json.containsKey(r'buildSpec'), 'Required key "BikeResponse[buildSpec]" is missing from JSON.');
        assert(json.containsKey(r'frameSize'), 'Required key "BikeResponse[frameSize]" is missing from JSON.');
        assert(json.containsKey(r'kind'), 'Required key "BikeResponse[kind]" is missing from JSON.');
        assert(json[r'kind'] != null, 'Required key "BikeResponse[kind]" has a null value in JSON.');
        assert(json.containsKey(r'wheelCircumferenceMm'), 'Required key "BikeResponse[wheelCircumferenceMm]" is missing from JSON.');
        assert(json[r'wheelCircumferenceMm'] != null, 'Required key "BikeResponse[wheelCircumferenceMm]" has a null value in JSON.');
        assert(json.containsKey(r'initialDistanceM'), 'Required key "BikeResponse[initialDistanceM]" is missing from JSON.');
        assert(json[r'initialDistanceM'] != null, 'Required key "BikeResponse[initialDistanceM]" has a null value in JSON.');
        assert(json.containsKey(r'purchasedOn'), 'Required key "BikeResponse[purchasedOn]" is missing from JSON.');
        assert(json.containsKey(r'isDefault'), 'Required key "BikeResponse[isDefault]" is missing from JSON.');
        assert(json[r'isDefault'] != null, 'Required key "BikeResponse[isDefault]" has a null value in JSON.');
        assert(json.containsKey(r'isActive'), 'Required key "BikeResponse[isActive]" is missing from JSON.');
        assert(json[r'isActive'] != null, 'Required key "BikeResponse[isActive]" has a null value in JSON.');
        assert(json.containsKey(r'rideCount'), 'Required key "BikeResponse[rideCount]" is missing from JSON.');
        assert(json[r'rideCount'] != null, 'Required key "BikeResponse[rideCount]" has a null value in JSON.');
        assert(json.containsKey(r'distanceM'), 'Required key "BikeResponse[distanceM]" is missing from JSON.');
        assert(json[r'distanceM'] != null, 'Required key "BikeResponse[distanceM]" has a null value in JSON.');
        assert(json.containsKey(r'movingS'), 'Required key "BikeResponse[movingS]" is missing from JSON.');
        assert(json[r'movingS'] != null, 'Required key "BikeResponse[movingS]" has a null value in JSON.');
        return true;
      }());

      return BikeResponse(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        brand: mapValueOfType<String>(json, r'brand'),
        model: mapValueOfType<String>(json, r'model'),
        modelYear: mapValueOfType<int>(json, r'modelYear'),
        buildSpec: mapValueOfType<String>(json, r'buildSpec'),
        frameSize: mapValueOfType<String>(json, r'frameSize'),
        kind: mapValueOfType<String>(json, r'kind')!,
        wheelCircumferenceMm: mapValueOfType<int>(json, r'wheelCircumferenceMm')!,
        initialDistanceM: mapValueOfType<double>(json, r'initialDistanceM')!,
        purchasedOn: mapDateTime(json, r'purchasedOn', r''),
        isDefault: mapValueOfType<bool>(json, r'isDefault')!,
        isActive: mapValueOfType<bool>(json, r'isActive')!,
        rideCount: mapValueOfType<int>(json, r'rideCount')!,
        distanceM: mapValueOfType<double>(json, r'distanceM')!,
        movingS: mapValueOfType<double>(json, r'movingS')!,
      );
    }
    return null;
  }

  static List<BikeResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BikeResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BikeResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BikeResponse> mapFromJson(dynamic json) {
    final map = <String, BikeResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BikeResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BikeResponse-objects as value to a dart map
  static Map<String, List<BikeResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<BikeResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BikeResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'brand',
    'model',
    'modelYear',
    'buildSpec',
    'frameSize',
    'kind',
    'wheelCircumferenceMm',
    'initialDistanceM',
    'purchasedOn',
    'isDefault',
    'isActive',
    'rideCount',
    'distanceM',
    'movingS',
  };
}

