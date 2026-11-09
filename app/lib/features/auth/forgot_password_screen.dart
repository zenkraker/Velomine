import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:velomine_api/api.dart';

import '../../core/l10n.dart';
import '../../core/session.dart';

/// Asks for the email address and always says the same thing: the answer must not reveal who is registered.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.session});

  final Session session;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = l10n.errorEnterEmail);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    String? error;
    try {
      await widget.session.accounts.forgotPassword(
        ForgotPasswordRequest(email: email),
      );
    } on ApiException catch (e) {
      error = switch (e.code) {
        503 => l10n.forgotPasswordUnavailable,
        429 => l10n.forgotPasswordTooMany,
        _ => l10n.forgotPasswordFailed,
      };
    } on Object {
      error = l10n.forgotPasswordFailed;
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      _sent = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              if (_sent) ...[
                const SizedBox(height: 16),
                Text(l10n.forgotPasswordSent, key: const Key('forgot-sent')),
                const SizedBox(height: 12),
                TextButton(
                  key: const Key('forgot-back'),
                  onPressed: () => context.go('/sign-in'),
                  child: Text(l10n.goToSignIn),
                ),
              ] else ...[
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    key: const Key('forgot-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('forgot-submit'),
                  onPressed: _busy ? null : _send,
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
