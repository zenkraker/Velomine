import 'package:flutter/animation.dart' show Cubic, Curve;

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
  static const double large = 28;

  /// The top corners of a bottom sheet.
  static const double sheet = 28;

  /// A card that needs to stand out of the page, for an overlay or a selected state.
  static const double xlarge = 32;
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

/// The page header that [PageScaffold] draws: a toolbar row with a large title that collapses into it.
abstract final class AppHeader {
  /// The pinned toolbar row: back arrow, collapsed title and the page's buttons.
  static const double toolbarHeight = 64;

  /// Room under the large title before the content starts.
  static const double bottomGap = AppSpacing.md;

  /// Line heights the large block is sized from, as multiples of the font size.
  static const double titleLineHeight = 1.4;
  static const double textLineHeight = 1.4;

  /// How many lines of subtitle the large block reserves room for.
  static const int subtitleLines = 2;

  /// A subtitle longer than this many characters may wrap, so the block reserves [subtitleLines].
  static const int longSubtitle = 60;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 320);

  /// A small overshoot that settles: things that arrive (a sheet, a pill, a chip).
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1);

  /// Fast out, slow in: things that move on the screen.
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);
}

/// The bottom sheet that [SheetFrame] draws.
abstract final class AppSheet {
  /// The widest a sheet grows on a tablet or the web.
  static const double maxWidth = 640;

  /// The margin at the sides of the title, the fields and the pinned action.
  static const double gutter = AppSpacing.xl;
}

/// The bottom action bar that [PageScaffold] pins under a full-page form.
abstract final class AppBottomBar {
  /// The smallest height of the pinned button: a comfortable tap target.
  static const double buttonHeight = 48;

  /// The size of the progress ring shown in the button while it works.
  static const double busyIndicator = 20;
}

/// The block [LoadingState] fills while a page loads for the first time.
abstract final class AppLoading {
  /// The height of the centred indicator block.
  static const double blockHeight = 160;

  /// The height of one skeleton row from [LoadingState.rows].
  static const double rowHeight = 56;

  /// The height of one skeleton card in a list of cards, such as the rides.
  static const double cardRowHeight = 96;

  /// The size of the icon before an error line.
  static const double errorIcon = 18;
}

/// The floating navigation pill the shell draws over a phone's content.
abstract final class AppNav {
  /// The collapsed rail's width: icons with labels under them.
  static const double railWidth = 88;

  /// The expanded rail's width: the brand, labels beside the icons, the club and the privacy note.
  static const double railExpandedWidth = 240;

  /// The pill's height.
  static const double pillHeight = 64;

  /// The space between the pill and the screen edges, and between it and the bottom safe area.
  static const double pillMargin = AppSpacing.md;

  /// The pill never grows wider than this, so it stays a pill on a large phone.
  static const double pillMaxWidth = 420;

  /// The room a page leaves under its content, over the bottom safe area, so the last item clears the pill.
  static const double pillClearance = pillHeight + pillMargin;

  /// The blur behind the translucent pill.
  static const double pillBlur = 20;

  /// The least height of the live-ride banner, a comfortable tap target.
  static const double bannerHeight = 56;

  /// The space between the live-ride banner and the pill under it.
  static const double bannerGap = AppSpacing.sm;

  /// How opaque the pill's surface is over the blur.
  static const double pillOpacity = 0.82;

  /// How far the pill slides down, in its own heights, when it hides: past the margin and safe area.
  static const double pillHiddenOffset = 2;

  /// The most the pill's labels grow with the system text size.
  static const double maxLabelScale = 1.2;

  /// How far a scroll must move, in logical pixels, before the pill hides or returns.
  static const double scrollThreshold = 4;
}
