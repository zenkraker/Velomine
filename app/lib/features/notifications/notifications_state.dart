import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';

/// What the notifications screen renders, and what the bell badge reads.
class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.unread = 0,
    this.load = const CommandState.idle(),
    this.markAll = const CommandState.idle(),
    this.messages = const [],
  });

  final List<NotificationResponse> items;
  final int unread;
  final CommandState<ListNotificationsResponse?> load;
  final VoidCommand markAll;
  final List<UserMessage> messages;

  NotificationsState copyWith({
    List<NotificationResponse>? items,
    int? unread,
    CommandState<ListNotificationsResponse?>? load,
    VoidCommand? markAll,
    List<UserMessage>? messages,
  }) => NotificationsState(
    items: items ?? this.items,
    unread: unread ?? this.unread,
    load: load ?? this.load,
    markAll: markAll ?? this.markAll,
    messages: messages ?? this.messages,
  );
}
