import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';

/// The member's bikes.
class BikesState {
  const BikesState({
    this.bikes = const [],
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final List<BikeResponse> bikes;
  final CommandState<List<BikeResponse>> load;
  final VoidCommand action;
  final List<UserMessage> messages;

  BikesState copyWith({
    List<BikeResponse>? bikes,
    CommandState<List<BikeResponse>>? load,
    VoidCommand? action,
    List<UserMessage>? messages,
  }) => BikesState(
    bikes: bikes ?? this.bikes,
    load: load ?? this.load,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}

/// One bike with its parts and service: the types a part may have, the club's templates, the common jobs
/// that fit the bike and its service log.
class BikeDetailState {
  const BikeDetailState({
    this.detail,
    this.types = const [],
    this.templates = const [],
    this.jobs = const [],
    this.log = const [],
    this.logHasMore = false,
    this.logComponentId,
    this.logLoad = const CommandState.idle(),
    this.notFound = false,
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final BikeDetailResponse? detail;
  final List<ComponentTypeResponse> types;
  final List<BikeTemplateResponse> templates;

  /// The common maintenance jobs that fit this kind of bike.
  final List<MaintenanceJob> jobs;

  /// The service log, newest first; [logHasMore] says another page waits.
  final List<ServiceEntryResponse> log;
  final bool logHasMore;

  /// Only the entries about this part, or all of them when null.
  final String? logComponentId;
  final VoidCommand logLoad;
  final bool notFound;
  final CommandState<BikeDetailResponse?> load;

  /// A change to the bike or one of its parts.
  final VoidCommand action;
  final List<UserMessage> messages;

  BikeDetailState copyWith({
    BikeDetailResponse? detail,
    List<ComponentTypeResponse>? types,
    List<BikeTemplateResponse>? templates,
    List<MaintenanceJob>? jobs,
    List<ServiceEntryResponse>? log,
    bool? logHasMore,
    String? logComponentId,
    bool clearLogFilter = false,
    VoidCommand? logLoad,
    bool? notFound,
    CommandState<BikeDetailResponse?>? load,
    VoidCommand? action,
    List<UserMessage>? messages,
  }) => BikeDetailState(
    detail: detail ?? this.detail,
    types: types ?? this.types,
    templates: templates ?? this.templates,
    jobs: jobs ?? this.jobs,
    log: log ?? this.log,
    logHasMore: logHasMore ?? this.logHasMore,
    logComponentId: clearLogFilter
        ? null
        : (logComponentId ?? this.logComponentId),
    logLoad: logLoad ?? this.logLoad,
    notFound: notFound ?? this.notFound,
    load: load ?? this.load,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}
