import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import 'training_text.dart';

/// A session's shape: one bar per block, its width the block's minutes and its height how hard the block is. Hard
/// blocks are drawn in the accent colour; everything else is muted.
class SessionShape extends StatelessWidget {
  const SessionShape({
    super.key,
    required this.blocks,
    this.height = AppTraining.shapeHeight,
  });

  final List<BlockTarget> blocks;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) return const SizedBox.shrink();
    final palette = VelomineColors.of(context);
    return Semantics(
      label: blocks
          .map((block) => blockRole(context.l10n, block.role))
          .join(', '),
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: AppSpacing.xs,
          children: [
            for (final block in blocks)
              Expanded(
                flex: block.minutes < 1 ? 1 : block.minutes,
                child: Container(
                  height: height * _barFraction(block),
                  decoration: BoxDecoration(
                    color: isHardBlock(block)
                        ? palette.accentStrong
                        : palette.barMuted,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// A bar's height: feel 1 is a quarter of the strip, feel 10 all of it.
  static double _barFraction(BlockTarget block) =>
      0.25 +
      0.75 * ((((block.feelLow + block.feelHigh) / 2) - 1) / 9).clamp(0, 1);
}
