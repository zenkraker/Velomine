//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class PartResponse {
  /// Returns a new [PartResponse] instance.
  PartResponse({
    required this.id,
    required this.type,
    required this.brand,
    required this.model,
    required this.mpn,
    required this.gtin,
    required this.confirmations,
  });

  final String id;

  final String type;

  final String brand;

  final String model;

  final String? mpn;

  final String? gtin;

  final int confirmations;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PartResponse &&
    other.id == id &&
    other.type == type &&
    other.brand == brand &&
    other.model == model &&
    other.mpn == mpn &&
    other.gtin == gtin &&
    other.confirmations == confirmations;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (type.hashCode) +
    (brand.hashCode) +
    (model.hashCode) +
    (mpn == null ? 0 : mpn!.hashCode) +
    (gtin == null ? 0 : gtin!.hashCode) +
    (confirmations.hashCode);

  @override
  String toString() => 'PartResponse[id=$id, type=$type, brand=$brand, model=$model, mpn=$mpn, gtin=$gtin, confirmations=$confirmations]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'type'] = this.type;
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
      json[r'confirmations'] = this.confirmations;
    return json;
  }

  /// Clones this instance of [PartResponse] and returns a new one where some of the
  /// properties have changed.
  PartResponse copyWith({
    String? id,
    String? type,
    String? brand,
    String? model,
    String? mpn,
    bool mpnSetToNull = false,
    String? gtin,
    bool gtinSetToNull = false,
    int? confirmations,
  }) => PartResponse(
    id: id ?? this.id,
    type: type ?? this.type,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    mpn: mpnSetToNull ? null : mpn ?? this.mpn,
    gtin: gtinSetToNull ? null : gtin ?? this.gtin,
    confirmations: confirmations ?? this.confirmations,
  );

  /// Returns a new [PartResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PartResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "PartResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "PartResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'type'), 'Required key "PartResponse[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "PartResponse[type]" has a null value in JSON.');
        assert(json.containsKey(r'brand'), 'Required key "PartResponse[brand]" is missing from JSON.');
        assert(json[r'brand'] != null, 'Required key "PartResponse[brand]" has a null value in JSON.');
        assert(json.containsKey(r'model'), 'Required key "PartResponse[model]" is missing from JSON.');
        assert(json[r'model'] != null, 'Required key "PartResponse[model]" has a null value in JSON.');
        assert(json.containsKey(r'mpn'), 'Required key "PartResponse[mpn]" is missing from JSON.');
        assert(json.containsKey(r'gtin'), 'Required key "PartResponse[gtin]" is missing from JSON.');
        assert(json.containsKey(r'confirmations'), 'Required key "PartResponse[confirmations]" is missing from JSON.');
        assert(json[r'confirmations'] != null, 'Required key "PartResponse[confirmations]" has a null value in JSON.');
        return true;
      }());

      return PartResponse(
        id: mapValueOfType<String>(json, r'id')!,
        type: mapValueOfType<String>(json, r'type')!,
        brand: mapValueOfType<String>(json, r'brand')!,
        model: mapValueOfType<String>(json, r'model')!,
        mpn: mapValueOfType<String>(json, r'mpn'),
        gtin: mapValueOfType<String>(json, r'gtin'),
        confirmations: mapValueOfType<int>(json, r'confirmations')!,
      );
    }
    return null;
  }

  static List<PartResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PartResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PartResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PartResponse> mapFromJson(dynamic json) {
    final map = <String, PartResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PartResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PartResponse-objects as value to a dart map
  static Map<String, List<PartResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PartResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PartResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'type',
    'brand',
    'model',
    'mpn',
    'gtin',
    'confirmations',
  };
}

