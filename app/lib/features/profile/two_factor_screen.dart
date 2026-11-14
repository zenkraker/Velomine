import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/user_message_text.dart';
import 'two_factor_view_model.dart';
import '../../core/tokens.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';

class TwoFactorScreen extends ConsumerStatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  final _password = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(twoFactorViewModelProvider);
    final notifier = ref.read(twoFactorViewModelProvider.notifier);
    final info = state.load.value;
    final codes =
        state.enable.value?.recoveryCodes ??
        state.regenerate.value?.recoveryCodes;
    final setup = state.start.value;

    ref.listen(
      twoFactorViewModelProvider,
      (_, next) =>
          showUserMessage(context, next.message, notifier.messageShown),
    );

    return PageScaffold(
      eyebrow: l10n.profileTitle,
      title: l10n.twoFactorTitle,
      maxWidth: AppLayout.contentNarrow,
      children: [
        if (state.load.running && info == null)
          const Center(child: CircularProgressIndicator())
        else if (state.load.failure case final failure?)
          ErrorState(
            message: failureText(l10n, failure),
            actionKey: const Key('two-factor-error'),
            onRetry: notifier.load,
          )
        else ...[
          Text(
            (info?.enabled ?? false)
                ? l10n.twoFactorStateOn
                : l10n.twoFactorStateOff,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!(info?.hasPassword ?? false))
            Text(l10n.twoFactorNoPassword)
          else ...[
            Text(l10n.twoFactorIntro),
            const SizedBox(height: AppSpacing.lg),
            if (info?.enabled ?? false) ...[
              TextField(
                key: const Key('two-factor-password'),
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.twoFactorPassword),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                key: const Key('two-factor-disable'),
                onPressed: state.disable.running
                    ? null
                    : () => notifier.disable(_password.text),
                child: Text(l10n.twoFactorDisable),
              ),
              OutlinedButton(
                key: const Key('two-factor-regenerate'),
                onPressed: state.regenerate.running
                    ? null
                    : () => notifier.regenerate(_password.text),
                child: Text(l10n.twoFactorRegenerate),
              ),
            ] else if (setup == null)
              OutlinedButton(
                key: const Key('two-factor-start'),
                onPressed: state.start.running ? null : notifier.start,
                child: Text(l10n.twoFactorStart),
              )
            else ...[
              Text(l10n.twoFactorKeyHelp),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    '${l10n.twoFactorKey}: ',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Expanded(
                    child: SelectableText(
                      setup.key,
                      key: const Key('two-factor-key'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('two-factor-password'),
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.twoFactorPassword),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('two-factor-code'),
                controller: _code,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.twoFactorCodeLabel),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                key: const Key('two-factor-enable'),
                onPressed: state.enable.running
                    ? null
                    : () => notifier.enable(
                        password: _password.text,
                        code: _code.text,
                      ),
                child: Text(l10n.twoFactorEnable),
              ),
            ],
            if (codes != null) ...[
              const Divider(),
              Text(
                l10n.twoFactorRecoveryTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(l10n.twoFactorRecoveryHelp),
              const SizedBox(height: AppSpacing.sm),
              for (final code in codes)
                SelectableText(
                  code,
                  key: Key('recovery-$code'),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
            ],
          ],
        ],
      ],
    );
  }
}
