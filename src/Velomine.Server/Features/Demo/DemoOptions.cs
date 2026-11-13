namespace Velomine.Server.Features.Demo;

/// <summary>
/// Bound from "Velomine:Demo" (environment: VELOMINE__DEMO__ENABLED). A public demo: everyone shares the same accounts,
/// so the actions that would lock the others out are refused, and every night the accounts and their data are
/// deleted and made again.
/// </summary>
public sealed class DemoOptions
{
    public bool Enabled { get; set; }
}
