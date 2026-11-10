//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class TwoFactorState {
  /// Returns a new [TwoFactorState] instance.
  TwoFactorState({
    required this.enabled,
    required this.hasPassword,
  });

  final bool enabled;

  final bool hasPassword;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TwoFactorState &&
    other.enabled == enabled &&
    other.hasPassword == hasPassword;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (enabled.hashCode) +
    (hasPassword.hashCode);

  @override
  String toString() => 'TwoFactorState[enabled=$enabled, hasPassword=$hasPassword]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'enabled'] = this.enabled;
      json[r'hasPassword'] = this.hasPassword;
    return json;
  }

  /// Clones this instance of [TwoFactorState] and returns a new one where some of the
  /// properties have changed.
  TwoFactorState copyWith({
    bool? enabled,
    bool? hasPassword,
  }) => TwoFactorState(
    enabled: enabled ?? this.enabled,
    hasPassword: hasPassword ?? this.hasPassword,
  );

  /// Returns a new [TwoFactorState] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TwoFactorState? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'enabled'), 'Required key "TwoFactorState[enabled]" is missing from JSON.');
        assert(json[r'enabled'] != null, 'Required key "TwoFactorState[enabled]" has a null value in JSON.');
        assert(json.containsKey(r'hasPassword'), 'Required key "TwoFactorState[hasPassword]" is missing from JSON.');
        assert(json[r'hasPassword'] != null, 'Required key "TwoFactorState[hasPassword]" has a null value in JSON.');
        return true;
      }());

      return TwoFactorState(
        enabled: mapValueOfType<bool>(json, r'enabled')!,
        hasPassword: mapValueOfType<bool>(json, r'hasPassword')!,
      );
    }
    return null;
  }

  static List<TwoFactorState> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TwoFactorState>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TwoFactorState.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TwoFactorState> mapFromJson(dynamic json) {
    final map = <String, TwoFactorState>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TwoFactorState.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TwoFactorState-objects as value to a dart map
  static Map<String, List<TwoFactorState>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TwoFactorState>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TwoFactorState.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'enabled',
    'hasPassword',
  };
}

