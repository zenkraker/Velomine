import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/result.dart';
import '../../core/user_message.dart';
import '../club/club_view_model.dart';
import 'sharing_data.dart';
import 'sharing_state.dart';

part 'sharing_view_model.g.dart';

/// The member's choices for what the club may see. Loaded when a club is known,
/// and emptied when the club is left or the account changes.
@Riverpod(keepAlive: true)
class SharingViewModel extends _$SharingViewModel {
  int _messageId = 0;

  @override
  SharingState build() {
    final clubId = ref.watch(clubViewModelProvider.select((s) => s.club?.id));
    if (clubId == null) return const SharingState();
    Future.microtask(load);
    return const SharingState();
  }

  Future<void> load() async {
    if (state.load.running) return;
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(sharingDataProvider).load();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        rides: value.sharing?.rides ?? state.rides,
        analytics: value.sharing?.analytics ?? state.analytics,
        routes: value.sharing?.routes ?? state.routes,
        wellbeing: value.sharing?.wellbeing ?? state.wellbeing,
        views: value.views?.views ?? const [],
        loaded: true,
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  /// Saves one change, keeping the other choices as they are. Routes are a map
  /// on shared rides: turning rides off turns them off too.
  Future<void> choose({
    String? rides,
    String? analytics,
    String? routes,
    String? wellbeing,
  }) async {
    if (state.save.running) return;
    final nextRides = rides ?? state.rides;
    final nextAnalytics = analytics ?? state.analytics;
    final nextRoutes = nextRides == 'none' ? 'none' : (routes ?? state.routes);
    final nextWellbeing = wellbeing ?? state.wellbeing;

    state = state.copyWith(save: state.save.start());
    final result = await ref
        .read(sharingDataProvider)
        .update(
          UpdateSharingRequest(
            rides: nextRides,
            analytics: nextAnalytics,
            routes: nextRoutes,
            wellbeing: nextWellbeing,
          ),
        );
    if (!ref.mounted) return;
    if (result case Failed(:final failure)) {
      state = state.copyWith(save: state.save.finish(result));
      _fail(failure);
      return;
    }
    state = state.copyWith(
      save: state.save.finish(result),
      rides: nextRides,
      analytics: nextAnalytics,
      routes: nextRoutes,
      wellbeing: nextWellbeing,
      loaded: true,
    );
  }

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
