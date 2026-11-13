import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/hooks.dart';
import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/session.dart';
import '../../l10n/generated/app_localizations.dart';
import 'auth_view_models.dart';
import 'password_field.dart';
import '../../core/tokens.dart';

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
    await ref.read(signInViewModelProvider.notifier).verifyCode(_code.text);
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
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AutofillGroup(
                onDisposeAction: AutofillContextAction.cancel,
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    Text(
                      'Velomine',
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (widget.onChangeServer != null) ...[
                      const SizedBox(height: AppSpacing.sm),
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
                    const SizedBox(height: AppSpacing.xl),
                    if (s.challenge != null) ...[
                      Text(
                        l10n.twoFactorTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(l10n.twoFactorHelp),
                      const SizedBox(height: AppSpacing.lg),
                      AutofillGroup(
                        child: TextField(
                          key: const Key('two-factor-code'),
                          controller: _code,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          decoration: InputDecoration(
                            labelText: l10n.twoFactorCode,
                          ),
                          onSubmitted: (_) => _verifyCode(),
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          message,
                          key: const Key('sign-in-error'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        key: const Key('two-factor-verify'),
                        onPressed: s.command.running ? null : _verifyCode,
                        child: Text(l10n.twoFactorVerify),
                      ),
                      TextButton(
                        key: const Key('two-factor-back'),
                        onPressed: s.command.running
                            ? null
                            : ref
                                  .read(signInViewModelProvider.notifier)
                                  .useAnotherAccount,
                        child: Text(l10n.twoFactorUseAnother),
                      ),
                    ] else ...[
                      TextField(
                        key: const Key('email'),
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        // An address, not a typed-named login: the browser pairs it with the password below
                        // and every password manager recognises the pair.
                        autofillHints: const [
                          AutofillHints.email,
                          AutofillHints.username,
                        ],
                        decoration: InputDecoration(labelText: l10n.email),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PasswordField(
                        fieldKey: const Key('password'),
                        visibilityKey: const Key('password-visibility'),
                        controller: _password,
                        label: l10n.password,
                        autofillHints: const [
                          AutofillHints.password,
                          AutofillHints.newPassword,
                        ],
                        onSubmitted: (_) => _signIn(),
                      ),
                      CheckboxListTile(
                        key: const Key('stay-signed-in'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _staySignedIn,
                        onChanged: (value) =>
                            setState(() => _staySignedIn = value ?? true),
                        title: Text(l10n.staySignedIn),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          key: const Key('forgot-password'),
                          onPressed: () => context.push('/forgot-password'),
                          child: Text(l10n.forgotPassword),
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          message,
                          key: const Key('sign-in-error'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      if (restoreProblem != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton(
                          key: const Key('retry-session'),
                          onPressed: ref
                              .read(signInViewModelProvider.notifier)
                              .retryRestore,
                          child: Text(l10n.tryAgain),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        key: const Key('sign-in'),
                        onPressed: s.command.running ? null : _signIn,
                        child: Text(l10n.signIn),
                      ),
                      if (kIsWeb
                          ? (sso?.enabled ?? false)
                          : (sso?.appSsoEnabled ?? false)) ...[
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton(
                          key: const Key('sso'),
                          onPressed: widget.startSso,
                          child: Text(
                            l10n.continueWith(
                              sso!.displayName ?? l10n.ssoGeneric,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        key: const Key('to-register'),
                        onPressed: () => context.push('/register'),
                        child: Text(l10n.createAccount),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
