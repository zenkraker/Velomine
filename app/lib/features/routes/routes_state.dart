import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';

const routeSurfaceIds = ['road', 'gravel', 'mountain', 'mixed'];
const routeSortIds = ['newest', 'shortest', 'longest'];

/// The club's route library, with the order and the surface the member asked for.
class RoutesState {
  const RoutesState({
    this.routes = const [],
    this.sort = 'newest',
    this.surface,
    this.load = const CommandState.idle(),
    this.messages = const [],
  });

  final List<RouteSummaryResponse> routes;
  final String sort;
  final String? surface;
  final CommandState<List<RouteSummaryResponse>> load;
  final List<UserMessage> messages;

  RoutesState copyWith({
    List<RouteSummaryResponse>? routes,
    String? sort,
    String? surface,
    bool clearSurface = false,
    CommandState<List<RouteSummaryResponse>>? load,
    List<UserMessage>? messages,
  }) => RoutesState(
    routes: routes ?? this.routes,
    sort: sort ?? this.sort,
    surface: clearSurface ? null : surface ?? this.surface,
    load: load ?? this.load,
    messages: messages ?? this.messages,
  );
}

/// One route with its line.
class RouteDetailState {
  const RouteDetailState({
    this.detail,
    this.notFound = false,
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final RouteDetailResponse? detail;
  final bool notFound;
  final CommandState<RouteDetailResponse?> load;
  final VoidCommand action;
  final List<UserMessage> messages;

  RouteDetailState copyWith({
    RouteDetailResponse? detail,
    bool? notFound,
    CommandState<RouteDetailResponse?>? load,
    VoidCommand? action,
    List<UserMessage>? messages,
  }) => RouteDetailState(
    detail: detail ?? this.detail,
    notFound: notFound ?? this.notFound,
    load: load ?? this.load,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}

/// Adding a route: the member's rides to take a line from, or a GPX file, then the line as it will be stored.
class AddRouteState {
  const AddRouteState({
    this.rides = const [],
    this.ridesLoad = const CommandState.idle(),
    this.draft,
    this.draftForRideId,
    this.draftLoad = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final List<RideResponse> rides;
  final CommandState<List<RideResponse>> ridesLoad;

  /// The line as it will be stored, with the privacy rules already applied.
  final RouteDraftResponse? draft;
  final String? draftForRideId;
  final CommandState<RouteDraftResponse?> draftLoad;
  final CommandState<RouteDetailResponse?> action;
  final List<UserMessage> messages;

  AddRouteState copyWith({
    List<RideResponse>? rides,
    CommandState<List<RideResponse>>? ridesLoad,
    RouteDraftResponse? draft,
    String? draftForRideId,
    CommandState<RouteDraftResponse?>? draftLoad,
    CommandState<RouteDetailResponse?>? action,
    List<UserMessage>? messages,
  }) => AddRouteState(
    rides: rides ?? this.rides,
    ridesLoad: ridesLoad ?? this.ridesLoad,
    draft: draft ?? this.draft,
    draftForRideId: draftForRideId ?? this.draftForRideId,
    draftLoad: draftLoad ?? this.draftLoad,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}

/// Changing a route's name, description and surface. The line never changes.
class RouteEditState {
  const RouteEditState({
    this.detail,
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final RouteDetailResponse? detail;
  final CommandState<RouteDetailResponse?> load;
  final CommandState<RouteSummaryResponse?> action;
  final List<UserMessage> messages;

  RouteEditState copyWith({
    RouteDetailResponse? detail,
    CommandState<RouteDetailResponse?>? load,
    CommandState<RouteSummaryResponse?>? action,
    List<UserMessage>? messages,
  }) => RouteEditState(
    detail: detail ?? this.detail,
    load: load ?? this.load,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}
