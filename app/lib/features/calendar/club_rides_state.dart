import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';

/// The club calendar: what is coming and what has just happened.
class ClubRidesState {
  const ClubRidesState({
    this.upcoming = const [],
    this.past = const [],
    this.load = const CommandState.idle(),
    this.messages = const [],
  });

  final List<ClubRideSummaryResponse> upcoming;
  final List<ClubRideSummaryResponse> past;
  final CommandState<ClubRideListResponse?> load;
  final List<UserMessage> messages;

  ClubRidesState copyWith({
    List<ClubRideSummaryResponse>? upcoming,
    List<ClubRideSummaryResponse>? past,
    CommandState<ClubRideListResponse?>? load,
    List<UserMessage>? messages,
  }) => ClubRidesState(
    upcoming: upcoming ?? this.upcoming,
    past: past ?? this.past,
    load: load ?? this.load,
    messages: messages ?? this.messages,
  );
}

/// One ride with its meeting point, route and who is in.
class ClubRideDetailState {
  const ClubRideDetailState({
    this.detail,
    this.notFound = false,
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final ClubRideDetailResponse? detail;
  final bool notFound;
  final CommandState<ClubRideDetailResponse?> load;
  final CommandState<ClubRideDetailResponse?> action;
  final List<UserMessage> messages;

  ClubRideDetailState copyWith({
    ClubRideDetailResponse? detail,
    bool? notFound,
    CommandState<ClubRideDetailResponse?>? load,
    CommandState<ClubRideDetailResponse?>? action,
    List<UserMessage>? messages,
  }) => ClubRideDetailState(
    detail: detail ?? this.detail,
    notFound: notFound ?? this.notFound,
    load: load ?? this.load,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}

/// Planning a ride, or changing one; the routes to choose from come from the club library.
class PlanRideState {
  const PlanRideState({
    this.detail,
    this.routes = const [],
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final ClubRideDetailResponse? detail;
  final List<RouteSummaryResponse> routes;
  final CommandState<void> load;
  final CommandState<ClubRideDetailResponse?> action;
  final List<UserMessage> messages;

  PlanRideState copyWith({
    ClubRideDetailResponse? detail,
    List<RouteSummaryResponse>? routes,
    CommandState<void>? load,
    CommandState<ClubRideDetailResponse?>? action,
    List<UserMessage>? messages,
  }) => PlanRideState(
    detail: detail ?? this.detail,
    routes: routes ?? this.routes,
    load: load ?? this.load,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}

/// The member's private calendar address; the address itself is only known right after it is made.
class CalendarFeedState {
  const CalendarFeedState({
    this.active = false,
    this.createdAt,
    this.address,
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final bool active;
  final DateTime? createdAt;
  final String? address;
  final CommandState<CalendarFeedStatusResponse?> load;
  final VoidCommand action;
  final List<UserMessage> messages;

  CalendarFeedState copyWith({
    bool? active,
    DateTime? createdAt,
    String? address,
    bool clearAddress = false,
    CommandState<CalendarFeedStatusResponse?>? load,
    VoidCommand? action,
    List<UserMessage>? messages,
  }) => CalendarFeedState(
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
    address: clearAddress ? null : address ?? this.address,
    load: load ?? this.load,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}
