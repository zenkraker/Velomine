import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:velomine/core/widgets/source_note.dart';

import 'fake_server.dart';

/// Where the FTP came from: the line under the profile field, and the history sheet from the progress menu.
void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com', name: 'Ada'));
  });

  Future<void> openProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await openAccount(tester, 'profile');
    await tester.pumpAndSettle();
  }

  Future<void> openProgress(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
  }

  testWidgets('ProfileScreen_ShouldSayWhereTheFtpCameFrom_WhenItWasTyped', (
    tester,
  ) async {
    server.ftpHistory['rider@example.com'] = [
      {
        'watts': 250,
        'setAt': '2026-11-12T09:00:00Z',
        'source': 'manual',
        'rideId': null,
      },
    ];
    server.profiles['rider@example.com'] = {
      'displayName': 'Ada',
      'ftpW': 250,
      'ftpSetAt': '2026-11-12T09:00:00Z',
      'ftpSource': 'manual',
      'weightKg': null,
      'birthYear': null,
      'timeZone': null,
      'firstDayOfWeek': 'monday',
      'emailNotifications': true,
      'emailAccountNotifications': true,
      'emailTrainingNotifications': false,
      'hasPassword': true,
    };
    await openProfile(tester);

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('profile-ftp')))
          .controller!
          .text,
      '250',
    );
    // The date in the rider's locale, short form, in the shared source note.
    final line = tester.widget<SourceNote>(
      find.byKey(const Key('profile-ftp-source')),
    );
    expect(
      line.text,
      'Set by you on ${DateFormat.yMMMd().format(DateTime(2026, 11, 12))}',
    );
  });

  testWidgets('ProfileScreen_ShouldShowNoSource_WhenThereIsNoFtp', (
    tester,
  ) async {
    await openProfile(tester);

    expect(find.byKey(const Key('profile-ftp-source')), findsNothing);
  });

  testWidgets(
    'PowerSummary_ShouldRecordTheEstimate_WhenTheSuggestionIsAdopted',
    (tester) async {
      await openProgress(tester);

      final useFtp = find.byKey(const Key('use-ftp'));
      await tester.scrollUntilVisible(
        useFtp,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(useFtp);
      await tester.pumpAndSettle();

      expect(server.profiles['rider@example.com']?['ftpW'], 266);
      expect(
        server.ftpHistory['rider@example.com']?.first['source'],
        'estimate',
      );
    },
  );

  Future<void> openHistory(WidgetTester tester) async {
    await openProgress(tester);
    await tester.tap(find.byKey(const Key('progress-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('progress-ftp-history')));
    await tester.pumpAndSettle();
  }

  testWidgets('FtpHistorySheet_ShouldListDateWattsAndSource_WhenThereAreTwo', (
    tester,
  ) async {
    server.ftpHistory['rider@example.com'] = [
      {
        'watts': 266,
        'setAt': '2026-11-12T09:00:00Z',
        'source': 'estimate',
        'rideId': null,
      },
      {
        'watts': 250,
        'setAt': '2026-10-01T09:00:00Z',
        'source': 'earlier',
        'rideId': null,
      },
    ];

    await openHistory(tester);

    ListTile row(int i) =>
        tester.widget<ListTile>(find.byKey(Key('ftp-history-$i')));
    expect((row(0).title! as Text).data, '266 W');
    expect((row(1).title! as Text).data, '250 W');
    final newest = (row(0).subtitle! as Text).data!;
    expect(newest, endsWith('From the estimate'));
    expect(
      newest,
      startsWith(DateFormat.yMMMd().format(DateTime(2026, 11, 12))),
    );
    expect(
      (row(1).subtitle! as Text).data,
      endsWith('Before history was kept'),
    );
    expect(find.byKey(const Key('ftp-history-empty')), findsNothing);
  });

  testWidgets('FtpHistorySheet_ShouldSayThereIsNothingToCompare_WhenOnlyOne', (
    tester,
  ) async {
    server.ftpHistory['rider@example.com'] = [
      {
        'watts': 250,
        'setAt': '2026-11-12T09:00:00Z',
        'source': 'manual',
        'rideId': null,
      },
    ];

    await openHistory(tester);

    expect(find.byKey(const Key('ftp-history-empty')), findsOneWidget);
    expect(find.byKey(const Key('ftp-history-0')), findsNothing);
  });
}
