import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import 'club_view_model.dart';

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
            FailureKind.conflict => l10n.joinAlready,
            _ => failureText(l10n, failure),
          };
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: AutofillGroup(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Velomine',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.joinTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(l10n.joinIntro),
                const SizedBox(height: 24),
                TextField(
                  key: const Key('join-code'),
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(labelText: l10n.joinCode),
                  onSubmitted: (_) => _join(),
                ),
                if (message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    message,
                    key: const Key('join-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('join-club'),
                  onPressed: state.action.running ? null : _join,
                  child: Text(l10n.joinAction),
                ),
                if (widget.onSkip != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('skip-join'),
                    onPressed: state.action.running ? null : widget.onSkip,
                    child: Text(l10n.joinSkip),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
