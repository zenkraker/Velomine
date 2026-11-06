import 'dart:typed_data';

import 'package:http/http.dart' show MultipartFile;
import 'package:velomine_api/api.dart';

class RideUploadResult {
  const RideUploadResult({required this.serverRideId, required this.status});

  final String serverRideId;
  final String status;
}

class RideStatusResult {
  const RideStatusResult({required this.status, this.error});

  final String status;
  final String? error;

  bool get isDone => status != 'processing';
}

/// Uploads one FIT file and reads the server's ingestion status back.
abstract interface class RideUploader {
  Future<RideUploadResult> upload(Uint8List bytes, String idempotencyKey);

  Future<RideStatusResult> status(String serverRideId);
}

class ServerRideUploader implements RideUploader {
  ServerRideUploader(this.api);

  final RidesApi api;

  @override
  Future<RideUploadResult> upload(
    Uint8List bytes,
    String idempotencyKey,
  ) async {
    final file = MultipartFile.fromBytes('file', bytes, filename: 'ride.fit');
    final response = await api.uploadRide(file, idempotencyKey: idempotencyKey);
    if (response == null) {
      throw const RideUploadException('empty', 'The server did not accept it.');
    }
    return RideUploadResult(
      serverRideId: response.rideId,
      status: response.status,
    );
  }

  @override
  Future<RideStatusResult> status(String serverRideId) async {
    final ride = await api.getRide(serverRideId);
    if (ride == null) {
      throw const RideUploadException('not_found', 'The ride disappeared.');
    }
    return RideStatusResult(status: ride.status, error: ride.error);
  }
}

class RideUploadException implements Exception {
  const RideUploadException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}
