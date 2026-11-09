/// The part of a ride covered by one lap, in seconds since the ride started.
class LapRange {
  const LapRange(this.startS, this.endS);

  final double startS;
  final double endS;
}
