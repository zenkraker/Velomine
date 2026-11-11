import 'package:flutter/widgets.dart';
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
  int _loadGeneration = 0;
  ScrollController? _scroll;
  double _offset = 0;

  /// The list's controller. It outlives the screen, so coming back to the tab lands where it left.
  ScrollController get scroll =>
      _scroll ??= (ScrollController()
        ..addListener(() => _offset = _scroll!.offset));

  double get scrollOffset => _offset;

  @override
  RidesState build() {
    // A rebuild registers this again; the controller is dropped once.
    ref.onDispose(() {
      final scroll = _scroll;
      _scroll = null;
      scroll?.dispose();
    });
    if (ref.watch(signedInUserIdProvider) == null) return const RidesState();
    Future.microtask(refresh);
    return const RidesState();
  }

  Future<void> refresh() async {
    final generation = ++_loadGeneration;
    state = state.copyWith(load: state.load.start());
    final result = await _page();
    if (!ref.mounted || generation != _loadGeneration) return;
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
    if (cursor == null) return;
    final generation = ++_loadGeneration;
    state = state.copyWith(load: state.load.start());
    final result = await _page(cursor: cursor);
    if (!ref.mounted || generation != _loadGeneration) return;
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

  /// Shows only the rides whose title or description contains [value]; empty shows every ride.
  Future<void> setQuery(String value) async {
    final query = value.trim();
    if (state.query == query) return;
    state = state.copyWith(query: query, clearNext: true);
    await refresh();
  }

  /// Shows only the rides on these days (both included), or every day when [value] is null.
  Future<void> setDateRange(DateSpan? value) async {
    if (state.dateRange == value) return;
    state = state.copyWith(
      dateRange: value,
      clearDateRange: value == null,
      clearNext: true,
    );
    await refresh();
  }

  /// Puts every filter back, so the whole list shows again.
  Future<void> clearFilters() async {
    if (!state.filtered) return;
    state = state.copyWith(
      query: '',
      clearDateRange: true,
      clearDisciplineFilter: true,
      clearNext: true,
    );
    await refresh();
  }

  Future<Result<RidesPage>> _page({String? cursor}) => ref
      .read(ridesDataProvider)
      .page(
        cursor: cursor,
        discipline: state.disciplineFilter,
        query: state.query,
        from: state.dateRange?.from,
        to: state.dateRange?.to,
      );

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

  /// Picks a Strava export, sends it, and returns its import id so the route can
  /// show the progress. The server reads the archive in the background.
  Future<String?> startImport() async {
    if (state.import.running) return null;
    final picked = await ref.read(importFilePickerProvider)();
    if (picked == null || !ref.mounted) return null;

    state = state.copyWith(import: state.import.start());
    final result = await ref.read(ridesDataProvider).startImport(picked);
    if (!ref.mounted) return null;
    state = state.copyWith(import: state.import.finish(result));
    if (result case Failed(:final failure)) {
      _fail(failure);
      return null;
    }
    return result.valueOrNull;
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
