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
    this.type = const Optional.present('https://www.rfc-editor.org/rfc/rfc7231#section-6.5.1'),
    this.title = const Optional.present('One or more validation errors occurred.'),
    this.status = const Optional.present(400),
    this.instance = const Optional.present('/api/route'),
    this.traceId = const Optional.present('0HMPNHL0JHL76:00000001'),
    this.detail = const Optional.absent(),
    this.errors = const Optional.present(const []),
  });

  final Optional<String?> type;

  final Optional<String?> title;

  final Optional<int?> status;

  final Optional<String?> instance;

  final Optional<String?> traceId;

  /// the details of the error
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> detail;

  final Optional<List<ProblemDetailsErrorsInner>?> errors;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ProblemDetails &&
    other.type == type &&
    other.title == title &&
    other.status == status &&
    other.instance == instance &&
    other.traceId == traceId &&
    other.detail == detail &&
    _deepEquality.equals(other.errors, errors);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (type.hashCode) +
    (title.hashCode) +
    (status.hashCode) +
    (instance.hashCode) +
    (traceId.hashCode) +
    (detail == null ? 0 : detail!.hashCode) +
    (errors.hashCode);

  @override
  String toString() => 'ProblemDetails[type=$type, title=$title, status=$status, instance=$instance, traceId=$traceId, detail=$detail, errors=$errors]';

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
    if (this.instance.isPresent) {
      final value = this.instance.value;
      json[r'instance'] = value;
    }
    if (this.traceId.isPresent) {
      final value = this.traceId.value;
      json[r'traceId'] = value;
    }
    if (this.detail.isPresent) {
      final value = this.detail.value;
      json[r'detail'] = value;
    }
    if (this.errors.isPresent) {
      final value = this.errors.value;
      json[r'errors'] = value;
    }
    return json;
  }

  /// Clones this instance of [ProblemDetails] and returns a new one where some of the
  /// properties have changed.
  ProblemDetails copyWith({
    Optional<String?>? type,
    Optional<String?>? title,
    Optional<int?>? status,
    Optional<String?>? instance,
    Optional<String?>? traceId,
    Optional<String?>? detail,
    Optional<List<ProblemDetailsErrorsInner>?>? errors,
  }) => ProblemDetails(
    type: type ?? this.type,
    title: title ?? this.title,
    status: status ?? this.status,
    instance: instance ?? this.instance,
    traceId: traceId ?? this.traceId,
    detail: detail ?? this.detail,
    errors: errors ?? this.errors,
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
        instance: json.containsKey(r'instance') ? Optional.present(mapValueOfType<String>(json, r'instance')) : const Optional.absent(),
        traceId: json.containsKey(r'traceId') ? Optional.present(mapValueOfType<String>(json, r'traceId')) : const Optional.absent(),
        detail: json.containsKey(r'detail') ? Optional.present(mapValueOfType<String>(json, r'detail')) : const Optional.absent(),
        errors: json.containsKey(r'errors') ? Optional.present(ProblemDetailsErrorsInner.listFromJson(json[r'errors'])) : const Optional.absent(),
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

