import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/user_message_text.dart';
import 'admin_view_models.dart';
import '../../core/tokens.dart';

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
            ? const CircularProgressIndicator()
            : Text(
                s.load.failure == null
                    ? l10n.noSettings
                    : failureText(l10n, s.load.failure!),
              ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                Text(
                  l10n.signUp,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SwitchListTile(
                  key: const Key('setting-signup'),
                  value: s.signUpEnabled,
                  title: Text(l10n.peopleCanCreate),
                  onChanged: (v) => ref
                      .read(adminSettingsViewModelProvider.notifier)
                      .setSignUpEnabled(v),
                ),
                SwitchListTile(
                  key: const Key('setting-approval'),
                  value: s.requireAdminApproval,
                  title: Text(l10n.newAccountsApproval),
                  onChanged: (v) => ref
                      .read(adminSettingsViewModelProvider.notifier)
                      .setRequireAdminApproval(v),
                ),
                SwitchListTile(
                  key: const Key('setting-club-creation'),
                  value: s.clubCreationEnabled,
                  title: Text(l10n.adminClubCreation),
                  subtitle: Text(l10n.adminClubCreationHelp),
                  onChanged: (v) => ref
                      .read(adminSettingsViewModelProvider.notifier)
                      .setClubCreationEnabled(v),
                ),
                if (s.load.failure case final failure?)
                  Text(
                    failureText(l10n, failure),
                    key: const Key('settings-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (s.save.completed)
                  Text(l10n.saved, key: const Key('settings-saved')),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    key: const Key('setting-save'),
                    onPressed: s.save.running
                        ? null
                        : () => ref
                              .read(adminSettingsViewModelProvider.notifier)
                              .saveSettings(),
                    child: Text(l10n.save),
                  ),
                ),
                const Divider(),
                Text(
                  l10n.envVariables,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(l10n.secretsHelp),
                if (settings.smtp.configured)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: const Key('send-test-email'),
                      onPressed: s.testEmail.running
                          ? null
                          : () => ref
                                .read(adminSettingsViewModelProvider.notifier)
                                .sendTestEmail(),
                      icon: const Icon(Icons.send),
                      label: Text(l10n.sendTestEmail),
                    ),
                  ),
                if (s.testEmail.completed || s.testEmail.failure != null)
                  Text(
                    s.testEmail.failure == null
                        ? l10n.testEmailSent
                        : failureText(l10n, s.testEmail.failure!),
                    key: const Key('test-email-result'),
                    style: s.testEmail.failure != null
                        ? TextStyle(color: Theme.of(context).colorScheme.error)
                        : null,
                  ),
                _StatusCard(
                  key: const Key('smtp-status'),
                  icon: Icons.mail_outline,
                  title: l10n.emailSmtp,
                  on: settings.smtp.configured,
                  detail: settings.smtp.configured
                      ? l10n.smtpDetail(
                          settings.smtp.host ?? '',
                          settings.smtp.port ?? 0,
                          settings.smtp.security ?? '',
                          settings.smtp.from ?? '',
                        )
                      : l10n.smtpNotConfigured,
                ),
                _StatusCard(
                  key: const Key('sso-status'),
                  icon: Icons.login,
                  title: l10n.singleSignOn,
                  on: settings.sso.enabled,
                  detail: settings.sso.enabled
                      ? l10n.ssoDetail(
                          settings.sso.displayName ?? l10n.ssoGeneric,
                          settings.sso.authority ?? '',
                        )
                      : l10n.ssoNotConfigured,
                ),
                const Divider(),
                Text(
                  l10n.sharedCatalogue,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(l10n.sharePartsHelp),
                if (catalogue != null) ...[
                  _StatusCard(
                    key: const Key('catalogue-status'),
                    icon: Icons.public,
                    title: l10n.sharedCatalogue,
                    on:
                        catalogue.contributionEndpointConfigured &&
                        catalogue.contributionKeyConfigured,
                    detail:
                        !catalogue.contributionEndpointConfigured ||
                            !catalogue.contributionKeyConfigured
                        ? l10n.catalogueNotConfigured
                        : catalogue.syncedAt == null
                        ? l10n.catalogueNeverSynced
                        : l10n.catalogueSynced(
                            DateFormat.yMMMd(
                              Localizations.localeOf(context).toLanguageTag(),
                            ).format(catalogue.syncedAt!.toLocal()),
                          ),
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
                  if (catalogue.problems.isNotEmpty) ...[
                    Text(
                      l10n.catalogueProblems,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    for (final problem in catalogue.problems)
                      Card(
                        key: Key('contribution-${problem.id}'),
                        child: ListTile(
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
                      ),
                  ],
                ],
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    super.key,
    required this.icon,
    required this.title,
    required this.on,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final bool on;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(on ? l10n.statusOn(title) : l10n.statusOff(title)),
        subtitle: Text(detail),
      ),
    );
  }
}
