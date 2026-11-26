import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/widgets/app_text_field.dart';
import 'auth_page.dart';
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
    return AuthPage(
      title: l10n.forgotPasswordTitle,
      caption: l10n.forgotPasswordCaption,
      help: l10n.forgotPasswordHelp,
      onBack: () => context.go('/sign-in'),
      primaryLabel: l10n.sendResetLink,
      primaryKey: const Key('forgot-submit'),
      onPrimary: _send,
      primaryBusy: s.command.running,
      children: [
        AppTextField(
          fieldKey: const Key('forgot-email'),
          controller: _email,
          label: l10n.email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onDone: (_) => _send(),
        ),
        if (s.sent) ...[
          Text(l10n.forgotPasswordSent, key: const Key('forgot-sent')),
        ] else if (s.problem != null) ...[
          AuthFailure(
            keyName: 'forgot-error',
            message: forgotProblemText(l10n, s.problem!),
          ),
        ],
        // The way back is on the page before and after the ask, as the design draws it.
        SizedBox(
          width: double.infinity,
          child: TextButton(
            key: const Key('forgot-back'),
            onPressed: () => context.go('/sign-in'),
            child: Text(l10n.backToSignIn),
          ),
        ),
      ],
    );
  }
}
