import 'package:flutter/foundation.dart';
import 'package:velomine_api/api.dart';

/// Runs a call and turns failures into a message the screen can show; a 401 means the session ended.
Future<String?> guardCall(
  Future<void> Function() action,
  VoidCallback onUnauthorized, {
  String what = 'do that',
}) async {
  try {
    await action();
    return null;
  } on ApiException catch (e) {
    if (e.code == 401) {
      onUnauthorized();
      return null;
    }
    if (e.code == 400) {
      return 'The server did not accept that. Check the values.';
    }
    if (e.code == 404) return 'It no longer exists.';
    return 'Could not $what (${e.code}). Try again.';
  } on Object {
    return 'Could not reach the server. Try again.';
  }
}

/// The member's bikes, and adding one.
class BikesController extends ChangeNotifier {
  BikesController({required this.api, required this.onUnauthorized});

  final BikesApi api;
  final VoidCallback onUnauthorized;

  List<BikeResponse> bikes = [];
  bool loading = false;
  String? error;

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    error = await guardCall(
      () async {
        bikes = (await api.listBikes())?.bikes ?? [];
      },
      onUnauthorized,
      what: 'load your bikes',
    );
    loading = false;
    notifyListeners();
  }

  /// Returns the new bike's id, or null when it failed (then [error] says why).
  Future<String?> add(CreateBikeRequest bike) async {
    String? id;
    error = await guardCall(
      () async {
        id = (await api.createBike(bike))?.bike.id;
      },
      onUnauthorized,
      what: 'add the bike',
    );
    if (id != null) await refresh();
    notifyListeners();
    return id;
  }
}

/// One bike with its parts: editing the bike, and adding, replacing and removing parts.
class BikeDetailController extends ChangeNotifier {
  BikeDetailController({
    required this.api,
    required this.id,
    required this.onUnauthorized,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final BikesApi api;
  final String id;
  final VoidCallback onUnauthorized;
  final DateTime Function() _now;

  BikeDetailResponse? detail;
  List<ComponentTypeResponse> types = [];
  bool loading = true;
  bool notFound = false;
  String? error;

  Future<void> load() async {
    error = await guardCall(
      () async {
        try {
          detail = await api.getBike(id);
          types = (await api.listComponentTypes())?.types ?? [];
        } on ApiException catch (e) {
          if (e.code != 404) rethrow;
          notFound = true;
        }
      },
      onUnauthorized,
      what: 'load this bike',
    );
    loading = false;
    notifyListeners();
  }

  Future<bool> _change(
    Future<BikeDetailResponse?> Function() call,
    String what,
  ) async {
    BikeDetailResponse? result;
    error = await guardCall(
      () async => result = await call(),
      onUnauthorized,
      what: what,
    );
    if (result != null) detail = result;
    notifyListeners();
    return error == null;
  }

  Future<bool> save(UpdateBikeRequest bike) =>
      _change(() => api.updateBike(id, bike), 'save the bike');

  /// Archiving keeps the rides and the history; the bike just stops being offered for new rides.
  Future<bool> setActive(bool active) {
    final b = detail!.bike;
    return save(
      UpdateBikeRequest(
        name: b.name,
        brand: Optional.present(b.brand),
        model: Optional.present(b.model),
        kind: b.kind,
        wheelCircumferenceMm: b.wheelCircumferenceMm,
        initialDistanceM: b.initialDistanceM,
        purchasedOn: Optional.present(b.purchasedOn),
        isActive: Optional.present(active),
      ),
    );
  }

  Future<bool> makeDefault() async {
    error = await guardCall(
      () => api.setDefaultBike(id),
      onUnauthorized,
      what: 'set the default',
    );
    if (error == null) await load();
    notifyListeners();
    return error == null;
  }

  Future<bool> delete() async {
    error = await guardCall(
      () => api.deleteBike(id),
      onUnauthorized,
      what: 'delete the bike',
    );
    notifyListeners();
    return error == null;
  }

  Future<bool> addPart(CreateComponentRequest part) =>
      _change(() => api.createComponent(id, part), 'add the part');

  Future<bool> editPart(String partId, UpdateComponentRequest part) =>
      _change(() => api.updateComponent(id, partId, part), 'save the part');

  Future<bool> removePart(String partId) async {
    error = await guardCall(
      () => api.deleteComponent(id, partId),
      onUnauthorized,
      what: 'remove the part',
    );
    if (error == null) await load();
    notifyListeners();
    return error == null;
  }

  /// Takes the old part off today and fits [replacement] (usually the same kind of part, new).
  Future<bool> replacePart(
    ComponentResponse old,
    CreateComponentRequest replacement,
  ) async {
    final today = _now();
    final retired = await editPart(
      old.id,
      UpdateComponentRequest(
        type: old.type,
        brand: Optional.present(old.brand),
        model: Optional.present(old.model),
        installedOn: old.installedOn,
        removedOn: Optional.present(
          DateTime(today.year, today.month, today.day),
        ),
        expectedDistanceM: Optional.present(old.expectedDistanceM),
        expectedHours: Optional.present(old.expectedHours),
        expectedMonths: Optional.present(old.expectedMonths),
      ),
    );
    return retired && await addPart(replacement);
  }

  DateTime get today => _now();
}
