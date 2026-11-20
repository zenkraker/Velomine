//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class IntensityResponse {
  /// Returns a new [IntensityResponse] instance.
  IntensityResponse({
    required this.easyS,
    required this.moderateS,
    required this.hardS,
    required this.easyPct,
    required this.moderatePct,
    required this.hardPct,
    required this.polarisationIndex,
    required this.label,
    required this.rides,
    this.heartRateZoneModel = const Optional.absent(),
    this.heartRateZoneReferenceBpm = const Optional.absent(),
    this.heartRateZoneReferenceSource = const Optional.absent(),
  });

  final double easyS;

  final double moderateS;

  final double hardS;

  final double easyPct;

  final double moderatePct;

  final double hardPct;

  final double? polarisationIndex;

  final String label;

  final int rides;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> heartRateZoneModel;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> heartRateZoneReferenceBpm;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> heartRateZoneReferenceSource;

  @override
  bool operator ==(Object other) => identical(this, other) || other is IntensityResponse &&
    other.easyS == easyS &&
    other.moderateS == moderateS &&
    other.hardS == hardS &&
    other.easyPct == easyPct &&
    other.moderatePct == moderatePct &&
    other.hardPct == hardPct &&
    other.polarisationIndex == polarisationIndex &&
    other.label == label &&
    other.rides == rides &&
    other.heartRateZoneModel == heartRateZoneModel &&
    other.heartRateZoneReferenceBpm == heartRateZoneReferenceBpm &&
    other.heartRateZoneReferenceSource == heartRateZoneReferenceSource;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (easyS.hashCode) +
    (moderateS.hashCode) +
    (hardS.hashCode) +
    (easyPct.hashCode) +
    (moderatePct.hashCode) +
    (hardPct.hashCode) +
    (polarisationIndex == null ? 0 : polarisationIndex!.hashCode) +
    (label.hashCode) +
    (rides.hashCode) +
    (heartRateZoneModel == null ? 0 : heartRateZoneModel!.hashCode) +
    (heartRateZoneReferenceBpm == null ? 0 : heartRateZoneReferenceBpm!.hashCode) +
    (heartRateZoneReferenceSource == null ? 0 : heartRateZoneReferenceSource!.hashCode);

  @override
  String toString() => 'IntensityResponse[easyS=$easyS, moderateS=$moderateS, hardS=$hardS, easyPct=$easyPct, moderatePct=$moderatePct, hardPct=$hardPct, polarisationIndex=$polarisationIndex, label=$label, rides=$rides, heartRateZoneModel=$heartRateZoneModel, heartRateZoneReferenceBpm=$heartRateZoneReferenceBpm, heartRateZoneReferenceSource=$heartRateZoneReferenceSource]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'easyS'] = this.easyS;
      json[r'moderateS'] = this.moderateS;
      json[r'hardS'] = this.hardS;
      json[r'easyPct'] = this.easyPct;
      json[r'moderatePct'] = this.moderatePct;
      json[r'hardPct'] = this.hardPct;
    if (this.polarisationIndex != null) {
      json[r'polarisationIndex'] = this.polarisationIndex;
    } else {
      json[r'polarisationIndex'] = null;
    }
      json[r'label'] = this.label;
      json[r'rides'] = this.rides;
    if (this.heartRateZoneModel.isPresent) {
      final value = this.heartRateZoneModel.value;
      json[r'heartRateZoneModel'] = value;
    }
    if (this.heartRateZoneReferenceBpm.isPresent) {
      final value = this.heartRateZoneReferenceBpm.value;
      json[r'heartRateZoneReferenceBpm'] = value;
    }
    if (this.heartRateZoneReferenceSource.isPresent) {
      final value = this.heartRateZoneReferenceSource.value;
      json[r'heartRateZoneReferenceSource'] = value;
    }
    return json;
  }

  /// Clones this instance of [IntensityResponse] and returns a new one where some of the
  /// properties have changed.
  IntensityResponse copyWith({
    double? easyS,
    double? moderateS,
    double? hardS,
    double? easyPct,
    double? moderatePct,
    double? hardPct,
    double? polarisationIndex,
    bool polarisationIndexSetToNull = false,
    String? label,
    int? rides,
    Optional<String?>? heartRateZoneModel,
    Optional<int?>? heartRateZoneReferenceBpm,
    Optional<String?>? heartRateZoneReferenceSource,
  }) => IntensityResponse(
    easyS: easyS ?? this.easyS,
    moderateS: moderateS ?? this.moderateS,
    hardS: hardS ?? this.hardS,
    easyPct: easyPct ?? this.easyPct,
    moderatePct: moderatePct ?? this.moderatePct,
    hardPct: hardPct ?? this.hardPct,
    polarisationIndex: polarisationIndexSetToNull ? null : polarisationIndex ?? this.polarisationIndex,
    label: label ?? this.label,
    rides: rides ?? this.rides,
    heartRateZoneModel: heartRateZoneModel ?? this.heartRateZoneModel,
    heartRateZoneReferenceBpm: heartRateZoneReferenceBpm ?? this.heartRateZoneReferenceBpm,
    heartRateZoneReferenceSource: heartRateZoneReferenceSource ?? this.heartRateZoneReferenceSource,
  );

  /// Returns a new [IntensityResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static IntensityResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'easyS'), 'Required key "IntensityResponse[easyS]" is missing from JSON.');
        assert(json[r'easyS'] != null, 'Required key "IntensityResponse[easyS]" has a null value in JSON.');
        assert(json.containsKey(r'moderateS'), 'Required key "IntensityResponse[moderateS]" is missing from JSON.');
        assert(json[r'moderateS'] != null, 'Required key "IntensityResponse[moderateS]" has a null value in JSON.');
        assert(json.containsKey(r'hardS'), 'Required key "IntensityResponse[hardS]" is missing from JSON.');
        assert(json[r'hardS'] != null, 'Required key "IntensityResponse[hardS]" has a null value in JSON.');
        assert(json.containsKey(r'easyPct'), 'Required key "IntensityResponse[easyPct]" is missing from JSON.');
        assert(json[r'easyPct'] != null, 'Required key "IntensityResponse[easyPct]" has a null value in JSON.');
        assert(json.containsKey(r'moderatePct'), 'Required key "IntensityResponse[moderatePct]" is missing from JSON.');
        assert(json[r'moderatePct'] != null, 'Required key "IntensityResponse[moderatePct]" has a null value in JSON.');
        assert(json.containsKey(r'hardPct'), 'Required key "IntensityResponse[hardPct]" is missing from JSON.');
        assert(json[r'hardPct'] != null, 'Required key "IntensityResponse[hardPct]" has a null value in JSON.');
        assert(json.containsKey(r'polarisationIndex'), 'Required key "IntensityResponse[polarisationIndex]" is missing from JSON.');
        assert(json.containsKey(r'label'), 'Required key "IntensityResponse[label]" is missing from JSON.');
        assert(json[r'label'] != null, 'Required key "IntensityResponse[label]" has a null value in JSON.');
        assert(json.containsKey(r'rides'), 'Required key "IntensityResponse[rides]" is missing from JSON.');
        assert(json[r'rides'] != null, 'Required key "IntensityResponse[rides]" has a null value in JSON.');
        return true;
      }());

      return IntensityResponse(
        easyS: mapValueOfType<double>(json, r'easyS')!,
        moderateS: mapValueOfType<double>(json, r'moderateS')!,
        hardS: mapValueOfType<double>(json, r'hardS')!,
        easyPct: mapValueOfType<double>(json, r'easyPct')!,
        moderatePct: mapValueOfType<double>(json, r'moderatePct')!,
        hardPct: mapValueOfType<double>(json, r'hardPct')!,
        polarisationIndex: mapValueOfType<double>(json, r'polarisationIndex'),
        label: mapValueOfType<String>(json, r'label')!,
        rides: mapValueOfType<int>(json, r'rides')!,
        heartRateZoneModel: json.containsKey(r'heartRateZoneModel') ? Optional.present(mapValueOfType<String>(json, r'heartRateZoneModel')) : const Optional.absent(),
        heartRateZoneReferenceBpm: json.containsKey(r'heartRateZoneReferenceBpm') ? Optional.present(json[r'heartRateZoneReferenceBpm'] == null ? null : int.parse('${json[r'heartRateZoneReferenceBpm']}')) : const Optional.absent(),
        heartRateZoneReferenceSource: json.containsKey(r'heartRateZoneReferenceSource') ? Optional.present(mapValueOfType<String>(json, r'heartRateZoneReferenceSource')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<IntensityResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <IntensityResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = IntensityResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, IntensityResponse> mapFromJson(dynamic json) {
    final map = <String, IntensityResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = IntensityResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of IntensityResponse-objects as value to a dart map
  static Map<String, List<IntensityResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<IntensityResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = IntensityResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'easyS',
    'moderateS',
    'hardS',
    'easyPct',
    'moderatePct',
    'hardPct',
    'polarisationIndex',
    'label',
    'rides',
  };
}

