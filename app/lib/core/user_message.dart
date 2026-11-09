import 'failure.dart';

/// Something the view shows once and then reports as consumed.
///
/// This is Android's `userMessages` list: failures and confirmations are state,
/// not events, so a message is not lost when a screen rebuilds. The view
/// translates a [FailureMessage] with `failureText`.
sealed class UserMessage {
  const UserMessage(this.id);

  /// Unique within one ViewModel's state; the view uses it to clear the message.
  final int id;
}

final class FailureMessage extends UserMessage {
  const FailureMessage(super.id, this.failure);

  final Failure failure;
}

final class SavedMessage extends UserMessage {
  const SavedMessage(super.id);
}

final class CopiedMessage extends UserMessage {
  const CopiedMessage(super.id);
}

final class RequestSentMessage extends UserMessage {
  const RequestSentMessage(super.id);
}
