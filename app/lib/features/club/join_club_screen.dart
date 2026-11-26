import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../auth/auth_page.dart';
import 'club_view_model.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/bottom_action_bar.dart';
import '../../core/widgets/page_scaffold.dart';

/// Where a signed-in account without a club lands. It joins with the code the owner shared.
class JoinClubScreen extends ConsumerStatefulWidget {
  const JoinClubScreen({
    super.key,
    this.initialCode = '',
    this.onJoined,
    this.onSkip,
  });

  final String initialCode;

  /// Called once the membership exists, so an invite code kept for this visit can be forgotten.
  final VoidCallback? onJoined;

  /// Called when someone chooses to carry on without a club; null hides the way out (an invite link).
  final VoidCallback? onSkip;

  @override
  ConsumerState<JoinClubScreen> createState() => _JoinClubScreenState();
}

class _JoinClubScreenState extends ConsumerState<JoinClubScreen> {
  late final _code = TextEditingController(
    text: widget.initialCode.toUpperCase(),
  );

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    final joined = await ref.read(clubViewModelProvider.notifier).join(code);
    if (joined) widget.onJoined?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(clubViewModelProvider);
    final failure = state.action.failure;
    final message = failure == null
        ? null
        : switch (failure.kind) {
            FailureKind.missing => l10n.joinInvalid,
            // This page is only shown to someone without a club, so a conflict is the club's plan: the server says which.
            FailureKind.conflict => failure.detail ?? l10n.joinAlready,
            _ => failureText(l10n, failure),
          };
    return PageScaffold(
      title: l10n.joinTitle,
      parent: l10n.navClub,
      subtitle: l10n.joinIntro,
      maxWidth: AppLayout.contentNarrow,
      bottomAction: BottomActionBar.button(
        buttonKey: const Key('join-club'),
        label: l10n.joinAction,
        busy: state.action.running,
        onPressed: _join,
      ),
      children: [
        // The code and the way out are the page's one form, in one card.
        AppCard(
          key: const Key('join-club-form'),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  fieldKey: const Key('join-code'),
                  controller: _code,
                  label: l10n.joinCode,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onDone: (_) => _join(),
                ),
                if (message != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  AuthFailure(keyName: 'join-error', message: message),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (widget.onSkip != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const Key('skip-join'),
                      onPressed: state.action.running ? null : widget.onSkip,
                      child: Text(l10n.joinSkip),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
