//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class UpdateSettingsRequest {
  /// Returns a new [UpdateSettingsRequest] instance.
  UpdateSettingsRequest({
    required this.signUpEnabled,
    required this.requireAdminApproval,
    this.clubCreationEnabled = const Optional.absent(),
  });

  final bool signUpEnabled;

  final bool requireAdminApproval;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> clubCreationEnabled;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UpdateSettingsRequest &&
    other.signUpEnabled == signUpEnabled &&
    other.requireAdminApproval == requireAdminApproval &&
    other.clubCreationEnabled == clubCreationEnabled;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (signUpEnabled.hashCode) +
    (requireAdminApproval.hashCode) +
    (clubCreationEnabled == null ? 0 : clubCreationEnabled!.hashCode);

  @override
  String toString() => 'UpdateSettingsRequest[signUpEnabled=$signUpEnabled, requireAdminApproval=$requireAdminApproval, clubCreationEnabled=$clubCreationEnabled]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'signUpEnabled'] = this.signUpEnabled;
      json[r'requireAdminApproval'] = this.requireAdminApproval;
    if (this.clubCreationEnabled.isPresent) {
      final value = this.clubCreationEnabled.value;
      json[r'clubCreationEnabled'] = value;
    }
    return json;
  }

  /// Clones this instance of [UpdateSettingsRequest] and returns a new one where some of the
  /// properties have changed.
  UpdateSettingsRequest copyWith({
    bool? signUpEnabled,
    bool? requireAdminApproval,
    Optional<bool?>? clubCreationEnabled,
  }) => UpdateSettingsRequest(
    signUpEnabled: signUpEnabled ?? this.signUpEnabled,
    requireAdminApproval: requireAdminApproval ?? this.requireAdminApproval,
    clubCreationEnabled: clubCreationEnabled ?? this.clubCreationEnabled,
  );

  /// Returns a new [UpdateSettingsRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateSettingsRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'signUpEnabled'), 'Required key "UpdateSettingsRequest[signUpEnabled]" is missing from JSON.');
        assert(json[r'signUpEnabled'] != null, 'Required key "UpdateSettingsRequest[signUpEnabled]" has a null value in JSON.');
        assert(json.containsKey(r'requireAdminApproval'), 'Required key "UpdateSettingsRequest[requireAdminApproval]" is missing from JSON.');
        assert(json[r'requireAdminApproval'] != null, 'Required key "UpdateSettingsRequest[requireAdminApproval]" has a null value in JSON.');
        return true;
      }());

      return UpdateSettingsRequest(
        signUpEnabled: mapValueOfType<bool>(json, r'signUpEnabled')!,
        requireAdminApproval: mapValueOfType<bool>(json, r'requireAdminApproval')!,
        clubCreationEnabled: json.containsKey(r'clubCreationEnabled') ? Optional.present(mapValueOfType<bool>(json, r'clubCreationEnabled')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<UpdateSettingsRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UpdateSettingsRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateSettingsRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateSettingsRequest> mapFromJson(dynamic json) {
    final map = <String, UpdateSettingsRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateSettingsRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateSettingsRequest-objects as value to a dart map
  static Map<String, List<UpdateSettingsRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UpdateSettingsRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateSettingsRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'signUpEnabled',
    'requireAdminApproval',
  };
}

