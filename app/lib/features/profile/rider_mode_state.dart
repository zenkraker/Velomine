import '../../core/command.dart';

/// The rider mode question and its save. There is no copy of the mode itself: it is read from `session.me`.
class RiderModeState {
  const RiderModeState({
    this.promptHandled = false,
    this.save = const CommandState.idle(),
  });

  /// The sheet has been shown or dismissed in this signed-in session, so it does not open again here. It comes
  /// back at the next sign-in or app start while the account still has no mode.
  final bool promptHandled;

  /// The last save of the mode, for the sheet's error line and its waiting state.
  final VoidCommand save;

  RiderModeState copyWith({bool? promptHandled, VoidCommand? save}) =>
      RiderModeState(
        promptHandled: promptHandled ?? this.promptHandled,
        save: save ?? this.save,
      );
}
