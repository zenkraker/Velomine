import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import '../../core/user_message.dart';
import 'rides_data.dart';
import 'rides_state.dart';

part 'rides_view_model.g.dart';

/// The member's rides: filtering, paging, uploading, and following an upload
/// until the server has read it.
@Riverpod(keepAlive: true)
class RidesViewModel extends _$RidesViewModel {
  static const _watchAttempts = 120;

  int _messageId = 0;

  @override
  RidesState build() {
    if (ref.watch(signedInUserIdProvider) == null) return const RidesState();
    Future.microtask(refresh);
    return const RidesState();
  }

  Future<void> refresh() async {
    if (state.load.running) return;
    state = state.copyWith(load: state.load.start());
    final result = await ref
        .read(ridesDataProvider)
        .page(discipline: state.disciplineFilter);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        rides: value.rides,
        next: value.next,
        clearNext: value.next == null,
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  Future<void> loadMore() async {
    final cursor = state.next;
    if (cursor == null || state.load.running) return;
    state = state.copyWith(load: state.load.start());
    final result = await ref
        .read(ridesDataProvider)
        .page(cursor: cursor, discipline: state.disciplineFilter);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        rides: [...state.rides, ...value.rides],
        next: value.next,
        clearNext: value.next == null,
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  /// Shows only one surface, or every ride when [value] is null.
  Future<void> setDisciplineFilter(String? value) async {
    if (state.disciplineFilter == value) return;
    state = state.copyWith(
      disciplineFilter: value,
      clearDisciplineFilter: value == null,
      clearNext: true,
    );
    await refresh();
  }

  /// Picks a file, uploads it, then watches the ride until the server has read it.
  Future<void> upload() async {
    if (state.upload.running) return;
    final picked = await ref.read(filePickerProvider)();
    if (picked == null || !ref.mounted) return;

    state = state.copyWith(upload: state.upload.start());
    final result = await ref.read(ridesDataProvider).upload(picked);
    if (!ref.mounted) return;
    state = state.copyWith(upload: state.upload.finish(result));
    if (result case Failed(:final failure)) {
      _fail(failure);
      return;
    }
    final rideId = result.valueOrNull;
    if (rideId == null) return;

    await refresh();
    await _watch(rideId);
  }

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );

  /// The server reads uploads in the background; ask until the ride is no
  /// longer "processing".
  Future<void> _watch(String id) async {
    final interval = ref.read(ridePollIntervalProvider);
    for (var i = 0; i < _watchAttempts; i++) {
      await Future<void>.delayed(interval);
      if (!ref.mounted) return;
      final result = await ref.read(ridesDataProvider).ride(id);
      if (!ref.mounted) return;
      if (result case Failed()) return;
      final ride = result.valueOrNull;
      if (ride == null) return;

      final index = state.rides.indexWhere((r) => r.id == id);
      if (index >= 0) {
        state = state.copyWith(rides: [...state.rides]..[index] = ride);
      }
      if (ride.status != 'processing') {
        if (index < 0) await refresh();
        return;
      }
    }
  }

  void _fail(Failure failure) => state = state.copyWith(
    messages: [...state.messages, FailureMessage(_messageId++, failure)],
  );
}
