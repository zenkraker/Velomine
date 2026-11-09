//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ComponentResponse {
  /// Returns a new [ComponentResponse] instance.
  ComponentResponse({
    required this.id,
    required this.type,
    required this.typeName,
    required this.brand,
    required this.model,
    required this.mpn,
    required this.gtin,
    required this.partId,
    required this.installedOn,
    required this.removedOn,
    required this.expectedDistanceM,
    required this.expectedHours,
    required this.expectedMonths,
    required this.usedDistanceM,
    required this.usedHours,
    required this.usedMonths,
    required this.wearPercent,
    required this.status,
  });

  final String id;

  final String type;

  final String typeName;

  final String? brand;

  final String? model;

  final String? mpn;

  final String? gtin;

  final String? partId;

  final DateTime installedOn;

  final DateTime? removedOn;

  final double? expectedDistanceM;

  final double? expectedHours;

  final int? expectedMonths;

  final double usedDistanceM;

  final double usedHours;

  final double usedMonths;

  final int? wearPercent;

  final String status;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ComponentResponse &&
    other.id == id &&
    other.type == type &&
    other.typeName == typeName &&
    other.brand == brand &&
    other.model == model &&
    other.mpn == mpn &&
    other.gtin == gtin &&
    other.partId == partId &&
    other.installedOn == installedOn &&
    other.removedOn == removedOn &&
    other.expectedDistanceM == expectedDistanceM &&
    other.expectedHours == expectedHours &&
    other.expectedMonths == expectedMonths &&
    other.usedDistanceM == usedDistanceM &&
    other.usedHours == usedHours &&
    other.usedMonths == usedMonths &&
    other.wearPercent == wearPercent &&
    other.status == status;

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
    (partId == null ? 0 : partId!.hashCode) +
    (installedOn.hashCode) +
    (removedOn == null ? 0 : removedOn!.hashCode) +
    (expectedDistanceM == null ? 0 : expectedDistanceM!.hashCode) +
    (expectedHours == null ? 0 : expectedHours!.hashCode) +
    (expectedMonths == null ? 0 : expectedMonths!.hashCode) +
    (usedDistanceM.hashCode) +
    (usedHours.hashCode) +
    (usedMonths.hashCode) +
    (wearPercent == null ? 0 : wearPercent!.hashCode) +
    (status.hashCode);

  @override
  String toString() => 'ComponentResponse[id=$id, type=$type, typeName=$typeName, brand=$brand, model=$model, mpn=$mpn, gtin=$gtin, partId=$partId, installedOn=$installedOn, removedOn=$removedOn, expectedDistanceM=$expectedDistanceM, expectedHours=$expectedHours, expectedMonths=$expectedMonths, usedDistanceM=$usedDistanceM, usedHours=$usedHours, usedMonths=$usedMonths, wearPercent=$wearPercent, status=$status]';

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
    if (this.partId != null) {
      json[r'partId'] = this.partId;
    } else {
      json[r'partId'] = null;
    }
      json[r'installedOn'] = _dateFormatter.format(this.installedOn);
    if (this.removedOn != null) {
      json[r'removedOn'] = _dateFormatter.format(this.removedOn!);
    } else {
      json[r'removedOn'] = null;
    }
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
      json[r'usedDistanceM'] = this.usedDistanceM;
      json[r'usedHours'] = this.usedHours;
      json[r'usedMonths'] = this.usedMonths;
    if (this.wearPercent != null) {
      json[r'wearPercent'] = this.wearPercent;
    } else {
      json[r'wearPercent'] = null;
    }
      json[r'status'] = this.status;
    return json;
  }

  /// Clones this instance of [ComponentResponse] and returns a new one where some of the
  /// properties have changed.
  ComponentResponse copyWith({
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
    String? partId,
    bool partIdSetToNull = false,
    DateTime? installedOn,
    DateTime? removedOn,
    bool removedOnSetToNull = false,
    double? expectedDistanceM,
    bool expectedDistanceMSetToNull = false,
    double? expectedHours,
    bool expectedHoursSetToNull = false,
    int? expectedMonths,
    bool expectedMonthsSetToNull = false,
    double? usedDistanceM,
    double? usedHours,
    double? usedMonths,
    int? wearPercent,
    bool wearPercentSetToNull = false,
    String? status,
  }) => ComponentResponse(
    id: id ?? this.id,
    type: type ?? this.type,
    typeName: typeName ?? this.typeName,
    brand: brandSetToNull ? null : brand ?? this.brand,
    model: modelSetToNull ? null : model ?? this.model,
    mpn: mpnSetToNull ? null : mpn ?? this.mpn,
    gtin: gtinSetToNull ? null : gtin ?? this.gtin,
    partId: partIdSetToNull ? null : partId ?? this.partId,
    installedOn: installedOn ?? this.installedOn,
    removedOn: removedOnSetToNull ? null : removedOn ?? this.removedOn,
    expectedDistanceM: expectedDistanceMSetToNull ? null : expectedDistanceM ?? this.expectedDistanceM,
    expectedHours: expectedHoursSetToNull ? null : expectedHours ?? this.expectedHours,
    expectedMonths: expectedMonthsSetToNull ? null : expectedMonths ?? this.expectedMonths,
    usedDistanceM: usedDistanceM ?? this.usedDistanceM,
    usedHours: usedHours ?? this.usedHours,
    usedMonths: usedMonths ?? this.usedMonths,
    wearPercent: wearPercentSetToNull ? null : wearPercent ?? this.wearPercent,
    status: status ?? this.status,
  );

  /// Returns a new [ComponentResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ComponentResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "ComponentResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "ComponentResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'type'), 'Required key "ComponentResponse[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "ComponentResponse[type]" has a null value in JSON.');
        assert(json.containsKey(r'typeName'), 'Required key "ComponentResponse[typeName]" is missing from JSON.');
        assert(json[r'typeName'] != null, 'Required key "ComponentResponse[typeName]" has a null value in JSON.');
        assert(json.containsKey(r'brand'), 'Required key "ComponentResponse[brand]" is missing from JSON.');
        assert(json.containsKey(r'model'), 'Required key "ComponentResponse[model]" is missing from JSON.');
        assert(json.containsKey(r'mpn'), 'Required key "ComponentResponse[mpn]" is missing from JSON.');
        assert(json.containsKey(r'gtin'), 'Required key "ComponentResponse[gtin]" is missing from JSON.');
        assert(json.containsKey(r'partId'), 'Required key "ComponentResponse[partId]" is missing from JSON.');
        assert(json.containsKey(r'installedOn'), 'Required key "ComponentResponse[installedOn]" is missing from JSON.');
        assert(json[r'installedOn'] != null, 'Required key "ComponentResponse[installedOn]" has a null value in JSON.');
        assert(json.containsKey(r'removedOn'), 'Required key "ComponentResponse[removedOn]" is missing from JSON.');
        assert(json.containsKey(r'expectedDistanceM'), 'Required key "ComponentResponse[expectedDistanceM]" is missing from JSON.');
        assert(json.containsKey(r'expectedHours'), 'Required key "ComponentResponse[expectedHours]" is missing from JSON.');
        assert(json.containsKey(r'expectedMonths'), 'Required key "ComponentResponse[expectedMonths]" is missing from JSON.');
        assert(json.containsKey(r'usedDistanceM'), 'Required key "ComponentResponse[usedDistanceM]" is missing from JSON.');
        assert(json[r'usedDistanceM'] != null, 'Required key "ComponentResponse[usedDistanceM]" has a null value in JSON.');
        assert(json.containsKey(r'usedHours'), 'Required key "ComponentResponse[usedHours]" is missing from JSON.');
        assert(json[r'usedHours'] != null, 'Required key "ComponentResponse[usedHours]" has a null value in JSON.');
        assert(json.containsKey(r'usedMonths'), 'Required key "ComponentResponse[usedMonths]" is missing from JSON.');
        assert(json[r'usedMonths'] != null, 'Required key "ComponentResponse[usedMonths]" has a null value in JSON.');
        assert(json.containsKey(r'wearPercent'), 'Required key "ComponentResponse[wearPercent]" is missing from JSON.');
        assert(json.containsKey(r'status'), 'Required key "ComponentResponse[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "ComponentResponse[status]" has a null value in JSON.');
        return true;
      }());

      return ComponentResponse(
        id: mapValueOfType<String>(json, r'id')!,
        type: mapValueOfType<String>(json, r'type')!,
        typeName: mapValueOfType<String>(json, r'typeName')!,
        brand: mapValueOfType<String>(json, r'brand'),
        model: mapValueOfType<String>(json, r'model'),
        mpn: mapValueOfType<String>(json, r'mpn'),
        gtin: mapValueOfType<String>(json, r'gtin'),
        partId: mapValueOfType<String>(json, r'partId'),
        installedOn: mapDateTime(json, r'installedOn', r'')!,
        removedOn: mapDateTime(json, r'removedOn', r''),
        expectedDistanceM: mapValueOfType<double>(json, r'expectedDistanceM'),
        expectedHours: mapValueOfType<double>(json, r'expectedHours'),
        expectedMonths: mapValueOfType<int>(json, r'expectedMonths'),
        usedDistanceM: mapValueOfType<double>(json, r'usedDistanceM')!,
        usedHours: mapValueOfType<double>(json, r'usedHours')!,
        usedMonths: mapValueOfType<double>(json, r'usedMonths')!,
        wearPercent: mapValueOfType<int>(json, r'wearPercent'),
        status: mapValueOfType<String>(json, r'status')!,
      );
    }
    return null;
  }

  static List<ComponentResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ComponentResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ComponentResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ComponentResponse> mapFromJson(dynamic json) {
    final map = <String, ComponentResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ComponentResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ComponentResponse-objects as value to a dart map
  static Map<String, List<ComponentResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ComponentResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ComponentResponse.listFromJson(entry.value, growable: growable,);
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
    'partId',
    'installedOn',
    'removedOn',
    'expectedDistanceM',
    'expectedHours',
    'expectedMonths',
    'usedDistanceM',
    'usedHours',
    'usedMonths',
    'wearPercent',
    'status',
  };
}

