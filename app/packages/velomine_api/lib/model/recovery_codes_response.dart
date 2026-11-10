//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class RecoveryCodesResponse {
  /// Returns a new [RecoveryCodesResponse] instance.
  RecoveryCodesResponse({
    this.recoveryCodes = const [],
  });

  final List<String> recoveryCodes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecoveryCodesResponse &&
    _deepEquality.equals(other.recoveryCodes, recoveryCodes);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (recoveryCodes.hashCode);

  @override
  String toString() => 'RecoveryCodesResponse[recoveryCodes=$recoveryCodes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'recoveryCodes'] = this.recoveryCodes;
    return json;
  }

  /// Clones this instance of [RecoveryCodesResponse] and returns a new one where some of the
  /// properties have changed.
  RecoveryCodesResponse copyWith({
    List<String>? recoveryCodes,
  }) => RecoveryCodesResponse(
    recoveryCodes: recoveryCodes ?? this.recoveryCodes,
  );

  /// Returns a new [RecoveryCodesResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecoveryCodesResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'recoveryCodes'), 'Required key "RecoveryCodesResponse[recoveryCodes]" is missing from JSON.');
        assert(json[r'recoveryCodes'] != null, 'Required key "RecoveryCodesResponse[recoveryCodes]" has a null value in JSON.');
        return true;
      }());

      return RecoveryCodesResponse(
        recoveryCodes: json[r'recoveryCodes'] is Iterable
            ? (json[r'recoveryCodes'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<RecoveryCodesResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecoveryCodesResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecoveryCodesResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecoveryCodesResponse> mapFromJson(dynamic json) {
    final map = <String, RecoveryCodesResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecoveryCodesResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecoveryCodesResponse-objects as value to a dart map
  static Map<String, List<RecoveryCodesResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecoveryCodesResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecoveryCodesResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'recoveryCodes',
  };
}

