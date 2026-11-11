import 'dart:math';
import 'dart:typed_data';

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

/// A day as the server reads it ("2026-11-03"), written by hand so the numerals do not follow the language.
String calendarDay(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// The ride endpoints as values: the ViewModels never see an exception.
class RidesData {
  RidesData(this._api);

  final RidesApi _api;

  /// [query] matches the title and description; [from] and [to] are calendar days, both included.
  Future<Result<RidesPage>> page({
    String? cursor,
    String? discipline,
    String? query,
    DateTime? from,
    DateTime? to,
  }) async =>
      (await _api
              .listRides(
                cursor: cursor,
                discipline: discipline,
                q: query == null || query.trim().isEmpty ? null : query.trim(),
                from: from == null ? null : calendarDay(from),
                to: to == null ? null : calendarDay(to),
              )
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
    return (await _api.uploadRide(upload, idempotencyKey: newKey()))?.rideId;
  })().guard(FailureAction.uploadRide);

  /// Sends one file of a bulk drop. The server makes no notification for it; the screen shows one summary.
  /// [key] is kept for a retry, so a file sent twice (after a pause for the rate limit) is still one ride.
  Future<Result<String?>> uploadBulk(
    String name,
    Uint8List bytes,
    String key,
  ) => (() async {
    final upload = MultipartFile.fromBytes('file', bytes, filename: name);
    return (await _api.uploadRide(
      upload,
      idempotencyKey: key,
      bulkImport: true,
    ))?.rideId;
  })().guard(FailureAction.uploadRide);

  Future<Result<RideResponse?>> ride(String id) =>
      _api.getRide(id).guard(FailureAction.loadRide);

  /// Uploads a Strava export archive. The server reads it in the background:
  /// [importStatus] follows it until it is done.
  Future<Result<String?>> startImport(XFile file) => (() async {
    final upload = MultipartFile(
      'file',
      file.openRead(),
      await file.length(),
      filename: file.name,
    );
    return (await _api.startRideImport(upload))?.importId;
  })().guard(FailureAction.importRides);

  Future<Result<RideImportResponse?>> importStatus(String id) =>
      _api.getRideImport(id).guard(FailureAction.loadImport);

  /// A random key for one upload.
  static String newKey() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

@Riverpod(keepAlive: true)
RidesData ridesData(Ref ref) => RidesData(ref.watch(sessionProvider).rides);
