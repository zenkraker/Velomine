//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class BikeDetailResponse {
  /// Returns a new [BikeDetailResponse] instance.
  BikeDetailResponse({
    required this.bike,
    this.components = const [],
    this.reminders = const [],
  });

  final BikeResponse bike;

  final List<ComponentResponse> components;

  final List<MaintenanceReminderResponse> reminders;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BikeDetailResponse &&
    other.bike == bike &&
    _deepEquality.equals(other.components, components) &&
    _deepEquality.equals(other.reminders, reminders);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (bike.hashCode) +
    (components.hashCode) +
    (reminders.hashCode);

  @override
  String toString() => 'BikeDetailResponse[bike=$bike, components=$components, reminders=$reminders]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'bike'] = this.bike;
      json[r'components'] = this.components;
      json[r'reminders'] = this.reminders;
    return json;
  }

  /// Clones this instance of [BikeDetailResponse] and returns a new one where some of the
  /// properties have changed.
  BikeDetailResponse copyWith({
    BikeResponse? bike,
    List<ComponentResponse>? components,
    List<MaintenanceReminderResponse>? reminders,
  }) => BikeDetailResponse(
    bike: bike ?? this.bike,
    components: components ?? this.components,
    reminders: reminders ?? this.reminders,
  );

  /// Returns a new [BikeDetailResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BikeDetailResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'bike'), 'Required key "BikeDetailResponse[bike]" is missing from JSON.');
        assert(json[r'bike'] != null, 'Required key "BikeDetailResponse[bike]" has a null value in JSON.');
        assert(json.containsKey(r'components'), 'Required key "BikeDetailResponse[components]" is missing from JSON.');
        assert(json[r'components'] != null, 'Required key "BikeDetailResponse[components]" has a null value in JSON.');
        assert(json.containsKey(r'reminders'), 'Required key "BikeDetailResponse[reminders]" is missing from JSON.');
        assert(json[r'reminders'] != null, 'Required key "BikeDetailResponse[reminders]" has a null value in JSON.');
        return true;
      }());

      return BikeDetailResponse(
        bike: BikeResponse.fromJson(json[r'bike'])!,
        components: ComponentResponse.listFromJson(json[r'components']),
        reminders: MaintenanceReminderResponse.listFromJson(json[r'reminders']),
      );
    }
    return null;
  }

  static List<BikeDetailResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BikeDetailResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BikeDetailResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BikeDetailResponse> mapFromJson(dynamic json) {
    final map = <String, BikeDetailResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BikeDetailResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BikeDetailResponse-objects as value to a dart map
  static Map<String, List<BikeDetailResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<BikeDetailResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BikeDetailResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'bike',
    'components',
    'reminders',
  };
}

