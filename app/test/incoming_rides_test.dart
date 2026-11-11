import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/providers.dart';
import 'package:velomine/features/recording/recording_providers.dart';
import 'package:velomine/features/rides/incoming/incoming_batch.dart';
import 'package:velomine/features/rides/incoming/incoming_rides_area.dart';
import 'package:velomine/features/rides/incoming/incoming_rides_view_model.dart';
import 'package:velomine/features/rides/incoming/incoming_source.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';

class _FakeIncomingSource implements IncomingSource {
  final _batches = StreamController<IncomingBatch>.broadcast();

  void add(IncomingBatch batch) => _batches.add(batch);

  @override
  Stream<IncomingBatch> get batches => _batches.stream;

  @override
  void dispose() => _batches.close();
}

void main() {
  test('IncomingRidesViewModel_ShouldKeepTheFilesAndAskToSignIn_WhenTheMemberIsSignedOut', () async {
    final source = _FakeIncomingSource();
    final container = ProviderContainer(
      overrides: [
        incomingSourceProvider.overrideWithValue(source),
        signedInUserIdProvider.overrideWithValue(null),
        recorderProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      incomingRidesViewModelProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    source.add(const IncomingBatch(added: 2, alreadyHere: 1));
    await Future<void>.delayed(Duration.zero);

    final state = container.read(incomingRidesViewModelProvider);
    expect(state.signedOut, isTrue);
    expect(state.batch?.added, 2);
    expect(state.confirmation, 1);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(incomingLines(l10n, state), [
      '3 rides are kept. Sign in and they will upload.',
    ]);

    container.read(incomingRidesViewModelProvider.notifier).shown(1);
    expect(container.read(incomingRidesViewModelProvider).batch, isNull);
  });

  test(
    'IncomingRidesViewModel_ShouldSayWhatArrived_WhenTheMemberIsSignedIn',
    () async {
      final source = _FakeIncomingSource();
      final container = ProviderContainer(
        overrides: [
          incomingSourceProvider.overrideWithValue(source),
          signedInUserIdProvider.overrideWithValue('me'),
          recorderProvider.overrideWithValue(null),
          uploadQueueProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        incomingRidesViewModelProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      source.add(
        const IncomingBatch(added: 2, alreadyHere: 1, rejected: ['notes.txt']),
      );
      await Future<void>.delayed(Duration.zero);

      final state = container.read(incomingRidesViewModelProvider);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(incomingLines(l10n, state), [
        '2 rides added. They will upload in the background.',
        '1 ride was already here.',
        'notes.txt is not a ride file and was skipped.',
      ]);
    },
  );
}
