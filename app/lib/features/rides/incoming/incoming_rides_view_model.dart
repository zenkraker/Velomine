import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../../recording/recording_providers.dart';
import 'incoming_batch.dart';
import 'incoming_source.dart';

part 'incoming_rides_view_model.g.dart';

/// Where ride files shared to the app come from. Tests override it with a fake.
final incomingSourceProvider = Provider<IncomingSource>((ref) {
  final source = createIncomingSource();
  ref.onDispose(source.dispose);
  return source;
});

class IncomingRidesState {
  const IncomingRidesState({
    this.batch,
    this.signedOut = false,
    this.confirmation = 0,
  });

  /// The last batch of received files, until it has been shown.
  final IncomingBatch? batch;

  /// The files arrived while nobody was signed in: they are kept, and upload after sign-in.
  final bool signedOut;

  /// Goes up for every confirmation, so the view shows each one once.
  final int confirmation;

  IncomingRidesState copyWith({
    IncomingBatch? batch,
    bool? signedOut,
    int? confirmation,
    bool clearBatch = false,
  }) => IncomingRidesState(
    batch: clearBatch ? null : (batch ?? this.batch),
    signedOut: signedOut ?? this.signedOut,
    confirmation: confirmation ?? this.confirmation,
  );
}

/// "Share to Velomine": the files are already on the phone, so this tells the member and starts the upload queue.
@Riverpod(keepAlive: true)
class IncomingRidesViewModel extends _$IncomingRidesViewModel {
  IncomingBatch? _waitingForSignIn;

  @override
  IncomingRidesState build() {
    final source = ref.watch(incomingSourceProvider);
    final subscription = source.batches.listen(_arrived);
    ref.onDispose(subscription.cancel);
    ref.listen(signedInUserIdProvider, (_, accountId) {
      if (accountId == null) return;
      final waiting = _waitingForSignIn;
      _waitingForSignIn = null;
      if (waiting != null) _confirm(waiting, signedOut: false);
      unawaited(_resume());
    });
    // Files received while the app was closed, and rides that never finished uploading.
    Future.microtask(_resume);
    return const IncomingRidesState();
  }

  void _arrived(IncomingBatch batch) {
    if (batch.isEmpty) return;
    if (ref.read(signedInUserIdProvider) == null) {
      _waitingForSignIn = batch;
      _confirm(batch, signedOut: true);
      return;
    }
    _confirm(batch, signedOut: false);
    unawaited(_resume());
  }

  void _confirm(IncomingBatch batch, {required bool signedOut}) {
    if (!ref.mounted) return;
    state = state.copyWith(
      batch: batch,
      signedOut: signedOut,
      confirmation: state.confirmation + 1,
    );
  }

  /// The confirmation was shown; a later batch still has its own.
  void shown(int confirmation) {
    if (state.confirmation == confirmation) {
      state = state.copyWith(clearBatch: true);
    }
  }

  /// Hands the ready rides, received ones included, to the existing upload queue.
  Future<void> _resume() async {
    final accountId = ref.read(signedInUserIdProvider);
    final recorder = ref.read(recorderProvider);
    if (accountId == null || recorder == null) return;
    try {
      final rides = await recorder.listRides(accountId: accountId);
      if (!ref.mounted) return;
      await ref.read(uploadQueueProvider)?.resume(rides);
    } on Object {
      // Left on the phone; the Record tab resumes the queue the next time it opens.
    }
  }
}
