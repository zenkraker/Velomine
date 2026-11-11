import 'dart:async';

import 'package:flutter/services.dart';

import 'incoming_batch.dart';
import 'incoming_source.dart';

/// The Android side copies received files into the rides folder and keeps the outcome until the app asks.
IncomingSource createPlatformIncomingSource() => _NativeIncomingSource();

class _NativeIncomingSource implements IncomingSource {
  static const _channel = MethodChannel('velomine/incoming');

  final _batches = StreamController<IncomingBatch>.broadcast();

  _NativeIncomingSource() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'arrived') await _take();
    });
    // Files received while the app was closed are waiting.
    unawaited(_take());
  }

  @override
  Stream<IncomingBatch> get batches => _batches.stream;

  Future<void> _take() async {
    try {
      final batch = IncomingBatch.fromMap(
        await _channel.invokeMethod<Map<Object?, Object?>>('take'),
      );
      if (batch != null && !batch.isEmpty && !_batches.isClosed) {
        _batches.add(batch);
      }
    } on MissingPluginException {
      // iOS has no native side for this yet.
    } on PlatformException {
      // The files stay on disk; the upload queue picks them up when the member signs in.
    }
  }

  @override
  void dispose() {
    unawaited(_batches.close());
  }
}
