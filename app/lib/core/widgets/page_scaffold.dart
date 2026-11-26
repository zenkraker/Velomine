import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../tokens.dart';
import 'bottom_action_bar.dart';

/// What the shell gives every page under it: whether to draw the header on a phone, the buttons that
/// end the header's top row, and the way back for a pushed screen.
///
/// A page merges these with its own: its own `onBack` wins, and its own `trailing` comes before the
/// shell's. Without a scope a phone page draws no header and the shell supplies nothing.
class PageHeaderScope extends InheritedWidget {
  const PageHeaderScope({
    super.key,
    required this.showOnPhone,
    this.trailing = const [],
    this.onBack,
    required super.child,
  });

  final bool showOnPhone;

  /// Notifications and the account (and, until the pages carry their own, a phone's page buttons).
  final List<Widget> trailing;

  /// The way back, set while the location is a pushed screen rather than a tab.
  final VoidCallback? onBack;

  static PageHeaderScope? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PageHeaderScope>();

  /// Whether a page under [context] draws its header on a phone.
  static bool showOnPhoneOf(BuildContext context) =>
      _of(context)?.showOnPhone ?? false;

  /// The shell's buttons for the end of the header's top row.
  static List<Widget> trailingOf(BuildContext context) =>
      _of(context)?.trailing ?? const [];

  /// The shell's way back, or null on a tab.
  static VoidCallback? onBackOf(BuildContext context) => _of(context)?.onBack;

  @override
  bool updateShouldNotify(PageHeaderScope oldWidget) =>
      showOnPhone != oldWidget.showOnPhone ||
      trailing != oldWidget.trailing ||
      onBack != oldWidget.onBack;
}

/// The body of a page: a large title that collapses into a small bar as the page scrolls, then its
/// content in a readable measure.
///
/// The header is drawn from the tablet width up (600 dp), and at any width under a
/// [PageHeaderScope] with `showOnPhone` true (the shell sets it). Otherwise only the content is laid out.
///
/// The content ends above the bottom safe area, and above the floating navigation pill when the shell
/// shows one: the shell widens the media padding by the pill's room, and this reads it.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    this.parent,
    this.title,
    this.titleKey,
    this.subtitle,
    this.primaryAction,
    this.menu,
    this.onBack,
    this.trailing,
    this.actions,
    required this.children,
    this.maxWidth = AppLayout.contentMax,
    this.controller,
    this.refresh,
    this.bottomPadding = AppSpacing.xl,
    this.bottomAction,
    this.fillLast = false,
  });

  /// The page this one belongs to, as a small caption above the title: "Progress" above "Power".
  final String? parent;

  final String? title;

  /// A key on the large title, for a test that reads or looks for it.
  final Key? titleKey;

  /// A line under the title: what the page shows, in one sentence.
  final String? subtitle;

  /// The one filled button of the page, in the header's top row.
  final Widget? primaryAction;

  /// The `⋯` menu for the page's rare actions, after [primaryAction].
  final Widget? menu;

  /// Shows a back arrow that calls this.
  final VoidCallback? onBack;

  /// Notifications and the account, supplied by the shell, at the end of the top row.
  final List<Widget>? trailing;

  /// Deprecated: use [primaryAction] and [menu]. The old row of buttons, laid out at the start of the
  /// content under the header. (Not annotated with `@Deprecated` so the callers that still pass it do not
  /// fail analysis until each page moves over.)
  final Widget? actions;

  final List<Widget> children;
  final double maxWidth;

  /// The scroll position, for a page that keeps it across a tab change.
  final ScrollController? controller;

  /// Pull to refresh, on the platforms that offer it.
  final Future<void> Function()? refresh;

  /// Room under the last child, for a button that floats over the list.
  final double bottomPadding;

  /// The action that finishes the page, such as Save: pinned under the scrolling content, above the
  /// keyboard and the safe area, so it never scrolls away. Usually a [BottomActionBar].
  final Widget? bottomAction;

  /// Grows the last child to the bottom of the window when it is shorter than the room left, as a page
  /// whose main chart ends level with the sidebar draws it.
  ///
  /// It is a minimum height, not a fixed one: a child taller than the window -- a long card, a larger text
  /// size, a short window -- is laid out at its own height and the page scrolls, so nothing overflows.
  final bool fillLast;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= AppBreakpoint.compactWidth;
    final onBack = this.onBack ?? PageHeaderScope.onBackOf(context);
    final trailing = [
      ...?this.trailing,
      ...PageHeaderScope.trailingOf(context),
    ];
    final hasHeader =
        (wide || PageHeaderScope.showOnPhoneOf(context)) &&
        (title != null ||
            primaryAction != null ||
            menu != null ||
            onBack != null ||
            trailing.isNotEmpty);
    final gutter = AppLayout.gutterFor(width);
    final legacyActions = hasHeader || wide ? actions : null;
    final scroll = CustomScrollView(
      controller: controller,
      slivers: [
        if (hasHeader)
          // The room the page really has (the window less the sidebar) decides how many lines the
          // sub-line wraps to, so the header is as tall as its text and nothing ends in an ellipsis.
          SliverLayoutBuilder(
            builder: (context, constraints) => SliverPersistentHeader(
              pinned: true,
              delegate: _HeaderDelegate(
                topInset: MediaQuery.paddingOf(context).top,
                textScaler: MediaQuery.textScalerOf(context),
                theme: Theme.of(context),
                gutter: gutter,
                maxWidth: maxWidth,
                available: constraints.crossAxisExtent,
                parent: parent,
                title: title,
                titleKey: titleKey,
                subtitle: subtitle,
                primaryAction: primaryAction,
                menu: menu,
                onBack: onBack,
                trailing: trailing,
              ),
            ),
          ),
        ..._content(context, gutter, hasHeader, legacyActions),
      ],
    );
    final body = refresh == null
        ? scroll
        : RefreshIndicator(onRefresh: refresh!, child: scroll);
    final action = bottomAction;
    if (action == null) return body;
    // The bar sits below the scroll view, not over it, so the last field always scrolls clear of it.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: body),
        action,
      ],
    );
  }

  /// The content slivers: everything in one box, or the last child on its own so it can reach the bottom
  /// of the window.
  List<Widget> _content(
    BuildContext context,
    double gutter,
    bool hasHeader,
    Widget? legacyActions,
  ) {
    final top = hasHeader ? AppSpacing.md : AppSpacing.sm;
    // A pinned bottom action already sits above the safe area and the pill.
    final bottom =
        bottomPadding + (bottomAction == null ? bottomClearanceOf(context) : 0);
    final rest = [...children];
    final last = fillLast && rest.isNotEmpty ? rest.removeLast() : null;
    // The gap over the last child: the column's own gap under the children above it, or the page's top
    // padding when it is the only one.
    final gap = rest.isEmpty && legacyActions == null ? top : AppSpacing.lg;
    Widget column(List<Widget> items) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.lg,
          children: items,
        ),
      ),
    );
    return [
      if (last == null || rest.isNotEmpty || legacyActions != null)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            top,
            gutter,
            last == null ? bottom : 0,
          ),
          sliver: SliverToBoxAdapter(
            child: column([
              if (legacyActions != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: legacyActions,
                ),
              ...rest,
            ]),
          ),
        ),
      if (last != null)
        // The room the slivers above left: not the child's own height, which is why this needs no
        // intrinsic measurement -- the charts inside are `LayoutBuilder`s and have none.
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final space =
                constraints.viewportMainAxisExtent -
                constraints.precedingScrollExtent;
            return SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, gap, gutter, bottom),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth,
                      minHeight: math.max(space - gap - bottom, 0),
                    ),
                    child: last,
                  ),
                ),
              ),
            );
          },
        ),
    ];
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({
    required this.topInset,
    required this.textScaler,
    required this.theme,
    required this.gutter,
    required this.maxWidth,
    required this.available,
    this.parent,
    this.title,
    this.titleKey,
    this.subtitle,
    this.primaryAction,
    this.menu,
    this.onBack,
    this.trailing,
  });

  /// The width the page is laid out in, before the gutters and the content measure take their share.
  final double available;

  final double topInset;
  final TextScaler textScaler;
  final ThemeData theme;
  final double gutter;
  final double maxWidth;
  final String? parent;
  final String? title;
  final Key? titleKey;
  final String? subtitle;
  final Widget? primaryAction;
  final Widget? menu;
  final VoidCallback? onBack;
  final List<Widget>? trailing;

  double _line(double? fontSize, double lineHeight) =>
      textScaler.scale(fontSize ?? 14) * lineHeight;

  /// The height of the large title block under the toolbar row.
  double get _largeBlock {
    if (title == null) return 0;
    final text = theme.textTheme;
    var height = _line(text.headlineLarge?.fontSize, AppHeader.titleLineHeight);
    if (parent != null) {
      height +=
          AppSpacing.xs +
          _line(text.bodySmall?.fontSize, AppHeader.textLineHeight);
    }
    if (subtitle != null) {
      height +=
          AppSpacing.xs +
          _subtitleLines *
              _line(text.bodyMedium?.fontSize, AppHeader.textLineHeight);
    }
    return height + AppHeader.bottomGap;
  }

  /// How many lines the sub-line takes at the width it is drawn in.
  late final int _subtitleLines = () {
    final painter =
        TextPainter(
          text: TextSpan(
            text: subtitle,
            style: theme.textTheme.bodyMedium ?? const TextStyle(),
          ),
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
        )..layout(
          maxWidth: math.max(
            1,
            math.min(available, maxWidth + 2 * gutter) - 2 * gutter,
          ),
        );
    final lines = painter.computeLineMetrics().length;
    painter.dispose();
    return math.max(1, lines);
  }();

  /// Whether the top row holds anything while the page is expanded. When it does not, the large title
  /// sits right under the top edge instead of under an empty row.
  bool get _rowHasContent =>
      onBack != null ||
      primaryAction != null ||
      menu != null ||
      (trailing?.isNotEmpty ?? false);

  double get _expandedRow =>
      _rowHasContent ? AppHeader.toolbarHeight : AppHeader.bottomGap;

  @override
  double get minExtent => topInset + AppHeader.toolbarHeight;

  @override
  double get maxExtent =>
      math.max(minExtent, topInset + _expandedRow + _largeBlock);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final range = maxExtent - minExtent;
    final t = range <= 0 ? 0.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final collapsed = title != null && t >= 0.5;
    final expanded = title != null && t < 0.5;
    final trailingButtons = [...?trailing];

    final toolbar = SizedBox(
      height: AppHeader.toolbarHeight,
      child: Row(
        children: [
          if (onBack != null)
            BackButton(onPressed: onBack)
          else if (collapsed)
            const SizedBox(width: AppSpacing.sm),
          // Only the collapsed bar has a title to hold room for: an empty slot would take half the row and
          // squeeze the buttons to half their size.
          if (collapsed)
            Expanded(
              child: Opacity(
                opacity: ((t - 0.5) * 2).clamp(0.0, 1.0),
                child: Semantics(
                  header: true,
                  child: Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge,
                  ),
                ),
              ),
            ),
          // The buttons grow only so far: the row is one fixed height, and at twice the text scale the
          // title would be squeezed to nothing and the buttons would run off the edge. A narrow window
          // where a labelled main action, the notifications, the account and the menu do not fit scales
          // that cluster down rather than running past the edge.
          // The cluster is pinned to the end of the row: a loose Flexible sizes
          // to its content and would otherwise sit where its half of the free
          // space begins, which draws the page's one action and the ⋯ halfway
          // across the page instead of in the title row's corner.
          (collapsed ? Flexible.new : Expanded.new)(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Row(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final button in trailingButtons)
                      MediaQuery.withClampedTextScaling(
                        maxScaleFactor: AppHeader.maxToolbarTextScale,
                        child: button,
                      ),
                    if (primaryAction case final primaryAction?)
                      MediaQuery.withClampedTextScaling(
                        maxScaleFactor: AppHeader.maxToolbarTextScale,
                        child: primaryAction,
                      ),
                    if (menu case final menu?)
                      MediaQuery.withClampedTextScaling(
                        maxScaleFactor: AppHeader.maxToolbarTextScale,
                        child: menu,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final large = expanded
        ? Positioned.fill(
            top: _expandedRow,
            child: ClipRect(
              child: OverflowBox(
                alignment: AlignmentDirectional.bottomStart,
                minHeight: 0,
                maxHeight: double.infinity,
                child: Opacity(
                  opacity: ((0.5 - t) * 2).clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppHeader.bottomGap),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      spacing: AppSpacing.xs,
                      children: [
                        if (parent case final parent?)
                          Text(
                            parent,
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        Semantics(
                          header: true,
                          child: Text(
                            title!,
                            key: titleKey,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.headlineLarge,
                          ),
                        ),
                        if (subtitle case final subtitle?)
                          Text(
                            subtitle,
                            style: text.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        : null;

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: EdgeInsets.only(top: topInset),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth + 2 * gutter),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: Stack(
                children: [
                  Positioned(top: 0, left: 0, right: 0, child: toolbar),
                  ?large,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) => true;
}
