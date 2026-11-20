import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/widgets/nice_ticks.dart';

void main() {
  test('niceTicks_ShouldReturn0_40_80_120_WhenMaxIs101', () {
    expect(niceTicks(0, 101), [0, 40, 80, 120]);
  });

  test('niceTicks_ShouldKeepTopAt120_WhenMaxIsExactly120', () {
    expect(niceTicks(0, 120), [0, 40, 80, 120]);
  });

  test('niceTicks_ShouldReturnZeroToOne_WhenMaxIsZero', () {
    expect(niceTicks(0, 0), [0, 1]);
  });

  test('niceTicks_ShouldUseFractions_WhenMaxIsBelowOne', () {
    expect(niceTicks(0, 0.05), [0, 0.02, 0.04, 0.06]);
  });

  test('niceTicks_ShouldSnapToRoundBounds_WhenRangeDoesNotStartAtZero', () {
    expect(niceTicks(13, 27), [10, 20, 30]);
  });

  test('niceTicks_ShouldReturnAtMostFourLines_WhenRangeIsAnything', () {
    for (final (min, max) in [
      (0.0, 1.0),
      (0.0, 7.0),
      (0.0, 33.0),
      (0.0, 999.0),
      (0.0, 12345.0),
      (-40.0, 60.0),
      (0.9, 1.4),
      (250.0, 250.0),
      (0.0, 0.004),
      (3.0, 3.1),
    ]) {
      final ticks = niceTicks(min, max);
      expect(ticks.length, lessThanOrEqualTo(4), reason: '$min..$max');
      expect(ticks.first, lessThanOrEqualTo(min), reason: '$min..$max');
      expect(ticks.last, greaterThanOrEqualTo(max), reason: '$min..$max');
      expect(ticks, orderedEquals([...ticks]..sort()), reason: '$min..$max');
    }
  });

  test('barLabelStep_ShouldBeThree_WhenCompactAndBarsAreWide', () {
    expect(barLabelStep(slot: 100, compact: true), 3);
  });

  test('barLabelStep_ShouldBeTwo_WhenMediumOrWider', () {
    expect(barLabelStep(slot: 100, compact: false), 2);
  });

  test('barLabelStep_ShouldGrow_WhenBarsAreNarrow', () {
    expect(barLabelStep(slot: 10, compact: false), 5);
  });
}
