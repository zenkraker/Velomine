import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';

/// The member's own privacy choices and the places whose surroundings are hidden.
class PrivacyState {
  const PrivacyState({
    this.privacy,
    this.loaded = false,
    this.load = const CommandState.idle(),
    this.save = const CommandState.idle(),
    this.messages = const [],
  });

  final PrivacyResponse? privacy;
  final bool loaded;
  final CommandState<PrivacyResponse?> load;
  final VoidCommand save;
  final List<UserMessage> messages;

  PrivacyState copyWith({
    PrivacyResponse? privacy,
    bool? loaded,
    CommandState<PrivacyResponse?>? load,
    VoidCommand? save,
    List<UserMessage>? messages,
  }) => PrivacyState(
    privacy: privacy ?? this.privacy,
    loaded: loaded ?? this.loaded,
    load: load ?? this.load,
    save: save ?? this.save,
    messages: messages ?? this.messages,
  );
}
