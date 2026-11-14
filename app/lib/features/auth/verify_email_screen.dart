import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/tokens.dart';
import 'auth_data.dart';
import 'auth_page.dart';

/// Opens the link from the confirmation email: the token is in the URL fragment, so it never reaches the server in
/// an address line. The screen says what happened and sends a person to sign in either way.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.email, this.token});

  final String? email;
  final String? token;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  /// Null while the address is being confirmed, then whether the link worked.
  bool? _confirmed;
  bool _resent = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_verify);
  }

  Future<void> _verify() async {
    final email = widget.email;
    final token = widget.token;
    if (email == null || email.isEmpty || token == null || token.isEmpty) {
      if (mounted) setState(() => _confirmed = false);
      return;
    }
    final result = await ref
        .read(authDataProvider)
        .verifyEmail(email: email, token: token);
    if (mounted) setState(() => _confirmed = result.failureOrNull == null);
  }

  Future<void> _sendAgain() async {
    final email = widget.email;
    if (email == null || email.isEmpty) return;
    final result = await ref.read(authDataProvider).resendVerification(email);
    if (mounted) setState(() => _resent = result.failureOrNull == null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canResend = widget.email?.isNotEmpty == true;
    return AuthPage(
      title: l10n.verifyEmailTitle,
      onBack: () => context.go('/sign-in'),
      children: [
        if (_confirmed == null)
          Row(
            spacing: AppSpacing.md,
            children: [
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              Expanded(child: Text(l10n.verifyEmailWorking)),
            ],
          )
        else ...[
          Text(
            _confirmed! ? l10n.verifyEmailDone : l10n.verifyEmailInvalid,
            key: const Key('verify-result'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (!_confirmed! && canResend) ...[
            const SizedBox(height: AppSpacing.md),
            if (_resent)
              Text(l10n.verifyEmailResent, key: const Key('verify-resent'))
            else
              TextButton(
                key: const Key('verify-send-again'),
                onPressed: _sendAgain,
                child: Text(l10n.verifyEmailSendAgain),
              ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            key: const Key('verify-to-sign-in'),
            onPressed: () => context.go('/sign-in'),
            child: Text(l10n.backToSignIn),
          ),
        ],
      ],
    );
  }
}
