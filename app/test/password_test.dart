import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/providers.dart';
import 'package:velomine/features/auth/reset_password_screen.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';

import 'fake_server.dart';

import 'package:velomine/core/l10n.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.add('rider@example.com');
  });

  Future<void> openForgot(WidgetTester tester) async {
    await startApp(tester, server.session(useCookies: false));
    await tester.tap(find.byKey(const Key('forgot-password')));
    await tester.pumpAndSettle();
  }

  Future<void> pumpReset(
    WidgetTester tester, {
    String token = 'good',
    String? email = 'rider@example.com',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(
            (ref) => server.session(useCookies: false),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ResetPasswordScreen(token: token, email: email),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('SignInScreen_ShouldOpenForgotPassword_WhenTheLinkIsPressed', (
    tester,
  ) async {
    await openForgot(tester);

    expect(find.byKey(const Key('forgot-email')), findsOneWidget);
  });

  testWidgets(
    'ForgotPasswordScreen_ShouldSayTheSame_WhenTheAddressIsUnknownOrKnown',
    (tester) async {
      server.smtpConfigured = true;
      server.add('rider@example.com');
      await openForgot(tester);

      Future<void> ask(String address) async {
        await tester.enterText(find.byKey(const Key('forgot-email')), address);
        await tester.tap(find.byKey(const Key('forgot-submit')));
        await tester.pumpAndSettle();
      }

      // An address with no account shows the same words as one with an account, so the form
      // never tells a visitor whether somebody is registered here.
      await ask('stranger@example.com');
      expect(find.byKey(const Key('forgot-sent')), findsOneWidget);
      final unknown = find
          .textContaining('If an account exists')
          .evaluate()
          .single;

      await tester.enterText(find.byKey(const Key('forgot-email')), '');
      await ask('rider@example.com');
      final known = find
          .textContaining('If an account exists')
          .evaluate()
          .single;

      expect((known.widget as Text).data, (unknown.widget as Text).data);
      expect(server.passwordResetEmails, contains('rider@example.com'));
    },
  );

  testWidgets(
    'ForgotPasswordScreen_ShouldExplainTheAdminRoute_WhenEmailIsNotSetUp',
    (tester) async {
      await openForgot(tester);

      await tester.enterText(
        find.byKey(const Key('forgot-email')),
        'rider@example.com',
      );
      await tester.tap(find.byKey(const Key('forgot-submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('forgot-error')), findsOneWidget);
      expect(find.textContaining('club admin'), findsOneWidget);
      expect(server.passwordResetEmails, isEmpty);
    },
  );

  testWidgets(
    'ResetPasswordScreen_ShouldRejectMismatchedPasswords_WhenSubmitting',
    (tester) async {
      await pumpReset(tester);

      await tester.enterText(
        find.byKey(const Key('reset-password')),
        'New-password-1',
      );
      await tester.enterText(
        find.byKey(const Key('reset-confirm')),
        'Other-password-1',
      );
      await tester.tap(find.byKey(const Key('reset-submit')));
      await tester.pumpAndSettle();

      expect(find.text('The two passwords are not the same.'), findsOneWidget);
      expect(find.byKey(const Key('reset-done')), findsNothing);
    },
  );

  testWidgets(
    'ResetPasswordScreen_ShouldChangeThePassword_WhenTheTokenIsGood',
    (tester) async {
      await pumpReset(tester);

      await tester.enterText(
        find.byKey(const Key('reset-password')),
        'New-password-1',
      );
      await tester.enterText(
        find.byKey(const Key('reset-confirm')),
        'New-password-1',
      );
      await tester.tap(find.byKey(const Key('reset-submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reset-done')), findsOneWidget);
      expect(server.accounts['rider@example.com']!.password, 'New-password-1');
    },
  );

  testWidgets(
    'ResetPasswordScreen_ShouldExplainAnInvalidLink_WhenTheTokenIsBad',
    (tester) async {
      await pumpReset(tester, token: 'bad');

      await tester.enterText(
        find.byKey(const Key('reset-password')),
        'New-password-1',
      );
      await tester.enterText(
        find.byKey(const Key('reset-confirm')),
        'New-password-1',
      );
      await tester.tap(find.byKey(const Key('reset-submit')));
      await tester.pumpAndSettle();

      expect(find.textContaining('not valid or has expired'), findsOneWidget);
      expect(find.byKey(const Key('reset-done')), findsNothing);
    },
  );

  testWidgets('ForgotPasswordScreen_ShouldShowItsCaption_WhenTheFormOpens', (
    tester,
  ) async {
    await openForgot(tester);

    expect(find.text('Password help'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Password help')).dy,
      lessThan(tester.getTopLeft(find.text('Reset your password')).dy),
    );
  });

  testWidgets(
    'ResetPasswordScreen_ShouldShowOneButtonAndItsCaption_WhenTheLinkOpens',
    (tester) async {
      await pumpReset(tester);

      expect(
        tester.getTopLeft(find.text('New password').first).dy,
        lessThan(tester.getTopLeft(find.text('Choose a new password')).dy),
      );
      // The form ends at the pinned Set new password button: no way back to asking again.
      expect(find.text('Forgot password?'), findsNothing);
    },
  );

  for (final width in [390.0, 1300.0]) {
    testWidgets(
      'ForgotPasswordScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await openForgot(tester);

        expect(find.byKey(const Key('forgot-submit')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ResetPasswordScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpReset(tester);

        expect(find.byKey(const Key('reset-submit')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
