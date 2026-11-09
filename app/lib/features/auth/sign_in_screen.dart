import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/hooks.dart';
import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/session.dart';
import '../../l10n/generated/app_localizations.dart';
import 'auth_view_models.dart';

String authProblemText(AppLocalizations l10n, AuthProblem problem) =>
    switch (problem) {
      AuthProblem.wrongPassword => l10n.authWrongPassword,
      AuthProblem.notApproved => l10n.authNotApproved,
      AuthProblem.lockedOut => l10n.authLockedOut,
      AuthProblem.signUpClosed => l10n.authSignUpClosed,
      AuthProblem.weakPassword => l10n.authWeakPassword,
      AuthProblem.emailTaken => l10n.authEmailTaken,
      AuthProblem.unavailable => l10n.authUnavailable,
    };

String ssoErrorText(AppLocalizations l10n, String code) => switch (code) {
  'not_approved' => l10n.authNotApproved,
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

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() => ref
      .read(signInViewModelProvider.notifier)
      .signIn(_email.text.trim(), _password.text);

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
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      'Velomine',
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (widget.onChangeServer != null) ...[
                      const SizedBox(height: 8),
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
                    const SizedBox(height: 24),
                    TextField(
                      key: const Key('email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(labelText: l10n.email),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('password'),
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(labelText: l10n.password),
                      onSubmitted: (_) => _signIn(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const Key('forgot-password'),
                        onPressed: () => context.go('/forgot-password'),
                        child: Text(l10n.forgotPassword),
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        message,
                        key: const Key('sign-in-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (restoreProblem != null) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        key: const Key('retry-session'),
                        onPressed: ref
                            .read(signInViewModelProvider.notifier)
                            .retryRestore,
                        child: Text(l10n.tryAgain),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('sign-in'),
                      onPressed: s.command.running ? null : _signIn,
                      child: Text(l10n.signIn),
                    ),
                    if (sso?.enabled ?? false) ...[
                      const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    TextButton(
                      key: const Key('to-register'),
                      onPressed: () => context.go('/register'),
                      child: Text(l10n.createAccount),
                    ),
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
