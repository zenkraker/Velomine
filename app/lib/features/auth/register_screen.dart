import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/session.dart';
import 'sign_in_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.session});

  final Session session;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  AuthProblem? _problem;
  bool? _approved; // null until the account is created
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _busy = true;
      _problem = null;
    });
    final result = await widget.session.signUp(
      _email.text.trim(),
      _name.text.trim(),
      _password.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.problem != null) {
        _problem = result.problem;
      } else {
        _approved = result.approved;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final created = _approved != null;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createAccount)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: created
                ? [
                    Text(
                      _approved!
                          ? l10n.registeredReady
                          : l10n.registeredPending,
                      key: const Key('registered'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/sign-in'),
                      child: Text(l10n.backToSignIn),
                    ),
                  ]
                : [
                    TextField(
                      key: const Key('email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: l10n.email),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('name'),
                      controller: _name,
                      decoration: InputDecoration(labelText: l10n.name),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('password'),
                      controller: _password,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        helperText: l10n.passwordHint,
                        helperMaxLines: 3, // the hint is long and must not be cut off on a narrow screen
                      ),
                    ),
                    if (_problem != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        authProblemText(l10n, _problem!),
                        key: const Key('register-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('register'),
                      onPressed: _busy ? null : _register,
                      child: Text(l10n.createAccountAction),
                    ),
                    TextButton(
                      onPressed: () => context.go('/sign-in'),
                      child: Text(l10n.haveAccount),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
