import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/placeholder_block.dart';
import 'package:velomine/core/tokens.dart';
import 'package:velomine/core/widgets/loading_state.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('LoadingState_ShouldShowOneIndicatorInATokenBlock_WhenBuilt', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const LoadingState()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.getSize(find.byType(LoadingState)).height,
      AppLoading.blockHeight,
    );
  });

  testWidgets('LoadingState_ShouldLabelTheIndicator_WhenBuilt', (tester) async {
    await tester.pumpWidget(_host(const LoadingState()));

    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.semanticsLabel, 'Loading');
  });

  testWidgets('LoadingState_ShouldStopSpinning_WhenMotionIsReduced', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const LoadingState(), reduceMotion: true));

    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.value, isNotNull);
  });

  testWidgets('LoadingStateRows_ShouldDrawPlaceholderRows_WhenCountIsGiven', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const LoadingState.rows(count: 4)));

    expect(find.byType(PlaceholderBlock), findsNWidgets(4));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
