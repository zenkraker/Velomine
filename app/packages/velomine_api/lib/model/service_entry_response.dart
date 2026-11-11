//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ServiceEntryResponse {
  /// Returns a new [ServiceEntryResponse] instance.
  ServiceEntryResponse({
    required this.id,
    required this.date,
    required this.title,
    required this.notes,
    required this.place,
    required this.costAmount,
    required this.costCurrency,
    required this.componentId,
    required this.reminderId,
    required this.origin,
    required this.bikeDistanceM,
  });

  final String id;

  final DateTime date;

  final String title;

  final String? notes;

  final String? place;

  final double? costAmount;

  final String? costCurrency;

  final String? componentId;

  final String? reminderId;

  final String origin;

  final double bikeDistanceM;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ServiceEntryResponse &&
    other.id == id &&
    other.date == date &&
    other.title == title &&
    other.notes == notes &&
    other.place == place &&
    other.costAmount == costAmount &&
    other.costCurrency == costCurrency &&
    other.componentId == componentId &&
    other.reminderId == reminderId &&
    other.origin == origin &&
    other.bikeDistanceM == bikeDistanceM;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (date.hashCode) +
    (title.hashCode) +
    (notes == null ? 0 : notes!.hashCode) +
    (place == null ? 0 : place!.hashCode) +
    (costAmount == null ? 0 : costAmount!.hashCode) +
    (costCurrency == null ? 0 : costCurrency!.hashCode) +
    (componentId == null ? 0 : componentId!.hashCode) +
    (reminderId == null ? 0 : reminderId!.hashCode) +
    (origin.hashCode) +
    (bikeDistanceM.hashCode);

  @override
  String toString() => 'ServiceEntryResponse[id=$id, date=$date, title=$title, notes=$notes, place=$place, costAmount=$costAmount, costCurrency=$costCurrency, componentId=$componentId, reminderId=$reminderId, origin=$origin, bikeDistanceM=$bikeDistanceM]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'date'] = _dateFormatter.format(this.date);
      json[r'title'] = this.title;
    if (this.notes != null) {
      json[r'notes'] = this.notes;
    } else {
      json[r'notes'] = null;
    }
    if (this.place != null) {
      json[r'place'] = this.place;
    } else {
      json[r'place'] = null;
    }
    if (this.costAmount != null) {
      json[r'costAmount'] = this.costAmount;
    } else {
      json[r'costAmount'] = null;
    }
    if (this.costCurrency != null) {
      json[r'costCurrency'] = this.costCurrency;
    } else {
      json[r'costCurrency'] = null;
    }
    if (this.componentId != null) {
      json[r'componentId'] = this.componentId;
    } else {
      json[r'componentId'] = null;
    }
    if (this.reminderId != null) {
      json[r'reminderId'] = this.reminderId;
    } else {
      json[r'reminderId'] = null;
    }
      json[r'origin'] = this.origin;
      json[r'bikeDistanceM'] = this.bikeDistanceM;
    return json;
  }

  /// Clones this instance of [ServiceEntryResponse] and returns a new one where some of the
  /// properties have changed.
  ServiceEntryResponse copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? notes,
    bool notesSetToNull = false,
    String? place,
    bool placeSetToNull = false,
    double? costAmount,
    bool costAmountSetToNull = false,
    String? costCurrency,
    bool costCurrencySetToNull = false,
    String? componentId,
    bool componentIdSetToNull = false,
    String? reminderId,
    bool reminderIdSetToNull = false,
    String? origin,
    double? bikeDistanceM,
  }) => ServiceEntryResponse(
    id: id ?? this.id,
    date: date ?? this.date,
    title: title ?? this.title,
    notes: notesSetToNull ? null : notes ?? this.notes,
    place: placeSetToNull ? null : place ?? this.place,
    costAmount: costAmountSetToNull ? null : costAmount ?? this.costAmount,
    costCurrency: costCurrencySetToNull ? null : costCurrency ?? this.costCurrency,
    componentId: componentIdSetToNull ? null : componentId ?? this.componentId,
    reminderId: reminderIdSetToNull ? null : reminderId ?? this.reminderId,
    origin: origin ?? this.origin,
    bikeDistanceM: bikeDistanceM ?? this.bikeDistanceM,
  );

  /// Returns a new [ServiceEntryResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ServiceEntryResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "ServiceEntryResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "ServiceEntryResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'date'), 'Required key "ServiceEntryResponse[date]" is missing from JSON.');
        assert(json[r'date'] != null, 'Required key "ServiceEntryResponse[date]" has a null value in JSON.');
        assert(json.containsKey(r'title'), 'Required key "ServiceEntryResponse[title]" is missing from JSON.');
        assert(json[r'title'] != null, 'Required key "ServiceEntryResponse[title]" has a null value in JSON.');
        assert(json.containsKey(r'notes'), 'Required key "ServiceEntryResponse[notes]" is missing from JSON.');
        assert(json.containsKey(r'place'), 'Required key "ServiceEntryResponse[place]" is missing from JSON.');
        assert(json.containsKey(r'costAmount'), 'Required key "ServiceEntryResponse[costAmount]" is missing from JSON.');
        assert(json.containsKey(r'costCurrency'), 'Required key "ServiceEntryResponse[costCurrency]" is missing from JSON.');
        assert(json.containsKey(r'componentId'), 'Required key "ServiceEntryResponse[componentId]" is missing from JSON.');
        assert(json.containsKey(r'reminderId'), 'Required key "ServiceEntryResponse[reminderId]" is missing from JSON.');
        assert(json.containsKey(r'origin'), 'Required key "ServiceEntryResponse[origin]" is missing from JSON.');
        assert(json[r'origin'] != null, 'Required key "ServiceEntryResponse[origin]" has a null value in JSON.');
        assert(json.containsKey(r'bikeDistanceM'), 'Required key "ServiceEntryResponse[bikeDistanceM]" is missing from JSON.');
        assert(json[r'bikeDistanceM'] != null, 'Required key "ServiceEntryResponse[bikeDistanceM]" has a null value in JSON.');
        return true;
      }());

      return ServiceEntryResponse(
        id: mapValueOfType<String>(json, r'id')!,
        date: mapDateTime(json, r'date', r'')!,
        title: mapValueOfType<String>(json, r'title')!,
        notes: mapValueOfType<String>(json, r'notes'),
        place: mapValueOfType<String>(json, r'place'),
        costAmount: mapValueOfType<double>(json, r'costAmount'),
        costCurrency: mapValueOfType<String>(json, r'costCurrency'),
        componentId: mapValueOfType<String>(json, r'componentId'),
        reminderId: mapValueOfType<String>(json, r'reminderId'),
        origin: mapValueOfType<String>(json, r'origin')!,
        bikeDistanceM: mapValueOfType<double>(json, r'bikeDistanceM')!,
      );
    }
    return null;
  }

  static List<ServiceEntryResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ServiceEntryResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ServiceEntryResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ServiceEntryResponse> mapFromJson(dynamic json) {
    final map = <String, ServiceEntryResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ServiceEntryResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ServiceEntryResponse-objects as value to a dart map
  static Map<String, List<ServiceEntryResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ServiceEntryResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ServiceEntryResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'date',
    'title',
    'notes',
    'place',
    'costAmount',
    'costCurrency',
    'componentId',
    'reminderId',
    'origin',
    'bikeDistanceM',
  };
}

