import 'package:flutter/material.dart';

import '../../core/session.dart';

/// Where the phone lands when the browser hands a single sign-on back (`com.velomine.app:/sso-callback?code=...`).
/// It trades the code for a session; the router then moves a signed-in member on, and a failure goes back to sign-in
/// with the reason shown there.
class SsoCallbackScreen extends StatefulWidget {
  const SsoCallbackScreen({
    super.key,
    required this.session,
    required this.code,
    required this.error,
    required this.onFailed,
  });

  final Session session;
  final String? code;
  final String? error;
  final VoidCallback onFailed;

  @override
  State<SsoCallbackScreen> createState() => _SsoCallbackScreenState();
}

class _SsoCallbackScreenState extends State<SsoCallbackScreen> {
  @override
  void initState() {
    super.initState();
    // Not while the screen is being built: finishing may move to another route.
    WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
  }

  Future<void> _finish() async {
    final code = widget.code;
    final problem =
        widget.error ??
        (code == null ? 'failed' : await widget.session.finishAppSso(code));
    if (problem == null) return; // signed in: the router takes it from here
    widget.session.ssoError = problem;
    if (mounted) widget.onFailed();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [CircularProgressIndicator(), Text('Signing you in…')],
      ),
    ),
  );
}
