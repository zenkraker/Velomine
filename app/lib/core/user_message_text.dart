import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import 'failure.dart';
import '../l10n/generated/app_localizations.dart';
import 'l10n.dart';
import 'user_message.dart';

/// The sentence for a [UserMessage] in the language on screen.
String userMessageText(AppLocalizations l10n, UserMessage message) =>
    switch (message) {
      FailureMessage(:final failure) => failureText(l10n, failure),
      SavedMessage() => l10n.saved,
      CopiedMessage() => l10n.linkCopied,
      RequestSentMessage() => l10n.nearbyRequestSent,
    };

/// Shows [message], then tells the ViewModel it was shown, so a rebuild cannot repeat it.
void showUserMessage(
  BuildContext context,
  UserMessage? message,
  void Function(int id) messageShown,
) {
  if (message == null) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(userMessageText(context.l10n, message))),
  );
  messageShown(message.id);
}

/// Shows every message a ViewModel queues in [source] and clears each one.
void listenUserMessages(
  WidgetRef ref,
  BuildContext context,
  ProviderListenable<List<UserMessage>> source,
  void Function(int id) messageShown,
) {
  ref.listen(source, (_, messages) {
    for (final message in messages) {
      showUserMessage(context, message, messageShown);
    }
  });
}
