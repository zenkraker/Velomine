import 'package:flutter/material.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import 'club_controller.dart';

/// Where a signed-in account without a club lands. It joins with the code the owner shared.
class JoinClubScreen extends StatefulWidget {
  const JoinClubScreen({
    super.key,
    required this.controller,
    this.initialCode = '',
    this.onJoined,
  });

  final ClubController controller;
  final String initialCode;

  /// Called once the membership exists, so an invite code kept for this visit can be forgotten.
  final VoidCallback? onJoined;

  @override
  State<JoinClubScreen> createState() => _JoinClubScreenState();
}

class _JoinClubScreenState extends State<JoinClubScreen> {
  late final _code = TextEditingController(
    text: widget.initialCode.toUpperCase(),
  );
  Failure? _failure;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    setState(() => _failure = null);
    final failure = await widget.controller.join(code);
    if (failure == null) widget.onJoined?.call();
    if (mounted) setState(() => _failure = failure);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = _failure;
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
                  onPressed: widget.controller.busy ? null : _join,
                  child: Text(l10n.joinAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
