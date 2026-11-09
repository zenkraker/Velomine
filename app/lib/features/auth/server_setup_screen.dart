import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/l10n.dart';
import '../../core/server_config.dart';

part 'server_setup_screen.g.dart';

enum SetupProblem { invalidAddress, unreachable, saveFailed }

class ServerSetupState {
  const ServerSetupState({this.busy = false, this.problem});

  final bool busy;
  final SetupProblem? problem;

  ServerSetupState copyWith({
    bool? busy,
    SetupProblem? problem,
    bool clearProblem = false,
  }) => ServerSetupState(
    busy: busy ?? this.busy,
    problem: clearProblem ? null : (problem ?? this.problem),
  );
}

/// Asks the server who it is. Tests replace it with a fixed answer.
final serverInfoCheckProvider =
    Provider<Future<ServerInfoResponse?> Function(String url)>(
      (ref) => _lookUp,
    );

Future<ServerInfoResponse?> _lookUp(String url) =>
    ServerApi(ApiClient(basePath: url)).getServerInfo();

/// Checks the typed address and saves it. The root then leaves this screen on
/// its own, because it watches the saved address.
@riverpod
class ServerSetupViewModel extends _$ServerSetupViewModel {
  /// A phone on the wrong network otherwise sits on "Checking…" until the
  /// system gives up, which can be minutes.
  static const _checkTimeout = Duration(seconds: 10);

  @override
  ServerSetupState build() => const ServerSetupState();

  Future<void> save(String input) async {
    if (state.busy) return;
    final normalized = normalizeServerUrl(input);
    if (normalized == null) {
      state = state.copyWith(problem: SetupProblem.invalidAddress);
      return;
    }

    state = state.copyWith(busy: true, clearProblem: true);
    ServerInfoResponse? info;
    try {
      info = await ref
          .read(serverInfoCheckProvider)(normalized)
          .timeout(_checkTimeout);
    } on Object {
      info = null;
    }
    if (!ref.mounted) return;
    if (info == null) {
      state = state.copyWith(busy: false, problem: SetupProblem.unreachable);
      return;
    }

    try {
      await ref.read(serverConfigViewModelProvider.notifier).save(normalized);
    } on Object {
      if (!ref.mounted) return;
      state = state.copyWith(busy: false, problem: SetupProblem.saveFailed);
      return;
    }
    if (!ref.mounted) return;
    state = state.copyWith(busy: false, clearProblem: true);
  }
}

/// The first screen on a phone: which Velomine server does this member belong to?
class ServerSetupScreen extends ConsumerStatefulWidget {
  const ServerSetupScreen({super.key, this.initialUrl = ''});

  final String initialUrl;

  @override
  ConsumerState<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends ConsumerState<ServerSetupScreen> {
  late final _url = TextEditingController(text: widget.initialUrl);

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _save() =>
      ref.read(serverSetupViewModelProvider.notifier).save(_url.text);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(serverSetupViewModelProvider);
    final l10n = context.l10n;
    final error = switch (s.problem) {
      null => null,
      SetupProblem.invalidAddress => l10n.setupInvalidAddress,
      SetupProblem.unreachable => l10n.setupUnreachable,
      SetupProblem.saveFailed => l10n.setupSaveFailed,
    };
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Velomine',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.setupTitle,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                key: const Key('server-url'),
                controller: _url,
                keyboardType: TextInputType.url,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.setupServerAddress,
                  hintText: l10n.setupServerHint,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (!s.busy) _save();
                },
              ),
              if (_url.text.trim().toLowerCase().startsWith('http://')) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.setupInsecure,
                  key: const Key('server-insecure'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error,
                  key: const Key('server-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('server-save'),
                onPressed: s.busy ? null : _save,
                child: Text(s.busy ? l10n.setupChecking : l10n.setupConnect),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.setupHelp,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
