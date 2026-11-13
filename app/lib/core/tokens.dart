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

/// Where the layout changes shape: a phone, a tablet, a desktop window.
abstract final class AppBreakpoint {
  /// Narrower than this is a phone: the bottom bar and one column.
  static const double compactWidth = 600;

  /// From this width the sidebar replaces the rail and pages may use two columns.
  static const double expandedWidth = 1200;
}

/// The measure and the margin of a page, the same on every screen.
abstract final class AppLayout {
  /// A list or a dashboard.
  static const double contentMax = 1160;

  /// A form or a page of prose, which reads better short.
  static const double contentNarrow = 720;

  static const double sidebarWidth = 240;

  static const double gutter = 32;
  static const double gutterMedium = 24;
  static const double gutterCompact = 16;

  /// The page margin for [width]: wide windows get more air than a phone.
  static double gutterFor(double width) => width >= AppBreakpoint.expandedWidth
      ? gutter
      : width >= AppBreakpoint.compactWidth
      ? gutterMedium
      : gutterCompact;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 320);
}
