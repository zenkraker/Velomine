//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ListServiceEntriesResponse {
  /// Returns a new [ListServiceEntriesResponse] instance.
  ListServiceEntriesResponse({
    this.entries = const [],
    required this.hasMore,
  });

  final List<ServiceEntryResponse> entries;

  final bool hasMore;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ListServiceEntriesResponse &&
    _deepEquality.equals(other.entries, entries) &&
    other.hasMore == hasMore;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (entries.hashCode) +
    (hasMore.hashCode);

  @override
  String toString() => 'ListServiceEntriesResponse[entries=$entries, hasMore=$hasMore]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'entries'] = this.entries;
      json[r'hasMore'] = this.hasMore;
    return json;
  }

  /// Clones this instance of [ListServiceEntriesResponse] and returns a new one where some of the
  /// properties have changed.
  ListServiceEntriesResponse copyWith({
    List<ServiceEntryResponse>? entries,
    bool? hasMore,
  }) => ListServiceEntriesResponse(
    entries: entries ?? this.entries,
    hasMore: hasMore ?? this.hasMore,
  );

  /// Returns a new [ListServiceEntriesResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ListServiceEntriesResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'entries'), 'Required key "ListServiceEntriesResponse[entries]" is missing from JSON.');
        assert(json[r'entries'] != null, 'Required key "ListServiceEntriesResponse[entries]" has a null value in JSON.');
        assert(json.containsKey(r'hasMore'), 'Required key "ListServiceEntriesResponse[hasMore]" is missing from JSON.');
        assert(json[r'hasMore'] != null, 'Required key "ListServiceEntriesResponse[hasMore]" has a null value in JSON.');
        return true;
      }());

      return ListServiceEntriesResponse(
        entries: ServiceEntryResponse.listFromJson(json[r'entries']),
        hasMore: mapValueOfType<bool>(json, r'hasMore')!,
      );
    }
    return null;
  }

  static List<ListServiceEntriesResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListServiceEntriesResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListServiceEntriesResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ListServiceEntriesResponse> mapFromJson(dynamic json) {
    final map = <String, ListServiceEntriesResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ListServiceEntriesResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ListServiceEntriesResponse-objects as value to a dart map
  static Map<String, List<ListServiceEntriesResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ListServiceEntriesResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ListServiceEntriesResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'entries',
    'hasMore',
  };
}

