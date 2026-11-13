import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'tokens.dart';

/// The screen the shell is showing. The title bar only takes buttons from this one, so a page that
/// is being replaced cannot put its own back over the next screen.
final currentLocationProvider = NotifierProvider<CurrentLocation, String?>(
  CurrentLocation.new,
);

class CurrentLocation extends Notifier<String?> {
  @override
  String? build() => null;

  void moveTo(String? location) {
    if (state == location) return;
    state = location;
  }
}

/// What a tab puts in the phone's title bar — a filter button, its own overflow menu — so the tab
/// does not draw a row of buttons over the list. The title bar belongs to the shell; a wide window
/// leaves this empty because the page carries its own header.
///
/// It belongs to one location: when the person opens another screen, the buttons go with it.
final pageActionsProvider = NotifierProvider<PageActions, List<Widget>>(
  PageActions.new,
);

class PageActions extends Notifier<List<Widget>> {
  @override
  List<Widget> build() {
    // Another screen starts with an empty title bar.
    ref.watch(currentLocationProvider);
    return const [];
  }

  /// Takes [actions] for the screen at [where]; a page that is not on screen is ignored.
  void set(String where, List<Widget> actions) {
    if (where != ref.read(currentLocationProvider)) return;
    if (listEquals(state, actions)) return;
    state = actions;
  }
}

/// The filter button a phone's title bar shows for a page that has filters.
Widget phoneFilterButton({
  required Key key,
  required String tooltip,
  required bool active,
  required VoidCallback onPressed,
}) => IconButton(
  key: key,
  tooltip: tooltip,
  isSelected: active,
  onPressed: onPressed,
  icon: const Icon(Icons.tune),
);

/// Gives a screen's actions to the phone's title bar. A wide window shows them in the page's own
/// header, so this does nothing there; on a phone the shell draws them instead, which is the only
/// place they fit. Called after the frame, because a build may not change a provider.
void publishPhoneActions(
  BuildContext context,
  WidgetRef ref,
  List<Widget> actions,
) {
  final where = GoRouterState.of(context).uri.path;
  // The element, not just the context: a screen that is being removed is still "mounted" in its
  // final frame and must not put its buttons back over the screen replacing it.
  final element = context as Element;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!element.mounted) return;
    Future.microtask(
      () => ref.read(pageActionsProvider.notifier).set(where, actions),
    );
  });
}

/// A modal sheet with a page's filters, kept above the keyboard so a search field stays visible.
Future<void> showFiltersSheet(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: builder(context),
      ),
    );
