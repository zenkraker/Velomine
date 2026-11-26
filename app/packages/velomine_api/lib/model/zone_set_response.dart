//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ZoneSetResponse {
  /// Returns a new [ZoneSetResponse] instance.
  ZoneSetResponse({
    required this.set_,
    this.bounds = const [],
    required this.custom,
    required this.reference,
    required this.referenceSource,
    this.zones = const [],
  });

  final String set_;

  final List<double> bounds;

  final bool custom;

  final int? reference;

  final String? referenceSource;

  final List<ZoneTime> zones;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ZoneSetResponse &&
    other.set_ == set_ &&
    _deepEquality.equals(other.bounds, bounds) &&
    other.custom == custom &&
    other.reference == reference &&
    other.referenceSource == referenceSource &&
    _deepEquality.equals(other.zones, zones);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (set_.hashCode) +
    (bounds.hashCode) +
    (custom.hashCode) +
    (reference == null ? 0 : reference!.hashCode) +
    (referenceSource == null ? 0 : referenceSource!.hashCode) +
    (zones.hashCode);

  @override
  String toString() => 'ZoneSetResponse[set_=$set_, bounds=$bounds, custom=$custom, reference=$reference, referenceSource=$referenceSource, zones=$zones]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'set'] = this.set_;
      json[r'bounds'] = this.bounds;
      json[r'custom'] = this.custom;
    if (this.reference != null) {
      json[r'reference'] = this.reference;
    } else {
      json[r'reference'] = null;
    }
    if (this.referenceSource != null) {
      json[r'referenceSource'] = this.referenceSource;
    } else {
      json[r'referenceSource'] = null;
    }
      json[r'zones'] = this.zones;
    return json;
  }

  /// Clones this instance of [ZoneSetResponse] and returns a new one where some of the
  /// properties have changed.
  ZoneSetResponse copyWith({
    String? set_,
    List<double>? bounds,
    bool? custom,
    int? reference,
    bool referenceSetToNull = false,
    String? referenceSource,
    bool referenceSourceSetToNull = false,
    List<ZoneTime>? zones,
  }) => ZoneSetResponse(
    set_: set_ ?? this.set_,
    bounds: bounds ?? this.bounds,
    custom: custom ?? this.custom,
    reference: referenceSetToNull ? null : reference ?? this.reference,
    referenceSource: referenceSourceSetToNull ? null : referenceSource ?? this.referenceSource,
    zones: zones ?? this.zones,
  );

  /// Returns a new [ZoneSetResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ZoneSetResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'set'), 'Required key "ZoneSetResponse[set]" is missing from JSON.');
        assert(json[r'set'] != null, 'Required key "ZoneSetResponse[set]" has a null value in JSON.');
        assert(json.containsKey(r'bounds'), 'Required key "ZoneSetResponse[bounds]" is missing from JSON.');
        assert(json[r'bounds'] != null, 'Required key "ZoneSetResponse[bounds]" has a null value in JSON.');
        assert(json.containsKey(r'custom'), 'Required key "ZoneSetResponse[custom]" is missing from JSON.');
        assert(json[r'custom'] != null, 'Required key "ZoneSetResponse[custom]" has a null value in JSON.');
        assert(json.containsKey(r'reference'), 'Required key "ZoneSetResponse[reference]" is missing from JSON.');
        assert(json.containsKey(r'referenceSource'), 'Required key "ZoneSetResponse[referenceSource]" is missing from JSON.');
        assert(json.containsKey(r'zones'), 'Required key "ZoneSetResponse[zones]" is missing from JSON.');
        assert(json[r'zones'] != null, 'Required key "ZoneSetResponse[zones]" has a null value in JSON.');
        return true;
      }());

      return ZoneSetResponse(
        set_: mapValueOfType<String>(json, r'set')!,
        bounds: json[r'bounds'] is Iterable
            ? (json[r'bounds'] as Iterable).map((e) => (e as num).toDouble()).toList(growable: false)
            : const [],
        custom: mapValueOfType<bool>(json, r'custom')!,
        reference: mapValueOfType<int>(json, r'reference'),
        referenceSource: mapValueOfType<String>(json, r'referenceSource'),
        zones: ZoneTime.listFromJson(json[r'zones']),
      );
    }
    return null;
  }

  static List<ZoneSetResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ZoneSetResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ZoneSetResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ZoneSetResponse> mapFromJson(dynamic json) {
    final map = <String, ZoneSetResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ZoneSetResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ZoneSetResponse-objects as value to a dart map
  static Map<String, List<ZoneSetResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ZoneSetResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ZoneSetResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'set',
    'bounds',
    'custom',
    'reference',
    'referenceSource',
    'zones',
  };
}

