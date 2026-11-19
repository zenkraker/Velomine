//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ListHeartRateSuggestionsResponse {
  /// Returns a new [ListHeartRateSuggestionsResponse] instance.
  ListHeartRateSuggestionsResponse({
    this.suggestions = const [],
  });

  final List<HeartRateSuggestionResponse> suggestions;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ListHeartRateSuggestionsResponse &&
    _deepEquality.equals(other.suggestions, suggestions);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (suggestions.hashCode);

  @override
  String toString() => 'ListHeartRateSuggestionsResponse[suggestions=$suggestions]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'suggestions'] = this.suggestions;
    return json;
  }

  /// Clones this instance of [ListHeartRateSuggestionsResponse] and returns a new one where some of the
  /// properties have changed.
  ListHeartRateSuggestionsResponse copyWith({
    List<HeartRateSuggestionResponse>? suggestions,
  }) => ListHeartRateSuggestionsResponse(
    suggestions: suggestions ?? this.suggestions,
  );

  /// Returns a new [ListHeartRateSuggestionsResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ListHeartRateSuggestionsResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'suggestions'), 'Required key "ListHeartRateSuggestionsResponse[suggestions]" is missing from JSON.');
        assert(json[r'suggestions'] != null, 'Required key "ListHeartRateSuggestionsResponse[suggestions]" has a null value in JSON.');
        return true;
      }());

      return ListHeartRateSuggestionsResponse(
        suggestions: HeartRateSuggestionResponse.listFromJson(json[r'suggestions']),
      );
    }
    return null;
  }

  static List<ListHeartRateSuggestionsResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListHeartRateSuggestionsResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListHeartRateSuggestionsResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ListHeartRateSuggestionsResponse> mapFromJson(dynamic json) {
    final map = <String, ListHeartRateSuggestionsResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ListHeartRateSuggestionsResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ListHeartRateSuggestionsResponse-objects as value to a dart map
  static Map<String, List<ListHeartRateSuggestionsResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ListHeartRateSuggestionsResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ListHeartRateSuggestionsResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'suggestions',
  };
}

