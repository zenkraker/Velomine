/// Layout constants shared by every screen, so a gap or a corner is the same number everywhere.
/// Colours and type come from the theme; these are the numbers the theme does not carry.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

abstract final class AppRadius {
  static const double small = 8;
  static const double medium = 16;
  static const double large = 22;

  /// A card that needs to stand out of the page, for an overlay or a selected state.
  static const double xlarge = 28;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 320);
}
