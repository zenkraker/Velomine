import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/failure.dart';
import '../../core/home_location.dart';
import '../../core/location_service.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import '../../core/user_message.dart';
import 'club_data.dart';
import 'nearby_clubs_state.dart';

part 'nearby_clubs_view_model.g.dart';

/// Clubs within reach of the rider and the one open join request.
///
/// The position flow lives here: the device first, then the point saved on this
/// phone. The screen only navigates to the map picker and hands back a point.
@Riverpod(keepAlive: true)
class NearbyClubsViewModel extends _$NearbyClubsViewModel {
  static const radii = [25, 50, 100, 200];

  int _messageId = 0;

  @override
  NearbyClubsState build() {
    final userId = ref.watch(signedInUserIdProvider);
    if (userId == null) return const NearbyClubsState();
    Future.microtask(_loadRequest);
    return const NearbyClubsState();
  }

  /// The open ask, without needing a position: the club tab shows it too.
  Future<void> _loadRequest() async {
    final result = await ref.read(clubDataProvider).myJoinRequest();
    if (!ref.mounted) return;
    if (result case Ok(:final value)) {
      state = state.copyWith(request: value?.request);
    }
  }

  /// Finds a position for the page: the device first, then the saved point.
  Future<void> start() async {
    if (state.locating) return;
    state = state.copyWith(locating: true, askedDevice: false);

    final device = await ref.read(locationServiceProvider).current();
    if (!ref.mounted) return;
    if (device != null) {
      await usePoint(device);
      return;
    }

    final saved = await _savedPoint();
    if (!ref.mounted) return;
    if (saved != null) {
      await usePoint(saved, fromSaved: true);
      return;
    }

    state = state.copyWith(
      locating: false,
      askedDevice: true,
      origin: NearbyOrigin.none,
    );
  }

  /// Uses a point the rider picked on the map and saves it as the fallback.
  Future<void> useSavedPoint(GeoPoint point) async {
    final userId = ref.read(signedInUserIdProvider);
    final home = ref.read(homeLocationViewModelProvider.notifier);
    if (userId != null) {
      await home.load(userId);
      await home.save(point);
    }
    if (!ref.mounted) return;
    await usePoint(point, fromSaved: true);
  }

  Future<void> usePoint(GeoPoint point, {bool fromSaved = false}) async {
    state = state.copyWith(
      position: point,
      locating: false,
      askedDevice: false,
      origin: fromSaved ? NearbyOrigin.saved : NearbyOrigin.device,
    );
    await refresh();
  }

  Future<void> refresh() async {
    final position = state.position;
    if (position == null || state.load.running) return;

    state = state.copyWith(load: state.load.start());
    final result = await ref
        .read(clubDataProvider)
        .nearby(position, state.radiusKm);
    if (!ref.mounted) return;
    if (result case Failed()) {
      state = state.copyWith(load: state.load.finish(result));
      return;
    }

    state = state.copyWith(
      load: state.load.finish(result),
      clubs: result.valueOrNull?.clubs ?? const [],
    );
    final mine = await ref.read(clubDataProvider).myJoinRequest();
    if (!ref.mounted) return;
    if (mine case Ok(:final value)) {
      state = state.copyWith(request: value?.request);
    }
  }

  Future<void> setRadius(int radiusKm) async {
    if (radiusKm == state.radiusKm || state.load.running) return;
    state = state.copyWith(radiusKm: radiusKm);
    await refresh();
  }

  /// The next wider radius, or null when the widest is already shown.
  int? nextRadius() => radii.where((r) => r > state.radiusKm).firstOrNull;

  Future<bool> askToJoin(String clubId, String? note) async {
    if (state.action.running) return false;
    state = state.copyWith(action: state.action.start());
    final result = await ref.read(clubDataProvider).requestToJoin(clubId, note);
    if (!ref.mounted) return false;
    if (result case Failed(:final failure)) {
      state = state.copyWith(action: state.action.finish(result));
      _fail(failure);
      return false;
    }
    state = state.copyWith(
      action: state.action.finish(result),
      request: result.valueOrNull?.request,
      messages: [...state.messages, RequestSentMessage(_messageId++)],
    );
    return true;
  }

  Future<bool> cancelRequest() async {
    if (state.action.running) return false;
    state = state.copyWith(action: state.action.start());
    final result = await ref.read(clubDataProvider).cancelJoinRequest();
    if (!ref.mounted) return false;
    if (result case Failed(:final failure)) {
      state = state.copyWith(action: state.action.finish(result));
      _fail(failure);
      return false;
    }
    state = state.copyWith(
      action: state.action.finish(result),
      clearRequest: true,
    );
    return true;
  }

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );

  Future<GeoPoint?> _savedPoint() async {
    final userId = ref.read(signedInUserIdProvider);
    if (userId == null) return null;
    final home = ref.read(homeLocationViewModelProvider.notifier);
    await home.load(userId);
    return ref.read(homeLocationViewModelProvider);
  }

  void _fail(Failure failure) => state = state.copyWith(
    messages: [...state.messages, FailureMessage(_messageId++, failure)],
  );
}
