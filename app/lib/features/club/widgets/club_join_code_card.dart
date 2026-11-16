import 'package:material_ui/material_ui.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/page_menu.dart';
import '../../../core/widgets/section_card.dart';

/// The club's join code, the link to copy and, in the card's menu, a new code (which ends the old one).
class ClubJoinCodeCard extends StatelessWidget {
  const ClubJoinCodeCard({
    super.key,
    required this.code,
    required this.busy,
    required this.onCopy,
    required this.onNewCode,
  });

  final String code;
  final bool busy;
  final VoidCallback onCopy;
  final VoidCallback onNewCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SectionCard(
      title: l10n.clubJoinCode,
      menu: PageMenu(
        buttonKey: const Key('join-code-actions'),
        entries: [
          PageMenuEntry(
            key: const Key('new-join-code'),
            label: l10n.clubNewCode,
            icon: Icons.refresh,
            destructive: true,
            onSelected: busy ? () {} : onNewCode,
          ),
        ],
      ),
      children: [
        SelectableText(
          code,
          key: const Key('join-code-value'),
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(letterSpacing: 4),
        ),
        Text(
          l10n.clubJoinCodeHelp,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('copy-join-link'),
            onPressed: onCopy,
            icon: const Icon(Icons.link),
            label: Text(l10n.clubCopy),
          ),
        ),
      ],
    );
  }
}
