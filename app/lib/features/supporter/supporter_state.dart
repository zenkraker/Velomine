import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';

/// The member's optional supporter licence, and the operations on it.
class SupporterState {
  const SupporterState({
    this.available = false,
    this.riderLicence,
    this.load = const CommandState.idle(),
    this.activate = const CommandState.idle(),
    this.hidden = const CommandState.idle(),
    this.messages = const [],
  });

  /// Whether this server can activate a licence at all; false leaves the
  /// profile with no entry and no badge.
  final bool available;
  final RiderLicenceResponse? riderLicence;
  final CommandState<SupporterStatusResponse?> load;

  /// The last activation. Its value is the licence the celebration shows.
  final CommandState<SupporterStatusResponse?> activate;
  final CommandState<RiderLicenceResponse?> hidden;
  final List<UserMessage> messages;

  /// The badge is shown only when the member has a licence and has not hidden it.
  bool get badgeShown => riderLicence?.hidden == false;

  /// "Become a supporter" shows only where the server can take a key and the
  /// member has no licence yet.
  bool get becomeSupporter => available && riderLicence == null;

  SupporterState copyWith({
    bool? available,
    RiderLicenceResponse? riderLicence,
    CommandState<SupporterStatusResponse?>? load,
    CommandState<SupporterStatusResponse?>? activate,
    CommandState<RiderLicenceResponse?>? hidden,
    List<UserMessage>? messages,
  }) => SupporterState(
    available: available ?? this.available,
    riderLicence: riderLicence ?? this.riderLicence,
    load: load ?? this.load,
    activate: activate ?? this.activate,
    hidden: hidden ?? this.hidden,
    messages: messages ?? this.messages,
  );
}
