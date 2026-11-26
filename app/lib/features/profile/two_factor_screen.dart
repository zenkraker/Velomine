import '../../core/widgets/loading_state.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/user_message_text.dart';
import 'two_factor_view_model.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/bottom_action_bar.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
import '../auth/password_field.dart';

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
      title: l10n.twoFactorTitle,
      parent: l10n.profileTitle,
      subtitle: l10n.twoFactorIntro,
      maxWidth: AppLayout.contentNarrow,
      bottomAction: !(info?.hasPassword ?? false)
          ? null
          : (info?.enabled ?? false)
          ? BottomActionBar.button(
              buttonKey: const Key('two-factor-disable'),
              label: l10n.twoFactorDisable,
              busy: state.disable.running,
              onPressed: () => notifier.disable(_password.text),
            )
          : setup == null
          ? null
          : BottomActionBar.button(
              buttonKey: const Key('two-factor-enable'),
              label: l10n.twoFactorEnable,
              busy: state.enable.running,
              onPressed: () =>
                  notifier.enable(password: _password.text, code: _code.text),
            ),
      children: [
        if (state.load.running && info == null)
          const LoadingState()
        else if (state.load.failure case final failure?)
          ErrorState(
            message: failureText(l10n, failure),
            actionKey: const Key('two-factor-error'),
            onRetry: notifier.load,
          )
        else if (!(info?.hasPassword ?? false))
          // Single sign-on already has its second step, so the setup card does not appear at all.
          AppCard(
            key: const Key('two-factor-sso'),
            child: Text(l10n.twoFactorNoPassword),
          )
        else ...[
          SectionCard(
            title: l10n.twoFactorSetupTitle,
            description: (info?.enabled ?? false)
                ? null
                : l10n.twoFactorKeyHelp,
            children: [
              if (info?.enabled ?? false) ...[
                Text(l10n.twoFactorStateOn),
                PasswordField(
                  fieldKey: const Key('two-factor-password'),
                  visibilityKey: const Key('two-factor-password-visibility'),
                  controller: _password,
                  label: l10n.twoFactorPassword,
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton(
                    key: const Key('two-factor-regenerate'),
                    onPressed: state.regenerate.running
                        ? null
                        : () => notifier.regenerate(_password.text),
                    child: Text(l10n.twoFactorRegenerate),
                  ),
                ),
              ] else if (setup == null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton(
                    key: const Key('two-factor-start'),
                    onPressed: state.start.running ? null : notifier.start,
                    child: Text(l10n.twoFactorStartSetup),
                  ),
                )
              else ...[
                // The key the member types into the app, with the copy the mock-up draws at its end.
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
                    IconButton(
                      key: const Key('two-factor-key-copy'),
                      tooltip: l10n.clubCopy,
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: setup.key));
                        notifier.copied();
                      },
                      icon: const Icon(Icons.copy_outlined),
                    ),
                  ],
                ),
                PasswordField(
                  fieldKey: const Key('two-factor-password'),
                  visibilityKey: const Key('two-factor-password-visibility'),
                  controller: _password,
                  label: l10n.twoFactorPassword,
                ),
                AppTextField(
                  fieldKey: const Key('two-factor-code'),
                  controller: _code,
                  label: l10n.twoFactorCodeLabel,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                ),
              ],
            ],
          ),
          if (codes != null)
            SectionCard(
              title: l10n.twoFactorRecoveryTitle,
              description: l10n.twoFactorRecoveryHelp,
              children: [
                for (final code in codes)
                  SelectableText(
                    code,
                    key: Key('recovery-$code'),
                    style: VelomineText.of(context).code,
                  ),
              ],
            ),
        ],
      ],
    );
  }
}
