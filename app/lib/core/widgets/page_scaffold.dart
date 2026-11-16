import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../tokens.dart';
import 'eyebrow.dart';

/// Says whether [PageScaffold] draws its header below the tablet width.
///
/// Until the shell stops drawing its own phone title bar, a phone page shows no header of its own. The
/// shell will wrap its pages in `PageHeaderScope(showOnPhone: true)` once it does. Without a scope the
/// answer is false.
class PageHeaderScope extends InheritedWidget {
  const PageHeaderScope({
    super.key,
    required this.showOnPhone,
    required super.child,
  });

  final bool showOnPhone;

  /// Whether a page under [context] draws its header on a phone.
  static bool showOnPhoneOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<PageHeaderScope>()
          ?.showOnPhone ??
      false;

  @override
  bool updateShouldNotify(PageHeaderScope oldWidget) =>
      showOnPhone != oldWidget.showOnPhone;
}

/// The body of a page: a large title that collapses into a small bar as the page scrolls, then its
/// content in a readable measure.
///
/// The header is drawn from the tablet width up (600 dp), and at any width under a
/// [PageHeaderScope] with `showOnPhone` true. Otherwise (a phone, today) the shell's title bar names the
/// screen and only the content is laid out.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    this.eyebrow,
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
  });

  /// A short line above the title, saying what the page is for in two or three words.
  final String? eyebrow;

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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= AppBreakpoint.compactWidth;
    final hasHeader =
        (wide || PageHeaderScope.showOnPhoneOf(context)) &&
        (title != null ||
            primaryAction != null ||
            menu != null ||
            onBack != null ||
            (trailing?.isNotEmpty ?? false));
    final gutter = AppLayout.gutterFor(width);
    final legacyActions = hasHeader || wide ? actions : null;
    final scroll = CustomScrollView(
      controller: controller,
      slivers: [
        if (hasHeader)
          SliverPersistentHeader(
            pinned: true,
            delegate: _HeaderDelegate(
              topInset: MediaQuery.paddingOf(context).top,
              textScaler: MediaQuery.textScalerOf(context),
              theme: Theme.of(context),
              gutter: gutter,
              maxWidth: maxWidth,
              eyebrow: eyebrow,
              title: title,
              titleKey: titleKey,
              subtitle: subtitle,
              primaryAction: primaryAction,
              menu: menu,
              onBack: onBack,
              trailing: trailing,
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            hasHeader ? AppSpacing.md : AppSpacing.sm,
            gutter,
            bottomPadding,
          ),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.lg,
                  children: [
                    if (legacyActions != null)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: legacyActions,
                      ),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
    if (refresh == null) return scroll;
    return RefreshIndicator(onRefresh: refresh!, child: scroll);
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({
    required this.topInset,
    required this.textScaler,
    required this.theme,
    required this.gutter,
    required this.maxWidth,
    this.eyebrow,
    this.title,
    this.titleKey,
    this.subtitle,
    this.primaryAction,
    this.menu,
    this.onBack,
    this.trailing,
  });

  final double topInset;
  final TextScaler textScaler;
  final ThemeData theme;
  final double gutter;
  final double maxWidth;
  final String? eyebrow;
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
    var height = _line(
      text.headlineMedium?.fontSize,
      AppHeader.titleLineHeight,
    );
    if (eyebrow != null) {
      height += AppSpacing.xs + _line(11, AppHeader.textLineHeight);
    }
    if (subtitle != null) {
      height +=
          AppSpacing.xs +
          (subtitle!.length > AppHeader.longSubtitle
                  ? AppHeader.subtitleLines
                  : 1) *
              _line(text.bodyMedium?.fontSize, AppHeader.textLineHeight);
    }
    return height + AppHeader.bottomGap;
  }

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
          Expanded(
            child: collapsed
                ? Opacity(
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
                  )
                : const SizedBox.shrink(),
          ),
          for (final button in trailingButtons) button,
          if (primaryAction != null) ...[
            const SizedBox(width: AppSpacing.sm),
            primaryAction!,
          ],
          if (menu != null) ...[const SizedBox(width: AppSpacing.xs), menu!],
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
                        if (eyebrow case final eyebrow?) Eyebrow(eyebrow),
                        Semantics(
                          header: true,
                          child: Text(
                            title!,
                            key: titleKey,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.headlineMedium,
                          ),
                        ),
                        if (subtitle case final subtitle?)
                          Text(
                            subtitle,
                            maxLines: AppHeader.subtitleLines,
                            overflow: TextOverflow.ellipsis,
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
