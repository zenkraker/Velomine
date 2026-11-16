import 'package:material_ui/material_ui.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';

/// A small flag on a bike that has a job due (red) or nearly due.
class ServiceMarker extends StatelessWidget {
  const ServiceMarker({super.key, required this.due});

  final bool due;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = due
        ? Theme.of(context).colorScheme.error
        : VelomineColors.of(context).wearSoon;
    final label = due ? l10n.bikeServiceDue : l10n.bikeServiceSoon;
    return Semantics(
      label: label,
      child: Tooltip(
        message: label,
        child: Icon(
          Icons.build_circle_outlined,
          key: Key(due ? 'service-due' : 'service-soon'),
          color: color,
          size: 22,
        ),
      ),
    );
  }
}
