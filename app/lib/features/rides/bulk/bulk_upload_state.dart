import 'bulk_upload_runner.dart';

enum BulkPhase {
  /// Nothing going on.
  idle,

  /// A dropped folder is being walked to find its files.
  scanning,

  /// Files are being sent and read.
  running,

  /// Finished or stopped; [BulkUploadState.summary] says how it went.
  done,
}

/// Something to tell the member once, in a line, instead of starting work.
enum BulkNotice {
  /// Files arrived while nobody is signed in.
  signedOut,

  /// The drop held no ride files at all.
  nothingUsable,
}

class BulkUploadState {
  const BulkUploadState({
    this.phase = BulkPhase.idle,
    this.total = 0,
    this.completed = 0,
    this.waiting = false,
    this.cancelling = false,
    this.dragging = false,
    this.summary,
    this.notice,
  });

  final BulkPhase phase;

  /// Ride files in this run, and how many are finished.
  final int total;
  final int completed;

  /// The server asked us to slow down and the run is pausing.
  final bool waiting;

  /// The member pressed Cancel; the files already in flight finish first.
  final bool cancelling;

  /// Files are being dragged over the page.
  final bool dragging;
  final BulkSummary? summary;
  final BulkNotice? notice;

  bool get busy => phase == BulkPhase.scanning || phase == BulkPhase.running;

  BulkUploadState copyWith({
    BulkPhase? phase,
    int? total,
    int? completed,
    bool? waiting,
    bool? cancelling,
    bool? dragging,
    BulkSummary? summary,
    bool clearSummary = false,
    BulkNotice? notice,
    bool clearNotice = false,
  }) => BulkUploadState(
    phase: phase ?? this.phase,
    total: total ?? this.total,
    completed: completed ?? this.completed,
    waiting: waiting ?? this.waiting,
    cancelling: cancelling ?? this.cancelling,
    dragging: dragging ?? this.dragging,
    summary: clearSummary ? null : (summary ?? this.summary),
    notice: clearNotice ? null : (notice ?? this.notice),
  );
}
