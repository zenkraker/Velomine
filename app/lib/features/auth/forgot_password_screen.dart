import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import 'auth_page.dart';
import '../../l10n/generated/app_localizations.dart';
import 'auth_state.dart';
import 'auth_view_models.dart';
import '../../core/tokens.dart';

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
    return AuthPage(
      eyebrow: l10n.authEyebrowForgot,
      title: l10n.forgotPasswordTitle,
      help: l10n.forgotPasswordHelp,
      onBack: () => context.go('/sign-in'),
      children: [
        TextField(
          key: const Key('forgot-email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(labelText: l10n.email),
          onSubmitted: (_) => _send(),
        ),
        if (s.sent) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.forgotPasswordSent, key: const Key('forgot-sent')),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            key: const Key('forgot-back'),
            onPressed: () => context.go('/sign-in'),
            child: Text(l10n.goToSignIn),
          ),
        ] else ...[
          if (s.problem != null) ...[
            const SizedBox(height: AppSpacing.md),
            AuthFailure(
              keyName: 'forgot-error',
              message: forgotProblemText(l10n, s.problem!),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            key: const Key('forgot-submit'),
            onPressed: s.command.running ? null : _send,
            child: Text(l10n.sendResetLink),
          ),
        ],
      ],
    );
  }
}
