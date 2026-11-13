import 'package:flutter/material.dart';

import '../tokens.dart';

/// The body of a page: the header that names it, then its content in a readable measure.
///
/// On a phone the shell's title bar already names the screen, so only the content is laid out.
/// From a tablet up the header is part of the page — a large title, a line about it and the page's
/// own actions — so the content can use the window's width instead of a stretched phone column.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    this.eyebrow,
    this.title,
    this.titleKey,
    this.subtitle,
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

  /// A key on the title, for a test that reads or looks for it.
  final Key? titleKey;

  /// A line under the title: what the page shows, in one sentence.
  final String? subtitle;

  /// The page's buttons, right of the title on a wide window and under it when narrow.
  final Widget? actions;

  final List<Widget> children;
  final double maxWidth;

  /// The list's scroll position, for a page that keeps it across a tab change.
  final ScrollController? controller;

  /// Pull to refresh, on the platforms that offer it.
  final Future<void> Function()? refresh;

  /// Room under the last child, for a button that floats over the list.
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final header = width >= AppBreakpoint.compactWidth;
    final gutter = AppLayout.gutterFor(width);
    final list = ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(
        gutter,
        header ? 28 : 8,
        gutter,
        bottomPadding,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.lg,
              children: [
                if (header && (title != null || actions != null))
                  _PageHeader(
                    eyebrow: eyebrow,
                    title: title,
                    titleKey: titleKey,
                    subtitle: subtitle,
                    actions: actions,
                  ),
                ...children,
              ],
            ),
          ),
        ),
      ],
    );
    if (refresh == null) return list;
    return RefreshIndicator(onRefresh: refresh!, child: list);
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    this.eyebrow,
    this.title,
    this.titleKey,
    this.subtitle,
    this.actions,
  });

  final String? eyebrow;
  final String? title;
  final Key? titleKey;
  final String? subtitle;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: [
        if (eyebrow case final eyebrow?)
          Text(
            eyebrow.toUpperCase(),
            style: text.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.76,
              color: scheme.onSurfaceVariant,
            ),
          ),
        if (title case final title?)
          Semantics(
            header: true,
            child: Text(title, key: titleKey, style: text.headlineMedium),
          ),
        if (subtitle case final subtitle?)
          Text(
            subtitle,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
      ],
    );
    final buttons = actions;
    if (buttons == null) return heading;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xl,
      runSpacing: AppSpacing.md,
      children: [heading, buttons],
    );
  }
}
