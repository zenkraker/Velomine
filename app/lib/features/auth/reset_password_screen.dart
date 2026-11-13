import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import 'auth_page.dart';
import '../../l10n/generated/app_localizations.dart';
import 'auth_state.dart';
import 'auth_view_models.dart';
import 'password_field.dart';
import '../../core/tokens.dart';

String resetProblemText(AppLocalizations l10n, ResetProblem problem) =>
    switch (problem) {
      ResetProblem.invalidLink => l10n.resetPasswordInvalid,
      ResetProblem.tooShort => l10n.passwordTooShort,
      ResetProblem.mismatch => l10n.passwordsDoNotMatch,
      ResetProblem.tooMany => l10n.forgotPasswordTooMany,
      ResetProblem.failed => l10n.passwordChangeFailed,
    };

/// The page the one-time email link opens. The token and email come from the URL fragment, so the browser never
/// sends them to the server; the reset call carries them in its body instead.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.token,
    required this.email,
  });

  final String? token;
  final String? email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _reset() => ref
      .read(resetPasswordViewModelProvider.notifier)
      .reset(
        token: widget.token,
        email: widget.email,
        password: _password.text,
        confirm: _confirm.text,
      );

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(resetPasswordViewModelProvider);
    final l10n = context.l10n;
    return AuthPage(
      eyebrow: l10n.authEyebrowReset,
      title: l10n.resetPasswordTitle,
      help: s.done ? null : l10n.resetPasswordHelp,
      onBack: () => context.go('/sign-in'),
      children: [
        if (s.done) ...[
          Text(l10n.resetPasswordDone, key: const Key('reset-done')),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            key: const Key('reset-to-sign-in'),
            onPressed: () => context.go('/sign-in'),
            child: Text(l10n.goToSignIn),
          ),
        ] else ...[
          PasswordField(
            fieldKey: const Key('reset-password'),
            visibilityKey: const Key('reset-password-visibility'),
            controller: _password,
            label: l10n.newPassword,
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: AppSpacing.md),
          PasswordField(
            fieldKey: const Key('reset-confirm'),
            visibilityKey: const Key('reset-confirm-visibility'),
            controller: _confirm,
            label: l10n.confirmPassword,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _reset(),
          ),
          if (s.problem != null) ...[
            const SizedBox(height: AppSpacing.md),
            AuthFailure(
              keyName: 'reset-error',
              message: resetProblemText(l10n, s.problem!),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            key: const Key('reset-submit'),
            onPressed: s.command.running ? null : _reset,
            child: Text(l10n.setNewPassword),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            key: const Key('reset-ask-again'),
            onPressed: () => context.go('/forgot-password'),
            child: Text(l10n.forgotPassword),
          ),
        ],
      ],
    );
  }
}
