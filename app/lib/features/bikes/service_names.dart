import '../../l10n/generated/app_localizations.dart';

/// The name of a common maintenance job in the language on screen. The server sends only the id; a job this build
/// does not know is shown by its id, which is never the case for the jobs the server offers today.
String serviceJobName(AppLocalizations l10n, String id) => switch (id) {
  'chain_lube' => l10n.jobChainLube,
  'chain_wear_check' => l10n.jobChainWearCheck,
  'sealant_top_up' => l10n.jobSealantTopUp,
  'brake_bleed' => l10n.jobBrakeBleed,
  'fork_service' => l10n.jobForkService,
  'shock_service' => l10n.jobShockService,
  'bolt_check' => l10n.jobBoltCheck,
  'shifting_battery_charge' => l10n.jobShiftingBattery,
  _ => id,
};
