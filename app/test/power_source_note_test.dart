import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:velomine/core/widgets/source_note.dart';

import 'fake_server.dart';

/// Where each number on the progress power card came from (Story 2).
void main() {
  // The critical power note (Story 5) sits above the FTP and VO2max notes.
  const criticalPowerNote =
      'Fitted from your best 2 minutes, 5 minutes, 10 minutes and 20 minutes '
      'in this range';

  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com', name: 'Ada'));
  });

  Future<void> openPower(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/progress/power');
  }

  Future<void> openProgress(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/progress');
  }

  /// Every note on the power card, in order: critical power, current FTP, estimate, VO2max.
  List<SourceNote> notes(WidgetTester tester) =>
      tester.widgetList<SourceNote>(find.byType(SourceNote)).toList();

  /// The same, without the critical power note that sits above them.
  List<SourceNote> estimateNotes(WidgetTester tester) =>
      notes(tester).where((note) => note.text != criticalPowerNote).toList();

  void giveFtp(int watts) => server.profiles['rider@example.com'] = {
    'displayName': 'Ada',
    'ftpW': watts,
    'weightKg': null,
    'birthYear': null,
    'timeZone': null,
    'firstDayOfWeek': 'monday',
    'emailNotifications': true,
    'emailAccountNotifications': true,
    'emailTrainingNotifications': false,
    'hasPassword': true,
  };

  testWidgets(
    'PowerSummary_ShouldSayTheFtpWasSetByTheRider_WhenTheSourceIsManual',
    (tester) async {
      giveFtp(250);
      server.ftpHistory['rider@example.com'] = [
        {
          'watts': 250,
          'setAt': '2026-11-12T09:00:00Z',
          'source': 'manual',
          'rideId': null,
        },
      ];
      await openPower(tester);

      expect(
        estimateNotes(tester).first.text,
        'Set by you on ${DateFormat.yMMMd().format(DateTime(2026, 11, 12))}',
      );
    },
  );

  testWidgets('PowerSummary_ShouldOpenTheRide_WhenTheFtpCameFromATest', (
    tester,
  ) async {
    server.rides.add(
      rideJson(
        'r1',
        'ready',
        distanceM: 42300,
        movingS: 5400,
        startTime: '2026-11-12T07:30:00Z',
      ),
    );
    giveFtp(250);
    server.ftpHistory['rider@example.com'] = [
      {
        'watts': 250,
        'setAt': '2026-11-12T09:00:00Z',
        'source': 'test',
        'rideId': 'r1',
      },
    ];
    await openPower(tester);

    final note = estimateNotes(tester).first;
    expect(
      note.text,
      'From your ride on '
      '${DateFormat.yMMMd().format(DateTime(2026, 11, 12))}',
    );

    // The note is a way back to the ride it names.
    await tester.scrollUntilVisible(
      find.text(note.text),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(note.text));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ride-title')), findsOneWidget);
    expect(server.requests, contains('GET /api/v1/rides/r1'));
  });

  testWidgets(
    'PowerScreen_ShouldDateATestFtpByItsRide_WhenItWasAcceptedLater',
    (tester) async {
      server.rides.add(
        rideJson('r1', 'ready', startTime: '2026-11-12T07:30:00Z'),
      );
      giveFtp(250);
      server.ftpHistory['rider@example.com'] = [
        {
          'watts': 250,
          'setAt': '2026-11-15T09:00:00Z',
          'source': 'test',
          'rideId': 'r1',
        },
      ];
      await openPower(tester);

      // The day of the effort, not the day the number was accepted three days later.
      expect(
        estimateNotes(tester).first.text,
        'From your ride on '
        '${DateFormat.yMMMd().format(DateTime(2026, 11, 12))}',
      );
    },
  );

  testWidgets(
    'ProgressScreen_ShouldDateATestFtpByItsRide_WhenItWasAcceptedLater',
    (tester) async {
      server.rides.add(
        rideJson('r1', 'ready', startTime: '2026-11-12T07:30:00Z'),
      );
      giveFtp(250);
      server.ftpHistory['rider@example.com'] = [
        {
          'watts': 250,
          'setAt': '2026-11-15T09:00:00Z',
          'source': 'test',
          'rideId': 'r1',
        },
      ];
      await openProgress(tester);

      expect(
        find.text(
          'From your ride on '
          '${DateFormat.yMMMd().format(DateTime(2026, 11, 12))}',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('PowerSummary_ShouldExplainTheEstimate_WhenAnEstimateExists', (
    tester,
  ) async {
    await openPower(tester);

    // The rider has no FTP of their own, so the estimate's note is the first.
    expect(
      estimateNotes(tester).first.text,
      '95 % of your best 20 minutes, on '
      '${DateFormat.yMMMd().format(DateTime(2026, 10, 20))}',
    );
  });

  testWidgets('PowerSummary_ShouldExplainTheVo2Max_WhenThereIsOne', (
    tester,
  ) async {
    server.profiles['rider@example.com'] = {
      'displayName': 'Ada',
      'ftpW': null,
      'weightKg': 70.0,
      'birthYear': null,
      'timeZone': null,
      'firstDayOfWeek': 'monday',
      'emailNotifications': true,
      'emailAccountNotifications': true,
      'emailTrainingNotifications': false,
      'hasPassword': true,
    };
    await openPower(tester);

    expect(
      estimateNotes(tester).last.text,
      'From your best 5 minutes on '
      '${DateFormat.yMMMd().format(DateTime(2026, 10, 20))} and your weight',
    );
  });
}
