import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import 'auth_view_models.dart';
import 'password_field.dart';
import 'sign_in_screen.dart';
import '../../core/tokens.dart';
import '../auth/auth_page.dart';

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

  Future<void> _register() {
    // The manager is told the form is done before this screen swaps to the "created" view, so the
    // password it just saw is the one it offers to save.
    TextInput.finishAutofillContext();
    return ref
        .read(registerViewModelProvider.notifier)
        .register(_email.text.trim(), _name.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(registerViewModelProvider);
    final created = s.approved != null;
    final l10n = context.l10n;
    return AuthPage(
      title: l10n.createAccount,
      children: created
          ? [
              Text(
                s.approved! ? l10n.registeredReady : l10n.registeredPending,
                key: const Key('registered'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => context.go('/sign-in'),
                child: Text(l10n.backToSignIn),
              ),
            ]
          : [
              // One group, so the manager sees an address, a name and a new password that belong together
              // and offers to generate the password and to save it once the form is sent.
              AutofillGroup(
                onDisposeAction: AutofillContextAction.cancel,
                child: Column(
                  children: [
                    TextField(
                      key: const Key('email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.email,
                        AutofillHints.username,
                      ],
                      decoration: InputDecoration(labelText: l10n.email),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      key: const Key('name'),
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: InputDecoration(labelText: l10n.name),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PasswordField(
                      fieldKey: const Key('password'),
                      visibilityKey: const Key('password-visibility'),
                      controller: _password,
                      label: l10n.password,
                      helperText: l10n.passwordHint,
                      helperMaxLines: 3, // the hint is long and must not be cut off on a narrow screen
                      // A new password, so the manager offers to generate a strong one.
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _register(),
                    ),
                  ],
                ),
              ),
              if (s.problem != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  authProblemText(l10n, s.problem!),
                  key: const Key('register-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
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
    );
  }
}
