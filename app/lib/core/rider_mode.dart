import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import 'providers.dart';

/// How the member rides. It decides only what their own screens show first: nothing is locked, hidden for
/// good or removed, and the server never filters by it. The slugs are stored on the account and never renamed.
enum RiderMode {
  justRiding('just_riding'),
  withGoals('with_goals'),
  training('training');

  const RiderMode(this.slug);

  /// What the account stores and the API carries.
  final String slug;
}

/// What a never-chosen account shows, and what "Decide later" saves.
const defaultRiderMode = RiderMode.justRiding;

/// The mode a slug names, or null for a slug this build does not know (a newer server). Never throws.
RiderMode? knownRiderMode(String? slug) {
  for (final mode in RiderMode.values) {
    if (mode.slug == slug) return mode;
  }
  return null;
}

/// The facts a ride card may show, by the id the card gives each one.
const _distance = 'distance';
const _movingTime = 'moving-time';
const _climbing = 'climbing';
const _averageSpeed = 'average-speed';
const _averageHeartRate = 'average-heart-rate';
const _averagePower = 'average-power';
const _averageCadence = 'average-cadence';

/// The charts a ride may show, by the id of the series they draw.
const _elevationChart = 'elevation';
const _speedChart = 'speed';
const _heartRateChart = 'heartrate';
const _powerChart = 'power';
const _cadenceChart = 'cadence';
const _wPrimeChart = 'wprime';

/// What the member's own screens put first, for one rider mode. One table, so a screen never branches on the
/// enum: it asks the layout what to show and folds the rest under one button.
class RiderModeLayout {
  const RiderModeLayout({
    required this.foldAdvanced,
    required this.showZonesAndCharts,
    required this.showIntensity,
    required this.rideListFacts,
    required this.rideChartIds,
    required this.effortWord,
  });

  /// The plain layout: every number and chart in today's order. Training, and anything that cannot say which
  /// mode it is (an older server, an account not read yet, a mode from a newer build).
  static const full = RiderModeLayout(
    foldAdvanced: false,
    showZonesAndCharts: true,
    showIntensity: true,
    rideListFacts: {
      _distance,
      _movingTime,
      _climbing,
      _averageSpeed,
      _averageHeartRate,
      _averagePower,
      _averageCadence,
    },
    rideChartIds: {
      _elevationChart,
      _speedChart,
      _heartRateChart,
      _powerChart,
      _cadenceChart,
      _wPrimeChart,
    },
    effortWord: false,
  );

  /// Just riding: the route, the distance and how the ride went, with everything else one tap away.
  static const _justRiding = RiderModeLayout(
    foldAdvanced: true,
    showZonesAndCharts: false,
    showIntensity: false,
    rideListFacts: {_distance, _movingTime},
    rideChartIds: {},
    effortWord: true,
  );

  /// Riding with goals: the easy / moderate / hard split and the main charts, with the training lab folded.
  static const _withGoals = RiderModeLayout(
    foldAdvanced: true,
    showZonesAndCharts: true,
    showIntensity: true,
    rideListFacts: {_distance, _movingTime, _averageHeartRate},
    rideChartIds: {_elevationChart, _speedChart, _heartRateChart},
    effortWord: true,
  );

  static RiderModeLayout of(RiderMode mode) => switch (mode) {
    RiderMode.justRiding => _justRiding,
    RiderMode.withGoals => _withGoals,
    RiderMode.training => full,
  };

  /// Elements the member sees first; everything else goes under "Show more analysis" or "Show all details".
  final bool foldAdvanced;

  /// Heart-rate zones and the main ride charts, for riding with goals and above.
  final bool showZonesAndCharts;

  /// The easy / moderate / hard split, from power when the ride has it and heart rate otherwise.
  final bool showIntensity;

  final Set<String> rideListFacts;
  final Set<String> rideChartIds;

  /// The one plain-word effort line on a ride, which only the simple modes have.
  final bool effortWord;
}

/// The single rule: what the mode on the account means for the app right now. It is a pure function of
/// `session.me`, so there is no second copy of the mode and no cache to go stale.
class RiderModeSituation {
  const RiderModeSituation({
    required this.layout,
    required this.prompt,
    required this.settings,
    this.mode,
  });

  /// [me] is `session.me`: null before it is read, and on the sign-in screen.
  static RiderModeSituation of(MeResponse? me) {
    // Not read yet: show everything and ask nothing, so a training rider never meets the wrong prompt.
    if (me == null) {
      return const RiderModeSituation(
        layout: RiderModeLayout.full,
        prompt: false,
        settings: false,
      );
    }

    // An older server has no rider modes: no question, no row, and the app as it was.
    if (me.riderModeSupported != true) {
      return const RiderModeSituation(
        layout: RiderModeLayout.full,
        prompt: false,
        settings: false,
      );
    }

    final mode = knownRiderMode(me.riderMode);
    // A slug this build does not know (a newer server) shows everything and never crashes: nothing is marked.
    final unknown = me.riderMode != null && mode == null;
    return RiderModeSituation(
      // Never chosen shows just riding.
      layout: unknown
          ? RiderModeLayout.full
          : RiderModeLayout.of(mode ?? defaultRiderMode),
      prompt: me.riderMode == null,
      settings: true,
      mode: mode,
    );
  }

  final RiderModeLayout layout;

  /// Ask "How do you ride?" now.
  final bool prompt;

  /// Show the "How I ride" row in Settings.
  final bool settings;

  /// The mode in use; null when the account never chose, or chose one this build does not know.
  final RiderMode? mode;
}

/// The mode on screen, from the account. A screen that shows the member's own data watches this; a screen
/// that can show someone else's takes the layout as a parameter instead.
final riderModeSituationProvider = Provider<RiderModeSituation>(
  (ref) => RiderModeSituation.of(ref.watch(sessionViewModelProvider).me),
);

final riderLayoutProvider = Provider<RiderModeLayout>(
  (ref) => ref.watch(riderModeSituationProvider).layout,
);
