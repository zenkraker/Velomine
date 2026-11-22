import 'package:material_ui/material_ui.dart';

import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/widgets/bottom_action_bar.dart';
import '../../core/widgets/inline_error.dart';
import '../../core/widgets/page_scaffold.dart';

/// The frame every signed-out screen shares: the wordmark as a hero, the step's name, one sentence
/// about it, then one column at a readable width, a back arrow where there is a way back, and the
/// step's one primary button: pinned at the bottom on a phone, under the fields on a wide window.
///
/// There is no shell here, so the page asks for the header itself (`showOnPhone`): it only holds the
/// back arrow, because the wordmark is the page's title.
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    this.title,
    this.caption,
    this.help,
    this.onBack,
    this.primaryLabel,
    this.primaryKey,
    this.onPrimary,
    this.primaryBusy = false,
    required this.children,
  });

  /// The name of the step. Sign-in leaves it empty: the wordmark is its title.
  final String? title;

  /// The page this step belongs to, as a small caption above the title: "Password help" above "Reset
  /// your password".
  final String? caption;

  /// One sentence on what the step is for, under the title.
  final String? help;

  /// Where the back arrow goes when leaving means going somewhere, not popping.
  final VoidCallback? onBack;

  /// The step's primary button: its text, its key, what it does and whether it is working. Without a
  /// label the step has none.
  final String? primaryLabel;
  final Key? primaryKey;
  final VoidCallback? onPrimary;
  final bool primaryBusy;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    // The step's button is pinned under the content at every width, so it is always the last thing under
    // the fields however tall the window is, and on a phone it stays above the keyboard.
    final button = primaryLabel == null
        ? null
        : FilledButton(
            key: primaryKey,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(AppBottomBar.buttonHeight),
            ),
            onPressed: primaryBusy ? null : onPrimary,
            child: primaryBusy
                ? const SizedBox.square(
                    dimension: AppBottomBar.busyIndicator,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(primaryLabel!),
          );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: PageHeaderScope(
          showOnPhone: true,
          child: PageScaffold(
            maxWidth: AppLayout.contentNarrow,
            onBack: onBack,
            bottomAction: button == null
                ? null
                : BottomActionBar(
                    maxWidth: AppLayout.contentNarrow,
                    child: button,
                  ),
            children: [
              Semantics(
                header: title == null,
                child: Text(
                  'Velomine',
                  style: text.displayMedium?.copyWith(color: scheme.primary),
                  textAlign: TextAlign.center,
                ),
              ),
              if (caption case final caption?)
                Text(
                  caption,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              if (title case final title?)
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: text.headlineLarge,
                  ),
                ),
              if (help case final help?)
                Text(
                  help,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
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
    return InlineError(message, key: Key(keyName), showIcon: true);
  }
}

/// The word "or" between a form and another way in, such as single sign-on.
class AuthOr extends StatelessWidget {
  const AuthOr({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rule = Expanded(child: Divider(color: scheme.outlineVariant));
    return Row(
      spacing: AppSpacing.md,
      children: [
        rule,
        Text(
          context.l10n.authOr,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        rule,
      ],
    );
  }
}
