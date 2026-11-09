import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' show MultipartFile;
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/guard.dart';
import '../../core/hooks.dart';

/// The member's rides, and uploading new ones.
class RidesController extends ChangeNotifier {
  RidesController({
    required this.api,
    required this.pickFile,
    required this.onUnauthorized,
    this.pollInterval = const Duration(seconds: 1),
  });

  final RidesApi api;
  final FilePicker pickFile;
  final VoidCallback onUnauthorized;
  final Duration pollInterval;

  List<RideResponse> rides = [];
  String? next;
  String? disciplineFilter;
  bool loading = false;
  bool uploading = false;
  Failure? error;

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    await _guard(() async {
      final page = await api.listRides(discipline: disciplineFilter);
      rides = page?.rides ?? [];
      next = page?.next;
    }, FailureAction.loadRides);
    loading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (next == null || loading) return;
    loading = true;
    notifyListeners();
    await _guard(() async {
      final page = await api.listRides(
        cursor: next,
        discipline: disciplineFilter,
      );
      rides = [...rides, ...?page?.rides];
      next = page?.next;
    }, FailureAction.loadRides);
    loading = false;
    notifyListeners();
  }

  /// Shows only one surface, or every ride when [value] is null.
  Future<void> setDisciplineFilter(String? value) async {
    if (disciplineFilter == value) return;
    disciplineFilter = value;
    await refresh();
  }

  /// Picks a file, uploads it, then watches the ride until the server has read it.
  Future<void> upload() async {
    final picked = await pickFile();
    if (picked == null) return;

    uploading = true;
    error = null;
    notifyListeners();
    String? rideId;
    await _guard(() async {
      final file = MultipartFile.fromBytes(
        'file',
        await picked.readAsBytes(),
        filename: picked.name,
      );
      // The key makes a retry of the same upload safe: the server returns the first ride instead of making another.
      rideId = (await api.uploadRide(file, idempotencyKey: _newKey()))?.rideId;
    }, FailureAction.uploadRide);
    uploading = false;
    notifyListeners();
    if (rideId == null) return;

    await refresh();
    await _watch(rideId!);
  }

  /// The server reads uploads in the background; ask until the ride is no longer "processing".
  Future<void> _watch(String id) async {
    for (var i = 0; i < 120; i++) {
      await Future<void>.delayed(pollInterval);
      RideResponse? ride;
      await _guard(
        () async => ride = await api.getRide(id),
        FailureAction.loadRide,
      );
      if (ride == null) return;
      final index = rides.indexWhere((r) => r.id == id);
      if (index >= 0) {
        rides = [...rides]..[index] = ride!;
        notifyListeners();
      }
      if (ride!.status != 'processing') {
        if (index < 0) await refresh();
        return;
      }
    }
  }

  Future<void> _guard(
    Future<void> Function() action,
    FailureAction doing,
  ) async {
    error = await guardCall(action, onUnauthorized, doing: doing);
  }

  static String _newKey() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
