import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/section_card.dart';
import 'supporter_celebration_screen.dart';
import 'supporter_view_model.dart';

/// Where the licence key is pasted. A refused key shows its sentence and a
/// retry inline; on success the screen shows the celebration, whose "Continue"
/// ends back on the profile with the badge on.
class SupporterActivationScreen extends ConsumerStatefulWidget {
  const SupporterActivationScreen({
    super.key,
    required this.onDone,
    required this.onCelebrated,
  });

  /// Leaves the activation for the profile.
  final VoidCallback onDone;

  /// Called once the celebration is over, so the profile shows the badge.
  final VoidCallback onCelebrated;

  @override
  ConsumerState<SupporterActivationScreen> createState() =>
      _SupporterActivationScreenState();
}

class _SupporterActivationScreenState
    extends ConsumerState<SupporterActivationScreen> {
  final _key = TextEditingController();

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final activated = await ref
        .read(supporterViewModelProvider.notifier)
        .activate(_key.text);
    if (!activated || !mounted) return;
    final licence = ref.read(supporterViewModelProvider).riderLicence;
    if (licence == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SupporterCelebrationScreen(
          licence: licence,
          onContinue: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (!mounted) return;
    widget.onCelebrated();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = ref.watch(supporterViewModelProvider);
    final failure = s.activate.failure;
    final loadFailure = s.load.failure;
    return ListView(
      key: const Key('supporter-activation'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.lg,
              children: [
                if (loadFailure != null)
                  Row(
                    key: const Key('supporter-activation-load-error'),
                    spacing: AppSpacing.sm,
                    children: [
                      Expanded(
                        child: Text(
                          failureText(l10n, loadFailure),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      TextButton(
                        key: const Key('supporter-activation-reload'),
                        onPressed: s.load.running
                            ? null
                            : ref
                                  .read(supporterViewModelProvider.notifier)
                                  .load,
                        child: Text(l10n.tryAgain),
                      ),
                    ],
                  ),
                SectionCard(
                  title: l10n.supporterBecome,
                  description: l10n.supporterKeyHelp,
                  children: [
                    AppTextField(
                      fieldKey: const Key('supporter-key'),
                      controller: _key,
                      label: l10n.supporterKey,
                      maxLines: 3,
                    ),
                    if (failure != null)
                      Row(
                        key: const Key('supporter-activate-error'),
                        spacing: AppSpacing.sm,
                        children: [
                          Expanded(
                            child: Text(
                              switch (failure.code) {
                                403 => l10n.supporterClubOwnerOnly,
                                409 => l10n.supporterAlreadyActivated,
                                503 => l10n.supporterUnavailable,
                                _ => l10n.supporterKeyInvalid,
                              },
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                          TextButton(
                            key: const Key('supporter-activate-retry'),
                            onPressed: s.activate.running ? null : _activate,
                            child: Text(l10n.tryAgain),
                          ),
                        ],
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ValueListenableBuilder(
                        valueListenable: _key,
                        builder: (context, value, _) => FilledButton(
                          key: const Key('supporter-activate'),
                          onPressed:
                              s.activate.running || value.text.trim().isEmpty
                              ? null
                              : _activate,
                          child: Text(l10n.supporterActivate),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
