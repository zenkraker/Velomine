import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';
import 'sharing_data.dart';

/// What the member shares with their club, and who has looked.
class SharingState {
  const SharingState({
    this.rides = 'none',
    this.analytics = 'none',
    this.routes = 'none',
    this.wellbeing = 'none',
    this.views = const [],
    this.loaded = false,
    this.load = const CommandState.idle(),
    this.save = const CommandState.idle(),
    this.messages = const [],
  });

  final String rides;
  final String analytics;
  final String routes;
  final String wellbeing;
  final List<ShareViewResponse> views;
  final bool loaded;
  final CommandState<SharingBundle> load;
  final VoidCommand save;
  final List<UserMessage> messages;

  SharingState copyWith({
    String? rides,
    String? analytics,
    String? routes,
    String? wellbeing,
    List<ShareViewResponse>? views,
    bool? loaded,
    CommandState<SharingBundle>? load,
    VoidCommand? save,
    List<UserMessage>? messages,
  }) => SharingState(
    rides: rides ?? this.rides,
    analytics: analytics ?? this.analytics,
    routes: routes ?? this.routes,
    wellbeing: wellbeing ?? this.wellbeing,
    views: views ?? this.views,
    loaded: loaded ?? this.loaded,
    load: load ?? this.load,
    save: save ?? this.save,
    messages: messages ?? this.messages,
  );
}
