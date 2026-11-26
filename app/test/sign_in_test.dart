import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velomine/core/widgets/bottom_action_bar.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;
  setUp(() => server = FakeServer());

  Future<void> signIn(
    WidgetTester tester,
    String email,
    String password,
  ) async {
    await tester.enterText(find.byKey(const Key('email')), email);
    await tester.enterText(find.byKey(const Key('password')), password);
    // The button follows the fields, so on a short window it is below the fold.
    await tester.ensureVisible(find.byKey(const Key('sign-in')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sign-in')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'SignInScreen_ShouldShowFormWithoutSsoButton_WhenSingleSignOnIsOff',
    (tester) async {
      await startApp(tester, server.session(useCookies: false));

      expect(find.byKey(const Key('sign-in')), findsOneWidget);
      expect(find.byKey(const Key('sso')), findsNothing);
    },
  );

  testWidgets('SignInScreen_ShouldShowItsTitle_WhenTheFormOpens', (
    tester,
  ) async {
    await startApp(tester, server.session(useCookies: false));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text('Sign in to see your rides and your form.'),
      findsOneWidget,
    );
  });

  for (final width in [390.0, 1300.0]) {
    testWidgets('SignInScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: false));

      expect(find.byKey(const Key('sign-in')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'SignInScreen_ShouldKeepSignInInTheBottomBar_WhenTheKeyboardIsOpen',
    (tester) async {
      await startApp(tester, server.session(useCookies: false));
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('sign-in'));
      expect(
        find.ancestor(of: button, matching: find.byType(BottomActionBar)),
        findsOneWidget,
      );
      final bottom = tester.getBottomLeft(button).dy;
      final height =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(
        bottom,
        lessThanOrEqualTo(height - 300 / tester.view.devicePixelRatio),
      );
      expect(bottom, greaterThan(0));
    },
  );

  testWidgets(
    'ForgotPasswordScreen_ShouldGoBackToSignIn_WhenTheBackArrowIsTapped',
    (tester) async {
      await startApp(tester, server.session(useCookies: false));
      await tester.ensureVisible(find.byKey(const Key('forgot-password')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('forgot-password')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('forgot-submit')), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sign-in')), findsOneWidget);
      expect(find.byKey(const Key('forgot-submit')), findsNothing);
    },
  );

  testWidgets('App_ShouldGoBackToSignIn_WhenAnApiCallAnswers401', (
    tester,
  ) async {
    final rider = server.add('rider@example.com');
    server.signInBrowser(rider);
    server.unauthorized.add('/api/v1/rides');

    await startApp(tester, server.session(useCookies: true));

    expect(find.byKey(const Key('sign-in')), findsOneWidget);
  });

  testWidgets(
    'SignInScreen_ShouldShowSsoButtonAndStartIt_WhenServerOffersSso',
    (tester) async {
      server.ssoEnabled = true;
      var started = false;
      await startApp(
        tester,
        server.session(useCookies: true),
        startSso: () async => started = true,
      );

      expect(find.text('Continue with Test IdP'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('sso')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('sso')));
      expect(started, isTrue);
    },
  );

  testWidgets('SignInScreen_ShouldExplainSsoError_WhenVisitorIsSentBack', (
    tester,
  ) async {
    await startApp(
      tester,
      server.session(useCookies: false, ssoError: 'not_approved'),
    );

    expect(find.textContaining('waiting for an admin'), findsOneWidget);
  });

  testWidgets('SignInScreen_ShouldShowServerAndAllowChange_WhenOnAPhone', (
    tester,
  ) async {
    var changed = false;
    await startApp(
      tester,
      server.session(useCookies: false),
      onChangeServer: () async => changed = true,
    );

    expect(find.byKey(const Key('server-address')), findsOneWidget);
    expect(find.text('Server: http://server'), findsOneWidget);

    await tester.tap(find.byKey(const Key('change-server')));
    expect(changed, isTrue);
  });

  testWidgets(
    'SignInScreen_ShouldOfferCredentialsToPasswordManagers_WhenTheFormOpens',
    (tester) async {
      await startApp(tester, server.session(useCookies: false));
      TextField field(String key) =>
          tester.widget<TextField>(find.byKey(Key(key)));

      expect(
        field('email').autofillHints,
        containsAll([AutofillHints.email, AutofillHints.username]),
      );
      expect(field('email').textInputAction, TextInputAction.next);
      expect(field('password').autofillHints!.first, AutofillHints.password);
      expect(field('password').textInputAction, TextInputAction.done);
    },
  );

  testWidgets(
    'SignInScreen_ShouldSubmitTheSaveToPasswordManagers_WhenSigningIn',
    (tester) async {
      server.add('rider@example.com');
      await startApp(tester, server.session(useCookies: false));
      final textInput = tester.testTextInput..log.clear();

      await signIn(tester, 'rider@example.com', 'Rider-pass-123');

      // Before the screen leaves, so the browser still sees the form it just saved.
      final saves = textInput.log.where(
        (call) => call.method == 'TextInput.finishAutofillContext',
      );
      expect(saves, isNotEmpty);
      expect(saves.first.arguments, isTrue);
    },
  );

  testWidgets('SignInScreen_ShouldExplainWrongPassword_WhenSignInFails', (
    tester,
  ) async {
    server.add('rider@example.com');
    await startApp(tester, server.session(useCookies: false));

    await signIn(tester, 'rider@example.com', 'Not-the-password-1');

    expect(find.textContaining('not right'), findsOneWidget);
    expect(find.byKey(const Key('upload')), findsNothing);
  });

  testWidgets(
    'SignInScreen_ShouldIgnoreSpacesAroundCredentials_WhenSigningIn',
    (tester) async {
      server.add('rider@example.com');
      await startApp(tester, server.session(useCookies: false));

      await signIn(tester, '  rider@example.com  ', '  Rider-pass-123  ');

      expect(find.byKey(const Key('upload')), findsOneWidget);
      expect(find.byKey(const Key('sign-in-error')), findsNothing);
    },
  );

  testWidgets('SignInScreen_ShouldRevealTheTypedPassword_WhenShowIsTapped', (
    tester,
  ) async {
    await startApp(tester, server.session(useCookies: false));
    TextField password() =>
        tester.widget<TextField>(find.byKey(const Key('password')));

    // The design words the control, it does not draw an eye over it.
    expect(find.text('Show'), findsOneWidget);
    expect(find.byTooltip('Show password'), findsOneWidget);
    expect(password().obscureText, isTrue);
    await tester.enterText(find.byKey(const Key('password')), 'secret-1');
    await tester.tap(find.byKey(const Key('password-visibility')));
    await tester.pump();
    expect(password().obscureText, isFalse);
    expect(find.text('Hide'), findsOneWidget);
    expect(find.byTooltip('Hide password'), findsOneWidget);

    await tester.tap(find.byKey(const Key('password-visibility')));
    await tester.pump();
    expect(password().obscureText, isTrue);
  });

  testWidgets(
    'SignInScreen_ShouldDrawForgotPasswordAcrossTheColumn_WhenTheFormOpens',
    (tester) async {
      await startApp(tester, server.session(useCookies: false));
      await tester.ensureVisible(find.byKey(const Key('forgot-password')));
      await tester.pump();

      // A block text button under the fields, not a link pushed to the right edge.
      expect(
        tester.getSize(find.byKey(const Key('forgot-password'))).width,
        moreOrLessEquals(
          tester.getSize(find.byKey(const Key('email'))).width,
          epsilon: 1,
        ),
      );
    },
  );

  testWidgets('SignInScreen_ShouldStayLoggedInByDefault_WhenTheFormOpens', (
    tester,
  ) async {
    server.add('rider@example.com');
    await startApp(tester, server.session(useCookies: false));

    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('stay-signed-in')))
          .value,
      isTrue,
    );

    await signIn(tester, 'rider@example.com', 'Rider-pass-123');

    expect(server.lastRememberMe, isTrue);
  });

  testWidgets('SignInScreen_ShouldNotStayLoggedIn_WhenTheSwitchIsTapped', (
    tester,
  ) async {
    server.add('rider@example.com');
    await startApp(tester, server.session(useCookies: false));
    await tester.tap(find.byKey(const Key('stay-signed-in')));
    await tester.pump();

    await signIn(tester, 'rider@example.com', 'Rider-pass-123');

    expect(server.lastRememberMe, isFalse);
  });

  testWidgets('SignInScreen_ShouldTellToWait_WhenAccountIsNotApproved', (
    tester,
  ) async {
    server.add('rider@example.com', approved: false);
    await startApp(tester, server.session(useCookies: false));

    await signIn(tester, 'rider@example.com', 'Rider-pass-123');

    expect(find.textContaining('waiting for an admin'), findsOneWidget);
  });

  testWidgets(
    'SignInScreen_ShouldOpenRidesAndSendToken_WhenSigningInWithToken',
    (tester) async {
      server.add('rider@example.com', name: 'Alex Rider');
      server.rides.add(
        rideJson(
          'r1',
          'ready',
          distanceM: 42300,
          movingS: 5400,
          avgPowerW: 190,
        ),
      );
      await startApp(tester, server.session(useCookies: false));

      await signIn(tester, 'rider@example.com', 'Rider-pass-123');

      expect(find.byKey(const Key('upload')), findsOneWidget);
      await openAccountMenu(tester);
      expect(find.text('Alex Rider'), findsOneWidget);
      expect(find.text('42.3 km'), findsOneWidget);
      expect(
        server.requests,
        containsAllInOrder([
          'POST /api/v1/accounts/login',
          'GET /api/v1/accounts/me',
          'GET /api/v1/rides',
        ]),
      );
    },
  );

  testWidgets(
    'SignInScreen_ShouldGoStraightToRides_WhenThereIsASessionCookie',
    (tester) async {
      server.signInBrowser(server.add('rider@example.com'));
      await startApp(tester, server.session(useCookies: true));

      expect(find.byKey(const Key('upload')), findsOneWidget);
      expect(find.byKey(const Key('sign-in')), findsNothing);
    },
  );

  testWidgets('SignInScreen_ShouldReturnToSignInForm_WhenSigningOut', (
    tester,
  ) async {
    server.signInBrowser(server.add('rider@example.com'));
    await startApp(tester, server.session(useCookies: true));

    await openAccount(tester, 'sign-out');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign-in')), findsOneWidget);
    expect(server.requests, contains('POST /api/v1/accounts/logout'));
  });
}
