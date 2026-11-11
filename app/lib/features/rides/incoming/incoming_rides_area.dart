import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'incoming_rides_view_model.dart';

/// Says what arrived when another app shared ride files, and offers the ride list.
///
/// The files are already on the phone; the upload queue sends them in the background.
class IncomingRidesArea extends ConsumerWidget {
  const IncomingRidesArea({
    super.key,
    required this.onOpenRides,
    required this.child,
  });

  final VoidCallback onOpenRides;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) return child;
    final l10n = context.l10n;

    ref.listen(incomingRidesViewModelProvider.select((s) => s.confirmation), (
      _,
      confirmation,
    ) {
      final state = ref.read(incomingRidesViewModelProvider);
      final batch = state.batch;
      if (batch == null) return;
      final lines = incomingLines(l10n, state);
      if (lines.isEmpty) return;
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(lines.join('\n'), key: const Key('incoming-rides')),
            action: state.signedOut || batch.added == 0
                ? null
                : SnackBarAction(
                    label: l10n.incomingOpen,
                    onPressed: onOpenRides,
                  ),
          ),
        );
      ref.read(incomingRidesViewModelProvider.notifier).shown(confirmation);
    });

    return child;
  }
}

/// The sentence(s) for a batch of received files.
List<String> incomingLines(AppLocalizations l10n, IncomingRidesState state) {
  final batch = state.batch;
  if (batch == null) return const [];
  final kept = batch.added + batch.alreadyHere;
  if (state.signedOut && kept > 0) return [l10n.incomingSignedOut(kept)];
  final rejected = batch.rejected;
  return [
    if (batch.added > 0) l10n.incomingAdded(batch.added),
    if (batch.alreadyHere > 0) l10n.incomingAlreadyHere(batch.alreadyHere),
    if (rejected.length == 1)
      l10n.incomingRejectedOne(rejected.single)
    else if (rejected.length > 1)
      l10n.incomingRejectedMany(rejected.length),
  ];
}
