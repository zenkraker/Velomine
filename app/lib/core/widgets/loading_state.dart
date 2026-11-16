import 'package:material_ui/material_ui.dart';

import '../l10n.dart';
import '../motion.dart';
import '../placeholder_block.dart';
import '../tokens.dart';

/// What a page shows while it loads for the first time: a centred indicator in a block of a fixed height,
/// or, with [LoadingState.rows], skeleton rows for a page that knows its shape.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key}) : rows = 0, rowHeight = AppLoading.rowHeight;

  /// [count] neutral rows of [rowHeight], the size of the content that is coming.
  const LoadingState.rows({
    super.key,
    int count = 3,
    this.rowHeight = AppLoading.rowHeight,
  }) : rows = count;

  /// How many skeleton rows to draw; zero draws the centred indicator.
  final int rows;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.loading;
    if (rows > 0) {
      return Semantics(
        label: label,
        container: true,
        child: Column(
          spacing: AppSpacing.md,
          children: [
            for (var i = 0; i < rows; i++) PlaceholderBlock(height: rowHeight),
          ],
        ),
      );
    }
    return SizedBox(
      height: AppLoading.blockHeight,
      child: Center(
        child: CircularProgressIndicator(
          semanticsLabel: label,
          // A ring that spins forever is the motion to stop when the system asks for less.
          value: reduceMotion(context) ? 0.25 : null,
        ),
      ),
    );
  }
}
