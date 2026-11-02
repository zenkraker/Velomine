//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class UpdateBikeRequest {
  /// Returns a new [UpdateBikeRequest] instance.
  UpdateBikeRequest({
    required this.name,
    this.brand = const Optional.absent(),
    this.model = const Optional.absent(),
    required this.kind,
    required this.wheelCircumferenceMm,
    required this.initialDistanceM,
    this.purchasedOn = const Optional.absent(),
    this.isActive = const Optional.absent(),
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

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> isActive;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UpdateBikeRequest &&
    other.name == name &&
    other.brand == brand &&
    other.model == model &&
    other.kind == kind &&
    other.wheelCircumferenceMm == wheelCircumferenceMm &&
    other.initialDistanceM == initialDistanceM &&
    other.purchasedOn == purchasedOn &&
    other.isActive == isActive;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (brand == null ? 0 : brand!.hashCode) +
    (model == null ? 0 : model!.hashCode) +
    (kind.hashCode) +
    (wheelCircumferenceMm.hashCode) +
    (initialDistanceM.hashCode) +
    (purchasedOn == null ? 0 : purchasedOn!.hashCode) +
    (isActive == null ? 0 : isActive!.hashCode);

  @override
  String toString() => 'UpdateBikeRequest[name=$name, brand=$brand, model=$model, kind=$kind, wheelCircumferenceMm=$wheelCircumferenceMm, initialDistanceM=$initialDistanceM, purchasedOn=$purchasedOn, isActive=$isActive]';

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
      json[r'kind'] = this.kind;
      json[r'wheelCircumferenceMm'] = this.wheelCircumferenceMm;
      json[r'initialDistanceM'] = this.initialDistanceM;
    if (this.purchasedOn.isPresent) {
      final value = this.purchasedOn.value;
      json[r'purchasedOn'] = value == null ? null : _dateFormatter.format(value);
    }
    if (this.isActive.isPresent) {
      final value = this.isActive.value;
      json[r'isActive'] = value;
    }
    return json;
  }

  /// Clones this instance of [UpdateBikeRequest] and returns a new one where some of the
  /// properties have changed.
  UpdateBikeRequest copyWith({
    String? name,
    Optional<String?>? brand,
    Optional<String?>? model,
    String? kind,
    int? wheelCircumferenceMm,
    double? initialDistanceM,
    Optional<DateTime?>? purchasedOn,
    Optional<bool?>? isActive,
  }) => UpdateBikeRequest(
    name: name ?? this.name,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    kind: kind ?? this.kind,
    wheelCircumferenceMm: wheelCircumferenceMm ?? this.wheelCircumferenceMm,
    initialDistanceM: initialDistanceM ?? this.initialDistanceM,
    purchasedOn: purchasedOn ?? this.purchasedOn,
    isActive: isActive ?? this.isActive,
  );

  /// Returns a new [UpdateBikeRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateBikeRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "UpdateBikeRequest[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "UpdateBikeRequest[name]" has a null value in JSON.');
        assert(json.containsKey(r'kind'), 'Required key "UpdateBikeRequest[kind]" is missing from JSON.');
        assert(json[r'kind'] != null, 'Required key "UpdateBikeRequest[kind]" has a null value in JSON.');
        assert(json.containsKey(r'wheelCircumferenceMm'), 'Required key "UpdateBikeRequest[wheelCircumferenceMm]" is missing from JSON.');
        assert(json[r'wheelCircumferenceMm'] != null, 'Required key "UpdateBikeRequest[wheelCircumferenceMm]" has a null value in JSON.');
        assert(json.containsKey(r'initialDistanceM'), 'Required key "UpdateBikeRequest[initialDistanceM]" is missing from JSON.');
        assert(json[r'initialDistanceM'] != null, 'Required key "UpdateBikeRequest[initialDistanceM]" has a null value in JSON.');
        return true;
      }());

      return UpdateBikeRequest(
        name: mapValueOfType<String>(json, r'name')!,
        brand: json.containsKey(r'brand') ? Optional.present(mapValueOfType<String>(json, r'brand')) : const Optional.absent(),
        model: json.containsKey(r'model') ? Optional.present(mapValueOfType<String>(json, r'model')) : const Optional.absent(),
        kind: mapValueOfType<String>(json, r'kind')!,
        wheelCircumferenceMm: mapValueOfType<int>(json, r'wheelCircumferenceMm')!,
        initialDistanceM: mapValueOfType<double>(json, r'initialDistanceM')!,
        purchasedOn: json.containsKey(r'purchasedOn') ? Optional.present(mapDateTime(json, r'purchasedOn', r'')) : const Optional.absent(),
        isActive: json.containsKey(r'isActive') ? Optional.present(mapValueOfType<bool>(json, r'isActive')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<UpdateBikeRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UpdateBikeRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateBikeRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateBikeRequest> mapFromJson(dynamic json) {
    final map = <String, UpdateBikeRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateBikeRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateBikeRequest-objects as value to a dart map
  static Map<String, List<UpdateBikeRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UpdateBikeRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateBikeRequest.listFromJson(entry.value, growable: growable,);
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

