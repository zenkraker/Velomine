//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class CreateServiceEntryRequest {
  /// Returns a new [CreateServiceEntryRequest] instance.
  CreateServiceEntryRequest({
    required this.date,
    required this.title,
    this.notes = const Optional.absent(),
    this.place = const Optional.absent(),
    this.costAmount = const Optional.absent(),
    this.costCurrency = const Optional.absent(),
    this.componentId = const Optional.absent(),
    this.reminderId = const Optional.absent(),
  });

  final DateTime date;

  final String title;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> notes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> place;

  /// Minimum value: 0
  /// Maximum value: 1000000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<double?> costAmount;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> costCurrency;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> componentId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> reminderId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreateServiceEntryRequest &&
    other.date == date &&
    other.title == title &&
    other.notes == notes &&
    other.place == place &&
    other.costAmount == costAmount &&
    other.costCurrency == costCurrency &&
    other.componentId == componentId &&
    other.reminderId == reminderId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (date.hashCode) +
    (title.hashCode) +
    (notes == null ? 0 : notes!.hashCode) +
    (place == null ? 0 : place!.hashCode) +
    (costAmount == null ? 0 : costAmount!.hashCode) +
    (costCurrency == null ? 0 : costCurrency!.hashCode) +
    (componentId == null ? 0 : componentId!.hashCode) +
    (reminderId == null ? 0 : reminderId!.hashCode);

  @override
  String toString() => 'CreateServiceEntryRequest[date=$date, title=$title, notes=$notes, place=$place, costAmount=$costAmount, costCurrency=$costCurrency, componentId=$componentId, reminderId=$reminderId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'date'] = _dateFormatter.format(this.date);
      json[r'title'] = this.title;
    if (this.notes.isPresent) {
      final value = this.notes.value;
      json[r'notes'] = value;
    }
    if (this.place.isPresent) {
      final value = this.place.value;
      json[r'place'] = value;
    }
    if (this.costAmount.isPresent) {
      final value = this.costAmount.value;
      json[r'costAmount'] = value;
    }
    if (this.costCurrency.isPresent) {
      final value = this.costCurrency.value;
      json[r'costCurrency'] = value;
    }
    if (this.componentId.isPresent) {
      final value = this.componentId.value;
      json[r'componentId'] = value;
    }
    if (this.reminderId.isPresent) {
      final value = this.reminderId.value;
      json[r'reminderId'] = value;
    }
    return json;
  }

  /// Clones this instance of [CreateServiceEntryRequest] and returns a new one where some of the
  /// properties have changed.
  CreateServiceEntryRequest copyWith({
    DateTime? date,
    String? title,
    Optional<String?>? notes,
    Optional<String?>? place,
    Optional<double?>? costAmount,
    Optional<String?>? costCurrency,
    Optional<String?>? componentId,
    Optional<String?>? reminderId,
  }) => CreateServiceEntryRequest(
    date: date ?? this.date,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    place: place ?? this.place,
    costAmount: costAmount ?? this.costAmount,
    costCurrency: costCurrency ?? this.costCurrency,
    componentId: componentId ?? this.componentId,
    reminderId: reminderId ?? this.reminderId,
  );

  /// Returns a new [CreateServiceEntryRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateServiceEntryRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'date'), 'Required key "CreateServiceEntryRequest[date]" is missing from JSON.');
        assert(json[r'date'] != null, 'Required key "CreateServiceEntryRequest[date]" has a null value in JSON.');
        assert(json.containsKey(r'title'), 'Required key "CreateServiceEntryRequest[title]" is missing from JSON.');
        assert(json[r'title'] != null, 'Required key "CreateServiceEntryRequest[title]" has a null value in JSON.');
        return true;
      }());

      return CreateServiceEntryRequest(
        date: mapDateTime(json, r'date', r'')!,
        title: mapValueOfType<String>(json, r'title')!,
        notes: json.containsKey(r'notes') ? Optional.present(mapValueOfType<String>(json, r'notes')) : const Optional.absent(),
        place: json.containsKey(r'place') ? Optional.present(mapValueOfType<String>(json, r'place')) : const Optional.absent(),
        costAmount: json.containsKey(r'costAmount') ? Optional.present(mapValueOfType<double>(json, r'costAmount')) : const Optional.absent(),
        costCurrency: json.containsKey(r'costCurrency') ? Optional.present(mapValueOfType<String>(json, r'costCurrency')) : const Optional.absent(),
        componentId: json.containsKey(r'componentId') ? Optional.present(mapValueOfType<String>(json, r'componentId')) : const Optional.absent(),
        reminderId: json.containsKey(r'reminderId') ? Optional.present(mapValueOfType<String>(json, r'reminderId')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<CreateServiceEntryRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateServiceEntryRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateServiceEntryRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateServiceEntryRequest> mapFromJson(dynamic json) {
    final map = <String, CreateServiceEntryRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateServiceEntryRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateServiceEntryRequest-objects as value to a dart map
  static Map<String, List<CreateServiceEntryRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreateServiceEntryRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateServiceEntryRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'date',
    'title',
  };
}

