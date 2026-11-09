import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../l10n/generated/app_localizations.dart';
import 'auth_state.dart';
import 'auth_view_models.dart';

String forgotProblemText(AppLocalizations l10n, ForgotProblem problem) =>
    switch (problem) {
      ForgotProblem.missingEmail => l10n.errorEnterEmail,
      ForgotProblem.emailNotSetUp => l10n.forgotPasswordUnavailable,
      ForgotProblem.tooMany => l10n.forgotPasswordTooMany,
      ForgotProblem.failed => l10n.forgotPasswordFailed,
    };

/// Asks for the email address and always says the same thing: the answer must not reveal who is registered.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() => ref
      .read(forgotPasswordViewModelProvider.notifier)
      .send(_email.text.trim());

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(forgotPasswordViewModelProvider);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/sign-in')),
        title: Text(l10n.forgotPasswordTitle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              Text(l10n.forgotPasswordHelp),
              const SizedBox(height: 16),
              TextField(
                key: const Key('forgot-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(labelText: l10n.email),
                onSubmitted: (_) => _send(),
              ),
              if (s.sent) ...[
                const SizedBox(height: 16),
                Text(l10n.forgotPasswordSent, key: const Key('forgot-sent')),
                const SizedBox(height: 12),
                TextButton(
                  key: const Key('forgot-back'),
                  onPressed: () => context.go('/sign-in'),
                  child: Text(l10n.goToSignIn),
                ),
              ] else ...[
                if (s.problem != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    forgotProblemText(l10n, s.problem!),
                    key: const Key('forgot-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('forgot-submit'),
                  onPressed: s.command.running ? null : _send,
                  child: Text(l10n.sendResetLink),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
