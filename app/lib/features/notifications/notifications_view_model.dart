import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/failure.dart';

import 'package:velomine_api/api.dart';

import '../../core/providers.dart';
import '../../core/result.dart';
import '../../core/user_message.dart';
import 'notifications_data.dart';
import 'notifications_state.dart';

part 'notifications_view_model.g.dart';

/// How often the bell is refreshed while signed in. A server notification has no
/// push channel, so this is the one place a timer is allowed.
final notificationPollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(minutes: 1),
);

/// The member's notifications and unread count. Kept alive while signed in so the
/// bell has news without opening the screen; a sign-out rebuilds it empty.
@Riverpod(keepAlive: true)
class NotificationsViewModel extends _$NotificationsViewModel {
  int _messageId = 0;
  Timer? _timer;

  @override
  NotificationsState build() {
    final userId = ref.watch(signedInUserIdProvider);
    _timer?.cancel();
    _timer = null;
    ref.onDispose(() => _timer?.cancel());

    if (userId == null) return const NotificationsState();

    _timer = Timer.periodic(
      ref.watch(notificationPollIntervalProvider),
      (_) => refresh(),
    );
    Future.microtask(refresh);
    return const NotificationsState();
  }

  Future<void> refresh() async {
    if (state.load.running) return;
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(notificationsDataProvider).list();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        items: value?.notifications ?? const [],
        unread: value?.unreadCount ?? 0,
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  Future<void> markRead(NotificationResponse n) async {
    if (n.isRead) return;
    final result = await ref.read(notificationsDataProvider).markRead(n.id);
    if (!ref.mounted) return;
    if (result case Failed(:final failure)) {
      _fail(failure);
      return;
    }
    state = state.copyWith(
      items: [
        for (final item in state.items)
          item.id == n.id ? item.copyWith(isRead: true) : item,
      ],
      unread: state.unread > 0 ? state.unread - 1 : 0,
    );
  }

  Future<void> markAllRead() async {
    if (state.markAll.running) return;
    state = state.copyWith(markAll: state.markAll.start());
    final result = await ref.read(notificationsDataProvider).markAllRead();
    if (!ref.mounted) return;
    if (result case Failed(:final failure)) {
      state = state.copyWith(markAll: state.markAll.finish(result));
      _fail(failure);
      return;
    }
    state = state.copyWith(
      markAll: state.markAll.finish(result),
      items: [for (final item in state.items) item.copyWith(isRead: true)],
      unread: 0,
    );
  }

  /// The view has shown this message; drop it so it is not shown twice.
  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );

  void _fail(Failure failure) => state = state.copyWith(
    messages: [...state.messages, FailureMessage(_messageId++, failure)],
  );
}
