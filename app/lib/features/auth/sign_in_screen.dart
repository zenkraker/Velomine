import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/hooks.dart';
import '../../core/language_choice.dart';
import '../../core/session.dart';

String authProblemText(AuthProblem problem) => switch (problem) {
  AuthProblem.wrongPassword => 'The email or password is not right.',
  AuthProblem.notApproved =>
    'Your account is waiting for an admin to approve it.',
  AuthProblem.lockedOut =>
    'Too many wrong attempts. Try again in a few minutes.',
  AuthProblem.signUpClosed => 'Sign-up is closed on this server.',
  AuthProblem.weakPassword => 'The password needs at least 10 characters with a capital letter, a small letter and a digit.',
  AuthProblem.emailTaken => 'There is already an account with this email.',
  AuthProblem.unavailable => 'Could not reach the server. Try again.',
};

String ssoErrorText(String code) => switch (code) {
  'not_approved' => 'Your account is waiting for an admin to approve it.',
  'email_not_verified' =>
    'Your sign-in provider has not verified your email address.',
  'no_account' => 'There is no account for you here yet. Ask an admin.',
  'locked_out' => 'This account is locked. Try again in a few minutes.',
  'no_email' => 'Your sign-in provider did not share an email address.',
  _ => 'Single sign-on did not work. Try again.',
};

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.session,
    required this.startSso,
    required this.languageChoice,
    this.onChangeServer,
  });

  final Session session;
  final SsoStarter startSso;
  final LanguageChoice languageChoice;
  final Future<void> Function()? onChangeServer;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  late String? _ssoError = widget.session.ssoError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
      _ssoError = null;
    });
    final problem = await widget.session.signIn(
      _email.text.trim(),
      _password.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (problem != null) _error = authProblemText(problem);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sso = widget.session.sso;
    final restoreProblem = widget.session.restoreProblem;
    final message =
        _error ??
        (restoreProblem == null
            ? (_ssoError == null ? null : ssoErrorText(_ssoError!))
            : authProblemText(restoreProblem));
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: LanguageChoiceButton(choice: widget.languageChoice),
            ),
          ),
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
                              'Server: ${widget.session.serverUrl}',
                              key: const Key('server-address'),
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          TextButton(
                            key: const Key('change-server'),
                            onPressed: widget.onChangeServer,
                            child: const Text('Change'),
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
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('password'),
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: 'Password'),
                      onSubmitted: (_) => _signIn(),
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
                        onPressed: widget.session.retryRestore,
                        child: const Text('Try again'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('sign-in'),
                      onPressed: _busy ? null : _signIn,
                      child: const Text('Sign in'),
                    ),
                    if (sso?.enabled ?? false) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        key: const Key('sso'),
                        onPressed: widget.startSso,
                        child: Text(
                          'Continue with ${sso!.displayName ?? 'single sign-on'}',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextButton(
                      key: const Key('to-register'),
                      onPressed: () => context.go('/register'),
                      child: const Text('Create an account'),
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
