import '../../l10n/generated/app_localizations.dart';

/// The name of a kind of part in the language on screen. The catalogue comes from the server, so a part this build
/// does not know falls back to the name the server sent.
String componentTypeName(AppLocalizations l10n, String id, String fallback) =>
    switch (id) {
      'chain' => l10n.partChain,
      'cassette' => l10n.partCassette,
      'chainring' => l10n.partChainring,
      'crankset' => l10n.partCrankset,
      'bottom_bracket' => l10n.partBottomBracket,
      'front_derailleur' => l10n.partFrontDerailleur,
      'rear_derailleur' => l10n.partRearDerailleur,
      'derailleur_hanger' => l10n.partDerailleurHanger,
      'shifters' => l10n.partShifters,
      'shift_cables' => l10n.partShiftCables,
      'pedals' => l10n.partPedals,
      'front_tire' => l10n.partFrontTire,
      'rear_tire' => l10n.partRearTire,
      'tubeless_sealant' => l10n.partTubelessSealant,
      'inner_tubes' => l10n.partInnerTubes,
      'wheelset' => l10n.partWheelset,
      'hub_service' => l10n.partHubService,
      'front_brake_pads' => l10n.partFrontBrakePads,
      'rear_brake_pads' => l10n.partRearBrakePads,
      'front_rotor' => l10n.partFrontRotor,
      'rear_rotor' => l10n.partRearRotor,
      'brake_fluid' => l10n.partBrakeFluid,
      'brake_cables' => l10n.partBrakeCables,
      'handlebar_tape' => l10n.partHandlebarTape,
      'handlebar' => l10n.partHandlebar,
      'stem' => l10n.partStem,
      'headset' => l10n.partHeadset,
      'saddle' => l10n.partSaddle,
      'seatpost' => l10n.partSeatpost,
      'fork_service' => l10n.partForkService,
      'shock_service' => l10n.partShockService,
      'dropper_post_service' => l10n.partDropperPostService,
      'e_battery' => l10n.partEBattery,
      'e_motor' => l10n.partEMotor,
      'other' => l10n.partOther,
      _ => fallback,
    };

/// The group a part belongs to: "Drivetrain", "Wheels", and so on.
String componentGroupName(AppLocalizations l10n, String group) =>
    switch (group) {
      'Drivetrain' => l10n.partGroupDrivetrain,
      'Wheels' => l10n.partGroupWheels,
      'Brakes' => l10n.partGroupBrakes,
      'Cockpit' => l10n.partGroupCockpit,
      'Suspension' => l10n.partGroupSuspension,
      'Electric' => l10n.partGroupElectric,
      'Other' => l10n.partGroupOther,
      _ => group,
    };
