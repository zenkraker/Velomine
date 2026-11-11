import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/failure.dart';
import '../../../core/providers.dart';
import '../../../core/result.dart';
import '../rides_data.dart';
import '../rides_view_model.dart';
import 'bulk_upload_runner.dart';
import 'bulk_upload_state.dart';
import 'drop_source.dart';
import 'ride_file.dart';

part 'bulk_upload_view_model.g.dart';

/// Where dropped and chosen files come from. Tests override it with a fake; the phone gets one that does nothing.
final dropSourceProvider = Provider<DropSource>((ref) {
  final source = createDropSource();
  ref.onDispose(source.dispose);
  return source;
});

/// Paces the uploads. Tests override it with one that does not wait.
final bulkRunnerProvider = Provider<BulkUploadRunner>(
  (ref) => BulkUploadRunner(),
);

/// The server refuses a ride file bigger than this; sending it would only waste the time.
const _maxRideFileBytes = 30 * 1024 * 1024;

/// A folder or several files dropped on the page, sent a few at a time and summed up once.
@Riverpod(keepAlive: true)
class BulkUploadViewModel extends _$BulkUploadViewModel {
  _Run? _run;

  @override
  BulkUploadState build() {
    final source = ref.watch(dropSourceProvider);
    final signedIn = ref.watch(signedInUserIdProvider) != null;

    final dragging = source.dragging.listen((value) {
      if (ref.mounted) state = state.copyWith(dragging: value);
    });
    final drops = source.drops.listen((pending) {
      unawaited(_receive(pending, signedIn: signedIn));
    });
    // Signing out, or another account, stops a run that is under way: nothing it reads belongs to the new one.
    ref.onDispose(() {
      unawaited(dragging.cancel());
      unawaited(drops.cancel());
      _run?.cancelled = true;
      _run = null;
    });
    return const BulkUploadState();
  }

  bool get supported => ref.read(dropSourceProvider).supported;

  /// Opens the folder chooser. Call it straight from the button press: the browser allows it only then.
  Future<void> chooseFolder() {
    if (state.busy) return Future.value();
    final picked = ref.read(dropSourceProvider).pickFolder();
    return _receive(
      picked,
      signedIn: ref.read(signedInUserIdProvider) != null,
      scanning: false,
    );
  }

  /// Opens the file chooser, for several files.
  Future<void> chooseFiles() {
    if (state.busy) return Future.value();
    final picked = ref.read(dropSourceProvider).pickFiles();
    return _receive(
      picked,
      signedIn: ref.read(signedInUserIdProvider) != null,
      scanning: false,
    );
  }

  /// Stops after the files already in flight; what was read stays.
  void cancel() {
    final run = _run;
    if (run == null || state.phase != BulkPhase.running) return;
    run.cancelled = true;
    state = state.copyWith(cancelling: true);
  }

  /// Closes the summary.
  void dismiss() {
    if (state.busy) return;
    state = state.copyWith(phase: BulkPhase.idle, clearSummary: true);
  }

  void noticeShown() => state = state.copyWith(clearNotice: true);

  Future<void> _receive(
    Future<List<RideFileEntry>> pending, {
    required bool signedIn,
    bool scanning = true,
  }) async {
    if (state.busy) return;
    if (!signedIn) {
      state = state.copyWith(notice: BulkNotice.signedOut);
      return;
    }
    final run = _run = _Run();
    if (scanning) {
      state = state.copyWith(phase: BulkPhase.scanning, clearSummary: true);
    }

    final found = await pending.catchError((Object _) => const <RideFileEntry>[]);
    if (!ref.mounted || run.cancelled) return;
    // Closing the chooser without picking anything is not a mistake worth a message.
    if (found.isEmpty && !scanning) {
      _run = null;
      return;
    }
    final chosen = selectRideFiles(found);
    if (chosen.rides.isEmpty) {
      state = state.copyWith(
        phase: BulkPhase.idle,
        notice: BulkNotice.nothingUsable,
      );
      return;
    }
    await _send(run, chosen.rides, chosen.skipped);
  }

  Future<void> _send(_Run run, List<RideFileEntry> files, int skipped) async {
    state = state.copyWith(
      phase: BulkPhase.running,
      total: files.length,
      completed: 0,
      waiting: false,
      cancelling: false,
      clearSummary: true,
    );

    final summary = await ref
        .read(bulkRunnerProvider)
        .run(
          files,
          skipped: skipped,
          isCancelled: () => run.cancelled,
          upload: (file) => _uploadOne(file, run),
          onWaiting: (waiting) {
            if (ref.mounted && !run.cancelled) {
              state = state.copyWith(waiting: waiting);
            }
          },
          onProgress: (done, total) {
            if (!ref.mounted || identical(_run, run) == false) return;
            state = state.copyWith(completed: done, total: total);
            // The list fills in as the folder is read, without a refresh per file.
            if (done > 0 && done % 25 == 0) unawaited(_refreshList());
          },
        );
    if (!ref.mounted || !identical(_run, run)) return;

    state = state.copyWith(
      phase: BulkPhase.done,
      summary: summary,
      waiting: false,
      cancelling: false,
    );
    await _refreshList();
  }

  Future<void> _refreshList() async {
    if (!ref.mounted) return;
    await ref.read(ridesViewModelProvider.notifier).refresh();
  }

  Future<BulkFileResult> _uploadOne(RideFileEntry file, _Run run) async {
    final data = ref.read(ridesDataProvider);
    final bytes = await file.read();
    if (bytes.isEmpty) return const BulkFileResult.unreadable('invalid_file');
    if (bytes.length > _maxRideFileBytes) {
      return const BulkFileResult.unreadable('file_too_large');
    }

    // The same key on a retry after a pause: the server still makes one ride.
    final key = run.keys.putIfAbsent(file, RidesData.newKey);
    final sent = await data.uploadBulk(file.name, bytes, key);
    if (sent case Failed(:final failure)) return _failed(failure);
    final id = sent.valueOrNull;
    if (id == null) return const BulkFileResult.unreadable(null);

    final interval = ref.read(ridePollIntervalProvider);
    for (var poll = 0; poll < 120; poll++) {
      final read = await data.ride(id);
      switch (read) {
        case Failed(:final failure):
          return _failed(failure);
        case Ok(:final value):
          switch (value?.status) {
            case 'ready':
              return const BulkFileResult.added();
            case 'duplicate':
              return const BulkFileResult.alreadyHere();
            case 'processing':
              await Future<void>.delayed(interval);
            default:
              return BulkFileResult.unreadable(value?.error);
          }
      }
    }
    return const BulkFileResult.unreadable('timeout');
  }

  static BulkFileResult _failed(Failure failure) => switch (failure.kind) {
    FailureKind.throttled => const BulkFileResult.throttled(),
    FailureKind.unreachable => const BulkFileResult.unreadable('offline'),
    FailureKind.sessionEnded => const BulkFileResult.unreadable('sign_in'),
    FailureKind.rejected => const BulkFileResult.unreadable('invalid_file'),
    _ when failure.code == 413 => const BulkFileResult.unreadable(
      'file_too_large',
    ),
    _ => BulkFileResult.unreadable('http_${failure.code ?? 0}'),
  };
}

/// One run of the uploader: its own cancel flag and the keys of its files.
class _Run {
  bool cancelled = false;
  final keys = Map<RideFileEntry, String>.identity();
}
