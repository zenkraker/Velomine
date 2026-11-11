import 'package:file_selector/file_selector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import '../../core/user_message.dart';
import 'routes_data.dart';
import 'routes_state.dart';

part 'routes_view_model.g.dart';

/// The club's route library. Route-scoped: it reloads when a screen needs it and is
/// rebuilt empty when the account changes.
@riverpod
class RoutesViewModel extends _$RoutesViewModel {
  @override
  RoutesState build() {
    if (ref.watch(signedInUserIdProvider) == null) return const RoutesState();
    Future.microtask(refresh);
    return const RoutesState();
  }

  Future<void> refresh() async {
    state = state.copyWith(load: state.load.start());
    final result = await ref
        .read(routesDataProvider)
        .list(sort: state.sort, surface: state.surface);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        routes: value,
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  void setSort(String sort) {
    if (sort == state.sort) return;
    state = state.copyWith(sort: sort);
    refresh();
  }

  void setSurface(String? surface) {
    if (surface == state.surface) return;
    state = state.copyWith(surface: surface, clearSurface: surface == null);
    refresh();
  }

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );
}

/// One route with its line, and what its owner may do with it.
@riverpod
class RouteDetailViewModel extends _$RouteDetailViewModel {
  int _messageId = 0;

  @override
  RouteDetailState build(String id) {
    Future.microtask(load);
    return const RouteDetailState();
  }

  Future<void> load() async {
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(routesDataProvider).route(id);
    if (!ref.mounted) return;
    if (result case Failed(:final failure)
        when failure.kind == FailureKind.missing) {
      state = state.copyWith(
        load: state.load.finish(const Ok(null)),
        notFound: true,
      );
      return;
    }
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        detail: value,
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  /// Takes the route out of the club library. It stays the member's own route.
  Future<bool> withdraw() =>
      _change(() => ref.read(routesDataProvider).withdraw(id));

  Future<bool> share() => _change(() => ref.read(routesDataProvider).share(id));

  Future<bool> delete() async {
    final result = await _run(() => ref.read(routesDataProvider).delete(id));
    return result?.isOk ?? false;
  }

  Future<bool> save({
    required String name,
    required String surface,
    String? description,
  }) async {
    final result = await _run(
      () => ref
          .read(routesDataProvider)
          .update(
            id,
            UpdateRouteRequest(
              name: name,
              surface: surface,
              description: description == null || description.trim().isEmpty
                  ? const Optional.absent()
                  : Optional.present(description.trim()),
            ),
          ),
    );
    return result?.isOk ?? false;
  }

  /// The GPX address, for the view to hand to the system browser.
  Future<String?> download() async {
    final result = await ref.read(routesDataProvider).downloadLink(id);
    if (!ref.mounted) return null;
    if (result case Failed(:final failure)) {
      _fail(failure);
      return null;
    }
    return result.valueOrNull?.path;
  }

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );

  Future<bool> _change(Future<Result<void>> Function() call) async =>
      (await _run(call))?.isOk ?? false;

  /// Runs a mutation, reloads the route and keeps a failure for the view to show.
  Future<Result<void>?> _run(Future<Result<void>> Function() call) async {
    state = state.copyWith(action: state.action.start());
    final result = await call();
    if (!ref.mounted) return result;
    state = state.copyWith(action: state.action.finish(result));
    if (result case Failed(:final failure)) _fail(failure);
    await load();
    return result;
  }

  void _fail(Failure failure) => state = state.copyWith(
    messages: [...state.messages, FailureMessage(_messageId++, failure)],
  );
}

/// Adding a route from one of the member's rides or from a GPX file.
@riverpod
class AddRouteViewModel extends _$AddRouteViewModel {
  int _messageId = 0;

  @override
  AddRouteState build() {
    Future.microtask(loadRides);
    return const AddRouteState();
  }

  Future<void> loadRides() async {
    state = state.copyWith(ridesLoad: state.ridesLoad.start());
    final result = await ref.read(routesDataProvider).readyRides();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        ridesLoad: state.ridesLoad.finish(result),
        rides: value,
      ),
      Failed() => state.copyWith(ridesLoad: state.ridesLoad.finish(result)),
    };
  }

  /// Reads one of the member's rides through the privacy rules and shows the line.
  Future<bool> fromRide(String rideId) async {
    state = state.copyWith(draftLoad: state.draftLoad.start());
    final result = await ref.read(routesDataProvider).rideDraft(rideId);
    if (!ref.mounted) return false;
    return _draft(result, rideId, null);
  }

  /// Reads a GPX file into a line; the file's own name becomes the suggestion.
  Future<bool> fromFile(XFile file) async {
    state = state.copyWith(draftLoad: state.draftLoad.start());
    final result = await ref.read(routesDataProvider).gpxDraft(file);
    if (!ref.mounted) return false;
    return _draft(result, null, result.valueOrNull?.name);
  }

  bool _draft(
    Result<RouteDraftResponse?> result,
    String? rideId,
    String? name,
  ) {
    state = state.copyWith(draftLoad: state.draftLoad.finish(result));
    if (result case Failed(:final failure)) {
      _fail(failure);
      return false;
    }
    state = state.copyWith(draft: result.valueOrNull, draftForRideId: rideId);
    return true;
  }

  /// Adds the line the member is looking at. The server measures it again.
  Future<String?> save({
    required String name,
    required String surface,
    String? description,
  }) async {
    final draft = state.draft;
    if (draft == null || state.action.running) return null;
    final request = CreateRouteRequest(
      name: name,
      surface: surface,
      description: description == null || description.trim().isEmpty
          ? const Optional.absent()
          : Optional.present(description.trim()),
      rideId: state.draftForRideId == null
          ? const Optional.absent()
          : Optional.present(state.draftForRideId),
      latitude: state.draftForRideId != null
          ? const Optional.absent()
          : Optional.present(draft.latitude),
      longitude: state.draftForRideId != null
          ? const Optional.absent()
          : Optional.present(draft.longitude),
      elevation: state.draftForRideId != null || draft.elevation == null
          ? const Optional.absent()
          : Optional.present(draft.elevation),
    );
    state = state.copyWith(action: state.action.start());
    final result = await ref.read(routesDataProvider).create(request);
    if (!ref.mounted) return null;
    state = state.copyWith(action: state.action.finish(result));
    if (result case Failed(:final failure)) {
      _fail(failure);
      return null;
    }
    return result.valueOrNull?.id;
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

/// Editing a route's details; the server returns the club's summary.
@riverpod
class RouteEditViewModel extends _$RouteEditViewModel {
  int _messageId = 0;

  @override
  RouteEditState build(String id) {
    Future.microtask(load);
    return const RouteEditState();
  }

  Future<void> load() async {
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(routesDataProvider).route(id);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        detail: value,
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  Future<bool> save({
    required String name,
    required String surface,
    String? description,
  }) async {
    state = state.copyWith(action: state.action.start());
    final result = await ref
        .read(routesDataProvider)
        .update(
          id,
          UpdateRouteRequest(
            name: name,
            surface: surface,
            description: description == null || description.trim().isEmpty
                ? const Optional.absent()
                : Optional.present(description.trim()),
          ),
        );
    if (!ref.mounted) return false;
    state = state.copyWith(action: state.action.finish(result));
    if (result case Failed(:final failure)) {
      state = state.copyWith(
        messages: [...state.messages, FailureMessage(_messageId++, failure)],
      );
      return false;
    }
    return true;
  }

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );
}
