//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class TemplatePartResponse {
  /// Returns a new [TemplatePartResponse] instance.
  TemplatePartResponse({
    required this.id,
    required this.type,
    required this.typeName,
    required this.brand,
    required this.model,
    required this.mpn,
    required this.gtin,
    required this.isCustom,
    required this.expectedDistanceM,
    required this.expectedHours,
    required this.expectedMonths,
  });

  final String id;

  final String type;

  final String typeName;

  final String? brand;

  final String? model;

  final String? mpn;

  final String? gtin;

  final bool isCustom;

  final double? expectedDistanceM;

  final double? expectedHours;

  final int? expectedMonths;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TemplatePartResponse &&
    other.id == id &&
    other.type == type &&
    other.typeName == typeName &&
    other.brand == brand &&
    other.model == model &&
    other.mpn == mpn &&
    other.gtin == gtin &&
    other.isCustom == isCustom &&
    other.expectedDistanceM == expectedDistanceM &&
    other.expectedHours == expectedHours &&
    other.expectedMonths == expectedMonths;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (type.hashCode) +
    (typeName.hashCode) +
    (brand == null ? 0 : brand!.hashCode) +
    (model == null ? 0 : model!.hashCode) +
    (mpn == null ? 0 : mpn!.hashCode) +
    (gtin == null ? 0 : gtin!.hashCode) +
    (isCustom.hashCode) +
    (expectedDistanceM == null ? 0 : expectedDistanceM!.hashCode) +
    (expectedHours == null ? 0 : expectedHours!.hashCode) +
    (expectedMonths == null ? 0 : expectedMonths!.hashCode);

  @override
  String toString() => 'TemplatePartResponse[id=$id, type=$type, typeName=$typeName, brand=$brand, model=$model, mpn=$mpn, gtin=$gtin, isCustom=$isCustom, expectedDistanceM=$expectedDistanceM, expectedHours=$expectedHours, expectedMonths=$expectedMonths]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'type'] = this.type;
      json[r'typeName'] = this.typeName;
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
    if (this.mpn != null) {
      json[r'mpn'] = this.mpn;
    } else {
      json[r'mpn'] = null;
    }
    if (this.gtin != null) {
      json[r'gtin'] = this.gtin;
    } else {
      json[r'gtin'] = null;
    }
      json[r'isCustom'] = this.isCustom;
    if (this.expectedDistanceM != null) {
      json[r'expectedDistanceM'] = this.expectedDistanceM;
    } else {
      json[r'expectedDistanceM'] = null;
    }
    if (this.expectedHours != null) {
      json[r'expectedHours'] = this.expectedHours;
    } else {
      json[r'expectedHours'] = null;
    }
    if (this.expectedMonths != null) {
      json[r'expectedMonths'] = this.expectedMonths;
    } else {
      json[r'expectedMonths'] = null;
    }
    return json;
  }

  /// Clones this instance of [TemplatePartResponse] and returns a new one where some of the
  /// properties have changed.
  TemplatePartResponse copyWith({
    String? id,
    String? type,
    String? typeName,
    String? brand,
    bool brandSetToNull = false,
    String? model,
    bool modelSetToNull = false,
    String? mpn,
    bool mpnSetToNull = false,
    String? gtin,
    bool gtinSetToNull = false,
    bool? isCustom,
    double? expectedDistanceM,
    bool expectedDistanceMSetToNull = false,
    double? expectedHours,
    bool expectedHoursSetToNull = false,
    int? expectedMonths,
    bool expectedMonthsSetToNull = false,
  }) => TemplatePartResponse(
    id: id ?? this.id,
    type: type ?? this.type,
    typeName: typeName ?? this.typeName,
    brand: brandSetToNull ? null : brand ?? this.brand,
    model: modelSetToNull ? null : model ?? this.model,
    mpn: mpnSetToNull ? null : mpn ?? this.mpn,
    gtin: gtinSetToNull ? null : gtin ?? this.gtin,
    isCustom: isCustom ?? this.isCustom,
    expectedDistanceM: expectedDistanceMSetToNull ? null : expectedDistanceM ?? this.expectedDistanceM,
    expectedHours: expectedHoursSetToNull ? null : expectedHours ?? this.expectedHours,
    expectedMonths: expectedMonthsSetToNull ? null : expectedMonths ?? this.expectedMonths,
  );

  /// Returns a new [TemplatePartResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TemplatePartResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "TemplatePartResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "TemplatePartResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'type'), 'Required key "TemplatePartResponse[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "TemplatePartResponse[type]" has a null value in JSON.');
        assert(json.containsKey(r'typeName'), 'Required key "TemplatePartResponse[typeName]" is missing from JSON.');
        assert(json[r'typeName'] != null, 'Required key "TemplatePartResponse[typeName]" has a null value in JSON.');
        assert(json.containsKey(r'brand'), 'Required key "TemplatePartResponse[brand]" is missing from JSON.');
        assert(json.containsKey(r'model'), 'Required key "TemplatePartResponse[model]" is missing from JSON.');
        assert(json.containsKey(r'mpn'), 'Required key "TemplatePartResponse[mpn]" is missing from JSON.');
        assert(json.containsKey(r'gtin'), 'Required key "TemplatePartResponse[gtin]" is missing from JSON.');
        assert(json.containsKey(r'isCustom'), 'Required key "TemplatePartResponse[isCustom]" is missing from JSON.');
        assert(json[r'isCustom'] != null, 'Required key "TemplatePartResponse[isCustom]" has a null value in JSON.');
        assert(json.containsKey(r'expectedDistanceM'), 'Required key "TemplatePartResponse[expectedDistanceM]" is missing from JSON.');
        assert(json.containsKey(r'expectedHours'), 'Required key "TemplatePartResponse[expectedHours]" is missing from JSON.');
        assert(json.containsKey(r'expectedMonths'), 'Required key "TemplatePartResponse[expectedMonths]" is missing from JSON.');
        return true;
      }());

      return TemplatePartResponse(
        id: mapValueOfType<String>(json, r'id')!,
        type: mapValueOfType<String>(json, r'type')!,
        typeName: mapValueOfType<String>(json, r'typeName')!,
        brand: mapValueOfType<String>(json, r'brand'),
        model: mapValueOfType<String>(json, r'model'),
        mpn: mapValueOfType<String>(json, r'mpn'),
        gtin: mapValueOfType<String>(json, r'gtin'),
        isCustom: mapValueOfType<bool>(json, r'isCustom')!,
        expectedDistanceM: mapValueOfType<double>(json, r'expectedDistanceM'),
        expectedHours: mapValueOfType<double>(json, r'expectedHours'),
        expectedMonths: mapValueOfType<int>(json, r'expectedMonths'),
      );
    }
    return null;
  }

  static List<TemplatePartResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TemplatePartResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TemplatePartResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TemplatePartResponse> mapFromJson(dynamic json) {
    final map = <String, TemplatePartResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TemplatePartResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TemplatePartResponse-objects as value to a dart map
  static Map<String, List<TemplatePartResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TemplatePartResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TemplatePartResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'type',
    'typeName',
    'brand',
    'model',
    'mpn',
    'gtin',
    'isCustom',
    'expectedDistanceM',
    'expectedHours',
    'expectedMonths',
  };
}

