import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/providers.dart';
import 'package:velomine/features/rides/bulk/bulk_upload_runner.dart';
import 'package:velomine/features/rides/bulk/bulk_upload_state.dart';
import 'package:velomine/features/rides/bulk/bulk_upload_view_model.dart';
import 'package:velomine/features/rides/bulk/drop_source.dart';
import 'package:velomine/features/rides/bulk/ride_file.dart';
import 'package:velomine/features/recording/recording_providers.dart';

import 'fake_server.dart';

class _MemoryFile implements RideFileEntry {
  _MemoryFile(this.name);

  @override
  final String name;

  @override
  String get path => name;

  static const bytes = [1, 2, 3];

  @override
  Future<Uint8List> read() async => Uint8List.fromList(bytes);
}

class _FakeDropSource implements DropSource {
  _FakeDropSource({this.files = const []});

  final List<RideFileEntry> files;

  final _dragging = StreamController<bool>.broadcast();
  final _drops = StreamController<Future<List<RideFileEntry>>>.broadcast();

  @override
  bool get supported => true;

  @override
  Stream<bool> get dragging => _dragging.stream;

  @override
  Stream<Future<List<RideFileEntry>>> get drops => _drops.stream;

  @override
  Future<List<RideFileEntry>> pickFolder() async => files;

  @override
  Future<List<RideFileEntry>> pickFiles() async => files;

  @override
  void dispose() {
    _dragging.close();
    _drops.close();
  }
}

void main() {
  group('Ride file filtering', () {
    test(
      'IsRideFileName_ShouldAcceptFitGpxAndTcx_WhenTheyAreZippedOrInAnyCase',
      () {
        for (final name in [
          'a.fit',
          'B.GPX',
          'c.Tcx',
          'd.fit.gz',
          'e.GPX.GZ',
          'ride 2026-11-02.tcx.gz',
        ]) {
          expect(isRideFileName(name), isTrue, reason: name);
        }
      },
    );

    test('IsRideFileName_ShouldRejectOtherNames_WhenTheFileIsNotARide', () {
      for (final name in [
        '',
        'fit',
        '.fit',
        'notes.txt',
        'photo.jpg',
        'settings.json',
        'x.gz',
        'ride.zip',
        'ride.fit.bak',
      ]) {
        expect(isRideFileName(name), isFalse, reason: name);
      }
    });

    test('SelectRideFiles_ShouldKeepOnlyRideFilesAndCountTheRest_WhenAFolderHasOtherThings', () {
      final chosen = selectRideFiles([
        _MemoryFile('Activities/2026/ride.fit'),
        _MemoryFile('Activities/2026/settings.json'),
        _MemoryFile('Activities/2026/ride.gpx.gz'),
        _MemoryFile('Activities/2026/photo.jpg'),
        _MemoryFile('notes.txt'),
      ]);

      expect(chosen.rides.map((f) => f.name), [
        'Activities/2026/ride.fit',
        'Activities/2026/ride.gpx.gz',
      ]);
      expect(chosen.skipped, 3);
    });
  });

  group('Pacing and the summary', () {
    test('BulkUploadRunner_ShouldSendAFewAtATime_WhenTheFolderIsBig', () async {
      var active = 0;
      var peak = 0;
      final files = [for (var i = 0; i < 20; i++) _MemoryFile('ride$i.fit')];

      final summary = await BulkUploadRunner(concurrency: 3).run(
        files,
        upload: (file) async {
          active++;
          peak = max(peak, active);
          await Future<void>.delayed(Duration.zero);
          active--;
          return const BulkFileResult.added();
        },
        onProgress: (_, _) {},
        isCancelled: () => false,
      );

      expect(peak, 3);
      expect(summary.added, 20);
      expect(summary.notRead, 0);
    });

    test('BulkUploadRunner_ShouldCountNewOldUnreadableAndSkipped_WhenTheFolderIsMixed', () async {
      final files = [
        _MemoryFile('new-1.fit'),
        _MemoryFile('old.fit'),
        _MemoryFile('broken.gpx'),
        _MemoryFile('new-2.tcx'),
      ];
      final outcomes = [
        const BulkFileResult.added(),
        const BulkFileResult.alreadyHere(),
        const BulkFileResult.unreadable('corrupt_file'),
        const BulkFileResult.added(),
      ];
      final progress = <(int, int)>[];

      final summary = await BulkUploadRunner(concurrency: 1).run(
        files,
        skipped: 5,
        upload: (file) async =>
            outcomes[files.indexWhere((f) => f.name == file.name)],
        onProgress: (done, total) => progress.add((done, total)),
        isCancelled: () => false,
      );

      expect(summary.added, 2);
      expect(summary.alreadyHere, 1);
      expect(summary.skipped, 5);
      expect(summary.notRead, 0);
      expect(summary.cancelled, isFalse);
      expect(summary.unreadable.single.name, 'broken.gpx');
      expect(summary.unreadable.single.error, 'corrupt_file');
      expect(progress.last, (4, 4));
    });

    test('BulkUploadRunner_ShouldWaitAndTryTheSameFileAgain_WhenTheServerIsThrottled', () async {
      final waits = <Duration>[];
      final waiting = <bool>[];
      var attempts = 0;

      final summary =
          await BulkUploadRunner(
            throttleWait: const Duration(seconds: 30),
            wait: (duration) async => waits.add(duration),
          ).run(
            [_MemoryFile('ride.fit')],
            upload: (file) async => ++attempts == 1
                ? const BulkFileResult.throttled()
                : const BulkFileResult.added(),
            onProgress: (_, _) {},
            isCancelled: () => false,
            onWaiting: waiting.add,
          );

      expect(attempts, 2);
      expect(waits, [const Duration(seconds: 30)]);
      expect(waiting, [true, false]);
      expect(summary.added, 1);
    });

    test('BulkUploadRunner_ShouldKeepWhatWasReadAndCountTheRest_WhenTheMemberCancels', () async {
      var cancelled = false;
      final files = [for (var i = 0; i < 5; i++) _MemoryFile('r$i.fit')];

      final summary = await BulkUploadRunner(concurrency: 1).run(
        files,
        upload: (file) async => const BulkFileResult.added(),
        onProgress: (done, total) {
          if (done == 2) cancelled = true;
        },
        isCancelled: () => cancelled,
      );

      expect(summary.added, 2);
      expect(summary.notRead, 3);
      expect(summary.cancelled, isTrue);
    });
  });

  group('The bulk drop on the rides list', () {
    test(
      'BulkUploadViewModel_ShouldAskToSignIn_WhenFilesAreChosenSignedOut',
      () async {
        final container = ProviderContainer(
          overrides: [
            dropSourceProvider.overrideWithValue(
              _FakeDropSource(files: [_MemoryFile('ride.fit')]),
            ),
            signedInUserIdProvider.overrideWithValue(null),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(bulkUploadViewModelProvider.notifier)
            .chooseFiles();

        expect(
          container.read(bulkUploadViewModelProvider).notice,
          BulkNotice.signedOut,
        );
      },
    );

    test(
      'BulkUploadViewModel_ShouldSayNothingWasUsable_WhenTheFilesAreNotRides',
      () async {
        final container = ProviderContainer(
          overrides: [
            dropSourceProvider.overrideWithValue(
              _FakeDropSource(files: [_MemoryFile('notes.txt')]),
            ),
            signedInUserIdProvider.overrideWithValue('me'),
            recorderProvider.overrideWithValue(null),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(bulkUploadViewModelProvider.notifier)
            .chooseFiles();

        expect(
          container.read(bulkUploadViewModelProvider).notice,
          BulkNotice.nothingUsable,
        );
      },
    );

    testWidgets('RidesScreen_ShouldShowOneSummary_WhenAFileIsChosen', (
      tester,
    ) async {
      final server = FakeServer();
      server.signInBrowser(server.add('rider@example.com'));
      final source = _FakeDropSource(files: [_MemoryFile('morning.gpx')]);

      await startApp(
        tester,
        server.session(useCookies: true),
        overrides: [
          dropSourceProvider.overrideWithValue(source),
          bulkRunnerProvider.overrideWithValue(
            BulkUploadRunner(wait: (_) async {}),
          ),
        ],
      );

      await tester.tap(find.byKey(const Key('bulk-files')));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }

      expect(find.text('1 new ride'), findsOneWidget);
      expect(find.byKey(const Key('bulk-close')), findsOneWidget);
      expect(
        server.requests.where((r) => r == 'POST /api/v1/rides/uploads'),
        hasLength(1),
      );
    });
  });
}
