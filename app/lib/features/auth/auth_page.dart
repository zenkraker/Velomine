import 'package:flutter/material.dart';

import '../../core/tokens.dart';

/// The frame every signed-out screen shares: the wordmark, the step's name, one sentence about it,
/// then one column at a readable width — and a bar with a way back where there is one.
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    this.title,
    this.eyebrow,
    this.help,
    this.onBack,
    required this.children,
  });

  /// The name of the step. Sign-in leaves it empty: the wordmark is its title.
  final String? title;

  /// A short line over the title, saying which part of signing in this is.
  final String? eyebrow;

  /// One sentence on what the step is for, under the title.
  final String? help;

  /// Where the bar's arrow goes when leaving means going somewhere, not popping.
  final VoidCallback? onBack;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: onBack == null
          ? null
          : AppBar(
              leading: BackButton(onPressed: onBack),
              backgroundColor: scheme.surface,
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.contentNarrow),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            children: [
              Text(
                'Velomine',
                style: text.headlineLarge,
                textAlign: TextAlign.center,
              ),
              if (eyebrow case final eyebrow?) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  eyebrow.toUpperCase(),
                  style: text.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.76,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (title case final title?) ...[
                const SizedBox(height: AppSpacing.xs),
                Semantics(
                  header: true,
                  child: Text(title, style: text.headlineMedium),
                ),
              ],
              if (help case final help?) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  help,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// What a signed-out form says when the attempt did not work: one line, next to the button that
/// failed, so the member does not go looking for it.
class AuthFailure extends StatelessWidget {
  const AuthFailure({super.key, required this.keyName, required this.message});

  /// The part of the screen that failed, by its [Key]'s value, so a test can still find it.
  final String keyName;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      key: Key(keyName),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Icon(Icons.error_outline, size: 18, color: scheme.error),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.error),
          ),
        ),
      ],
    );
  }
}
