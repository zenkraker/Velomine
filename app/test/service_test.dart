import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/features/notifications/notifications_text.dart';
import 'package:velomine/l10n/generated/app_localizations_en.dart';
import 'package:velomine/l10n/generated/app_localizations_it.dart';
import 'package:velomine_api/api.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
    server.bikes.add({
      'id': 'bike-1',
      'name': 'Climber',
      'kind': 'road',
      'wheelCircumferenceMm': 2105,
      'initialDistanceM': 1200000.0,
      'isDefault': true,
    });
  });

  Future<void> openBike(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.text('Bikes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bike-bike-1')));
    await tester.pumpAndSettle();
  }

  Map<String, Object?> reminder(
    String id,
    String name,
    String status, {
    int percent = 0,
    double usedKm = 0,
  }) => {
    'id': id,
    'name': name,
    'intervalDistanceM': 300000.0,
    'lastDoneOn': '2026-10-01',
    'usedDistanceM': usedKm * 1000,
    'percent': percent,
    'status': status,
  };

  testWidgets(
    'ServiceSection_ShouldShowProgressAndState_WhenTheBikeHasReminders',
    (tester) async {
      server.reminders['bike-1'] = [
        reminder('r1', 'Lube the chain', 'due', percent: 104, usedKm: 312),
        reminder('r2', 'Bolt check', 'ok', percent: 70, usedKm: 210),
      ];
      await openBike(tester);

      expect(find.text('Lube the chain'), findsOneWidget);
      expect(find.text('Due'), findsOneWidget);
      expect(find.text('Fine'), findsOneWidget);
      expect(find.text('210 of 300 km'), findsOneWidget);
      expect(find.byKey(const Key('reminder-bar-r2')), findsOneWidget);
      expect(find.text('Last done 2026-10-01'), findsNWidgets(2));
    },
  );

  testWidgets(
    'ServiceSection_ShouldOfferCommonJobsAndStartFromTheirInterval_WhenThereAreNoReminders',
    (tester) async {
      await openBike(tester);

      expect(find.byKey(const Key('no-reminders')), findsOneWidget);
      expect(find.byKey(const Key('no-entries')), findsOneWidget);
      await tester.tap(find.byKey(const Key('suggest-chain_lube')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(find.byKey(const Key('reminder-name')))
            .controller!
            .text,
        'Lube the chain',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('reminder-km')))
            .controller!
            .text,
        '300',
      );
      await tester.tap(find.byKey(const Key('reminder-save')));
      await tester.pumpAndSettle();

      final saved = server.reminders['bike-1']!.single;
      expect(saved['name'], 'Lube the chain');
      expect(saved['intervalDistanceM'], 300000.0);
      expect(find.byKey(const Key('no-reminders')), findsNothing);
    },
  );

  testWidgets('ReminderForm_ShouldExplainWhatIsMissing_WhenNoIntervalIsSet', (
    tester,
  ) async {
    await openBike(tester);
    await tester.tap(find.byKey(const Key('add-reminder')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reminder-name')),
      'Wax the chain',
    );
    await tester.tap(find.byKey(const Key('reminder-save')));
    await tester.pumpAndSettle();

    expect(find.text('Set a distance, hours or months.'), findsOneWidget);
    expect(server.reminders['bike-1'], isNull);
  });

  testWidgets(
    'ServiceSection_ShouldRestartTheJobAndShowItInTheLog_WhenMarkedDone',
    (tester) async {
      server.reminders['bike-1'] = [
        reminder('r1', 'Lube the chain', 'due', percent: 104, usedKm: 312),
      ];
      await openBike(tester);

      await tester.tap(find.byKey(const Key('reminder-done-r1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-done')));
      await tester.pumpAndSettle();

      expect(server.reminders['bike-1']!.single['status'], 'ok');
      expect(find.text('Fine'), findsOneWidget);
      final entry = server.serviceLog['bike-1']!.single;
      expect(entry['reminderId'], 'r1');
      expect(find.byKey(Key('entry-${entry['id']}')), findsOneWidget);
      expect(
        find.textContaining('at 1,200 km', findRichText: true),
        findsOneWidget,
      );
    },
  );

  testWidgets('ServiceSection_ShouldPauseAndResume_WhenTheButtonIsTapped', (
    tester,
  ) async {
    server.reminders['bike-1'] = [reminder('r1', 'Lube the chain', 'ok')];
    await openBike(tester);

    await tester.tap(find.byKey(const Key('reminder-pause-r1')));
    await tester.pumpAndSettle();

    expect(server.reminders['bike-1']!.single['isPaused'], isTrue);
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
  });

  testWidgets('ServiceSection_ShouldDeleteTheReminder_WhenConfirmed', (
    tester,
  ) async {
    server.reminders['bike-1'] = [reminder('r1', 'Lube the chain', 'ok')];
    await openBike(tester);

    await tester.tap(find.byKey(const Key('reminder-remove-r1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-remove-reminder')));
    await tester.pumpAndSettle();

    expect(server.reminders['bike-1'], isEmpty);
    expect(find.byKey(const Key('reminder-r1')), findsNothing);
  });

  testWidgets('ServiceSection_ShouldEditTheReminder_WhenTheFormIsSaved', (
    tester,
  ) async {
    server.reminders['bike-1'] = [reminder('r1', 'Lube the chain', 'ok')];
    await openBike(tester);

    await tester.tap(find.byKey(const Key('reminder-edit-r1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reminder-name')),
      'Wax the chain',
    );
    await tester.enterText(find.byKey(const Key('reminder-km')), '500');
    await tester.tap(find.byKey(const Key('reminder-save')));
    await tester.pumpAndSettle();

    final saved = server.reminders['bike-1']!.single;
    expect(saved['name'], 'Wax the chain');
    expect(saved['intervalDistanceM'], 500000.0);
    expect(find.text('Wax the chain'), findsOneWidget);
  });

  testWidgets('ServiceSection_ShouldAddAndRemoveAnEntry_WhenUsedByHand', (
    tester,
  ) async {
    await openBike(tester);

    await tester.tap(find.byKey(const Key('add-entry')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('entry-title')),
      'New brake pads',
    );
    await tester.enterText(find.byKey(const Key('entry-place')), 'Bici Rossi');
    await tester.enterText(find.byKey(const Key('entry-cost')), '85,5');
    await tester.enterText(find.byKey(const Key('entry-currency')), 'eur');
    await tester.tap(find.byKey(const Key('entry-save')));
    await tester.pumpAndSettle();

    final saved = server.serviceLog['bike-1']!.single;
    expect(saved['title'], 'New brake pads');
    expect(saved['place'], 'Bici Rossi');
    expect(saved['costAmount'], 85.5);
    expect(saved['costCurrency'], 'EUR');
    expect(find.text('New brake pads'), findsOneWidget);
    expect(find.textContaining('Bici Rossi'), findsOneWidget);

    await tester.tap(find.byKey(Key('entry-remove-${saved['id']}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-remove-entry')));
    await tester.pumpAndSettle();

    expect(server.serviceLog['bike-1'], isEmpty);
  });

  testWidgets('EntryForm_ShouldNeedACurrency_WhenACostIsGiven', (tester) async {
    await openBike(tester);
    await tester.tap(find.byKey(const Key('add-entry')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('entry-title')), 'Service');
    await tester.enterText(find.byKey(const Key('entry-cost')), '40');
    await tester.enterText(find.byKey(const Key('entry-currency')), 'E');
    await tester.tap(find.byKey(const Key('entry-save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('form-error')), findsOneWidget);
    expect(server.serviceLog['bike-1'], isEmpty);
  });

  testWidgets('ServiceSection_ShouldLinkTheEntryToAReminder_WhenOneIsPicked', (
    tester,
  ) async {
    server.reminders['bike-1'] = [reminder('r1', 'Lube the chain', 'ok')];
    await openBike(tester);

    await tester.tap(find.byKey(const Key('add-entry')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('entry-title')),
      'Shop service',
    );
    await tester.tap(find.byKey(const Key('entry-reminder')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lube the chain').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('entry-save')));
    await tester.pumpAndSettle();

    expect(server.serviceLog['bike-1']!.single['reminderId'], 'r1');
  });

  testWidgets('ServiceSection_ShouldFilterTheLogByPart_WhenAPartIsPicked', (
    tester,
  ) async {
    server.parts['bike-1'] = [
      {
        'id': 'part-1',
        'type': 'chain',
        'typeName': 'Chain',
        'installedOn': '2026-01-01',
      },
    ];
    server.serviceLog['bike-1'] = [
      {
        'id': 'e1',
        'date': '2026-10-05',
        'title': 'Replaced chain',
        'componentId': 'part-1',
      },
      {'id': 'e2', 'date': '2026-10-01', 'title': 'Cleaned the bike'},
    ];
    await openBike(tester);
    expect(find.text('Cleaned the bike'), findsOneWidget);

    await tester.tap(find.byKey(const Key('log-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chain').last);
    await tester.pumpAndSettle();

    expect(find.text('Replaced chain'), findsOneWidget);
    expect(find.text('Cleaned the bike'), findsNothing);
  });

  testWidgets('BikeDetailScreen_ShouldLogTheReplacement_WhenAPartIsReplaced', (
    tester,
  ) async {
    server.parts['bike-1'] = [
      {
        'id': 'part-1',
        'type': 'chain',
        'typeName': 'Chain',
        'installedOn': '2026-01-01',
        'expectedDistanceM': 4000000.0,
        'status': 'worn',
      },
    ];
    await openBike(tester);

    await tester.tap(find.byKey(const Key('replace-part-1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('part-brand')), 'Shimano');
    await tester.enterText(find.byKey(const Key('part-model')), 'CN-HG701');
    await tester.tap(find.byKey(const Key('part-save')));
    await tester.pumpAndSettle();

    final entry = server.serviceLog['bike-1']!.single;
    expect(entry['title'], 'Replaced chain: Shimano CN-HG701');
    expect(entry['origin'], 'part');
    expect(find.text('Replaced chain: Shimano CN-HG701'), findsOneWidget);
    expect(server.parts['bike-1']![0]['status'], 'retired');
  });

  testWidgets(
    'ServiceSection_ShouldFitThePhoneLayout_WhenThereAreRemindersAndEntries',
    (tester) async {
      server.reminders['bike-1'] = [
        reminder('r1', 'Lube the chain', 'due', percent: 104, usedKm: 312),
      ];
      server.serviceLog['bike-1'] = [
        {
          'id': 'e1',
          'date': '2026-10-05',
          'title': 'Full service',
          'bikeDistanceM': 1200000.0,
        },
      ];
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));
      await tester.tap(find.text('Bikes'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bike-bike-1')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('reminder-r1')), findsOneWidget);
      expect(find.byKey(const Key('entry-e1')), findsOneWidget);
    },
  );

  testWidgets('BikesScreen_ShouldMarkTheBike_WhenSomethingIsDueOrNearlyDue', (
    tester,
  ) async {
    server.bikes.add({
      'id': 'bike-2',
      'name': 'Gravel',
      'kind': 'gravel',
      'wheelCircumferenceMm': 2105,
      'initialDistanceM': 0.0,
      'serviceSoonCount': 1,
    });
    server.bikes[0]['serviceDueCount'] = 2;
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.text('Bikes'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('service-due')), findsOneWidget);
    expect(find.byKey(const Key('service-soon')), findsOneWidget);
  });

  test(
    'NotificationText_ShouldNameTheJobAndOpenTheBike_WhenAReminderIsDue',
    () {
      final due = NotificationResponse.fromJson(
        notificationJson(
          'n-1',
          'reminder_due',
          'Lube the chain on Road bike',
          bikeId: 'bike-1',
        ),
      )!;

      expect(
        notificationText(AppLocalizationsEn(), due),
        'Maintenance due: Lube the chain on Road bike.',
      );
      expect(
        notificationText(AppLocalizationsIt(), due),
        'Manutenzione da fare: Lube the chain on Road bike.',
      );
      expect(notificationTarget(due), '/bikes/bike-1');
    },
  );
}
