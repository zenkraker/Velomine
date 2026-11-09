//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class UpdateComponentRequest {
  /// Returns a new [UpdateComponentRequest] instance.
  UpdateComponentRequest({
    required this.type,
    this.brand = const Optional.absent(),
    this.model = const Optional.absent(),
    this.mpn = const Optional.absent(),
    this.gtin = const Optional.absent(),
    required this.installedOn,
    this.removedOn = const Optional.absent(),
    this.expectedDistanceM = const Optional.absent(),
    this.expectedHours = const Optional.absent(),
    this.expectedMonths = const Optional.absent(),
  });

  final String type;

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

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> mpn;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> gtin;

  final DateTime installedOn;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<DateTime?> removedOn;

  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<double?> expectedDistanceM;

  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<double?> expectedHours;

  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> expectedMonths;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UpdateComponentRequest &&
    other.type == type &&
    other.brand == brand &&
    other.model == model &&
    other.mpn == mpn &&
    other.gtin == gtin &&
    other.installedOn == installedOn &&
    other.removedOn == removedOn &&
    other.expectedDistanceM == expectedDistanceM &&
    other.expectedHours == expectedHours &&
    other.expectedMonths == expectedMonths;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (type.hashCode) +
    (brand == null ? 0 : brand!.hashCode) +
    (model == null ? 0 : model!.hashCode) +
    (mpn == null ? 0 : mpn!.hashCode) +
    (gtin == null ? 0 : gtin!.hashCode) +
    (installedOn.hashCode) +
    (removedOn == null ? 0 : removedOn!.hashCode) +
    (expectedDistanceM == null ? 0 : expectedDistanceM!.hashCode) +
    (expectedHours == null ? 0 : expectedHours!.hashCode) +
    (expectedMonths == null ? 0 : expectedMonths!.hashCode);

  @override
  String toString() => 'UpdateComponentRequest[type=$type, brand=$brand, model=$model, mpn=$mpn, gtin=$gtin, installedOn=$installedOn, removedOn=$removedOn, expectedDistanceM=$expectedDistanceM, expectedHours=$expectedHours, expectedMonths=$expectedMonths]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'type'] = this.type;
    if (this.brand.isPresent) {
      final value = this.brand.value;
      json[r'brand'] = value;
    }
    if (this.model.isPresent) {
      final value = this.model.value;
      json[r'model'] = value;
    }
    if (this.mpn.isPresent) {
      final value = this.mpn.value;
      json[r'mpn'] = value;
    }
    if (this.gtin.isPresent) {
      final value = this.gtin.value;
      json[r'gtin'] = value;
    }
      json[r'installedOn'] = _dateFormatter.format(this.installedOn);
    if (this.removedOn.isPresent) {
      final value = this.removedOn.value;
      json[r'removedOn'] = value == null ? null : _dateFormatter.format(value);
    }
    if (this.expectedDistanceM.isPresent) {
      final value = this.expectedDistanceM.value;
      json[r'expectedDistanceM'] = value;
    }
    if (this.expectedHours.isPresent) {
      final value = this.expectedHours.value;
      json[r'expectedHours'] = value;
    }
    if (this.expectedMonths.isPresent) {
      final value = this.expectedMonths.value;
      json[r'expectedMonths'] = value;
    }
    return json;
  }

  /// Clones this instance of [UpdateComponentRequest] and returns a new one where some of the
  /// properties have changed.
  UpdateComponentRequest copyWith({
    String? type,
    Optional<String?>? brand,
    Optional<String?>? model,
    Optional<String?>? mpn,
    Optional<String?>? gtin,
    DateTime? installedOn,
    Optional<DateTime?>? removedOn,
    Optional<double?>? expectedDistanceM,
    Optional<double?>? expectedHours,
    Optional<int?>? expectedMonths,
  }) => UpdateComponentRequest(
    type: type ?? this.type,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    mpn: mpn ?? this.mpn,
    gtin: gtin ?? this.gtin,
    installedOn: installedOn ?? this.installedOn,
    removedOn: removedOn ?? this.removedOn,
    expectedDistanceM: expectedDistanceM ?? this.expectedDistanceM,
    expectedHours: expectedHours ?? this.expectedHours,
    expectedMonths: expectedMonths ?? this.expectedMonths,
  );

  /// Returns a new [UpdateComponentRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateComponentRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'type'), 'Required key "UpdateComponentRequest[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "UpdateComponentRequest[type]" has a null value in JSON.');
        assert(json.containsKey(r'installedOn'), 'Required key "UpdateComponentRequest[installedOn]" is missing from JSON.');
        assert(json[r'installedOn'] != null, 'Required key "UpdateComponentRequest[installedOn]" has a null value in JSON.');
        return true;
      }());

      return UpdateComponentRequest(
        type: mapValueOfType<String>(json, r'type')!,
        brand: json.containsKey(r'brand') ? Optional.present(mapValueOfType<String>(json, r'brand')) : const Optional.absent(),
        model: json.containsKey(r'model') ? Optional.present(mapValueOfType<String>(json, r'model')) : const Optional.absent(),
        mpn: json.containsKey(r'mpn') ? Optional.present(mapValueOfType<String>(json, r'mpn')) : const Optional.absent(),
        gtin: json.containsKey(r'gtin') ? Optional.present(mapValueOfType<String>(json, r'gtin')) : const Optional.absent(),
        installedOn: mapDateTime(json, r'installedOn', r'')!,
        removedOn: json.containsKey(r'removedOn') ? Optional.present(mapDateTime(json, r'removedOn', r'')) : const Optional.absent(),
        expectedDistanceM: json.containsKey(r'expectedDistanceM') ? Optional.present(mapValueOfType<double>(json, r'expectedDistanceM')) : const Optional.absent(),
        expectedHours: json.containsKey(r'expectedHours') ? Optional.present(mapValueOfType<double>(json, r'expectedHours')) : const Optional.absent(),
        expectedMonths: json.containsKey(r'expectedMonths') ? Optional.present(json[r'expectedMonths'] == null ? null : int.parse('${json[r'expectedMonths']}')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<UpdateComponentRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UpdateComponentRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateComponentRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateComponentRequest> mapFromJson(dynamic json) {
    final map = <String, UpdateComponentRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateComponentRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateComponentRequest-objects as value to a dart map
  static Map<String, List<UpdateComponentRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UpdateComponentRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateComponentRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'type',
    'installedOn',
  };
}

