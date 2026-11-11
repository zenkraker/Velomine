import 'dart:async';

import 'ride_file.dart';

/// What happened to one file.
enum BulkFileOutcome {
  /// A new ride.
  added,

  /// The server already had this ride (the same file, or the same ride from another app).
  alreadyHere,

  /// The file could not be used; see [BulkFileResult.error].
  unreadable,

  /// The server asked us to slow down (429): the file is tried again after a pause.
  throttled,
}

class BulkFileResult {
  const BulkFileResult(this.outcome, [this.error]);

  const BulkFileResult.added() : this(BulkFileOutcome.added);
  const BulkFileResult.alreadyHere() : this(BulkFileOutcome.alreadyHere);
  const BulkFileResult.throttled() : this(BulkFileOutcome.throttled);
  const BulkFileResult.unreadable(String? error)
    : this(BulkFileOutcome.unreadable, error);

  final BulkFileOutcome outcome;

  /// A short code such as `corrupt_file` for an unreadable file, when the server or the app said why.
  final String? error;
}

/// A file that could not be read, with the reason, so the member can act on it.
class BulkFailure {
  const BulkFailure(this.name, this.error);

  final String name;
  final String? error;
}

/// How a whole drop went.
class BulkSummary {
  const BulkSummary({
    this.added = 0,
    this.alreadyHere = 0,
    this.unreadable = const [],
    this.skipped = 0,
    this.notRead = 0,
  });

  final int added;
  final int alreadyHere;
  final List<BulkFailure> unreadable;

  /// Files that are not ride files at all (settings, photos), set aside silently.
  final int skipped;

  /// Ride files left unread because the member cancelled.
  final int notRead;

  bool get cancelled => notRead > 0;
}

/// Sends many files a few at a time, never all at once, and slows down when the server says so.
///
/// It knows nothing about HTTP: the `upload` callback does one file and says how it went. That keeps the pacing,
/// the cancelling and the counting testable without a server.
class BulkUploadRunner {
  BulkUploadRunner({
    this.concurrency = 3,
    this.throttleWait = const Duration(seconds: 30),
    this.maxThrottleWaits = 120,
    Future<void> Function(Duration)? wait,
  }) : _wait = wait ?? Future<void>.delayed;

  /// Files in flight at once.
  final int concurrency;

  /// How long to pause when the server answers 429, before trying the same file again.
  final Duration throttleWait;

  /// How many pauses one file may cost before it is given up as unreadable.
  final int maxThrottleWaits;

  final Future<void> Function(Duration) _wait;

  Future<BulkSummary> run(
    List<RideFileEntry> files, {
    required Future<BulkFileResult> Function(RideFileEntry file) upload,
    required void Function(int done, int total) onProgress,
    required bool Function() isCancelled,
    void Function(bool waiting)? onWaiting,
    int skipped = 0,
  }) async {
    var next = 0;
    var done = 0;
    var added = 0;
    var alreadyHere = 0;
    final unreadable = <BulkFailure>[];
    onProgress(0, files.length);

    Future<void> worker() async {
      while (!isCancelled() && next < files.length) {
        final file = files[next++];
        final result = await _one(file, upload, isCancelled, onWaiting);
        // Cancelled while waiting for the server: the file was never sent, so it is left unread.
        if (result == null) continue;
        switch (result.outcome) {
          case BulkFileOutcome.added:
            added++;
          case BulkFileOutcome.alreadyHere:
            alreadyHere++;
          case BulkFileOutcome.unreadable || BulkFileOutcome.throttled:
            unreadable.add(BulkFailure(file.name, result.error));
        }
        onProgress(++done, files.length);
      }
    }

    await Future.wait([
      for (var i = 0; i < concurrency.clamp(1, 64); i++) worker(),
    ]);

    return BulkSummary(
      added: added,
      alreadyHere: alreadyHere,
      unreadable: unreadable,
      skipped: skipped,
      notRead: files.length - done,
    );
  }

  Future<BulkFileResult?> _one(
    RideFileEntry file,
    Future<BulkFileResult> Function(RideFileEntry file) upload,
    bool Function() isCancelled,
    void Function(bool waiting)? onWaiting,
  ) async {
    for (var pauses = 0; ; pauses++) {
      BulkFileResult result;
      try {
        result = await upload(file);
      } on Object {
        return const BulkFileResult.unreadable(null);
      }
      if (result.outcome != BulkFileOutcome.throttled) return result;
      if (isCancelled()) return null;
      if (pauses >= maxThrottleWaits) {
        return const BulkFileResult.unreadable('too_many');
      }
      onWaiting?.call(true);
      await _wait(throttleWait);
      onWaiting?.call(false);
      // Cancelled while waiting: the file is not sent again.
      if (isCancelled()) return null;
    }
  }
}
