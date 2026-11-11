import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/user_message.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';
import 'package:velomine/core/user_message_text.dart';

final class _Messages extends Notifier<List<UserMessage>> {
  @override
  List<UserMessage> build() => const [];

  void add(UserMessage message) => state = [...state, message];
}

final messagesProvider = NotifierProvider<_Messages, List<UserMessage>>(
  _Messages.new,
);

void main() {
  testWidgets('UserMessage_ShouldShowAndClear_WhenTheViewModelQueuesOne', (
    tester,
  ) async {
    final shown = <int>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                listenUserMessages(ref, context, messagesProvider, shown.add);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Consumer)),
    );
    container.read(messagesProvider.notifier).add(const SavedMessage(7));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Saved.'), findsOneWidget);
    expect(shown, [7]);
  });
}
