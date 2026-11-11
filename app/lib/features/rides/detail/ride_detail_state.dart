import 'package:velomine_api/api.dart';

import '../../../core/command.dart';
import '../../../core/user_message.dart';
import 'ride_series.dart';

/// One ride: its numbers, its samples for the charts and map, and how it felt.
class RideDetailState {
  const RideDetailState({
    this.ride,
    this.laps = const [],
    this.bikes = const [],
    this.series,
    this.feel,
    this.views,
    this.notFound = false,
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.feelCommand = const CommandState.idle(),
    this.messages = const [],
  });

  final RideResponse? ride;

  /// The ride's laps, empty when the file has none or they could not be loaded.
  final List<LapResponse> laps;

  /// The member's bikes, to pick the one ridden. Empty when they could not be
  /// loaded: the ride still shows.
  final List<BikeResponse> bikes;

  final RideSeries? series;

  /// How the ride felt, owned by this member.
  final RideFeelResponse? feel;

  /// Who looked at this ride, most recent first; null when it could not be loaded.
  final List<ShareViewResponse>? views;

  final bool notFound;
  final CommandState<RideResponse?> load;

  /// A change to the bike, the ride type or deleting the ride.
  final VoidCommand action;

  /// Saving or removing the ride feel.
  final VoidCommand feelCommand;

  final List<UserMessage> messages;

  RideDetailState copyWith({
    RideResponse? ride,
    List<LapResponse>? laps,
    List<BikeResponse>? bikes,
    RideSeries? series,
    RideFeelResponse? feel,
    List<ShareViewResponse>? views,
    bool? notFound,
    CommandState<RideResponse?>? load,
    VoidCommand? action,
    VoidCommand? feelCommand,
    List<UserMessage>? messages,
  }) => RideDetailState(
    ride: ride ?? this.ride,
    laps: laps ?? this.laps,
    bikes: bikes ?? this.bikes,
    series: series ?? this.series,
    feel: feel ?? this.feel,
    views: views ?? this.views,
    notFound: notFound ?? this.notFound,
    load: load ?? this.load,
    action: action ?? this.action,
    feelCommand: feelCommand ?? this.feelCommand,
    messages: messages ?? this.messages,
  );
}
