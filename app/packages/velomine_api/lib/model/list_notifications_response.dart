//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ListNotificationsResponse {
  /// Returns a new [ListNotificationsResponse] instance.
  ListNotificationsResponse({
    this.notifications = const [],
    required this.unreadCount,
  });

  final List<NotificationResponse> notifications;

  final int unreadCount;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ListNotificationsResponse &&
    _deepEquality.equals(other.notifications, notifications) &&
    other.unreadCount == unreadCount;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (notifications.hashCode) +
    (unreadCount.hashCode);

  @override
  String toString() => 'ListNotificationsResponse[notifications=$notifications, unreadCount=$unreadCount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'notifications'] = this.notifications;
      json[r'unreadCount'] = this.unreadCount;
    return json;
  }

  /// Clones this instance of [ListNotificationsResponse] and returns a new one where some of the
  /// properties have changed.
  ListNotificationsResponse copyWith({
    List<NotificationResponse>? notifications,
    int? unreadCount,
  }) => ListNotificationsResponse(
    notifications: notifications ?? this.notifications,
    unreadCount: unreadCount ?? this.unreadCount,
  );

  /// Returns a new [ListNotificationsResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ListNotificationsResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'notifications'), 'Required key "ListNotificationsResponse[notifications]" is missing from JSON.');
        assert(json[r'notifications'] != null, 'Required key "ListNotificationsResponse[notifications]" has a null value in JSON.');
        assert(json.containsKey(r'unreadCount'), 'Required key "ListNotificationsResponse[unreadCount]" is missing from JSON.');
        assert(json[r'unreadCount'] != null, 'Required key "ListNotificationsResponse[unreadCount]" has a null value in JSON.');
        return true;
      }());

      return ListNotificationsResponse(
        notifications: NotificationResponse.listFromJson(json[r'notifications']),
        unreadCount: mapValueOfType<int>(json, r'unreadCount')!,
      );
    }
    return null;
  }

  static List<ListNotificationsResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListNotificationsResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListNotificationsResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ListNotificationsResponse> mapFromJson(dynamic json) {
    final map = <String, ListNotificationsResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ListNotificationsResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ListNotificationsResponse-objects as value to a dart map
  static Map<String, List<ListNotificationsResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ListNotificationsResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ListNotificationsResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'notifications',
    'unreadCount',
  };
}

