import 'failure.dart';
import '../l10n/generated/app_localizations.dart';
import 'user_message.dart';

/// The sentence for a [UserMessage] in the language on screen.
String userMessageText(AppLocalizations l10n, UserMessage message) =>
    switch (message) {
      FailureMessage(:final failure) => failureText(l10n, failure),
      SavedMessage() => l10n.saved,
      CopiedMessage() => l10n.linkCopied,
      RequestSentMessage() => l10n.nearbyRequestSent,
    };
