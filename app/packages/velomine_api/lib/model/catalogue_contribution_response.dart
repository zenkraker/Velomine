//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class CatalogueContributionResponse {
  /// Returns a new [CatalogueContributionResponse] instance.
  CatalogueContributionResponse({
    required this.id,
    required this.type,
    required this.typeName,
    required this.brand,
    required this.model,
    required this.mpn,
    required this.gtin,
    required this.status,
    required this.attempts,
    required this.reason,
    required this.createdAt,
  });

  final String id;

  final String type;

  final String typeName;

  final String brand;

  final String model;

  final String? mpn;

  final String? gtin;

  final String status;

  final int attempts;

  final String? reason;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CatalogueContributionResponse &&
    other.id == id &&
    other.type == type &&
    other.typeName == typeName &&
    other.brand == brand &&
    other.model == model &&
    other.mpn == mpn &&
    other.gtin == gtin &&
    other.status == status &&
    other.attempts == attempts &&
    other.reason == reason &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (type.hashCode) +
    (typeName.hashCode) +
    (brand.hashCode) +
    (model.hashCode) +
    (mpn == null ? 0 : mpn!.hashCode) +
    (gtin == null ? 0 : gtin!.hashCode) +
    (status.hashCode) +
    (attempts.hashCode) +
    (reason == null ? 0 : reason!.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'CatalogueContributionResponse[id=$id, type=$type, typeName=$typeName, brand=$brand, model=$model, mpn=$mpn, gtin=$gtin, status=$status, attempts=$attempts, reason=$reason, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'type'] = this.type;
      json[r'typeName'] = this.typeName;
      json[r'brand'] = this.brand;
      json[r'model'] = this.model;
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
      json[r'status'] = this.status;
      json[r'attempts'] = this.attempts;
    if (this.reason != null) {
      json[r'reason'] = this.reason;
    } else {
      json[r'reason'] = null;
    }
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [CatalogueContributionResponse] and returns a new one where some of the
  /// properties have changed.
  CatalogueContributionResponse copyWith({
    String? id,
    String? type,
    String? typeName,
    String? brand,
    String? model,
    String? mpn,
    bool mpnSetToNull = false,
    String? gtin,
    bool gtinSetToNull = false,
    String? status,
    int? attempts,
    String? reason,
    bool reasonSetToNull = false,
    DateTime? createdAt,
  }) => CatalogueContributionResponse(
    id: id ?? this.id,
    type: type ?? this.type,
    typeName: typeName ?? this.typeName,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    mpn: mpnSetToNull ? null : mpn ?? this.mpn,
    gtin: gtinSetToNull ? null : gtin ?? this.gtin,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    reason: reasonSetToNull ? null : reason ?? this.reason,
    createdAt: createdAt ?? this.createdAt,
  );

  /// Returns a new [CatalogueContributionResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CatalogueContributionResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "CatalogueContributionResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "CatalogueContributionResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'type'), 'Required key "CatalogueContributionResponse[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "CatalogueContributionResponse[type]" has a null value in JSON.');
        assert(json.containsKey(r'typeName'), 'Required key "CatalogueContributionResponse[typeName]" is missing from JSON.');
        assert(json[r'typeName'] != null, 'Required key "CatalogueContributionResponse[typeName]" has a null value in JSON.');
        assert(json.containsKey(r'brand'), 'Required key "CatalogueContributionResponse[brand]" is missing from JSON.');
        assert(json[r'brand'] != null, 'Required key "CatalogueContributionResponse[brand]" has a null value in JSON.');
        assert(json.containsKey(r'model'), 'Required key "CatalogueContributionResponse[model]" is missing from JSON.');
        assert(json[r'model'] != null, 'Required key "CatalogueContributionResponse[model]" has a null value in JSON.');
        assert(json.containsKey(r'mpn'), 'Required key "CatalogueContributionResponse[mpn]" is missing from JSON.');
        assert(json.containsKey(r'gtin'), 'Required key "CatalogueContributionResponse[gtin]" is missing from JSON.');
        assert(json.containsKey(r'status'), 'Required key "CatalogueContributionResponse[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "CatalogueContributionResponse[status]" has a null value in JSON.');
        assert(json.containsKey(r'attempts'), 'Required key "CatalogueContributionResponse[attempts]" is missing from JSON.');
        assert(json[r'attempts'] != null, 'Required key "CatalogueContributionResponse[attempts]" has a null value in JSON.');
        assert(json.containsKey(r'reason'), 'Required key "CatalogueContributionResponse[reason]" is missing from JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "CatalogueContributionResponse[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "CatalogueContributionResponse[createdAt]" has a null value in JSON.');
        return true;
      }());

      return CatalogueContributionResponse(
        id: mapValueOfType<String>(json, r'id')!,
        type: mapValueOfType<String>(json, r'type')!,
        typeName: mapValueOfType<String>(json, r'typeName')!,
        brand: mapValueOfType<String>(json, r'brand')!,
        model: mapValueOfType<String>(json, r'model')!,
        mpn: mapValueOfType<String>(json, r'mpn'),
        gtin: mapValueOfType<String>(json, r'gtin'),
        status: mapValueOfType<String>(json, r'status')!,
        attempts: mapValueOfType<int>(json, r'attempts')!,
        reason: mapValueOfType<String>(json, r'reason'),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<CatalogueContributionResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CatalogueContributionResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CatalogueContributionResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CatalogueContributionResponse> mapFromJson(dynamic json) {
    final map = <String, CatalogueContributionResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CatalogueContributionResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CatalogueContributionResponse-objects as value to a dart map
  static Map<String, List<CatalogueContributionResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CatalogueContributionResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CatalogueContributionResponse.listFromJson(entry.value, growable: growable,);
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
    'status',
    'attempts',
    'reason',
    'createdAt',
  };
}

