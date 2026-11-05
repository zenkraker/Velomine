//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class NotificationResponse {
  /// Returns a new [NotificationResponse] instance.
  NotificationResponse({
    required this.id,
    required this.type,
    required this.subject,
    required this.rideId,
    required this.bikeId,
    required this.componentId,
    required this.aboutUserId,
    required this.createdAt,
    required this.isRead,
  });

  final String id;

  final String type;

  final String subject;

  final String? rideId;

  final String? bikeId;

  final String? componentId;

  final String? aboutUserId;

  final DateTime createdAt;

  final bool isRead;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotificationResponse &&
    other.id == id &&
    other.type == type &&
    other.subject == subject &&
    other.rideId == rideId &&
    other.bikeId == bikeId &&
    other.componentId == componentId &&
    other.aboutUserId == aboutUserId &&
    other.createdAt == createdAt &&
    other.isRead == isRead;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (type.hashCode) +
    (subject.hashCode) +
    (rideId == null ? 0 : rideId!.hashCode) +
    (bikeId == null ? 0 : bikeId!.hashCode) +
    (componentId == null ? 0 : componentId!.hashCode) +
    (aboutUserId == null ? 0 : aboutUserId!.hashCode) +
    (createdAt.hashCode) +
    (isRead.hashCode);

  @override
  String toString() => 'NotificationResponse[id=$id, type=$type, subject=$subject, rideId=$rideId, bikeId=$bikeId, componentId=$componentId, aboutUserId=$aboutUserId, createdAt=$createdAt, isRead=$isRead]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'type'] = this.type;
      json[r'subject'] = this.subject;
    if (this.rideId != null) {
      json[r'rideId'] = this.rideId;
    } else {
      json[r'rideId'] = null;
    }
    if (this.bikeId != null) {
      json[r'bikeId'] = this.bikeId;
    } else {
      json[r'bikeId'] = null;
    }
    if (this.componentId != null) {
      json[r'componentId'] = this.componentId;
    } else {
      json[r'componentId'] = null;
    }
    if (this.aboutUserId != null) {
      json[r'aboutUserId'] = this.aboutUserId;
    } else {
      json[r'aboutUserId'] = null;
    }
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
      json[r'isRead'] = this.isRead;
    return json;
  }

  /// Clones this instance of [NotificationResponse] and returns a new one where some of the
  /// properties have changed.
  NotificationResponse copyWith({
    String? id,
    String? type,
    String? subject,
    String? rideId,
    bool rideIdSetToNull = false,
    String? bikeId,
    bool bikeIdSetToNull = false,
    String? componentId,
    bool componentIdSetToNull = false,
    String? aboutUserId,
    bool aboutUserIdSetToNull = false,
    DateTime? createdAt,
    bool? isRead,
  }) => NotificationResponse(
    id: id ?? this.id,
    type: type ?? this.type,
    subject: subject ?? this.subject,
    rideId: rideIdSetToNull ? null : rideId ?? this.rideId,
    bikeId: bikeIdSetToNull ? null : bikeId ?? this.bikeId,
    componentId: componentIdSetToNull ? null : componentId ?? this.componentId,
    aboutUserId: aboutUserIdSetToNull ? null : aboutUserId ?? this.aboutUserId,
    createdAt: createdAt ?? this.createdAt,
    isRead: isRead ?? this.isRead,
  );

  /// Returns a new [NotificationResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotificationResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "NotificationResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "NotificationResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'type'), 'Required key "NotificationResponse[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "NotificationResponse[type]" has a null value in JSON.');
        assert(json.containsKey(r'subject'), 'Required key "NotificationResponse[subject]" is missing from JSON.');
        assert(json[r'subject'] != null, 'Required key "NotificationResponse[subject]" has a null value in JSON.');
        assert(json.containsKey(r'rideId'), 'Required key "NotificationResponse[rideId]" is missing from JSON.');
        assert(json.containsKey(r'bikeId'), 'Required key "NotificationResponse[bikeId]" is missing from JSON.');
        assert(json.containsKey(r'componentId'), 'Required key "NotificationResponse[componentId]" is missing from JSON.');
        assert(json.containsKey(r'aboutUserId'), 'Required key "NotificationResponse[aboutUserId]" is missing from JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "NotificationResponse[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "NotificationResponse[createdAt]" has a null value in JSON.');
        assert(json.containsKey(r'isRead'), 'Required key "NotificationResponse[isRead]" is missing from JSON.');
        assert(json[r'isRead'] != null, 'Required key "NotificationResponse[isRead]" has a null value in JSON.');
        return true;
      }());

      return NotificationResponse(
        id: mapValueOfType<String>(json, r'id')!,
        type: mapValueOfType<String>(json, r'type')!,
        subject: mapValueOfType<String>(json, r'subject')!,
        rideId: mapValueOfType<String>(json, r'rideId'),
        bikeId: mapValueOfType<String>(json, r'bikeId'),
        componentId: mapValueOfType<String>(json, r'componentId'),
        aboutUserId: mapValueOfType<String>(json, r'aboutUserId'),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        isRead: mapValueOfType<bool>(json, r'isRead')!,
      );
    }
    return null;
  }

  static List<NotificationResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotificationResponse> mapFromJson(dynamic json) {
    final map = <String, NotificationResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotificationResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotificationResponse-objects as value to a dart map
  static Map<String, List<NotificationResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotificationResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotificationResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'type',
    'subject',
    'rideId',
    'bikeId',
    'componentId',
    'aboutUserId',
    'createdAt',
    'isRead',
  };
}

