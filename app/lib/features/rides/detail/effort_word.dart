import 'package:velomine_api/api.dart';

/// How a ride felt, in one word: the only plain-word reading of a ride, and only the simple modes show it.
enum EffortWord { easy, steady, hard }

/// The effort line for a ride, from its heart-rate zone seconds: the largest share wins, and a tie goes to the
/// harder bucket, so the word never softens a ride. The buckets are the ones `Intensity.cs` uses for heart rate
/// (Z1–3 easy, Z4 moderate, Z5 hard).
///
/// Null when the ride has no zone time: no heart rate, no maximum heart rate, or nothing measured. It never says
/// "easy" by default.
EffortWord? effortWord(List<ZoneTime> zones) {
  var easy = 0.0;
  var moderate = 0.0;
  var hard = 0.0;
  for (final zone in zones) {
    if (zone.zone <= 3) {
      easy += zone.seconds;
    } else if (zone.zone == 4) {
      moderate += zone.seconds;
    } else {
      hard += zone.seconds;
    }
  }
  if (easy <= 0 && moderate <= 0 && hard <= 0) return null;
  if (hard >= moderate && hard >= easy) return EffortWord.hard;
  if (moderate >= easy) return EffortWord.steady;
  return EffortWord.easy;
}
