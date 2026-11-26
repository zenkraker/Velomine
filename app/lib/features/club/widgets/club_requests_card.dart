import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../../core/failure.dart';
import '../../../core/l10n.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/inline_error.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/toolbar_row.dart';
import '../join_requests_state.dart';

/// People asking to join, for the owner to approve or decline.
class ClubRequestsCard extends StatelessWidget {
  const ClubRequestsCard({
    super.key,
    required this.requests,
    required this.onRefresh,
    required this.onApprove,
    required this.onDecline,
  });

  final JoinRequestsState requests;
  final VoidCallback onRefresh;
  final void Function(JoinRequestResponse request) onApprove;
  final void Function(JoinRequestResponse request) onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final blocked = requests.admissionBlocked;
    return SectionCard(
      key: const Key('join-requests-card'),
      title: l10n.joinRequestsTitle,
      menu: IconButton(
        key: const Key('refresh-join-requests'),
        tooltip: l10n.actionLoadJoinRequests,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: requests.load.running ? null : onRefresh,
        icon: const Icon(Icons.refresh),
      ),
      children: [
        if (requests.load.failure case final failure?)
          InlineError(
            failureText(l10n, failure),
            key: const Key('join-requests-error'),
          ),
        if (requests.load.running)
          const LoadingState()
        else if (requests.requests.isEmpty)
          Text(l10n.joinRequestsEmpty, key: const Key('join-requests-empty'))
        else ...[
          if (blocked != null)
            Text(
              blocked == 'ended'
                  ? l10n.joinRequestsBlockedEnded
                  : l10n.joinRequestsBlockedFull,
              key: const Key('join-requests-blocked'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          for (final request in requests.requests)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.sm,
              children: [
                const Divider(),
                Text(
                  request.displayName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (request.note != null) Text(request.note!),
                Align(
                  alignment: Alignment.centerRight,
                  child: ToolbarRow(
                    children: [
                      TextButton(
                        key: Key('decline-${request.id}'),
                        onPressed: requests.action.running
                            ? null
                            : () => onDecline(request),
                        child: Text(l10n.joinRequestDecline),
                      ),
                      FilledButton.tonal(
                        key: Key('approve-${request.id}'),
                        onPressed: requests.action.running || blocked != null
                            ? null
                            : () => onApprove(request),
                        child: Text(l10n.joinRequestApprove),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }
}
