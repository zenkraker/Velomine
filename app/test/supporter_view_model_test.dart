import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/failure.dart';
import 'package:velomine/core/providers.dart';
import 'package:velomine/features/supporter/supporter_view_model.dart';

import 'fake_server.dart';

/// The supporter ViewModel, without BuildContext: the fake server answers the
/// generated client underneath the data source.
void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com', name: 'Ada'));
  });

  /// Signs in and waits for the first status load the ViewModel starts.
  Future<ProviderContainer> signedIn() async {
    final session = server.session(useCookies: true);
    await session.restore();
    final container = ProviderContainer(
      overrides: [sessionProvider.overrideWith((ref) => session)],
    );
    addTearDown(container.dispose);
    // A listener keeps the kept-alive ViewModel alive, then its first load runs.
    container.listen(supporterViewModelProvider, (_, _) {});
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return container;
  }

  test('SupporterViewModel_ShouldHoldNoLicence_WhenTheMemberHasNone', () async {
    final container = await signedIn();
    final state = container.read(supporterViewModelProvider);
    expect(state.riderLicence, isNull);
    expect(state.badgeShown, isFalse);
    expect(state.becomeSupporter, isTrue);
  });

  test(
    'SupporterViewModel_ShouldHoldTheLicence_WhenActivationSucceeds',
    () async {
      final container = await signedIn();
      final activated = await container
          .read(supporterViewModelProvider.notifier)
          .activate('SUPPORTER-1-ADA');
      final state = container.read(supporterViewModelProvider);
      expect(activated, isTrue);
      expect(state.riderLicence?.holder, 'Ada');
      expect(state.riderLicence?.serial, 42);
      expect(state.badgeShown, isTrue);
      expect(state.becomeSupporter, isFalse);
    },
  );

  test(
    'SupporterViewModel_ShouldCarryTheFailure_WhenTheKeyIsRefused',
    () async {
      final container = await signedIn();
      final activated = await container
          .read(supporterViewModelProvider.notifier)
          .activate('not-a-key');
      final state = container.read(supporterViewModelProvider);
      expect(activated, isFalse);
      expect(state.activate.failure?.kind, FailureKind.rejected);
      expect(state.riderLicence, isNull);
    },
  );

  test(
    'SupporterViewModel_ShouldHideAndShowAgain_WhenTheBadgeIsSwitched',
    () async {
      server.supporterLicences['rider@example.com'] = {
        'holder': 'Ada',
        'serial': 42,
        'hidden': false,
      };
      final container = await signedIn();
      final notifier = container.read(supporterViewModelProvider.notifier);
      expect(container.read(supporterViewModelProvider).badgeShown, isTrue);

      await notifier.setHidden(true);
      expect(container.read(supporterViewModelProvider).badgeShown, isFalse);
      expect(server.supporterLicences['rider@example.com']!['hidden'], isTrue);

      await notifier.setHidden(false);
      expect(container.read(supporterViewModelProvider).badgeShown, isTrue);
    },
  );

  test('SupporterViewModel_ShouldOfferNoEntry_WhenTheServerHasNoKey', () async {
    server.supporterAvailable = false;
    final container = await signedIn();
    final state = container.read(supporterViewModelProvider);
    expect(state.available, isFalse);
    expect(state.becomeSupporter, isFalse);
  });

  test(
    'SupporterViewModel_ShouldReportFailure_WhenTheServerCannotBeReached',
    () async {
      final container = await signedIn();
      await Future<void>.delayed(Duration.zero); // the first load finishes
      server.unreachable = true;
      final notifier = container.read(supporterViewModelProvider.notifier);
      await notifier.load();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        container.read(supporterViewModelProvider).load.failure?.kind,
        FailureKind.rejected,
      );
    },
  );
}
