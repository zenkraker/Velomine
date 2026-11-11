import 'package:flutter/material.dart';

/// Whether the person asked the system to reduce motion.
bool reduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// [duration], or zero when the person asked to reduce motion.
Duration motionDuration(BuildContext context, Duration duration) =>
    reduceMotion(context) ? Duration.zero : duration;

/// A page change with no transition, for when the person asked to reduce motion.
class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

/// The page transitions used when the system asks to reduce motion.
final noAnimationPageTransitions = PageTransitionsTheme(
  builders: {
    for (final platform in TargetPlatform.values)
      platform: const NoAnimationPageTransitionsBuilder(),
  },
);
