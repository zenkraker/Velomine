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
    this.profile,
    this.heartRateSuggestions = const [],
    this.notFound = false,
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.feelCommand = const CommandState.idle(),
    this.fileLink = const CommandState.idle(),
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

  /// The member's profile, for the value a heart-rate note measured or the one a suggestion is above.
  final ProfileResponse? profile;

  /// The member's open heart-rate suggestions, to find the one this ride caused.
  final List<HeartRateSuggestionResponse> heartRateSuggestions;

  final bool notFound;
  final CommandState<RideResponse?> load;

  /// A change to the bike, the ride type or deleting the ride.
  final VoidCommand action;

  /// Saving or removing the ride feel.
  final VoidCommand feelCommand;

  /// Making the address the browser downloads the ride's file from.
  final CommandState<String?> fileLink;

  final List<UserMessage> messages;

  RideDetailState copyWith({
    RideResponse? ride,
    List<LapResponse>? laps,
    List<BikeResponse>? bikes,
    RideSeries? series,
    RideFeelResponse? feel,
    List<ShareViewResponse>? views,
    ProfileResponse? profile,
    List<HeartRateSuggestionResponse>? heartRateSuggestions,
    bool? notFound,
    CommandState<RideResponse?>? load,
    VoidCommand? action,
    VoidCommand? feelCommand,
    CommandState<String?>? fileLink,
    List<UserMessage>? messages,
  }) => RideDetailState(
    ride: ride ?? this.ride,
    laps: laps ?? this.laps,
    bikes: bikes ?? this.bikes,
    series: series ?? this.series,
    feel: feel ?? this.feel,
    views: views ?? this.views,
    profile: profile ?? this.profile,
    heartRateSuggestions: heartRateSuggestions ?? this.heartRateSuggestions,
    notFound: notFound ?? this.notFound,
    load: load ?? this.load,
    action: action ?? this.action,
    feelCommand: feelCommand ?? this.feelCommand,
    fileLink: fileLink ?? this.fileLink,
    messages: messages ?? this.messages,
  );
}
