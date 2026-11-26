//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class FtpCheckResponse {
  /// Returns a new [FtpCheckResponse] instance.
  FtpCheckResponse({
    required this.reason,
    required this.ftpW,
    required this.ftpAgeDays,
    required this.estimateW,
    required this.estimateMethod,
  });

  final String? reason;

  final int? ftpW;

  final int? ftpAgeDays;

  final int? estimateW;

  final String? estimateMethod;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FtpCheckResponse &&
    other.reason == reason &&
    other.ftpW == ftpW &&
    other.ftpAgeDays == ftpAgeDays &&
    other.estimateW == estimateW &&
    other.estimateMethod == estimateMethod;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (reason == null ? 0 : reason!.hashCode) +
    (ftpW == null ? 0 : ftpW!.hashCode) +
    (ftpAgeDays == null ? 0 : ftpAgeDays!.hashCode) +
    (estimateW == null ? 0 : estimateW!.hashCode) +
    (estimateMethod == null ? 0 : estimateMethod!.hashCode);

  @override
  String toString() => 'FtpCheckResponse[reason=$reason, ftpW=$ftpW, ftpAgeDays=$ftpAgeDays, estimateW=$estimateW, estimateMethod=$estimateMethod]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.reason != null) {
      json[r'reason'] = this.reason;
    } else {
      json[r'reason'] = null;
    }
    if (this.ftpW != null) {
      json[r'ftpW'] = this.ftpW;
    } else {
      json[r'ftpW'] = null;
    }
    if (this.ftpAgeDays != null) {
      json[r'ftpAgeDays'] = this.ftpAgeDays;
    } else {
      json[r'ftpAgeDays'] = null;
    }
    if (this.estimateW != null) {
      json[r'estimateW'] = this.estimateW;
    } else {
      json[r'estimateW'] = null;
    }
    if (this.estimateMethod != null) {
      json[r'estimateMethod'] = this.estimateMethod;
    } else {
      json[r'estimateMethod'] = null;
    }
    return json;
  }

  /// Clones this instance of [FtpCheckResponse] and returns a new one where some of the
  /// properties have changed.
  FtpCheckResponse copyWith({
    String? reason,
    bool reasonSetToNull = false,
    int? ftpW,
    bool ftpWSetToNull = false,
    int? ftpAgeDays,
    bool ftpAgeDaysSetToNull = false,
    int? estimateW,
    bool estimateWSetToNull = false,
    String? estimateMethod,
    bool estimateMethodSetToNull = false,
  }) => FtpCheckResponse(
    reason: reasonSetToNull ? null : reason ?? this.reason,
    ftpW: ftpWSetToNull ? null : ftpW ?? this.ftpW,
    ftpAgeDays: ftpAgeDaysSetToNull ? null : ftpAgeDays ?? this.ftpAgeDays,
    estimateW: estimateWSetToNull ? null : estimateW ?? this.estimateW,
    estimateMethod: estimateMethodSetToNull ? null : estimateMethod ?? this.estimateMethod,
  );

  /// Returns a new [FtpCheckResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FtpCheckResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'reason'), 'Required key "FtpCheckResponse[reason]" is missing from JSON.');
        assert(json.containsKey(r'ftpW'), 'Required key "FtpCheckResponse[ftpW]" is missing from JSON.');
        assert(json.containsKey(r'ftpAgeDays'), 'Required key "FtpCheckResponse[ftpAgeDays]" is missing from JSON.');
        assert(json.containsKey(r'estimateW'), 'Required key "FtpCheckResponse[estimateW]" is missing from JSON.');
        assert(json.containsKey(r'estimateMethod'), 'Required key "FtpCheckResponse[estimateMethod]" is missing from JSON.');
        return true;
      }());

      return FtpCheckResponse(
        reason: mapValueOfType<String>(json, r'reason'),
        ftpW: mapValueOfType<int>(json, r'ftpW'),
        ftpAgeDays: mapValueOfType<int>(json, r'ftpAgeDays'),
        estimateW: mapValueOfType<int>(json, r'estimateW'),
        estimateMethod: mapValueOfType<String>(json, r'estimateMethod'),
      );
    }
    return null;
  }

  static List<FtpCheckResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FtpCheckResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FtpCheckResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FtpCheckResponse> mapFromJson(dynamic json) {
    final map = <String, FtpCheckResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FtpCheckResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FtpCheckResponse-objects as value to a dart map
  static Map<String, List<FtpCheckResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FtpCheckResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FtpCheckResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'reason',
    'ftpW',
    'ftpAgeDays',
    'estimateW',
    'estimateMethod',
  };
}

