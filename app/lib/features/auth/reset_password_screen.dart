import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:velomine_api/api.dart';

import '../../core/l10n.dart';
import '../../core/session.dart';

/// The page the one-time email link opens. The token and email come from the URL fragment, so the browser never
/// sends them to the server; the reset call carries them in its body instead.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.session,
    required this.token,
    required this.email,
  });

  final Session session;
  final String? token;
  final String? email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    final l10n = context.l10n;
    final token = widget.token;
    final email = widget.email;
    if (token == null || token.isEmpty || email == null || email.isEmpty) {
      setState(() => _error = l10n.resetPasswordInvalid);
      return;
    }
    if (_password.text.length < 10) {
      setState(() => _error = l10n.passwordTooShort);
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = l10n.passwordsDoNotMatch);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    String? error;
    try {
      await widget.session.accounts.resetPassword(
        ResetPasswordRequest(
          email: email,
          token: token,
          newPassword: _password.text,
        ),
      );
    } on ApiException catch (e) {
      error = switch (e.code) {
        400 => l10n.resetPasswordInvalid,
        429 => l10n.forgotPasswordTooMany,
        _ => l10n.passwordChangeFailed,
      };
    } on Object {
      error = l10n.passwordChangeFailed;
    }

    if (!mounted) return;
    if (error == null) {
      // The stamp changed: this session (if there was one) is no longer valid.
      await widget.session.signOut();
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      _done = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/sign-in')),
        title: Text(l10n.resetPasswordTitle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              if (_done) ...[
                Text(l10n.resetPasswordDone, key: const Key('reset-done')),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('reset-to-sign-in'),
                  onPressed: () => context.go('/sign-in'),
                  child: Text(l10n.goToSignIn),
                ),
              ] else ...[
                Text(l10n.resetPasswordHelp),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('reset-password'),
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(labelText: l10n.newPassword),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('reset-confirm'),
                  controller: _confirm,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(labelText: l10n.confirmPassword),
                  onSubmitted: (_) => _reset(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    key: const Key('reset-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('reset-submit'),
                  onPressed: _busy ? null : _reset,
                  child: Text(l10n.setNewPassword),
                ),
                const SizedBox(height: 8),
                TextButton(
                  key: const Key('reset-ask-again'),
                  onPressed: () => context.go('/forgot-password'),
                  child: Text(l10n.forgotPassword),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
