//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ProblemDetails {
  /// Returns a new [ProblemDetails] instance.
  ProblemDetails({
    this.type = const Optional.absent(),
    this.title = const Optional.absent(),
    this.status = const Optional.absent(),
    this.detail = const Optional.absent(),
    this.instance = const Optional.absent(),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> type;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> title;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> detail;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> instance;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ProblemDetails &&
    other.type == type &&
    other.title == title &&
    other.status == status &&
    other.detail == detail &&
    other.instance == instance;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (type == null ? 0 : type!.hashCode) +
    (title == null ? 0 : title!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (detail == null ? 0 : detail!.hashCode) +
    (instance == null ? 0 : instance!.hashCode);

  @override
  String toString() => 'ProblemDetails[type=$type, title=$title, status=$status, detail=$detail, instance=$instance]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.type.isPresent) {
      final value = this.type.value;
      json[r'type'] = value;
    }
    if (this.title.isPresent) {
      final value = this.title.value;
      json[r'title'] = value;
    }
    if (this.status.isPresent) {
      final value = this.status.value;
      json[r'status'] = value;
    }
    if (this.detail.isPresent) {
      final value = this.detail.value;
      json[r'detail'] = value;
    }
    if (this.instance.isPresent) {
      final value = this.instance.value;
      json[r'instance'] = value;
    }
    return json;
  }

  /// Clones this instance of [ProblemDetails] and returns a new one where some of the
  /// properties have changed.
  ProblemDetails copyWith({
    Optional<String?>? type,
    Optional<String?>? title,
    Optional<int?>? status,
    Optional<String?>? detail,
    Optional<String?>? instance,
  }) => ProblemDetails(
    type: type ?? this.type,
    title: title ?? this.title,
    status: status ?? this.status,
    detail: detail ?? this.detail,
    instance: instance ?? this.instance,
  );

  /// Returns a new [ProblemDetails] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProblemDetails? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return ProblemDetails(
        type: json.containsKey(r'type') ? Optional.present(mapValueOfType<String>(json, r'type')) : const Optional.absent(),
        title: json.containsKey(r'title') ? Optional.present(mapValueOfType<String>(json, r'title')) : const Optional.absent(),
        status: json.containsKey(r'status') ? Optional.present(json[r'status'] == null ? null : int.parse('${json[r'status']}')) : const Optional.absent(),
        detail: json.containsKey(r'detail') ? Optional.present(mapValueOfType<String>(json, r'detail')) : const Optional.absent(),
        instance: json.containsKey(r'instance') ? Optional.present(mapValueOfType<String>(json, r'instance')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<ProblemDetails> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ProblemDetails>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProblemDetails.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProblemDetails> mapFromJson(dynamic json) {
    final map = <String, ProblemDetails>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProblemDetails.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProblemDetails-objects as value to a dart map
  static Map<String, List<ProblemDetails>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ProblemDetails>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProblemDetails.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

