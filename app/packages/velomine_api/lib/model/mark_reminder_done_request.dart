//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class MarkReminderDoneRequest {
  /// Returns a new [MarkReminderDoneRequest] instance.
  MarkReminderDoneRequest({
    this.doneOn = const Optional.absent(),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<DateTime?> doneOn;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MarkReminderDoneRequest &&
    other.doneOn == doneOn;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (doneOn == null ? 0 : doneOn!.hashCode);

  @override
  String toString() => 'MarkReminderDoneRequest[doneOn=$doneOn]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.doneOn.isPresent) {
      final value = this.doneOn.value;
      json[r'doneOn'] = value == null ? null : _dateFormatter.format(value);
    }
    return json;
  }

  /// Clones this instance of [MarkReminderDoneRequest] and returns a new one where some of the
  /// properties have changed.
  MarkReminderDoneRequest copyWith({
    Optional<DateTime?>? doneOn,
  }) => MarkReminderDoneRequest(
    doneOn: doneOn ?? this.doneOn,
  );

  /// Returns a new [MarkReminderDoneRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MarkReminderDoneRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return MarkReminderDoneRequest(
        doneOn: json.containsKey(r'doneOn') ? Optional.present(mapDateTime(json, r'doneOn', r'')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<MarkReminderDoneRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MarkReminderDoneRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MarkReminderDoneRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MarkReminderDoneRequest> mapFromJson(dynamic json) {
    final map = <String, MarkReminderDoneRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MarkReminderDoneRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MarkReminderDoneRequest-objects as value to a dart map
  static Map<String, List<MarkReminderDoneRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MarkReminderDoneRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MarkReminderDoneRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

