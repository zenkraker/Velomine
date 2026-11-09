import '../../core/command.dart';
import '../../core/location_service.dart';
import '../../core/user_message.dart';

import 'package:velomine_api/api.dart';

/// Where the position shown on the nearby page came from.
enum NearbyOrigin { device, saved, none }

/// Clubs within reach, the one open ask, and how the position was found.
class NearbyClubsState {
  const NearbyClubsState({
    this.clubs = const [],
    this.request,
    this.position,
    this.origin = NearbyOrigin.none,
    this.locating = false,
    this.askedDevice = false,
    this.radiusKm = 50,
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final List<NearbyClubResponse> clubs;
  final PendingJoinRequestResponse? request;
  final GeoPoint? position;
  final NearbyOrigin origin;

  /// The device lookup is in flight.
  final bool locating;

  /// The device could not help and the rider has not picked a point yet.
  final bool askedDevice;

  final int radiusKm;
  final CommandState<NearbyClubsResponse?> load;
  final VoidCommand action;
  final List<UserMessage> messages;

  bool get usingSavedPoint => origin == NearbyOrigin.saved && position != null;

  NearbyClubsState copyWith({
    List<NearbyClubResponse>? clubs,
    PendingJoinRequestResponse? request,
    bool clearRequest = false,
    GeoPoint? position,
    NearbyOrigin? origin,
    bool? locating,
    bool? askedDevice,
    int? radiusKm,
    CommandState<NearbyClubsResponse?>? load,
    VoidCommand? action,
    List<UserMessage>? messages,
  }) => NearbyClubsState(
    clubs: clubs ?? this.clubs,
    request: clearRequest ? null : (request ?? this.request),
    position: position ?? this.position,
    origin: origin ?? this.origin,
    locating: locating ?? this.locating,
    askedDevice: askedDevice ?? this.askedDevice,
    radiusKm: radiusKm ?? this.radiusKm,
    load: load ?? this.load,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}
