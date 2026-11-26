import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/widgets/loading_state.dart';
import 'auth_page.dart';
import 'verify_email_view_model.dart';

/// Opens the link from the confirmation email: the token is in the link's query string, which Flutter web keeps
/// (it drops a `#fragment`). The screen says what happened and sends a person to sign in either way.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.email, this.token});

  final String? email;
  final String? token;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  @override
  void initState() {
    super.initState();
    // A command, not a read: the view model owns the call and the screen renders what comes back.
    Future.microtask(
      () => ref
          .read(verifyEmailViewModelProvider.notifier)
          .verify(email: widget.email, token: widget.token),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = ref.watch(verifyEmailViewModelProvider);
    final canResend = widget.email?.isNotEmpty == true;
    return AuthPage(
      title: l10n.verifyEmailTitle,
      primaryLabel: s.confirmed == null ? null : l10n.goToSignIn,
      primaryKey: const Key('verify-to-sign-in'),
      onPrimary: () => context.go('/sign-in'),
      children: [
        if (s.confirmed == null) ...[
          const LoadingState(key: Key('verify-loading')),
          Text(l10n.verifyEmailWorking, textAlign: TextAlign.center),
        ] else ...[
          Text(
            s.confirmed! ? l10n.verifyEmailDone : l10n.verifyEmailInvalid,
            key: const Key('verify-result'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (!s.confirmed! && canResend) ...[
            if (s.resent)
              Text(l10n.verifyEmailResent, key: const Key('verify-resent'))
            else
              TextButton(
                key: const Key('verify-send-again'),
                onPressed: s.command.running
                    ? null
                    : () => ref
                          .read(verifyEmailViewModelProvider.notifier)
                          .sendAgain(widget.email),
                child: Text(l10n.verifyEmailSendAgain),
              ),
          ],
        ],
      ],
    );
  }
}
