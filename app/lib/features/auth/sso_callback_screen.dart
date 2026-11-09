import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/l10n.dart';
import '../../core/providers.dart';

part 'sso_callback_screen.g.dart';

typedef SsoCallbackArgs = ({String? code, String? error});

/// Trades the one-time code for a session. True means it failed and the screen
/// must go back to sign-in with the reason showing there.
@riverpod
class SsoCallbackViewModel extends _$SsoCallbackViewModel {
  bool _started = false;

  @override
  bool build(SsoCallbackArgs args) {
    // Not while the screen is being built: finishing may move to another route.
    Future.microtask(_finish);
    return false;
  }

  Future<void> _finish() async {
    if (_started) return;
    _started = true;
    final session = ref.read(sessionProvider);
    final problem =
        args.error ??
        (args.code == null ? 'failed' : await session.finishAppSso(args.code!));
    if (problem == null) return; // signed in: the router takes it from here
    session.reportSsoError(problem);
    if (ref.mounted) state = true;
  }
}

/// Where the phone lands when the browser hands a single sign-on back
/// (`com.velomine.app:/sso-callback?code=...`).
class SsoCallbackScreen extends ConsumerWidget {
  const SsoCallbackScreen({
    super.key,
    required this.code,
    required this.error,
    required this.onFailed,
  });

  final String? code;
  final String? error;
  final VoidCallback onFailed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (code: code, error: error);
    final provider = ssoCallbackViewModelProvider(args);
    ref.watch(provider);
    ref.listen(provider, (_, failed) {
      if (failed) onFailed();
    });
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            const CircularProgressIndicator(),
            Text(context.l10n.signingIn),
          ],
        ),
      ),
    );
  }
}
