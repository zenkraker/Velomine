import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'l10n.dart';

/// One back-button rule for every screen: pop the page on top, otherwise go to the page's parent,
/// otherwise ask for a second press before the app closes.
class BackGuard extends StatefulWidget {
  const BackGuard({super.key, required this.location, required this.child});

  /// The current path, used to find the parent when there is no stack (a deep link).
  final String location;
  final Widget child;

  @override
  State<BackGuard> createState() => _BackGuardState();
}

class _BackGuardState extends State<BackGuard> {
  DateTime? _firstBackAt;

  @override
  void didUpdateWidget(BackGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) _firstBackAt = null;
  }

  void _back() {
    final router = GoRouter.maybeOf(context);

    // A page that was opened from another one pops back to it.
    if (router != null && router.canPop()) {
      router.pop();
      _firstBackAt = null;
      return;
    }

    // A deep link has no stack: go to the page it belongs to.
    final parent = backParentOf(widget.location);
    if (router != null && parent != null) {
      router.go(parent);
      _firstBackAt = null;
      return;
    }

    // A root: the first press warns, the second one closes the app.
    final now = DateTime.now();
    final first = _firstBackAt;
    if (first != null && now.difference(first) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _firstBackAt = now;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(context.l10n.pressBackAgain),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _back();
    },
    child: widget.child,
  );
}

/// The page a screen belongs to when it has no back stack. A tab root returns null, so back exits.
String? backParentOf(String location) {
  final path = Uri.parse(location).path;
  if (path == '/privacy') return '/profile';
  if (path == '/register' ||
      path == '/forgot-password' ||
      path == '/reset-password') {
    return '/sign-in';
  }
  if (path == '/join' || path == '/clubs') return '/club';
  if (path == '/club/athletes') return '/club';
  final coachedRide = RegExp(r'^/club/athletes/([^/]+)/rides/[^/]+$')
      .firstMatch(path);
  if (coachedRide != null) return '/club/athletes/${coachedRide.group(1)}';
  if (RegExp(r'^/club/athletes/[^/]+$').hasMatch(path)) {
    return '/club/athletes';
  }
  if (RegExp(r'^/rides/[^/]+$').hasMatch(path)) return '/rides';
  if (RegExp(r'^/bikes/[^/]+$').hasMatch(path)) return '/bikes';
  return null;
}
