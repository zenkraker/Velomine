import 'package:material_ui/material_ui.dart';

import '../../../core/l10n.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/section_card.dart';

/// The club's join code and the link to copy. A new code, which ends the old one, is in the page's `⋯` menu.
class ClubJoinCodeCard extends StatelessWidget {
  const ClubJoinCodeCard({super.key, required this.code, required this.onCopy});

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return SectionCard(
      title: l10n.clubJoinCode,
      children: [
        SelectableText(
          code,
          key: const Key('join-code-value'),
          style: VelomineText.of(context).stat,
        ),
        Text(l10n.clubJoinCodeHelp, style: text.bodySmall),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
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
