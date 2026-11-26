namespace Velomine.Server.Tests;

/// <summary>
/// Starts at a known instant and then follows the wall clock, so rows written one after another have their own
/// times: the two-minute export link still works, and a history still orders itself.
/// </summary>
public sealed class OffsetTime(DateTimeOffset start) : TimeProvider
{
    private readonly DateTimeOffset started = DateTimeOffset.UtcNow;

    public override DateTimeOffset GetUtcNow() => start + (DateTimeOffset.UtcNow - started);
}
