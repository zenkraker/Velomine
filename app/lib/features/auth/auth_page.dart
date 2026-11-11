import 'package:flutter/material.dart';

import '../../core/tokens.dart';

/// The frame every signed-out screen shares: one column at a readable width, centred, and a bar
/// with a way back where there is one.
class AuthPage extends StatelessWidget {
  const AuthPage({super.key, this.title, this.onBack, required this.children});

  /// The name of the step in the bar. Sign-in leaves it empty: the wordmark is its title.
  final String? title;

  /// Where the bar's arrow goes when leaving means going somewhere, not popping.
  final VoidCallback? onBack;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: title == null
        ? null
        : AppBar(
            leading: onBack == null ? null : BackButton(onPressed: onBack),
            title: Text(title!),
          ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: children,
        ),
      ),
    ),
  );
}
