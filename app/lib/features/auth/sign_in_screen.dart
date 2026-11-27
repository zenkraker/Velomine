import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/hooks.dart';
import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/session.dart';
import '../../core/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import 'auth_page.dart';
import 'auth_view_models.dart';
import 'password_field.dart';
import '../../core/widgets/app_text_field.dart';

String authProblemText(AppLocalizations l10n, AuthProblem problem) =>
    switch (problem) {
      AuthProblem.wrongPassword => l10n.authWrongPassword,
      AuthProblem.wrongCode => l10n.authWrongCode,
      AuthProblem.notApproved => l10n.authNotApproved,
      AuthProblem.emailNotConfirmed => l10n.authEmailNotConfirmed,
      AuthProblem.lockedOut => l10n.authLockedOut,
      AuthProblem.signUpClosed => l10n.authSignUpClosed,
      AuthProblem.weakPassword => l10n.authWeakPassword,
      AuthProblem.emailTaken => l10n.authEmailTaken,
      AuthProblem.unavailable => l10n.authUnavailable,
    };

String ssoErrorText(AppLocalizations l10n, String code) => switch (code) {
  'not_approved' => l10n.authNotApproved,
  'email_not_confirmed' => l10n.authEmailNotConfirmed,
  'email_not_verified' => l10n.ssoEmailNotVerified,
  'no_account' => l10n.ssoNoAccount,
  'locked_out' => l10n.ssoLockedOut,
  'no_email' => l10n.ssoNoEmail,
  _ => l10n.ssoFailed,
};

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, required this.startSso, this.onChangeServer});

  final SsoStarter startSso;
  final Future<void> Function()? onChangeServer;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  bool _staySignedIn = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    // The browser only offers to save what was submitted while its login form was still there, so the
    // context is finished before this screen leaves the tree. On the phone it asks to save too.
    TextInput.finishAutofillContext();
    await ref
        .read(signInViewModelProvider.notifier)
        .signIn(_email.text.trim(), _password.text, rememberMe: _staySignedIn);
  }

  Future<void> _verifyCode() async {
    await ref
        .read(signInViewModelProvider.notifier)
        .verifyCode(_email.text.trim(), _password.text, _code.text);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final state = ref.watch(sessionViewModelProvider);
    final s = ref.watch(signInViewModelProvider);
    final sso = state.sso;
    final restoreProblem = state.restoreProblem;
    final ssoError = state.ssoError;
    final l10n = context.l10n;
    final message = s.problem != null
        ? authProblemText(l10n, s.problem!)
        : (restoreProblem != null
              ? authProblemText(l10n, restoreProblem)
              : (ssoError == null ? null : ssoErrorText(l10n, ssoError)));
    return AuthPage(
      title: l10n.signInTitle,
      help: l10n.signInHelp,
      primaryLabel: s.needsCode ? l10n.twoFactorVerify : l10n.signIn,
      primaryKey: Key(s.needsCode ? 'two-factor-verify' : 'sign-in'),
      onPrimary: s.needsCode ? _verifyCode : _signIn,
      primaryBusy: s.command.running,
      children: [
        if (widget.onChangeServer != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  l10n.serverLabel(session.serverUrl),
                  key: const Key('server-address'),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton(
                key: const Key('change-server'),
                onPressed: widget.onChangeServer,
                child: Text(l10n.change),
              ),
            ],
          ),
        ],
        if (s.needsCode) ...[
          Text(
            l10n.twoFactorTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(l10n.twoFactorHelp),
          AutofillGroup(
            child: AppTextField(
              fieldKey: const Key('two-factor-code'),
              controller: _code,
              label: l10n.twoFactorCode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              onDone: (_) => _verifyCode(),
            ),
          ),
          if (message != null) ...[
            AuthFailure(keyName: 'sign-in-error', message: message),
          ],
          TextButton(
            key: const Key('two-factor-back'),
            onPressed: s.command.running
                ? null
                : ref.read(signInViewModelProvider.notifier).useAnotherAccount,
            child: Text(l10n.twoFactorUseAnother),
          ),
        ] else ...[
          // One group, so the two boxes are one login form to the browser and to the phone's autofill
          // service; alone, each is its own context and a password manager cannot pair them.
          AutofillGroup(
            onDisposeAction: AutofillContextAction.cancel,
            child: Column(
              spacing: AppSpacing.md,
              children: [
                AppTextField(
                  fieldKey: const Key('email'),
                  controller: _email,
                  label: l10n.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  // `username` alone: on the web the hints become one `autocomplete` value, and
                  // several field names make it invalid, so the browser ignores it.
                  autofillHints: const [AutofillHints.username],
                ),
                PasswordField(
                  fieldKey: const Key('password'),
                  visibilityKey: const Key('password-visibility'),
                  controller: _password,
                  label: l10n.password,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _signIn(),
                ),
              ],
            ),
          ),
          SwitchListTile(
            key: const Key('stay-signed-in'),
            contentPadding: EdgeInsets.zero,
            value: _staySignedIn,
            onChanged: (value) => setState(() => _staySignedIn = value),
            title: Text(l10n.staySignedIn),
          ),
          // Below the fields and above the ways in, as the design draws it: a full-width text button, not a
          // link pushed to the right edge.
          SizedBox(
            width: double.infinity,
            child: TextButton(
              key: const Key('forgot-password'),
              onPressed: () => context.push('/forgot-password'),
              child: Text(l10n.forgotPassword),
            ),
          ),
          if (message != null) ...[
            AuthFailure(keyName: 'sign-in-error', message: message),
          ],
          if (restoreProblem != null) ...[
            OutlinedButton(
              key: const Key('retry-session'),
              onPressed: ref
                  .read(signInViewModelProvider.notifier)
                  .retryRestore,
              child: Text(l10n.tryAgain),
            ),
          ],
          if (kIsWeb
              ? (sso?.enabled ?? false)
              : (sso?.appSsoEnabled ?? false)) ...[
            const AuthOr(),
            OutlinedButton(
              key: const Key('sso'),
              onPressed: widget.startSso,
              child: Text(
                l10n.continueWith(sso!.displayName ?? l10n.ssoGeneric),
              ),
            ),
          ],
          TextButton(
            key: const Key('to-register'),
            onPressed: () => context.push('/register'),
            child: Text(l10n.createAccount),
          ),
        ],
      ],
    );
  }
}
