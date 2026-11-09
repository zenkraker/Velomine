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

/// One bike with its parts, the types a part may have and the club's templates.
class BikeDetailState {
  const BikeDetailState({
    this.detail,
    this.types = const [],
    this.templates = const [],
    this.notFound = false,
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final BikeDetailResponse? detail;
  final List<ComponentTypeResponse> types;
  final List<BikeTemplateResponse> templates;
  final bool notFound;
  final CommandState<BikeDetailResponse?> load;

  /// A change to the bike or one of its parts.
  final VoidCommand action;
  final List<UserMessage> messages;

  BikeDetailState copyWith({
    BikeDetailResponse? detail,
    List<ComponentTypeResponse>? types,
    List<BikeTemplateResponse>? templates,
    bool? notFound,
    CommandState<BikeDetailResponse?>? load,
    VoidCommand? action,
    List<UserMessage>? messages,
  }) => BikeDetailState(
    detail: detail ?? this.detail,
    types: types ?? this.types,
    templates: templates ?? this.templates,
    notFound: notFound ?? this.notFound,
    load: load ?? this.load,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}
