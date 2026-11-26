import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/units.dart';
import 'recorder.dart';

/// A ride in progress, shown over every screen but the recorder: the state, the elapsed time and the
/// distance, in tabular figures so they do not jitter. Tapping it opens the recorder.
class LiveRideBanner extends ConsumerWidget {
  const LiveRideBanner({super.key, required this.snapshot});

  final RecorderSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final units = ref.watch(unitsChoiceViewModelProvider);
    final paused = snapshot.isPaused;
    final state = paused ? l10n.navRecordingPaused : l10n.navRecording;
    final time = stopwatch(snapshot.elapsedS);
    final distance = km(units, snapshot.distanceM);
    final figures = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: scheme.onSecondaryContainer,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Semantics(
      container: true,
      button: true,
      label: '$state, $time, $distance',
      child: ExcludeSemantics(
        child: Material(
          key: const Key('live-ride-banner'),
          color: scheme.secondaryContainer,
          shape: const StadiumBorder(),
          elevation: 2,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => context.push('/record'),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppNav.bannerHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  spacing: AppSpacing.md,
                  children: [
                    Icon(
                      paused
                          ? Icons.pause_circle_outline
                          : Icons.fiber_manual_record,
                      size: AppIconSize.medium,
                      color: paused
                          ? scheme.onSecondaryContainer
                          : scheme.error,
                    ),
                    Expanded(
                      child: Text(
                        state,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: scheme.onSecondaryContainer),
                      ),
                    ),
                    Text(
                      time,
                      key: const Key('live-ride-time'),
                      style: figures,
                    ),
                    Text(
                      distance,
                      key: const Key('live-ride-distance'),
                      style: figures,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
