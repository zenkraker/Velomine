//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class CreateBikeRequest {
  /// Returns a new [CreateBikeRequest] instance.
  CreateBikeRequest({
    required this.name,
    this.brand = const Optional.absent(),
    this.model = const Optional.absent(),
    this.modelYear = const Optional.absent(),
    this.buildSpec = const Optional.absent(),
    this.frameSize = const Optional.absent(),
    required this.kind,
    required this.wheelCircumferenceMm,
    required this.initialDistanceM,
    this.purchasedOn = const Optional.absent(),
  });

  final String name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> brand;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> model;

  /// Minimum value: 1900
  /// Maximum value: 2100
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> modelYear;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> buildSpec;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> frameSize;

  final String kind;

  /// Minimum value: 1000
  /// Maximum value: 2600
  final int wheelCircumferenceMm;

  /// Minimum value: 0
  /// Maximum value: 10000000
  final double initialDistanceM;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<DateTime?> purchasedOn;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreateBikeRequest &&
    other.name == name &&
    other.brand == brand &&
    other.model == model &&
    other.modelYear == modelYear &&
    other.buildSpec == buildSpec &&
    other.frameSize == frameSize &&
    other.kind == kind &&
    other.wheelCircumferenceMm == wheelCircumferenceMm &&
    other.initialDistanceM == initialDistanceM &&
    other.purchasedOn == purchasedOn;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (brand == null ? 0 : brand!.hashCode) +
    (model == null ? 0 : model!.hashCode) +
    (modelYear == null ? 0 : modelYear!.hashCode) +
    (buildSpec == null ? 0 : buildSpec!.hashCode) +
    (frameSize == null ? 0 : frameSize!.hashCode) +
    (kind.hashCode) +
    (wheelCircumferenceMm.hashCode) +
    (initialDistanceM.hashCode) +
    (purchasedOn == null ? 0 : purchasedOn!.hashCode);

  @override
  String toString() => 'CreateBikeRequest[name=$name, brand=$brand, model=$model, modelYear=$modelYear, buildSpec=$buildSpec, frameSize=$frameSize, kind=$kind, wheelCircumferenceMm=$wheelCircumferenceMm, initialDistanceM=$initialDistanceM, purchasedOn=$purchasedOn]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
    if (this.brand.isPresent) {
      final value = this.brand.value;
      json[r'brand'] = value;
    }
    if (this.model.isPresent) {
      final value = this.model.value;
      json[r'model'] = value;
    }
    if (this.modelYear.isPresent) {
      final value = this.modelYear.value;
      json[r'modelYear'] = value;
    }
    if (this.buildSpec.isPresent) {
      final value = this.buildSpec.value;
      json[r'buildSpec'] = value;
    }
    if (this.frameSize.isPresent) {
      final value = this.frameSize.value;
      json[r'frameSize'] = value;
    }
      json[r'kind'] = this.kind;
      json[r'wheelCircumferenceMm'] = this.wheelCircumferenceMm;
      json[r'initialDistanceM'] = this.initialDistanceM;
    if (this.purchasedOn.isPresent) {
      final value = this.purchasedOn.value;
      json[r'purchasedOn'] = value == null ? null : _dateFormatter.format(value);
    }
    return json;
  }

  /// Clones this instance of [CreateBikeRequest] and returns a new one where some of the
  /// properties have changed.
  CreateBikeRequest copyWith({
    String? name,
    Optional<String?>? brand,
    Optional<String?>? model,
    Optional<int?>? modelYear,
    Optional<String?>? buildSpec,
    Optional<String?>? frameSize,
    String? kind,
    int? wheelCircumferenceMm,
    double? initialDistanceM,
    Optional<DateTime?>? purchasedOn,
  }) => CreateBikeRequest(
    name: name ?? this.name,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    modelYear: modelYear ?? this.modelYear,
    buildSpec: buildSpec ?? this.buildSpec,
    frameSize: frameSize ?? this.frameSize,
    kind: kind ?? this.kind,
    wheelCircumferenceMm: wheelCircumferenceMm ?? this.wheelCircumferenceMm,
    initialDistanceM: initialDistanceM ?? this.initialDistanceM,
    purchasedOn: purchasedOn ?? this.purchasedOn,
  );

  /// Returns a new [CreateBikeRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateBikeRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "CreateBikeRequest[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "CreateBikeRequest[name]" has a null value in JSON.');
        assert(json.containsKey(r'kind'), 'Required key "CreateBikeRequest[kind]" is missing from JSON.');
        assert(json[r'kind'] != null, 'Required key "CreateBikeRequest[kind]" has a null value in JSON.');
        assert(json.containsKey(r'wheelCircumferenceMm'), 'Required key "CreateBikeRequest[wheelCircumferenceMm]" is missing from JSON.');
        assert(json[r'wheelCircumferenceMm'] != null, 'Required key "CreateBikeRequest[wheelCircumferenceMm]" has a null value in JSON.');
        assert(json.containsKey(r'initialDistanceM'), 'Required key "CreateBikeRequest[initialDistanceM]" is missing from JSON.');
        assert(json[r'initialDistanceM'] != null, 'Required key "CreateBikeRequest[initialDistanceM]" has a null value in JSON.');
        return true;
      }());

      return CreateBikeRequest(
        name: mapValueOfType<String>(json, r'name')!,
        brand: json.containsKey(r'brand') ? Optional.present(mapValueOfType<String>(json, r'brand')) : const Optional.absent(),
        model: json.containsKey(r'model') ? Optional.present(mapValueOfType<String>(json, r'model')) : const Optional.absent(),
        modelYear: json.containsKey(r'modelYear') ? Optional.present(json[r'modelYear'] == null ? null : int.parse('${json[r'modelYear']}')) : const Optional.absent(),
        buildSpec: json.containsKey(r'buildSpec') ? Optional.present(mapValueOfType<String>(json, r'buildSpec')) : const Optional.absent(),
        frameSize: json.containsKey(r'frameSize') ? Optional.present(mapValueOfType<String>(json, r'frameSize')) : const Optional.absent(),
        kind: mapValueOfType<String>(json, r'kind')!,
        wheelCircumferenceMm: mapValueOfType<int>(json, r'wheelCircumferenceMm')!,
        initialDistanceM: mapValueOfType<double>(json, r'initialDistanceM')!,
        purchasedOn: json.containsKey(r'purchasedOn') ? Optional.present(mapDateTime(json, r'purchasedOn', r'')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<CreateBikeRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateBikeRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateBikeRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateBikeRequest> mapFromJson(dynamic json) {
    final map = <String, CreateBikeRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateBikeRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateBikeRequest-objects as value to a dart map
  static Map<String, List<CreateBikeRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreateBikeRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateBikeRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'kind',
    'wheelCircumferenceMm',
    'initialDistanceM',
  };
}

