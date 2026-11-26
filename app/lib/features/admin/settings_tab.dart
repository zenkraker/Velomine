import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/user_message_text.dart';
import 'admin_view_models.dart';
import '../../core/tokens.dart';
import '../../core/widgets/bottom_action_bar.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/inline_error.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/more_details.dart';
import '../../core/widgets/section_card.dart';

/// The settings area's one action: the page pins it under the content ([PageScaffold.bottomAction]).
class AdminSettingsSave extends ConsumerWidget {
  const AdminSettingsSave({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(adminSettingsViewModelProvider);
    // Nothing to save until the settings have arrived; the tab shows why meanwhile.
    if (s.settings == null) return const SizedBox.shrink();
    return BottomActionBar.button(
      buttonKey: const Key('setting-save'),
      label: context.l10n.save,
      busy: s.save.running,
      onPressed: () =>
          ref.read(adminSettingsViewModelProvider.notifier).saveSettings(),
    );
  }
}

/// The settings an admin can change, and (read-only) what only the server's environment sets.
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(adminSettingsViewModelProvider);
    final l10n = context.l10n;
    final settings = s.settings;
    final catalogue = s.catalogue;

    listenUserMessages(
      ref,
      context,
      adminSettingsViewModelProvider.select((s) => s.messages),
      ref.read(adminSettingsViewModelProvider.notifier).messageShown,
    );

    if (settings == null) {
      return Center(
        child: s.load.running
            ? const LoadingState()
            : ErrorState(
                message: s.load.failure == null
                    ? l10n.noSettings
                    : failureText(l10n, s.load.failure!),
                onRetry: () =>
                    ref.read(adminSettingsViewModelProvider.notifier).load(),
                actionKey: const Key('settings-retry'),
              ),
      );
    }
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.contentNarrow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.lg,
              children: [
                SectionCard(
                  title: l10n.signUp,
                  children: [
                    SwitchListTile(
                      key: const Key('setting-signup'),
                      contentPadding: EdgeInsets.zero,
                      value: s.signUpEnabled,
                      title: Text(l10n.peopleCanCreate),
                      onChanged: (v) => ref
                          .read(adminSettingsViewModelProvider.notifier)
                          .setSignUpEnabled(v),
                    ),
                    SwitchListTile(
                      key: const Key('setting-approval'),
                      contentPadding: EdgeInsets.zero,
                      value: s.requireAdminApproval,
                      title: Text(l10n.newAccountsApproval),
                      onChanged: (v) => ref
                          .read(adminSettingsViewModelProvider.notifier)
                          .setRequireAdminApproval(v),
                    ),
                    SwitchListTile(
                      key: const Key('setting-club-creation'),
                      contentPadding: EdgeInsets.zero,
                      value: s.clubCreationEnabled,
                      title: Text(l10n.adminClubCreation),
                      subtitle: Text(l10n.adminClubCreationHelp),
                      onChanged: (v) => ref
                          .read(adminSettingsViewModelProvider.notifier)
                          .setClubCreationEnabled(v),
                    ),
                    if (s.load.failure case final failure?)
                      InlineError(
                        failureText(l10n, failure),
                        key: const Key('settings-error'),
                      ),
                    if (s.save.completed)
                      Text(l10n.saved, key: const Key('settings-saved')),
                  ],
                ),
                SectionCard(
                  title: l10n.envVariables,
                  description: l10n.secretsHelp,
                  children: [
                    ListTile(
                      key: const Key('smtp-status'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.mail_outline),
                      title: Text(l10n.emailSmtp),
                      subtitle: Text(
                        settings.smtp.configured
                            ? l10n.smtpDetail(
                                settings.smtp.host ?? '',
                                settings.smtp.port ?? 0,
                                settings.smtp.security ?? '',
                                settings.smtp.from ?? '',
                              )
                            : l10n.smtpNotConfigured,
                      ),
                    ),
                    if (settings.smtp.configured)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          key: const Key('send-test-email'),
                          onPressed: s.testEmail.running
                              ? null
                              : () => ref
                                    .read(
                                      adminSettingsViewModelProvider.notifier,
                                    )
                                    .sendTestEmail(),
                          icon: const Icon(Icons.send),
                          label: Text(l10n.sendTestEmail),
                        ),
                      ),
                    if (s.testEmail.completed || s.testEmail.failure != null)
                      s.testEmail.failure == null
                          ? Text(
                              l10n.testEmailSent,
                              key: const Key('test-email-result'),
                            )
                          : InlineError(
                              failureText(l10n, s.testEmail.failure!),
                              key: const Key('test-email-result'),
                            ),
                    ListTile(
                      key: const Key('sso-status'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.login),
                      title: Text(l10n.singleSignOn),
                      subtitle: Text(
                        settings.sso.enabled
                            ? l10n.ssoDetail(
                                settings.sso.displayName ?? l10n.ssoGeneric,
                                settings.sso.authority ?? '',
                              )
                            : l10n.ssoNotConfigured,
                      ),
                    ),
                  ],
                ),
                SectionCard(
                  title: l10n.sharedCatalogue,
                  description: l10n.sharePartsHelp,
                  children: [
                    if (catalogue != null) ...[
                      Text(
                        !catalogue.contributionEndpointConfigured ||
                                !catalogue.contributionKeyConfigured
                            ? l10n.catalogueNotConfigured
                            : catalogue.syncedAt == null
                            ? l10n.catalogueNeverSynced
                            : l10n.catalogueSynced(
                                DateFormat.yMMMd(
                                  Localizations.localeOf(context)
                                      .toLanguageTag(),
                                ).format(catalogue.syncedAt!.toLocal()),
                              ),
                        key: const Key('catalogue-status'),
                      ),
                      Text(
                        l10n.contributionCounts(
                          catalogue.contributions.pending,
                          catalogue.contributions.sent,
                          catalogue.contributions.rejected,
                          catalogue.contributions.failed,
                        ),
                        key: const Key('catalogue-contributions'),
                      ),
                      if (catalogue.problems.isNotEmpty)
                        // The design folds them behind one row, carrying the parts that were not taken.
                        MoreDetails(
                          label: l10n.catalogueProblems,
                          children: [
                            for (final problem in catalogue.problems)
                              ListTile(
                                key: Key('contribution-${problem.id}'),
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  '${problem.typeName} · '
                                  '${_partText(problem.brand, problem.model, problem.mpn)}',
                                ),
                                subtitle: problem.reason == null
                                    ? null
                                    : Text(problem.reason!),
                                trailing: Text(
                                  problem.status == 'rejected'
                                      ? l10n.contributionRejected
                                      : l10n.contributionFailed,
                                ),
                              ),
                          ],
                        ),
                    ],
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

String _partText(String brand, String model, String? mpn) =>
    [brand, model, if (mpn != null && mpn.isNotEmpty) mpn].join(' · ');
