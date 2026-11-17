import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/result.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/form_sheet.dart';
import '../../core/widgets/inline_error.dart';
import '../../core/widgets/loading_state.dart';
import '../accounts/ftp_source_text.dart';

/// Every FTP the rider has had, newest first: the date, the watts and how it was set.
/// One entry is not a history yet, so the sheet says so instead of listing it.
Future<void> showFtpHistorySheet(
  BuildContext context,
  Future<Result<FtpHistoryResponse?>> Function() load,
) => showSheet<void>(context, builder: (_) => _FtpHistorySheet(load: load));

class _FtpHistorySheet extends StatefulWidget {
  const _FtpHistorySheet({required this.load});

  final Future<Result<FtpHistoryResponse?>> Function() load;

  @override
  State<_FtpHistorySheet> createState() => _FtpHistorySheetState();
}

class _FtpHistorySheetState extends State<_FtpHistorySheet> {
  late Future<Result<FtpHistoryResponse?>> _history = widget.load();

  void _retry() => setState(() => _history = widget.load());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SheetFrame(
      title: l10n.ftpHistory,
      children: [
        FutureBuilder(
          future: _history,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LoadingState();
            return switch (snapshot.data!) {
              Failed(:final failure) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InlineError(
                    failureText(l10n, failure),
                    key: const Key('ftp-history-error'),
                  ),
                  TextButton(
                    key: const Key('ftp-history-retry'),
                    onPressed: _retry,
                    child: Text(l10n.retry),
                  ),
                ],
              ),
              Ok(:final value) => switch (value?.entries ?? const []) {
                _ when (value?.entries.length ?? 0) < 2 => EmptyState(
                  key: const Key('ftp-history-empty'),
                  message: l10n.ftpHistoryEmpty,
                  icon: Icons.history,
                ),
                final entries => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, entry) in entries.indexed)
                      ListTile(
                        key: Key('ftp-history-$i'),
                        contentPadding: EdgeInsets.zero,
                        title: Text('${entry.watts} W'),
                        subtitle: Text(
                          '${dateOnly(entry.setAt)} · '
                          '${ftpEntrySourceText(l10n, entry)}',
                        ),
                      ),
                  ],
                ),
              },
            };
          },
        ),
      ],
    );
  }
}
