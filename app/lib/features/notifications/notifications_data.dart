import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';

part 'notifications_data.g.dart';

/// The notification endpoints as values: the ViewModel never sees an exception.
class NotificationsData {
  NotificationsData(this._api);

  final NotificationsApi _api;

  Future<Result<ListNotificationsResponse?>> list() =>
      _api.listNotifications().guard(FailureAction.loadNotifications);

  Future<Result<void>> markRead(String id) =>
      _api.markNotificationRead(id).guard(FailureAction.markRead);

  Future<Result<void>> markAllRead() =>
      _api.markAllNotificationsRead().guard(FailureAction.markAllRead);
}

@Riverpod(keepAlive: true)
NotificationsData notificationsData(Ref ref) =>
    NotificationsData(ref.watch(sessionProvider).notifications);
