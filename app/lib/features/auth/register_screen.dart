import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import 'auth_view_models.dart';
import 'password_field.dart';
import 'sign_in_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() => ref
      .read(registerViewModelProvider.notifier)
      .register(_email.text.trim(), _name.text.trim(), _password.text);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(registerViewModelProvider);
    final created = s.approved != null;
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
                      s.approved!
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
                    PasswordField(
                      fieldKey: const Key('password'),
                      visibilityKey: const Key('password-visibility'),
                      controller: _password,
                      label: l10n.password,
                      helperText: l10n.passwordHint,
                      helperMaxLines: 3, // the hint is long and must not be cut off on a narrow screen
                      autofillHints: const [AutofillHints.newPassword],
                    ),
                    if (s.problem != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        authProblemText(l10n, s.problem!),
                        key: const Key('register-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('register'),
                      onPressed: s.command.running ? null : _register,
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
