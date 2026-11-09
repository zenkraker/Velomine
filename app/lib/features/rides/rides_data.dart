import 'dart:math';

import 'package:file_selector/file_selector.dart';
import 'package:http/http.dart' show MultipartFile;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';

part 'rides_data.g.dart';

/// One page of the member's rides.
typedef RidesPage = ({List<RideResponse> rides, String? next});

/// The ride endpoints as values: the ViewModels never see an exception.
class RidesData {
  RidesData(this._api);

  final RidesApi _api;

  Future<Result<RidesPage>> page({String? cursor, String? discipline}) async =>
      (await _api
              .listRides(cursor: cursor, discipline: discipline)
              .guard(FailureAction.loadRides))
          .map(
            (page) => (
              rides: page?.rides ?? const <RideResponse>[],
              next: page?.next,
            ),
          );

  /// Picks nothing; [file] is already chosen. The key makes a retry of the same
  /// upload safe: the server returns the first ride instead of making another.
  Future<Result<String?>> upload(XFile file) => (() async {
    final upload = MultipartFile.fromBytes(
      'file',
      await file.readAsBytes(),
      filename: file.name,
    );
    return (await _api.uploadRide(upload, idempotencyKey: _newKey()))?.rideId;
  })().guard(FailureAction.uploadRide);

  Future<Result<RideResponse?>> ride(String id) =>
      _api.getRide(id).guard(FailureAction.loadRide);

  static String _newKey() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

@Riverpod(keepAlive: true)
RidesData ridesData(Ref ref) => RidesData(ref.watch(sessionProvider).rides);
